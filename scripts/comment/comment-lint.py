#!/usr/bin/env python3
"""주석 하네스 — 스캔 / 검사 / 포인터 수집.

규격
    <!-- Name : 한글명 · 260918 -->
    <!-- Name : 한글명 · 260918/260920 · point-12 -->
    <!-- // Name -->

하위명령
    scan    현재 실태를 센다 (기준선)
    lint    규격 위반을 잡는다
    points  코드의 point-N 을 모아 리포트와 대조한다
    map     포인터 맵의 «연결 파일» 열을 다시 쓴다
    show    리포트 항목을 보고 «최근 조회» 를 찍는다
"""
import argparse
import os
import re
import subprocess
import sys
from datetime import datetime

DELIMS = {
    '.html': [('<!--', '-->')], '.htm': [('<!--', '-->')],
    '.jsx': [('{/*', '*/}'), ('/*', '*/'), ('//', None)],
    '.tsx': [('{/*', '*/}'), ('/*', '*/'), ('//', None)],
    '.js': [('/*', '*/'), ('//', None)], '.ts': [('/*', '*/'), ('//', None)],
    '.css': [('/*', '*/')], '.scss': [('/*', '*/'), ('//', None)],
    '.sh': [('#', None)], '.py': [('#', None)],
}
SKIP_DIRS = {'node_modules', '.git', 'dist', 'build', '.next', 'vendor'}

OPEN_RE = re.compile(
    r'^(?P<name>[A-Za-z][A-Za-z0-9]*)\s*:\s*(?P<ko>[^·]+?)\s*·\s*'
    r'(?P<d1>\d{6})(?:\s*/\s*(?P<d2>\d{6}))?'
    r'(?:\s*·\s*point-(?P<pt>\d+))?$'
)
CLOSE_RE = re.compile(r'^//\s*(?P<name>[A-Za-z][A-Za-z0-9]*)$')
POINT_RE = re.compile(r'point-(\d+)')

# BannedNum : 금지 수치 패턴 · 260921
BANNED_NUM = re.compile(r'\d+\s*(개|종|건|줄|행|자|%|px|em|rem|초|분)')
# // BannedNum
# Narrative : 설명형 신호 · 260921
NARRATIVE = re.compile(r'(합니다|됩니다|입니다|한다\b|된다\b|하며|이므로|때문에|위해)')
# // Narrative
# Historical : 이력 서술 신호 · 260921
HISTORICAL = re.compile(r'(Phase\s*\d|DEF-\d|\d{4}-\d{2}-\d{2}|v\d+\.\d+|ver\d)')
# // Historical

# CodeExample : 코드 예시 신호 · 260923
CODE_EXAMPLE_RE = re.compile(
    r'[A-Za-z0-9_$\]]\([^()]*\)\s*;|\{[^{}]*;[^{}]*\}'
    r'|\)\s*=>|=>\s*[{(]|\(\s*[A-Za-z_$][\w$]*\s*=>|:='
    r'|[A-Za-z0-9_)\]\'"]\s*===?\s*[A-Za-z0-9_(\'"\[-]'
    r'|\b(?:if|for|while)\s*\([^()]*\)\s*[{:]|\bdef\s+\w+\s*\(|\bfunction\b\s*\w*\s*\([^()]*\)\s*\{'
    r'|\breturn\s+[A-Za-z0-9_.$()\[\]\'"]+\s*;?\s*$'
    r'|</[A-Za-z][\w-]*\s*>|<[A-Za-z][\w-]*(?:\s[^<>]*)?/>|<[A-Za-z][\w-]*\s[^<>]*\b[\w:@-]+=["\'{][^<>]*>'
    r'|^import\s+(?:[\w.]+(?:\s+as\s+\w+)?\s*$|[{*])|\bfrom\s+[A-Za-z0-9_.]+\s+import\s+[\w*({]'
)
# // CodeExample

MAX_KO_WORDS = 5
MAX_LEN = 60


def walk(root):
    """(경로, 확장자) 목록. root가 파일이면 그 파일 하나만 낸다."""
    if os.path.isfile(root):
        ext = os.path.splitext(root)[1]
        if ext in DELIMS:
            yield root, ext
        return
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            ext = os.path.splitext(fn)[1]
            if ext in DELIMS:
                yield os.path.join(dirpath, fn), ext


