# Phase 1-5 Todo List — `/pab:wiki` SSOT skill 어댑터

## 진입 체크리스트 (Team Lead)

- [x] FRESH-1 SSOT v8.3 리로드
- [x] ENTRY-1~5 (status.md 작성)
- [x] HR-4 / CHAIN-10 디렉토리 패턴 검증
- [x] REFACTOR-2 레지스트리 확인 (700줄 초과 0건)
- [x] baseline 시뮬레이션 보고서 저장 (`poc/wiki-skill-simulation-baseline.md`)
- [x] plan.md 작성 (master-plan 단순화 명시)
- [ ] TeamCreate(`phase-1-5`) + backend-dev + verifier 스폰
- [ ] backend-dev에 T-1, T-2, T-4 위임 (SendMessage)
- [ ] verifier에 T-3 위임 (SendMessage)

## 구현 체크리스트 (backend-dev)

### T-1 — plugin namespace 셋업
- [ ] `.claude-plugin/plugin.json` 작성 (`name: pab`, version 0.1.0)
- [ ] `skills/wiki/` 디렉토리 생성
- [ ] 디렉토리 구조 검증 (`ls .claude-plugin/`, `ls skills/wiki/`)

### T-2 — `skills/wiki/SKILL.md` 작성
- [ ] frontmatter 작성 — `name: wiki`, `description`, `argument-hint`, `user-invocable: true`, `allowed-tools`
- [ ] §0 `--help` 처리 (PAB 공통)
- [ ] §1 입력 파싱 (위치 인수 자연어 + `--type`/`--dry` override)
- [ ] §2 옵시디언 규격 인라인
  - 6 TYPE 판별 휴리스틱 (RESEARCH_NOTE/CONCEPT/LESSON/PROJECT/DAILY/REFERENCE) — 예시 5건 이상
  - 6 DOMAIN 매핑표 (AI/HARNESS/ENGINEERING/PRODUCT/KNOWLEDGE_MGMT/MISC)
  - frontmatter 11필드 정의 (Critical 3 + High 5 + Low 3)
  - naming-convention `YYYY-MM-DD_slug.md` + slug 정규식
- [ ] §3 처리 절차 (10 step)
  1. 입력 파싱 + 외부 URL 페치 (있으면)
  2. TYPE 자동 판별
  3. DOMAIN 자동 매핑
  4. TOPIC 후보 추출 + 신규 TOPIC 마중물 정책
  5. 메타데이터 생성 (title/slug/aliases/tags/keywords/sources)
  6. 본문 생성 (옵시디언 친화 + wikilink 자동 삽입)
  7. frontmatter 11필드 채움
  8. 파일 저장 (`wiki/10_Notes/YYYY-MM-DD_<slug>.md`)
  9. `wiki link-check <파일>` 호출 검증
  10. 사용자 응답 메시지 출력
- [ ] §4 nexus 이전 가이드 (3개 복사 + 변경 항목)
- [ ] R-3 검증: 파일 분량 400줄 이하

### T-4 — `.claude/CLAUDE.md` 갱신
- [ ] plugin 호출 안내 한 줄 추가 (예: "`/pab:wiki <내용>` — 옵시디언 규격 wiki 노트 자동 생성")

## 검증 체크리스트 (verifier — T-3)

### G2_wiki — baseline 비교
- [ ] `/pab:wiki <baseline 입력>` 실제 호출 (Claude Code 재시작 후)
- [ ] 생성 파일 경로 확인 — `wiki/10_Notes/YYYY-MM-DD_*.md`
- [ ] frontmatter 11필드 모두 존재 검증
- [ ] 결정적 일치 항목 9개 모두 PASS (baseline §11.1)
- [ ] 의미적 일치 항목 6개 검토 (baseline §11.2 — Soft Match)
- [ ] `python3 scripts/wiki/wiki.py link-check <파일>` PASS
- [ ] 차이 분석 — FAIL 시 SKILL.md 보강 권고
- [ ] 리포트 작성 — `reports/report-verifier.md`

### G4 — Phase 완료 조건
- [ ] G1 PASS / G2_wiki PASS 확인
- [ ] Blocker 0건
- [ ] backend-dev / verifier 리포트 모두 작성됨

## 완료 체크리스트 (Team Lead)

- [ ] G4 PASS 확인 → status.md `current_state: DONE`
- [ ] REFACTOR-1 — 코드 스캔, 500줄 초과 신규 파일 0건 확인
- [ ] CHAIN-5 — Phase Chain 파일에 1줄 완료 요약 기록
- [ ] HR-8 / NOTIFY-1 — `scripts/pmAuto/report_to_telegram.sh` 발송
  - 메시지: `[PAB-Wiki] ✅ Phase 1-5 완료: /pab:wiki SSOT skill 어댑터\n📊 결과: G2_wiki PASS, baseline 일치\n📁 보고서: docs/phases/phase-1-5/reports/`
- [ ] LIFECYCLE-2 — 팀원 shutdown_request → TeamDelete
