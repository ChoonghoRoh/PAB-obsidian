---
# =============================================================================
# PROJECT.md frontmatter — 기계용 설정 (훅·스크립트가 읽음)
# 값 변경 후: /project-config sync 실행 (또는 새 세션 시작 시 자동 동기화)
# =============================================================================

# --- 프로젝트 식별 ---
project_name: "PAB-obsidian"
project_type: "data"               # web-app | api-server | fullstack | cli | library | mobile | data | ssot-bundle
platform: "cross"                  # 개발=macOS(맥북) / 배포=linux(3800X) / 클라이언트=iOS·Windows

# --- 기술 스택 ---
primary_language: "sh"             # 지식 문서(md) + 운영 스크립트(bash)
backend_stack: "none (CouchDB LiveSync · livesync-bridge · bash 운영 스크립트 — 애플리케이션 코드 없음)"
frontend_stack: "none (Obsidian 클라이언트)"

# --- 빌드·실행·테스트 명령 (없으면 "none") ---
build_cmd: "none"
run_cmd: "none"
test_cmd: "bash scripts/zombiecheck/zombie_check.sh --self-test"
lint_cmd: "none"

# --- 코드 영역 (HR-1 가드 대상 — 팀 운영 중 Team Lead 직접 수정 차단) ---
code_dirs: "scripts"
code_exts: "sh"

# --- HR-5 줄수 임계값 ---
line_warn: 500
line_crit: 700

# --- 테스트 게이트 (G3) ---
coverage_target: 80                # 인프라 Phase는 E-3 G3_smoke로 대체 (phase-2-exceptions.md)

# --- 알림 (NOTIFY-1, 구 HR-8) ---
notify_channel: "telegram"         # telegram | none
notify_project_label: "PAB-LLMDATA"  # 알림 메시지 [라벨]

# --- SSOT 연동 ---
ssot_version: "v8.2-renewal-6th"   # ver6-2 라인 (LIFECYCLE-5·6). policy/model-assignment.md는 v8.3에서 이식 보존
ssot_path: "docs/SSOT"
---

# PROJECT.md — 프로젝트 단일 설정 문서

> **이 문서 하나로 프로젝트별 설정을 전부 관리한다.**
> 상단 frontmatter는 훅·스크립트가 기계적으로 읽고(→ `.claude/hooks/hooks.env` 자동 생성),
> 아래 프로즈 섹션은 Team Lead·팀원 에이전트가 스폰 시 로드한다.
> SSOT 본체(`docs/SSOT/`)는 **프레임워크(불변)**, 본 문서는 **프로젝트별(가변)** — SSOT 업그레이드 시에도 본 문서는 보존된다.

## 1. 프로젝트 개요

- **이름**: PAB-obsidian
- **성격**: **개인 지식베이스(Obsidian vault) + 셀프호스팅 동기화 인프라**. 애플리케이션 코드가 없는 데이터·운영 프로젝트다
- **핵심 자산**: `PAB-LLMDATA/` — Karpathy 스타일 wiki vault. SOURCE(원본 불변) + 요약 노트 2파일 쌍으로 축적
- **목적**: ⑴ 다기기 실시간 동기화 ⑵ 오프사이트 백업 ⑶ PAB-v4 RAG 지식 공급원
- **SSOT 사용 범위**: 워크플로우(Phase·게이트·팀 운영)만 차용한다. 코드 검증 게이트(G2_be/G2_fe·pytest G3)는 산출물 성격이 달라 예외로 대체한다

### 1.1 vault 이원화 (중요)

| vault | authority | 성격 | 운영 체인 |
|---|---|---|---|
| `PAB-LLMDATA` | **PAB-obsidian** | 정보(운영 SSOT) | 편입 — 4홉 전파 |
| `PAB-LLMDATA-prove` | PAB-Prove | 개발용 데이터 | 미편입 (승격 예정) |

경계 정의와 승격 통지는 `docs/interop/pab-observer/`가 정본이다.

## 2. 인프라 (4홉 전파 체인)

```
PAB-LLMDATA(로컬) → LiveSync → CouchDB pab-llmdata(홉1, 3800X :5984)
  → livesync-bridge(홉2) → 미러 /home/oceanui/pab-vault-mirror(홉3)
  → PAB-v4 /vault-mirror :ro + Qdrant(홉4)
```

- **서버**: 3800X (`ssh 3800x`, Tailnet `100.109.251.86`). 공개 포트 0 — 전 서비스 Tailnet 전용
- **역할 분리**: LiveSync = **복제**(≠백업) / GitHub `ChoonghoRoh/PAB-obsidian` = **오프사이트 백업**
- **관측**: PAB-Observer(RPi5 Uptime Kuma) 소관. `#25` CouchDB · `#26` VaultChain 4홉 · `#31` 컨테이너

> **정합 ≠ 생존**: 2026-08-21 홉1이 3일간 죽은 동안에도 3자 일치 지표는 정상이었다. 일치를 생존 신호로 읽지 않는다.

## 3. 절대 제약

| # | 제약 | 근거 |
|---|------|------|
| R-1 | **단일 writer** — 미러·CouchDB에 직접 쓰지 않는다. 전파는 LiveSync 단방향 | 역방향 쓰기는 vault 손상 |
| R-4 | **SOURCE 불변** — `15_Sources/*_source.md` 재페치·덮어쓰기 금지 | 원본 보존이 wiki 설계 전제 |
| E-4 | **무인 자동화 추론은 로컬 vLLM만** — 외부 LLM API 호출 0 | 데이터 주권 (`phase-2-exceptions.md`) |
| DP-4 | **Tailnet 전용 바인딩** — `0.0.0.0` 노출 금지 | 공개 인터넷 차단 |

## 4. 게이트 예외 (SSOT 대체 규정)

`docs/phases/phase-2-exceptions.md`가 정본이다.

| 예외 | 대체 |
|---|---|
| E-1 | G2_be/G2_fe → **G2_infra** (서비스 헬스·보안·KPI) |
| E-2 | 인프라 설정파일은 HR-5 비대상. **단 신규 bash 스크립트는 정상 적용** |
| E-3 | G3 pytest → **G3_smoke** (헬스체크·E2E·장애 주입) |
| E-4 | 외부 API 추론 **영구 금지** (ARCHIVED 되지 않음) |

## 5. 운영 스크립트 (`code_dirs` = HR-1 가드 대상)

| 경로 | 용도 |
|---|---|
| `scripts/monitoring/` | vault 동기화 헬스 수집기 + Observer Push + 맥북 역방향 watchdog |
| `scripts/pmAuto/` | NOTIFY-1 Telegram 발송 |
| `scripts/zombiecheck/` | LIFECYCLE-5·6 좀비 감지·체크 스케줄러 (ver6-2 프레임워크) |

> **Telegram 주의**: `report_to_telegram.sh`는 `parse_mode=Markdown`을 강제한다. `G2_wiki` 같은 `_` 단독 토큰은 entity 파싱을 깨뜨리므로 하이픈 치환·escape가 필요하다.

## 6. 페르소나 추가 지시

- 응답 언어는 **한국어**. 기술 용어·코드 식별자는 원문 유지
- 이 프로젝트는 **지식 자산**을 다룬다. 노트의 삭제·덮어쓰기는 복제로 전 기기에 전파되므로, 파괴적 변경 전 반드시 확인한다
- vault 노트 생성은 `/wiki` 스킬 규격(frontmatter 11필드 + 6 TYPE + naming-convention)을 따른다