def out_root(root):
    """상대 경로 출력 기준. root가 파일이면 그 파일의 디렉토리를 쓴다."""
    root = os.path.abspath(root)
    return os.path.dirname(root) if os.path.isfile(root) else root


def _tail_comment_pos(line, op):
    """닫는 기호가 없는 구분자(#, //)의 실제 시작 위치. 없으면 -1.

    줄 머리이거나, 바로 앞이 공백이고 앞 구간의 따옴표 개수가 짝수이면 인정한다.
    """
    start = 0
    while True:
        i = line.find(op, start)
        if i < 0:
            return -1
        prefix = line[:i]
        if prefix.strip() == '':
            return i
        if (prefix[-1] in ' \t'
                and prefix.count("'") % 2 == 0
                and prefix.count('"') % 2 == 0):
            return i
        start = i + len(op)


def comments(path, ext):
    """(행번호, 본문) 목록. 한 줄 안에 닫히는 주석만 다룬다."""
    out = []
    try:
        lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
    except OSError:
        return out
    for n, line in enumerate(lines, 1):
        for op, cl in DELIMS[ext]:
            i = _tail_comment_pos(line, op) if cl is None else line.find(op)
            if i < 0:
                continue
            rest = line[i + len(op):]
            if cl:
                j = rest.find(cl)
                if j < 0:
                    continue
                body = rest[:j]
            else:
                body = rest
            body = body.strip()
            if body:
                out.append((n, body))
            break
    return out


