# 리팩토링 레지스트리

**최종 갱신**: 2026-03-14
**규정**: [refactoring-rules.md](refactoring-rules.md)
**SSOT**: [3-workflow.md §10](../SSOT/renewal/iterations/4th/3-workflow.md#10-코드-유지관리-리팩토링)

---

## 700줄 초과 — 리팩토링 대상

| # | 파일 경로 | 줄 수 | Lv | 상태 | 비고 |
|---|----------|------:|:--:|:----:|------|
| 1 | ~~`backend/routers/knowledge/labels_handlers.py`~~ | ~~748~~ | Lv1 | **해소** | Phase 18-0에서 3파일 분리 완료 |
| 2 | ~~`web/public/css/admin/admin-groups.css`~~ | ~~805~~ | Lv2 | **해소** | Phase 19-3-1에서 5파일 분리 완료 (base 190 + tree 192 + panel 208 + keywords 333 + responsive 20) |

## 500줄 초과 — 모니터링 대상

| # | 파일 경로 | 줄 수 | 잠재 Lv | 등록일 | 비고 |
|---|----------|------:|:------:|:------:|------|
| 1 | ~~`backend/services/system/statistics_service.py`~~ | ~~699~~ | ~~Lv1~~ | **해소** | Phase 20-1 R2: 3파일 분리 (service 222 + document 227 + knowledge 256) |
| 2 | `web/public/css/admin/admin-groups.css` | ~~613~~ **805** | **Lv2 확정** | 2026-02-21 | 700줄 돌파 → 700줄 초과 섹션에 등록 |
| 3 | ~~`web/public/css/reason.css`~~ | ~~607~~ | ~~Lv2~~ | **해소** | Phase 18-3 CSS 재구성: 5파일 분리 |
| 4 | ~~`web/public/css/reason-sections.css`~~ | ~~597~~ | ~~Lv2~~ | **해소** | Phase 18-3 CSS 재구성: 5파일 분리 |
| 5 | ~~`backend/routers/reasoning/stream_executor.py`~~ | ~~588~~ | ~~Lv1~~ | **해소** | Phase 20-1 R1: 3파일 분리 (executor 282 + rag_context_builder 191 + post_processor 106). R5 `reason_helpers.py`(352줄)도 해소 |
| 6 | ~~`backend/routers/automation/automation.py`~~ | ~~631~~ | ~~Lv1~~ | **해소** | Phase 36-1: 2파일 분리 (automation 437 + automation_ingest 194) |
| 7 | `web/public/css/admin/settings-common.css` | 534 | Lv1 | 2026-02-21 | 5개 설정 페이지 공유 |
| 8 | ~~`web/public/js/admin/keyword-group-crud.js`~~ | ~~618 [재발]~~ | ~~Lv1~~ | **해소** | Phase 36-2: 2파일 분리 (crud 500 + category 138). [재발] 해소 |
| 9 | ~~`web/public/js/admin/keyword-group-matching.js`~~ | ~~557~~ | ~~Lv1~~ | **해소** | Phase 36-2: 2파일 분리 (matching 467 + match-logic 146) |
| 10 | ~~`backend/routers/knowledge/labels_crud.py`~~ | ~~575~~ | ~~Lv1~~ | **해소** | Phase 20-1 R3: 2파일 분리 (crud 340 + validation 235) |
| 11 | `web/public/css/cognitive.css` | 719 | CSS 모니터링 | 2026-02-24 | Phase 20-7 신규. CSS 파일 규정 대상 외(모니터링). 6탭 통합 스타일 |
| 12 | `web/public/css/admin/admin-knowledge-files.css` | **620** | Lv1 | 2026-02-26 | Phase 21-5: 409→558줄. Phase 29-2: 배너+뱃지 CSS 추가 (558→620줄) |
| 20 | ~~`web/public/js/admin/knowledge-files.js`~~ | ~~527~~ | ~~Lv1~~ | **해소** | Phase 36-3: 2파일 분리 (knowledge-files 423 + knowledge-files-sync 122) |
| 21 | `web/public/js/components/header-component.js` | **535** | Lv1 | 2026-03-02 | Phase 29-2: 미반영 건수 배지+60초 폴링 추가 (522→535줄). 독립 분리 가능 |
| 23 | ~~`tests/test_knowledge_reset.py`~~ | ~~679~~ | ~~Lv1~~ | **해소** | Phase 36-2: 2파일 분리 (reset 383 + delete 331) |
| 24 | `tests/test_phase20_5.py` | **522** | Lv1 | 2026-03-11 | Phase 20-5: 500줄 모니터링 대상. 테스트 케이스 분리 가능 |
| 13 | ~~`backend/services/reasoning/recommendation_llm.py`~~ | ~~501~~ → **498** | ~~Lv1~~ | **해제** | 500줄 이하로 감소 (501→498줄). 모니터링 해제 |
| 14 | ~~`backend/services/ai/ollama_client.py`~~ | ~~655~~ | ~~Lv1~~ | **해소** | Phase 36-1: 3파일 분리 (ollama_client 374 + ollama_streaming 187 + ollama_preload 138) |
| 15 | ~~`backend/routers/knowledge/knowledge_handlers.py`~~ | ~~558~~ | ~~Lv1~~ | **해소** | Phase 36-3: 2파일 분리 (knowledge_handlers 414 + knowledge_delete_handlers 175) |
| 16 | ~~`backend/routers/knowledge/document_handlers.py`~~ | ~~583~~ | ~~Lv1~~ | **해소** | Phase 36-3: 2파일 분리 (document_handlers 500 + document_delete_handlers 111) |
| 17 | `backend/services/knowledge/folder_service.py` | **517** | Lv1 | 2026-03-02 | Phase 28-4: 경로 검증 (483→514줄). Phase 30-2: user_id 전달 (514→517줄). 독립 분리 가능 |
| 18 | ~~`backend/routers/knowledge/folder_management.py`~~ | ~~616~~ | ~~Lv1~~ | **해소** | Phase 36-1: 3파일 분리 (folder_management 348 + folder_sync 105 + folder_upload 177) |
| 19 | `web/public/js/search/search.js` | **540** | Lv1 | 2026-03-02 | Phase 28-4: 검색 모드 가이드 추가 (499→521줄). Phase 43-4: recommendation (521→527줄). Phase 44-5: brain_id 추가 (527→540줄). 독립 분리 가능 |
| 25 | `web/public/css/admin/admin-ai-automation.css` | **503** | CSS 모니터링 | 2026-03-14 | Phase 42-3: 3-Step Stepper 전체 재작성. CSS 파일 규정 대상 외(모니터링) |
| 26 | `backend/routers/ai/ai.py` | **522** | Lv1 | 2026-03-14 | Phase 43-3: folder_scope 추가 (→511줄). Phase 44-5: brain_id 추가 (511→522줄). 독립 분리 가능 (streaming 분리) |
| 27 | `backend/routers/knowledge/graph.py` | **511** | Lv1 | 2026-03-14 | Phase 44-5: brain_id 필터 추가 (495→511줄). 독립 분리 가능 |

## 페이지 단위 핫스팟 (Lv2 잠재 위험)

| 페이지 | 관련 파일 | 합산 줄 수 | 비고 |
|--------|----------|----------:|------|
| ~~`reason.html`~~ | ~~`reason.css`(607) + `reason-sections.css`(597)~~ | ~~**1,204**~~ | **해소** Phase 18-3: 5파일 분리 (base 227 + form 351 + steps 191 + results 170 + actions 432) |
| ~~`admin/groups.html`~~ | ~~`admin-groups.css`(805)~~ → 5파일(max 333) + ~~`keyword-group-crud.js`(618)~~ → 2파일(500+138) + ~~`keyword-group-matching.js`(557)~~ → 2파일(467+146) | ~~1,175~~ | **해소** Phase 36-2: CSS+JS 전부 분리 완료 |

## 해소 이력

| # | 원본 파일 (줄 수) | → 결과 파일 (줄 수, 관계) | 수행 Phase | 해소일 |
|---|-------------------|-------------------------|-----------|:------:|
| 18 | `folder_management.py` (616줄) | `folder_management.py`(348줄, 독립) + `folder_sync.py`(105줄, 독립) + `folder_upload.py`(177줄, 독립) | Phase 36-1 | 2026-03-12 |
| 17 | `automation.py` (631줄) | `automation.py`(437줄, 독립) + `automation_ingest.py`(194줄, 독립) | Phase 36-1 | 2026-03-12 |
| 16 | `ollama_client.py` (655줄) | `ollama_client.py`(374줄, 독립) + `ollama_streaming.py`(187줄, 참조:ollama_client) + `ollama_preload.py`(138줄, 참조:ollama_client) | Phase 36-1 | 2026-03-12 |
| 15 | `test_knowledge_reset.py` (679줄) | `test_knowledge_reset.py`(383줄, 독립) + `test_knowledge_delete.py`(331줄, 독립) | Phase 36-2 | 2026-03-12 |
| 14 | `keyword-group-crud.js` (618줄) | `keyword-group-crud.js`(500줄, 독립) + `keyword-group-category.js`(138줄, 독립) | Phase 36-2 | 2026-03-12 |
| 13 | `keyword-group-matching.js` (557줄) | `keyword-group-matching.js`(467줄, 독립) + `keyword-group-match-logic.js`(146줄, 독립) | Phase 36-2 | 2026-03-12 |
| 12 | `knowledge_handlers.py` (560줄) | `knowledge_handlers.py`(414줄, 독립) + `knowledge_delete_handlers.py`(175줄, 독립) | Phase 36-3 | 2026-03-12 |
| 11 | `document_handlers.py` (583줄) | `document_handlers.py`(500줄, 독립) + `document_delete_handlers.py`(111줄, 독립) | Phase 36-3 | 2026-03-12 |
| 10 | `knowledge-files.js` (527줄) | `knowledge-files.js`(423줄, 독립) + `knowledge-files-sync.js`(122줄, 독립) | Phase 36-3 | 2026-03-12 |
| 9 | `test_auto_ingest.py` (760줄) | `test_auto_ingest_watcher.py`(312줄, 독립) + `test_auto_ingest_service.py`(389줄, 독립) | Phase 31-1 | 2026-03-11 |
| 1 | `labels_handlers.py` (748줄) | `labels_crud.py`(396줄, 독립) + `labels_tree.py`(151줄, 독립) + `labels_suggest.py`(227줄, 참조:labels_tree) | Phase 18-0 | 2026-02-21 |
| 2 | `reason.css`(607줄) + `reason-sections.css`(597줄) | `reason-base.css`(227줄) + `reason-form.css`(351줄) + `reason-steps.css`(191줄) + `reason-results.css`(170줄) + `reason-actions.css`(432줄) | Phase 18-3 | 2026-02-21 |
| 3 | `admin-groups.css`(805줄) | `admin-groups-base.css`(190줄, 독립) + `admin-groups-tree.css`(192줄, 독립) + `admin-groups-panel.css`(208줄, 독립) + `admin-groups-keywords.css`(333줄, 독립) + `admin-groups-responsive.css`(20줄, 독립) | Phase 19-3 | 2026-02-22 |
| 4 | `stream_executor.py`(588줄) | `stream_executor.py`(282줄, 독립) + `rag_context_builder.py`(191줄, 참조:reason_helpers) + `stream_post_processor.py`(106줄, 독립) | Phase 20-1 | 2026-02-22 |
| 5 | `statistics_service.py`(699줄) | `statistics_service.py`(222줄, 독립) + `statistics_document.py`(227줄, 독립) + `statistics_knowledge.py`(256줄, 독립) | Phase 20-1 | 2026-02-22 |
| 6 | `labels_crud.py`(575줄) | `labels_crud.py`(340줄, 독립) + `labels_validation.py`(235줄, 독립) | Phase 20-1 | 2026-02-22 |
| 7 | `reason-control.js`(498줄) | `reason-control.js`(233줄, 독립) + `reason-progress.js`(249줄, 독립) | Phase 20-1 | 2026-02-22 |
| 8 | `reason_helpers.py`(484줄) | `reason_helpers.py`(352줄, 독립) + `reason_parsers.py`(150줄, 독립) | Phase 20-1 | 2026-02-22 |

※ 관계: `독립` = 단독 수정 가능, `참조:파일명` = 수정 시 함께 확인 필요
※ Lv2 ADR: 수행 Phase의 plan.md 참조

## [예외]

| # | 파일 경로 | 줄 수 | Lv | 사유 | 리포트 | 승인일 |
|---|----------|------:|:--:|------|--------|:------:|
| 1 | `web/public/css/admin/admin-groups.css` | 805 | Lv2 | 19-3이 D&D 제거·폴더형 전환·인라인 편집으로 CSS 대폭 변경 예정. 별도 Phase 분리 후 즉시 재수정은 비효율. 19-3 내 선행 Task(19-3-1)로 CSS 분리 편성 | [phase-19-master-plan.md](../phases/phase-19-master-plan.md) | 2026-02-21 |

---

**상태값**: `조사 대기` → `조사 중` → `Plan 수립` → `리팩토링 중` → `해소` / `[예외]`
**재발 태그**: 해소 이력의 결과 파일이 다시 500줄 초과 시 `[재발]` 부여 → 우선 검토

## 갱신 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-14 | Phase 44 완료: Brain 관리 레이어 도입. 신규 파일(brain.py 모델, brain.py 라우터, brain_scope_utils.py, brain-management.js 452줄, brain-management-checkpoint.js 232줄, brain-selector.js 158줄 등) — 전부 500줄 이하. graph.py(495→511줄) **500줄 초과 신규 등록** (#27). ai.py(511→522줄) #26 갱신. search.js(527→540줄) #19 갱신. 700줄 초과 없음. 578 passed, 회귀 0건 |
| 2026-03-14 | Phase 43 완료: ai.py(511줄) Lv1 #26 신규 등록 (folder_scope 추가). search.js(521→527줄) #19 갱신 (recommendation 연동). header-component.js(522→535줄) #21 갱신. 700줄 초과 없음. 577 passed, 회귀 0건 |
| 2026-03-14 | Phase 42 완료: admin-ai-automation.css(503줄) CSS 모니터링 #25 신규 등록. 3-Step Stepper 전체 재작성으로 500줄 초과. 700줄 초과 없음. 579 passed, 0 failed |
| 2026-03-12 | **Phase 36 (Chain 전체) 완료: 리팩토링 레지스트리 일괄 처리**. 9건 해소 + 1건 모니터링 해제. **36-1 BE 고위험**: ollama_client(655→374+187+138), automation(631→437+194), folder_management(616→348+105+177). **36-2 FE+테스트**: test_knowledge_reset(679→383+331), keyword-group-crud(618→500+138 [재발]해소), keyword-group-matching(557→467+146). **36-3 중위험**: document_handlers(583→500+111), knowledge_handlers(560→414+175), knowledge-files(527→423+122). recommendation_llm(501→498, 모니터링 해제). 585 passed 전 Phase 안정. **해소 이력 #10~#18 추가**. 핫스팟 admin/groups.html 해소 |
| 2026-03-11 | Phase 31-1-3 완료 + test_auto_ingest.py 리팩토링: test_auto_ingest.py(760줄) → test_auto_ingest_watcher.py(312줄, folder_watcher/sync-status API) + test_auto_ingest_service.py(389줄, auto_ingest_service/trigger-ingest). **해소 이력 #9 추가**. reason_helpers.py(8개 함수), reason_store.py, reason.py, reason_document.py, stream_executor.py, rag_context_builder.py에 user_id 필터 적용(~20 쿼리). test_knowledge_reset.py(679줄, 모니터링 #23 신규 등록). test_phase20_5.py(522줄, 모니터링 #24 신규 등록) |
| 2026-03-11 | Phase 31-1 진행: 독립 데이터 격리. Task 31-1-1~3 완료 (Conversations/Memories/ReasoningResults). reason_helpers.py(8개 함수), reason_store.py, reason.py, reason_document.py, stream_executor.py, rag_context_builder.py에 user_id 필터 적용. test_auto_ingest.py(690→760줄, 테스트 레지스트리 #22 신규 등록). test_knowledge_reset.py(679줄, 모니터링 #23 신규 등록) |
| 2026-03-11 | Phase 30-3 완료: 라벨·관계·변경로그·통계 격리. labels_crud.py(363→430줄), labels.py(395→450줄), labels_tree.py(215→233줄), relations.py(294→332줄), statistics_knowledge.py(256→297줄) — 전부 500줄 이하. 신규 500줄 초과 없음. test_user_isolation_labels.py(775줄, 테스트). **Phase Chain 30 전체 완료(30-1~30-3)**. 36+74 passed |
| 2026-03-10 | Phase 30-2 완료: 핵심 데이터 쿼리 격리. automation.py(619→631줄), knowledge_handlers.py(527→558줄), document_handlers.py(543→583줄), folder_service.py(514→517줄), folder_management.py(614→616줄) **레지스트리 갱신** (#6,#15,#16,#17,#18). knowledge.py(329→367줄), auto_ingest_service.py(234→236줄), workflow_extract.py(455줄 변경없음), auth.py(472→473줄) — 500줄 이하. test_user_isolation_core.py(395줄, 신규). 700줄 초과 없음. 17+51 passed |
| 2026-03-10 | Phase 30-1 완료: Alembic 도입 + user_id 스키마 변경. models.py(224→244줄), user_models.py(22→35줄), auth.py(454→472줄), user_filter.py(30줄 신규) — 전부 500줄 이하. alembic/ 신규(env.py 67줄, 4 revisions). 신규 500줄 초과 없음. 84 passed, 0 failed |
| 2026-03-02 | Phase 29-2 완료: 새로고침 UI. knowledge-files.js(527줄) **500줄 초과 신규 등록** (#20). header-component.js(522줄) **500줄 초과 신규 등록** (#21). admin-knowledge-files.css(558→620줄) **레지스트리 갱신** (#12). knowledge-files-api.js(498줄, 이하). 30 passed, 0 failed |
| 2026-03-02 | Phase 29-1 완료: 자동 감지+Ingest. folder_watcher.py(197줄, 신규), auto_ingest_service.py(234줄, 신규) — 500줄 이하. folder_management.py(516→614줄) **레지스트리 갱신** (#18). automation.py(542→619줄) **레지스트리 갱신** (#6). 32 passed, 0 failed |
| 2026-03-02 | Phase 28-4 완료: UI/UX 개선 + 검색 강화. folder_service.py(483→514줄) **500줄 초과 신규 등록** (#17). folder_management.py(474→516줄) **500줄 초과 신규 등록** (#18). search.js(499→521줄) **500줄 초과 신규 등록** (#19). ask-chat.css(370→555줄, CSS 모니터링). 29 passed, 0 failed |
| 2026-03-02 | Phase 28-1 완료: 지식 삭제·리셋 API 인프라. knowledge_handlers.py(385→527줄) **500줄 초과 신규 등록** (#15). document_handlers.py(458→543줄) **500줄 초과 신규 등록** (#16). knowledge_reset.py(278줄, 신규), chunk_sync_service.py(288줄). 36 passed, 0 failed |
| 2026-03-01 | Phase 25-4 Task 2: ollama_client.py _classify_error + 구조화 로깅 추가 (489→521줄). **500줄 초과 신규 등록** (#14). workflow_extract.py 캐시+source/confidence 구분 추가 (413→453줄, 500줄 이하) |
| 2026-03-01 | Phase 25-3 완료: LLM 안정성 강화. context_manager.py(219줄), ollama_client.py(488줄) — 500줄 이하. recommendation_llm.py(501줄) **500줄 초과 신규 등록** (Lock+TTL 추가). test_llm_concurrency.py 신규(8 PASSED). 회귀 168 passed, 0 failed |
| 2026-02-25 | Phase 21-2 완료: 검색·고급필터 라벨 UI 개선. search-label-popup.js(207줄, 신규), search.js 497→499줄(근접 감시 유지), search-filters.js 222→230줄, labels.py 391→395줄, labels_crud.py 351→363줄, search.py 387→392줄, documents.py 300→301줄, relation_recommendations.py(206줄), search_service.py(311줄). 전부 500줄 이하. 신규 500줄 초과 없음. M2 마일스톤(검색·필터 사용성 개선) 달성. 200 passed, 0 failed |
| 2026-02-24 | Phase 21-1 완료: 키워드 그룹 관리 전면 개선. keyword-group-treeview.js 470→392줄(감소), keyword-group-context-menu.js 312→189줄(감소), keyword-group-crud.js 472→618줄(**[재발]** 부모 카테고리 드롭다운 추가), keyword-group-suggestion.js 346→373줄, keyword-group-manager.js 88→133줄, keyword-group-ui.js 145→206줄. labels.py 374→391줄, labels_suggest.py 227→267줄, labels_tree.py 161→215줄. BE 전부 500줄 이하. crud.js 618줄 레지스트리 등록. 208 passed, 0 failed |
| 2026-02-24 | Phase 20-8 완료: 지식 그래프 인터랙티브 탐색. graph.py(418줄), graph-core.js(252줄), graph-interactions.js(265줄), graph-filters.js(195줄) — BE 500줄 이하, JS 전부 300줄 이하. knowledge-graph.css(448줄), knowledge-graph.html(97줄). 기존 knowledge-graph.js(159줄) 삭제→3파일 대체. 신규 500줄 초과 없음. **Phase Chain 20 전체 완료(20-0~20-8). M5 마일스톤(사용자 경험 혁신) 3/3 달성** |
| 2026-02-24 | Phase 20-7 완료(Round 2): 코그니티브 대시보드 6탭 구현. cognitive-dashboard.js(89줄), cognitive-memory.js(209줄), cognitive-learning.js(229줄), cognitive-meta.js(207줄), cognitive-personality.js(227줄), cognitive-context.js(173줄) — JS 전부 300줄 이하. cognitive.css(719줄, CSS 규정 대상 외 모니터링), cognitive.html(187줄). LNB AI Brain 메뉴 추가. M5 마일스톤 2/3 달성 |
| 2026-02-23 | Phase 20-6 완료: AI 대화 UX 리뉴얼. ask-chat.js(278줄), ask-stream.js(160줄), ask-session.js(280줄), ask-actions.js(169줄), ask-chat.css(370줄), ask-sidebar.css(154줄) 신규. conversations.py(455줄), ai.py(402줄), ask.js(409줄) — 전부 500줄 이하. ask.css(665줄)은 CSS 파일 기존 누적(모니터링). M5 마일스톤 1/3 달성 |
| 2026-02-23 | Phase 20-5 완료: 지식구조 고도화. history_service.py(57줄), changelog.py(110줄), knowledge-history.js(122줄) 신규. labels_validation.py(310줄), relations.py(294줄), labels.py(374줄), approval.py(419줄), knowledge_handlers.py(385줄), labels_crud.py(351줄) — 전부 500줄 이하. 신규 등록 없음. M4 마일스톤(지식 품질 기반) 달성 |
| 2026-02-22 | Phase 20-4 완료: AI 질의 고도화. ai.py(377줄), ai_handlers.py(387줄), ask.js(363줄), ask-sources.js(95줄), ask-history.js(221줄), ask-context-preview.js(413줄) — 전부 500줄 이하. ask.css(685줄)은 CSS 파일로 규정 대상 외(모니터링). M3 마일스톤(검색+AI 연계) 달성 |
| 2026-02-22 | Phase 20-3 완료: 검색 고도화. hybrid_search(452줄), search.py(387줄), search.js(497줄), ask.js(440줄) — 전부 500줄 이하. search-filters.js(222줄)+search-selection.js(143줄)+context-transfer.js(65줄) 신규. search.js 497줄 근접 감시. search.css 736줄은 CSS 파일로 규정 대상 외 |
| 2026-02-22 | Phase 20-1 완료: R1~R5 5파일 선행 리팩토링 완료. stream_executor(282)+rag_context_builder(191)+stream_post_processor(106), statistics_service(222)+statistics_document(227)+statistics_knowledge(256), labels_crud(340)+labels_validation(235), reason-control(233)+reason-progress(249), reason_helpers(352)+reason_parsers(150). 전부 500줄 이하. 해소 이력 5건 추가 |
| 2026-02-22 | Phase 20-0 완료: keyword-group-suggestion.js(346줄), knowledge-workflow.js(220줄), statistics.css(346줄) — 전부 500줄 이내. 신규 등록 없음 |
| 2026-02-22 | Phase 19-2 완료: statistics.css(337줄), statistics.html(217줄) — 500줄 이내 유지. labels_crud.py(575줄) 누락 보정 등록. Phase Chain 19 전체 완료 |
| 2026-02-22 | Phase 19-3 완료: admin-groups.css(805줄) → 5파일 분리 해소 (max 333줄). keyword-group-matching.js 557줄 신규 등록. keyword-group-crud.js 527→472줄 감소 |
| 2026-02-21 | Phase 18-4 완료: search 관련 파일 500줄 이내 유지 (hybrid_search 347줄, search.js 452줄) |
| 2026-02-21 | Phase 18-3 완료: reason.css+reason-sections.css 1,204줄 핫스팟 해소 → 5파일 분리 (max 432줄) |
| 2026-02-21 | Phase 18-2 완료: document_handlers.py 458줄, folder-tree.js 275줄, knowledge-tree.js 326줄 |
| 2026-02-21 | Phase 18-1 완료: admin-groups.css 613→805줄 (Lv2 확정), labels_crud.py 396→575줄 (모니터링) |
| 2026-02-21 | Phase 18-0 완료: labels_handlers.py(748줄) → 3파일 분리 해소. 테스트 168 passed |
| 2026-02-21 | 해소 이력 섹션 + [재발] 태그 규칙 추가. 규정 v1.1 적용 |
| 2026-02-21 | Level 분류 + 잠재 Lv 분석 + 페이지 단위 핫스팟 추가. 규정 v1.0 적용 |
| 2026-02-21 | 초기 생성. 전체 스캔 (700줄+ 1건, 500줄+ 8건) |
