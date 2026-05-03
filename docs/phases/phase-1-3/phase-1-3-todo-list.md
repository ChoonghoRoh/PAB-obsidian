# Phase 1-3 Todo List

## T-1: TYPES MOC 6종 작성 (backend-dev)

- [ ] `wiki/00_MOC/TYPES/` 디렉토리 생성
- [ ] `RESEARCH_NOTE.md` 작성 (frontmatter 11필드 + dataview + 폴백 + 가이드)
- [ ] `CONCEPT.md` 작성
- [ ] `LESSON.md` 작성
- [ ] `PROJECT.md` 작성
- [ ] `DAILY.md` 작성
- [ ] `REFERENCE.md` 작성
- [ ] 6개 파일 모두 frontmatter `type: "[[REFERENCE]]"` (MOC는 REFERENCE TYPE), `tags`에 `moc` + `types/{type}` 슬러그 포함
- [ ] dataview 쿼리: `LIST FROM "" WHERE type = "[[<TYPE>]]" SORT created DESC`
- [ ] 폴백 정적 링크 섹션 (현재는 빈 placeholder, Phase 1-4 `wiki moc-build`로 자동 채움)

## T-2: DOMAINS MOC 6종 작성 (backend-dev)

- [ ] `wiki/00_MOC/DOMAINS/` 디렉토리 생성
- [ ] `AI.md` 작성
- [ ] `HARNESS.md` 작성
- [ ] `ENGINEERING.md` 작성
- [ ] `PRODUCT.md` 작성
- [ ] `KNOWLEDGE_MGMT.md` 작성
- [ ] `MISC.md` 작성
- [ ] 6개 파일 frontmatter `type: "[[REFERENCE]]"`, `index: "[[ROOT]]"`, `tags`에 `moc` + `domains/{domain}` 슬러그 포함
- [ ] dataview 쿼리: `LIST FROM "" WHERE index = "[[<DOMAIN>]]" SORT created DESC`
- [ ] 도메인 정의/범위 섹션 (각 DOMAIN의 의미와 포괄 범위)
- [ ] 폴백 정적 링크 섹션

## T-3: TOPICS placeholder + 자동 생성 규칙 (backend-dev)

- [ ] `wiki/00_MOC/TOPICS/` 디렉토리 생성
- [ ] `_README.md` 작성 (frontmatter 포함)
- [ ] 자동 승격 임계치 명시 (노트 N건 이상 등장 시 MOC 승격, N=3 권고)
- [ ] 명명 규약: `topics/{slug}` → `TOPIC_{SLUG}.md` 또는 `{TOPIC}.md` (대문자)
- [ ] dataview 템플릿 스니펫 (TOPIC MOC 작성 시 복사 사용)

## T-4: _INDEX.md 갱신 (backend-dev, T-1~T-3 후)

- [ ] 기존 `_INDEX.md` 읽기 → placeholder 섹션 식별
- [ ] By Type 섹션: dataview 쿼리(`LIST FROM "00_MOC/TYPES"`) + 폴백 정적 링크 6개
- [ ] By Domain 섹션: dataview 쿼리(`LIST FROM "00_MOC/DOMAINS"`) + 폴백 정적 링크 6개
- [ ] By Topic 섹션: dataview 쿼리(`LIST FROM "00_MOC/TOPICS"`) + 폴백 placeholder
- [ ] 사용 가이드: MOC 추가 방법 + 시드 노트 작성 시 `index`/`topics` 백링크 권고

## T-5: TOC 추천 알고리즘 명세 (backend-dev)

- [ ] `wiki/30_Constraints/toc-recommendation.md` 작성 (frontmatter 11필드)
- [ ] 입력 정의: 마크다운 노트 1건 (heading 구조 포함)
- [ ] 출력 정의: outline 추천 (마크다운 또는 JSON)
- [ ] 알고리즘 단계: heading depth(H1~H4) 분석 + 섹션 길이 휴리스틱 + LLM 보강 기준
- [ ] 의사코드(pseudo-code) 1블록
- [ ] 적용 예시 1건 (Before/After)
- [ ] Phase 1-4 T-5 구현 인터페이스 (입력/출력 JSON 스키마)

## T-6: Schema strict 정렬 (backend-dev, T-1~T-5 후)

- [ ] `wiki/40_Templates/_schema.json` 수정: type pattern에 `INDEX` 추가, type description/examples 동기화, tags items pattern을 `^[a-z0-9-]+(/[a-z0-9-]+)*$`로 확장, tags description/examples nested 예시 추가 (총 5개 위치)
- [ ] `wiki/30_Constraints/frontmatter-spec.md` 4개 항목 동기화 (type 7종, tags nested 허용)
- [ ] `wiki/30_Constraints/linking-policy.md` 동기화 (type/tag pattern 언급 있을 시)
- [ ] JSON parse 통과 (`python3 json.load`)
- [ ] jsonschema strict 14/14 PASS (또는 manual diff 확인)
- [ ] 13 WARN → 0 해소 검증
- [ ] reports/report-backend-dev.md §T-6 섹션 추가

## G2_wiki 재검증 (verifier, T-6 후)

- [ ] T-6 변경 결과 검증 (schema strict diff 0 확인)
- [ ] reports/report-verifier.md §T-6 후속 섹션 추가

## G2_wiki 검증 (verifier)

- [ ] T-1~T-3 산출물 13개 frontmatter 11필드 검증 (Critical 3 필수)
- [ ] T-4 _INDEX.md 갱신 결과 검증 (3 placeholder 모두 채워짐)
- [ ] T-5 toc-recommendation.md 의사코드 + 예시 존재 확인
- [ ] MOC 간 cross-link 정합성: TYPES MOC ↔ DOMAINS MOC ↔ _INDEX.md 도달 가능
- [ ] dataview 쿼리 syntax valid (수기 검토)
- [ ] Phase 1-2 unresolved `[[AI]]`/`[[ROOT]]`/`[[CONSTRAINTS]]` 등 자동 해소 확인
- [ ] `reports/report-verifier.md` 작성

## Phase 완료 (Team Lead)

- [ ] G2_wiki PASS 확인 → G4 PASS 전이
- [ ] phase-1-3-status.md `current_state: DONE` 갱신
- [ ] master-plan §Phase 1-3에 CHAIN-5 1줄 완료 요약 추가
- [ ] REFACTOR-1: 500줄 초과 파일 스캔 (MOC는 단순 구조라 초과 가능성 낮음)
- [ ] NOTIFY-1: `[PAB-Wiki] ✅ Phase 1-3 완료` Telegram 발송
- [ ] HR-7 LIFECYCLE-2: backend-dev/verifier shutdown_request → TeamDelete
