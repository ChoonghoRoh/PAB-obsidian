# Phase 1-5 의도 동결 (Intent)

**작성일**: 2026-05-02 (REWORK 진입 시점)
**위상**: Phase 1-5의 *변경 불가* 본질 정의. 모든 산출물·검증·결정은 본 문서를 우선한다.
**유래**: 사용자 본질 통찰 — 원문을 보존하지 않으면 손실 압축 위험 (verifier 검증에서 §한계와 비판으로 자가인지). Karpathy 패턴 자체가 *원본 immutable + 위키 LLM 갱신* 분리인데 위키 한쪽만 만들었음 — 본질 누락.

---

## 본질 5항목 (변경 불가)

1. **원본 immutable 보존**
   - 위치: `wiki/15_Sources/YYYY-MM-DD_<slug>_source.md`
   - TYPE: `SOURCE` (신규)
   - 변경 정책: 작성 후 *수정 금지* (Karpathy "raw sources" 계층)
   - 보존 범위: URL/글의 원문 텍스트 + 출처 메타 (이미지·PDF는 본 Phase 외 별건)

2. **LLM 요약본**
   - 위치: `wiki/10_Notes/YYYY-MM-DD_<slug>.md` (현행)
   - TYPE: `RESEARCH_NOTE`/`CONCEPT`/`LESSON` 등 (현행 6 TYPE)
   - LLM이 지속 갱신 가능 (Karpathy "wiki" 계층)

3. **TOC 양방향 링크**
   - 요약본 각 H2 섹션 헤더 직후에 원본 anchor 링크 자동 삽입
   - 형식: `[원본 §<섹션명> →](2026-05-02_..._source#<섹션-anchor>)`
   - 요약본 frontmatter `sources`에 원본 wikilink 포함
   - 원본 frontmatter `sources`에 외부 URL만 (요약 링크는 backlink로 자동 형성)

4. **항상 두 산출물 동시 생성**
   - `/pab:wiki <input>` 1회 호출 → 원본 + 요약 두 파일 동시 생성
   - 옵션 모드 아님 (`--mode=full` 같은 분기 없음). 기본 동작.

5. **Karpathy 3계층 아키텍처 충족**
   - 원본 출처(immutable): `wiki/15_Sources/`
   - 위키(LLM 유지): `wiki/10_Notes/` + `wiki/00_MOC/`
   - 스키마(설정): `wiki/30_Constraints/` + `skills/wiki/SKILL.md`

---

## 본 Phase 진입 시 합의된 부수 결정

- **폴더 prefix**: `15_Sources/` (10_Notes와 _attachments 사이)
- **신규 TYPE 이름**: `SOURCE`
- **원본 보존 범위**: URL 본문 텍스트 (이미지/PDF 자동 다운로드는 본 Phase 외)
- **재작업 트리거**: 본 Phase 1-5 안에서 진행 (Phase 신설 안 함, 기존 G2_wiki PASS는 REWORK 후 재검증)

---

## 본 Phase 비목표 (out-of-scope, 잃지 말 것)

- ❌ 다중 SKILL 분리 (wiki-link-suggest 등) — 단일 `/pab:wiki`만
- ❌ skill_bridge.py + JSON 프로토콜 — LLM이 직접 작성
- ❌ Type A/B 패턴 일반화 — nexus 후속 별건
- ❌ `/pab:report`, `/pab:research` 등 타 skill — 별건
- ❌ 옵션 driven CLI 형태 — LLM intelligence 인터페이스 유지
- ❌ 이미지/PDF 자동 다운로드 — 본 Phase 외

---

## Chapter end 리마인드 절차

매 Task 완료 시 Team Lead가 다음 표를 작성하여 자가검증:

| 본질 항목 | 이번 chapter에서 부합? | 근거 |
|---|---|---|
| 1. 원본 immutable 보존 | ✓/✗ | ... |
| 2. LLM 요약본 | ✓/✗ | ... |
| 3. TOC 양방향 링크 | ✓/✗ | ... |
| 4. 두 산출물 동시 생성 | ✓/✗ | ... |
| 5. Karpathy 3계층 충족 | ✓/✗ | ... |

✗ 항목 발생 시 즉시 정정, 다음 chapter로 진행 금지.

---

## Cross-model 검증 강제

| 단계 | 모델 |
|---|---|
| 구현 (backend-dev) | sonnet |
| 검증 (verifier) | **opus** (다른 모델 강제) |
| auditor mode (verifier 마지막 단계) | opus가 의도 부합 별도 체크 |

verifier는 Hard/Soft Match 검증에 더해 본 본질 5항목을 *반드시* 체크하고 보고서에 명시한다.

---

## 본 문서 변경 정책

- **변경 가능**: Chapter end 리마인드 결과 추가, 부수 결정 보강
- **변경 불가**: 본질 5항목, 비목표 5항목
- 변경 가능 항목도 사용자 합의 없이는 변경 금지.
