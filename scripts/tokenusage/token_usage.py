#!/usr/bin/env python3
"""토큰 집계기 — CORE/shared-definitions.md §8을 그대로 구현한다.

형식 가정(transcript 필드) — 가정이 깨진 줄은 전체를 중단하지 않고
"읽지 못한 줄" 수로 드러난다(줄 단위 UTF-8 디코딩 · JSON 파싱 · 필드 접근 모두):
  - 최상위 세션 파일 `DIR/<session-id>.jsonl`: 한 줄이 JSON 객체 하나.
    레코드 필드 `timestamp`(ISO8601 문자열) · `message.id` · `message.usage`
    (객체 — `input_tokens` · `cache_creation_input_tokens` ·
    `cache_read_input_tokens` · `output_tokens`). 팀원 세션 레코드에는
    `agentName` · `teamName`도 있다(리더 세션은 `agentName` = 세션 제목,
    `teamName` 없음).
  - 서브에이전트·포크 파일 `DIR/<session-id>/subagents/<agent>.jsonl` +
    짝 `<agent>.meta.json`(키 `name` · `agentType`) — 레코드 필드는 위와 같다.
  - 묶음 키: 최상위 파일은 `세션 id 앞 8자[-agentName[(teamName)]]`,
    서브에이전트 파일은 meta의 `name`(없으면 `agentType`, 없으면 파일명).
  - 열지 못한 파일(OSError)은 unopened_files로 따로 센다(조용히 넘기지 않음).

종료 코드: 0 정상 · 1 대상 없음(파일 0 또는 구간 안 usage 0) · 2 사용법 오류 ·
  3 처리 중 예기치 않은 오류(형식 가정 밖의 예외).
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

USAGE_KEYS = (
    'input_tokens', 'cache_creation_input_tokens',
    'cache_read_input_tokens', 'output_tokens',
)


def default_project_dir():
    cwd = os.getcwd()
    name = re.sub(r'[^A-Za-z0-9-]', '-', cwd)
    return Path.home() / '.claude' / 'projects' / name


def parse_iso(value):
    text = value.strip()
    if text.endswith('Z'):
        text = text[:-1] + '+00:00'
    dt = datetime.fromisoformat(text)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def session_matches(session_id, filters):
    if not filters:
        return True
    return any(session_id.startswith(f) for f in filters)


def top_level_key(session_id, agent_name, team_name):
    prefix = session_id[:8] if session_id else 'unknown'
    if agent_name and team_name:
        return '{0}-{1}({2})'.format(prefix, agent_name, team_name)
    if agent_name:
        return '{0}-{1}'.format(prefix, agent_name)
    return prefix


def decode_line(raw_bytes):
    try:
        return raw_bytes.decode('utf-8').strip()
    except UnicodeDecodeError:
        return None


def subagent_key(meta_path, fallback):
    try:
        with meta_path.open('r', encoding='utf-8') as f:
            meta = json.load(f)
    except (OSError, ValueError):
        return fallback
    return meta.get('name') or meta.get('agentType') or fallback


class Aggregator:
    def __init__(self, since, until):
        self.since = since
        self.until = until
        self.seen_ids = set()
        self.stats = {}
        self.unread = 0
        self.unopened_files = 0

    def add(self, key, usage):
        entry = self.stats.setdefault(key, {'noncache': 0, 'cache_read': 0, 'messages': 0})
        noncache = sum(usage.get(k, 0) or 0 for k in ('input_tokens', 'cache_creation_input_tokens', 'output_tokens'))
        entry['noncache'] += noncache
        entry['cache_read'] += usage.get('cache_read_input_tokens', 0) or 0
        entry['messages'] += 1

    @staticmethod
    def usage_is_valid(usage):
        for k in USAGE_KEYS:
            v = usage.get(k, 0)
            if v is None:
                continue
            if isinstance(v, bool) or not isinstance(v, int):
                return False
        return True

    def in_range(self, ts):
        if ts < self.since:
            return False
        if self.until is not None and ts >= self.until:
            return False
        return True

    def process_file(self, path, key):
        try:
            handle = path.open('rb')
        except OSError:
            self.unopened_files += 1
            return
        with handle:
            for raw_bytes in handle:
                raw = decode_line(raw_bytes)
                if raw is None:
                    self.unread += 1
                    continue
                if not raw:
                    continue
                try:
                    record = json.loads(raw)
                except ValueError:
                    self.unread += 1
                    continue
                try:
                    ts_raw = record.get('timestamp')
                    if not ts_raw:
                        continue
                    ts = parse_iso(ts_raw)
                    if not self.in_range(ts):
                        continue
                    message = record.get('message') or {}
                    usage = message.get('usage')
                    if not usage:
                        continue
                    if not self.usage_is_valid(usage):
                        self.unread += 1
                        continue
                    msg_id = message.get('id')
                    if msg_id:
                        if msg_id in self.seen_ids:
                            continue
                        self.seen_ids.add(msg_id)
                    self.add(key, usage)
                except (AttributeError, TypeError, ValueError):
                    self.unread += 1
                    continue


def iter_project_dirs(args):
    if args.project_dirs:
        return [Path(d) for d in args.project_dirs]
    return [default_project_dir()]


def collect(agg, project_dirs, session_filters):
    file_count = 0
    for base in project_dirs:
        if not base.is_dir():
            continue
        for top in sorted(base.glob('*.jsonl')):
            session_id = top.stem
            if not session_matches(session_id, session_filters):
                continue
            file_count += 1
            agent_name, team_name = peek_top_fields(top)
            key = top_level_key(session_id, agent_name, team_name)
            agg.process_file(top, key)
        for session_dir in sorted(p for p in base.glob('*') if p.is_dir()):
            session_id = session_dir.name
            if not session_matches(session_id, session_filters):
                continue
            sub_dir = session_dir / 'subagents'
            if not sub_dir.is_dir():
                continue
            for sub in sorted(sub_dir.glob('*.jsonl')):
                file_count += 1
                meta_path = sub.with_name(sub.stem + '.meta.json')
                key = subagent_key(meta_path, sub.stem)
                agg.process_file(sub, key)
    return file_count


def peek_top_fields(path):
    agent_name = None
    team_name = None
    try:
        handle = path.open('rb')
    except OSError:
        return agent_name, team_name
    with handle:
        for raw_bytes in handle:
            raw = decode_line(raw_bytes)
            if not raw:
                continue
            try:
                record = json.loads(raw)
                if record.get('agentName'):
                    agent_name = record['agentName']
                    team_name = record.get('teamName')
                    break
            except (ValueError, AttributeError, TypeError):
                continue
    return agent_name, team_name


def render_text(agg, file_count):
    lines = []
    header = '{0:<40} {1:>14} {2:>12} {3:>8}'.format('역할(이름)', '비캐시', 'cache_read', '메시지')
    lines.append(header)
    lines.append('-' * len(header))
    total_noncache = total_cache_read = total_messages = 0
    for key in sorted(agg.stats):
        v = agg.stats[key]
        lines.append('{0:<40} {1:>14} {2:>12} {3:>8}'.format(key, v['noncache'], v['cache_read'], v['messages']))
        total_noncache += v['noncache']
        total_cache_read += v['cache_read']
        total_messages += v['messages']
    lines.append('-' * len(header))
    lines.append('{0:<40} {1:>14} {2:>12} {3:>8}'.format('합계', total_noncache, total_cache_read, total_messages))
    lines.append('대상 파일: {0}개 · 읽지 못한 줄: {1}개 · 열지 못한 파일: {2}개'.format(
        file_count, agg.unread, agg.unopened_files))
    return '\n'.join(lines)


def render_json(agg, file_count):
    total_noncache = sum(v['noncache'] for v in agg.stats.values())
    total_cache_read = sum(v['cache_read'] for v in agg.stats.values())
    total_messages = sum(v['messages'] for v in agg.stats.values())
    return json.dumps({
        'by_key': agg.stats,
        'total_noncache': total_noncache,
        'total_cache_read': total_cache_read,
        'total_messages': total_messages,
        'file_count': file_count,
        'unread_lines': agg.unread,
        'unopened_files': agg.unopened_files,
    }, ensure_ascii=False, indent=2)


def build_parser():
    parser = argparse.ArgumentParser(
        prog='token_usage.py',
        description='세션 transcript에서 비캐시·cache_read 토큰을 집계한다.',
        epilog='종료 코드: 0 정상 · 1 대상 없음 · 2 사용법 오류 · 3 처리 중 예기치 않은 오류',
    )
    parser.add_argument('--since', required=True, help='ISO8601 — 계측 시작(포함)')
    parser.add_argument('--until', default=None, help='ISO8601 — 계측 종료(미포함)')
    parser.add_argument('--project-dir', dest='project_dirs', action='append', default=[])
    parser.add_argument('--session', dest='sessions', action='append', default=[])
    parser.add_argument('--json', dest='as_json', action='store_true')
    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        since = parse_iso(args.since)
    except ValueError:
        parser.error('--since 값이 ISO8601이 아니다: {0}'.format(args.since))
    until = None
    if args.until is not None:
        try:
            until = parse_iso(args.until)
        except ValueError:
            parser.error('--until 값이 ISO8601이 아니다: {0}'.format(args.until))

    agg = Aggregator(since, until)
    try:
        project_dirs = iter_project_dirs(args)
        file_count = collect(agg, project_dirs, args.sessions)
        out = render_json(agg, file_count) if args.as_json else render_text(agg, file_count)
    except Exception as exc:
        print('예기치 않은 오류 — {0}: {1}'.format(type(exc).__name__, exc), file=sys.stderr)
        return 3
    print(out)

    total_messages = sum(v['messages'] for v in agg.stats.values())
    if total_messages == 0:
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