def git_mtime(path):
    """마지막 커밋 날짜(YYMMDD). 미커밋·오류면 None."""
    try:
        r = subprocess.run(
            ['git', 'log', '-1', '--format=%ad', '--date=format:%y%m%d', '--', path],
            capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None
    v = r.stdout.strip()
    return v if r.returncode == 0 and re.fullmatch(r'\d{6}', v) else None


def valid_date(s):
    try:
        datetime.strptime(s, '%y%m%d')
        return True
    except ValueError:
        return False


def ko_is_ordinal_only(ko):
    """한글명의 숫자가 «끝자리 순번» 하나뿐인가."""
    nums = re.findall(r'\d+', ko)
    if not nums:
        return True
    return len(nums) == 1 and re.search(r'\d+\s*$', ko) is not None


_NT_BLANK = re.compile(r'^[=\-─━═*#_~ ]+$')
_NT_SHELLCHECK = re.compile(r'^shellcheck\s')
_NT_TS_REF = re.compile(r'^/\s*<reference\b')
_NT_IE_COND = re.compile(r'^\[if\b')


# IsNonTarget : 판정 제외 · 260921/260927
def is_non_target(body, ext, lineno):
    """셔뱅·장식 문자만인 배너·shellcheck 지시어·디렉티브를 규격 검사 대상에서 뺀다.

    (주석은 맞지만 검사 대상이 아니다. 장식 문자와 글자가 섞인 줄은 대상이다)
    """
    if lineno == 1 and body.startswith('!'):
        return True
    if _NT_BLANK.fullmatch(body):
        return True
    if _NT_SHELLCHECK.match(body):
        return True
    if ext in ('.ts', '.tsx', '.js', '.jsx') and _NT_TS_REF.match(body):
        return True
    if ext in ('.html', '.htm') and _NT_IE_COND.match(body):
        return True
    return False
# // IsNonTarget


# IsCodeExample : 코드 예시 판정 · 260923
def is_code_example(body):
    """주석 본문에 코드 예시 신호(괄호·연산자·키워드·태그·import)가 있는가."""
    return bool(CODE_EXAMPLE_RE.search(body))
# // IsCodeExample


def cmd_scan(args):
    tot = marker = narrative = numeric = historical = excluded = code_ex = 0
    files = 0
    per_ext = {}
    for path, ext in walk(args.root):
        cs = comments(path, ext)
        if not cs:
            continue
        files += 1
        for n, body in cs:
            tot += 1
            per_ext[ext] = per_ext.get(ext, 0) + 1
            if is_non_target(body, ext, n):
                excluded += 1
                continue
            if is_code_example(body):
                code_ex += 1
                continue
            if OPEN_RE.match(body) or CLOSE_RE.match(body):
                marker += 1
                continue
            if NARRATIVE.search(body) or len(body) > MAX_LEN:
                narrative += 1
            if BANNED_NUM.search(body):
                numeric += 1
            if HISTORICAL.search(body):
                historical += 1
    pct = (lambda n: f'{n / tot * 100:.1f}%' if tot else '-')
    print(f'대상 파일      {files}개')
    print(f'주석 총계      {tot}건')
    print(f'  판정 제외    {excluded}건  {pct(excluded)}')
    print(f'  코드 예시    {code_ex}건  {pct(code_ex)}   ← 제거 · point-N 이관 대상')
    print(f'  규격 표지    {marker}건  {pct(marker)}')
    print(f'  설명형       {narrative}건  {pct(narrative)}   ← 교체 대상')
    print(f'  금지 수치    {numeric}건  {pct(numeric)}   ← 제거 대상')
    print(f'  이력 서술    {historical}건  {pct(historical)}   ← 리포트 이관 대상')
    if per_ext:
        print('  확장자별     ' + ' '.join(f'{k}:{v}' for k, v in sorted(per_ext.items())))
    return 0


HUNK_RE = re.compile(r'^@@ -\d+(?:,\d+)? \+(?P<s>\d+)(?:,(?P<l>\d+))? @@')

def file_line_count(path):
    """파일의 총 줄 수(끝 개행 제외 · 최소 1)."""
    try:
        c = open(path, encoding='utf-8', errors='replace').read()
        return max(1, c.count('\n') + (0 if c.endswith('\n') else 1))
    except OSError:
        return 1

def _git(repo, *args):
    """git 실행(quotePath · color · prefix 고정 · UTF-8 관용) — 실패(예외 · 반환코드≠0)면 None."""
    cfg = ['-c', 'core.quotePath=false', '-c', 'color.diff=never', '-c', 'diff.noprefix=false', '-c', 'diff.mnemonicPrefix=false']
    try:
        r = subprocess.run(['git', *cfg, '-C', repo, *args], capture_output=True, encoding='utf-8', errors='replace', timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None
    return r if r.returncode == 0 else None

# ChangedLines : 변경 줄 집계 · 260923/260924
def changed_lines_by_file(root, rev):
    """{절대경로: 변경 줄 집합} · 추적 안 된 새 파일은 'ALL'. 실패시 (None, 오류문구)."""
    base = os.path.dirname(os.path.realpath(root)) if os.path.isfile(root) else os.path.realpath(root)
    top = _git(base, 'rev-parse', '--show-toplevel')
    if top is None: return None, 'git 밖이다'
    repo = top.stdout.strip()
    ver = _git(repo, 'rev-parse', '--verify', f'{rev}^{{commit}}')
    if ver is None: return None, f'<rev> 해석 불가 — {rev}'
    rel = os.path.relpath(base, repo)
    diff = _git(repo, 'diff', '--no-ext-diff', '--src-prefix=a/', '--dst-prefix=b/', '-U0', rev, '--', rel)
    un = _git(repo, 'ls-files', '--others', '--exclude-standard', '--', rel)
    if diff is None or un is None: return None, 'git 조회 실패'
    out = {}
    cur = prev_minus = None
    in_header = False
    for line in diff.stdout.split('\n'):
        if line.startswith('diff --git '):
            in_header, prev_minus, cur = True, False, None
            continue
        if in_header:
            if prev_minus and line.startswith('+++ '):
                p = line[4:].strip()
                cur = None if p == '/dev/null' else os.path.join(repo, p[2:])
            prev_minus = line.startswith('--- ')
        m = HUNK_RE.match(line)
        if m:
            in_header = False
            if cur:
                s, length = int(m.group('s')), int(m.group('l') or 1)
                if length: out.setdefault(cur, set()).update(range(s, s + length))
    for p in un.stdout.strip().split('\n'):
        if p:
            out[os.path.join(repo, p)] = 'ALL'
    return out, None
# // ChangedLines

def cmd_lint(args):
    if not os.path.exists(args.root):
        print(f'오류 — 없는 경로: {args.root}', file=sys.stderr)
        return 2
    if os.path.isfile(args.root):
        ext = os.path.splitext(args.root)[1]
        if ext not in DELIMS:
            print(f'오류 — 판정 대상 아님(확장자 {ext}): {args.root}', file=sys.stderr)
            return 2

    changed = None
    if args.changed is not None:
        changed, err = changed_lines_by_file(args.root, args.changed)
        if err: print(f'오류 — {err}', file=sys.stderr); return 2

    errs = []
    blocks_by_file = {}
    walked = set()
    for path, ext in walk(args.root):
        if changed is not None: path = os.path.realpath(path)
        walked.add(path)
        cs = comments(path, ext)
        if not cs:
            continue
        gm = git_mtime(path) if args.check_date else None
        stack = []
        file_blocks = [] if changed is not None else None
        for n, body in cs:
            if is_non_target(body, ext, n):
                continue
            if is_code_example(body):
                errs.append((path, n, 'L8', f'주석 내 코드 예시 — {body[:40]}'))
                continue
            m = CLOSE_RE.match(body)
            if m:
                if not stack:
                    errs.append((path, n, 'L4', f'여는 표지 없이 닫음 — {m.group("name")}'))
                elif stack[-1][0] != m.group('name'):
                    errs.append((path, n, 'L4',
                                 f'짝 불일치 — 열림 {stack[-1][0]}(L{stack[-1][1]}) ≠ 닫힘 {m.group("name")}'))
                else:
                    if file_blocks is not None: file_blocks.append((stack[-1][1], n))
                    stack.pop()
                continue
            m = OPEN_RE.match(body)
            if not m:
                if NARRATIVE.search(body):
                    errs.append((path, n, 'L7', f'설명형 잔존 — {body[:40]}'))
                elif len(body) > MAX_LEN:
                    errs.append((path, n, 'L7', f'길이 초과({len(body)}자) — {body[:40]}'))
                else:
                    errs.append((path, n, 'L1', f'규격 불일치 — {body[:40]}'))
                continue
            stack.append((m.group('name'), n))
            ko = m.group('ko').strip()
            if len(ko.split()) > MAX_KO_WORDS:
                errs.append((path, n, 'L2', f'한글명 {len(ko.split())}단어 (상한 {MAX_KO_WORDS}) — {ko}'))
            if BANNED_NUM.search(ko):
                errs.append((path, n, 'L3', f'금지 수치 — {ko}'))
            elif not ko_is_ordinal_only(ko):
                errs.append((path, n, 'L3', f'순번 외 숫자 — {ko}'))
            for d in (m.group('d1'), m.group('d2')):
                if d and not valid_date(d):
                    errs.append((path, n, 'L1', f'날짜 아님 — {d}'))
            if gm:
                last = m.group('d2') or m.group('d1')
                if last < gm:
                    errs.append((path, n, 'L5', f'수정일자 stale — 주석 {last} < git {gm}'))
        for name, n in stack: errs.append((path, n, 'L4', f'안 닫힘 — {name}'))
        if file_blocks is not None: file_blocks.extend((n, file_line_count(path)) for _, n in reversed(stack))
        if file_blocks: blocks_by_file[path] = file_blocks

    if changed is not None:
        touched = {}
        for path, blks in blocks_by_file.items():
            ch = changed.get(path)
            if not ch: continue
            lines = range(1, file_line_count(path) + 1) if ch == 'ALL' else ch
            sel = set()
            for n in lines:
                b = next((bo for bo in blks if bo[0] <= n <= bo[1]), None)
                if b: sel.add(b)
            touched[path] = sel
        n_blk = sum(len(v) for v in touched.values())
        n_ln = sum(file_line_count(p) if changed[p] == 'ALL' else len(changed[p])
                   for p in changed if p in walked)
        print(f'범위: --changed {args.changed} — 건드린 블록 {n_blk}개 · 변경 줄 {n_ln}줄')
        errs = [e for e in errs if e[0] in changed and (
            changed[e[0]] == 'ALL' or e[1] in changed[e[0]]
            or any(o <= e[1] <= c for o, c in touched.get(e[0], ())))]

    if not errs:
        print('위반 0건')
        return 0
    by = {}
    for e in errs:
        by[e[2]] = by.get(e[2], 0) + 1
    root = out_root(args.root)
    for path, n, code, msg in errs:
        print(f'{os.path.relpath(path, root)}:{n}  [{code}] {msg}')
    print('\n── 합계 ──')
    for k in sorted(by):
        print(f'  {k} {by[k]}건')
    print(f'  총 {len(errs)}건')
    return 1


def cmd_points(args):
    used = {}
    for path, ext in walk(args.root):
        for n, body in comments(path, ext):
            for pid in POINT_RE.findall(body):
                used.setdefault(int(pid), []).append(f'{path}:{n}')

    declared = read_declared(args.points)
    if not declared:
        print(f'⚠ 항목 없음 — {args.points}/point-N-*.md')

    root = out_root(args.root)
    print(f'코드 참조   {len(used)}종 / {sum(len(v) for v in used.values())}건')
    print(f'항목 파일   {len(declared)}종')

    dead = sorted(set(used) - declared)
    orphan = sorted(declared - set(used))
    if dead:
        print('\n🔴 죽은 참조 — 코드가 가리키는데 항목 파일이 없다')
        for p in dead:
            for loc in used[p]:
                print(f'  point-{p}  {os.path.relpath(loc.rsplit(":", 1)[0], root)}:{loc.rsplit(":", 1)[1]}')
    if orphan:
        print('\n🟡 고아 항목 — 항목 파일은 있는데 코드가 안 가리킨다')
        for p in orphan:
            print(f'  point-{p}')
    if not dead and not orphan:
        print('\n불일치 0건')
    return 1 if dead else 0


MAP_HDR = '| point | 설명 | 연결 파일 | 작성일 | 수정일 | 최근 조회 |'
MAP_SEP = '|---|---|---|---|---|---|'
MAX_LOCS = 3


def collect_points(root):
    """{번호: ['파일:행', ...]}"""
    used = {}
    for path, ext in walk(root):
        for n, body in comments(path, ext):
            for pid in POINT_RE.findall(body):
                used.setdefault(int(pid), []).append((path, n))
    return used


def read_map(path):
    """{번호: [설명, 연결, 작성일, 수정일, 최근조회]} + 표 앞/뒤 원문."""
    rows, head, tail = {}, [], []
    if not os.path.exists(path):
        return rows, head, tail
    lines = open(path, encoding='utf-8').read().split('\n')
    state = 'head'
    for line in lines:
        s = line.strip()
        if state == 'head':
            head.append(line)
            if s.startswith('| point '):
                state = 'sep'
            continue
        if state == 'sep':
            state = 'rows'
            continue
        if state == 'rows':
            if s.startswith('|'):
                c = [x.strip() for x in s.strip('|').split('|')]
                m = POINT_RE.search(c[0]) if c else None
                if m and len(c) >= 6:
                    rows[int(m.group(1))] = c[1:6]
                continue
            state = 'tail'
        tail.append(line)
    return rows, head, tail


def fmt_locs(locs, root):
    rel = [f'`{os.path.relpath(p, root)}:{n}`' for p, n in sorted(locs)]
    if len(rel) > MAX_LOCS:
        return ' · '.join(rel[:MAX_LOCS]) + f' · 외 {len(rel) - MAX_LOCS}곳'
    return ' · '.join(rel)


def write_map(path, rows, head, tail, order, links=None):
    links = links or {}
    out = list(head) + [MAP_SEP]
    for pid in order:
        desc, locs, made, upd, seen = rows[pid]
        rows_link = links.get(pid, f'points/point-{pid}-*.md')
        out.append(f'| [point-{pid}]({rows_link}) '
                   f'| {desc} | {locs} | {made} | {upd} | {seen} |')
    out += tail
    open(path, 'w', encoding='utf-8').write('\n'.join(out))


def cmd_map(args):
    root = out_root(args.root)
    used = collect_points(args.root)
    files = point_files(args.points)
    declared = set(files)
    rows, head, tail = read_map(args.map)
    if not head:
        print(f'⚠ 맵 없음 — {args.map}. 헤더 행이 있어야 한다.')
        return 1

    for pid in sorted(set(used) | set(rows)):
        old = rows.get(pid, ['', '', '', '-', '-'])
        locs = fmt_locs(used[pid], root) if pid in used else '—'
        state = ''
        if pid in used and pid not in declared:
            state = ' 🔴'
        elif pid in declared and pid not in used:
            state = ' 🟡'
        desc = old[0] or (files[pid][1] if pid in files else '') or '(설명 미기재)'
        desc = re.sub(r'\s*[🔴🟡]$', '', desc) + state
        rows[pid] = [desc, locs, old[2] or '-', old[3] or '-', old[4] or '-']

    order = sorted(rows)
    write_map(args.map, rows, head, tail, order,
              {k: os.path.relpath(v[0], os.path.dirname(args.map)) for k, v in files.items()})
    dead = sorted(set(used) - declared)
    orphan = sorted(declared - set(used))
    print(f'맵 갱신 — {len(order)}행 · 연결 {sum(len(v) for v in used.values())}건')
    if dead:
        print(f'🔴 죽은 참조 {len(dead)}건 — ' + ' '.join(f'point-{p}' for p in dead))
    if orphan:
        print(f'🟡 고아 {len(orphan)}건 — ' + ' '.join(f'point-{p}' for p in orphan))
    return 1 if dead else 0


POINT_FILE_RE = re.compile(r'^point-(\d+)(?:-(?P<topic>[^.]+))?\.md$')


def point_files(points_dir):
    """{번호: (경로, 주제어)} — 한 항목 한 파일."""
    out = {}
    if not os.path.isdir(points_dir):
        return out
    for fn in sorted(os.listdir(points_dir)):
        m = POINT_FILE_RE.match(fn)
        if m:
            out[int(m.group(1))] = (os.path.join(points_dir, fn), m.group('topic') or '')
    return out


def read_declared(points_dir):
    return set(point_files(points_dir))


def cmd_show(args):
    m = POINT_RE.search(args.point)
    if not m:
        print('point-N 형식으로 지정한다. 예: point-12')
        return 1
    pid = int(m.group(1))

    files = point_files(args.points)
    if pid not in files:
        print(f'🔴 point-{pid} 파일이 없다 — {args.points}/point-{pid}-*.md')
        return 1
    path, _ = files[pid]
    print(open(path, encoding='utf-8').read().rstrip())
    print(f'\n— {os.path.relpath(path)}')

    if args.no_record:
        return 0

    today = datetime.now().strftime('%y%m%d')
    rows, head, tail = read_map(args.map)
    if pid in rows:
        rows[pid][4] = today
        write_map(args.map, rows, head, tail, sorted(rows),
                  {k: os.path.relpath(v[0], os.path.dirname(args.map)) for k, v in files.items()})
        print(f'\n— 최근 조회 {today} 기록됨')
    else:
        print(f'\n⚠ 맵에 point-{pid} 행이 없다. `comment-lint.py map` 을 먼저 돌린다.')
    return 0


def main():
    ap = argparse.ArgumentParser(description='주석 하네스')
    sub = ap.add_subparsers(dest='cmd', required=True)

    s = sub.add_parser('scan', help='현재 실태 (기준선)')
    s.add_argument('root', nargs='?', default='.')
    s.set_defaults(func=cmd_scan)

    s = sub.add_parser('lint', help='규격 위반 검사')
    s.add_argument('root', nargs='?', default='.')
    s.add_argument('--check-date', action='store_true', help='git 최종 수정일과 대조 (L5)')
    s.add_argument('--changed', metavar='REV', help='git diff -U0 REV 변경 범위(건드린 블록)만 판정')
    s.set_defaults(func=cmd_lint)

    s = sub.add_parser('points', help='포인터 수집·대조')
    s.add_argument('root', nargs='?', default='.')
    s.add_argument('--points', default='docs/comment-policy/points')
    s.set_defaults(func=cmd_points)

    s = sub.add_parser('map', help='포인터 맵 «연결 파일» 열 갱신')
    s.add_argument('root', nargs='?', default='.')
    s.add_argument('--points', default='docs/comment-policy/points')
    s.add_argument('--map', default='docs/comment-policy/pointer-map.md')
    s.set_defaults(func=cmd_map)

    s = sub.add_parser('show', help='리포트 항목 조회 + 최근 조회일 기록')
    s.add_argument('point', help='point-N')
    s.add_argument('--points', default='docs/comment-policy/points')
    s.add_argument('--map', default='docs/comment-policy/pointer-map.md')
    s.add_argument('--no-record', action='store_true', help='맵 「최근 조회」를 기록하지 않는다')
    s.set_defaults(func=cmd_show)

    a = ap.parse_args()
    sys.exit(a.func(a))


if __name__ == '__main__':
    main()
