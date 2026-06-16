---
title: "PAB-Conductor 구현 기능 전수 분석"
description: "PAB-Conductor의 23개 기능 모듈·8개 DB 모델·ER/시퀀스 다이어그램 요약"
created: 2026-06-14 22:23
updated: 2026-06-14 22:23
type: "[[RESEARCH_NOTE]]"
index: "[[ENGINEERING]]"
topics: ["[[PAB_CONDUCTOR]]"]
tags: [research-note, pab-conductor, architecture, mermaid]
keywords: [기능모듈, DB매핑, ER다이어그램, 시퀀스다이어그램, 에이전트, 오케스트레이터, 보안게이트]
sources: ["[[15_Sources/2026-06-14_pab_conductor_03_features_source]]"]
aliases: [Conductor기능분석, PAB-C-features]
---

# PAB-Conductor 구현 기능 전수 분석

PAB-Conductor 백엔드를 **기능 모듈 · DB 모델 · 동작 흐름** 관점에서 정리한다. 원격 에이전트 오케스트레이션 시스템으로 [[오케스트레이터]] · [[이벤트 버스]] · [[보안 게이트]] · [[하트비트 모니터]]가 핵심 축이다.

## 기능 모듈 (23)
[원본 §5-1 →](2026-06-14_pab_conductor_03_features_source.md#5-1-기능-모듈표-23)

`src/services` 16 + `src/reporters` 3 + 핵심 4. 주요 모듈:
- **[[에이전트 매니저]]** (`agent_manager.py`): listener spawn → 30초 동기화 → 60초 heartbeat
- **[[오케스트레이터]]** (`orchestrator.py`): pending 조회 → 온라인 확인 → [[이벤트 버스]] 발행 → processing 갱신
- **[[Claude 실행기]]** (`claude_executor.py`): `claude -p --output-format json` 서브프로세스 실행
- **[[보안 게이트]]** (`security_gate.py`): Rate Limit → 화이트리스트 → 세션 → OTP → 패턴 매칭
- **[[하트비트 모니터]]** (`heartbeat_monitor.py`): 60초 주기 dead(3분) 감지 → 알림
- 운영 보조: [[텔레그램 봇]] · [[메트릭 수집기]] · [[요약 보고]] · [[큐 잔류 감시]] · [[Discord 알림]]

> **발견**: `HeartbeatMonitor.send_heartbeat`/`check_nodes`는 호출되나 미구현(stub)으로 보임. 에이전트 heartbeat는 HTTP `POST /api/agent/heartbeat`로 처리.

## DB 모델 (8)
[원본 §5-2 →](2026-06-14_pab_conductor_03_features_source.md#5-2-db-엔티티-테이블-매핑-8-모델)

`src/models/models.py`의 SQLAlchemy 모델 8종:
- **Project** (PK `name`) · **Machine** (PK `id`, role/online/토큰) · **ProjectInstruction** (status 7종 CHECK)
- **AgentExecution** (실행 결과) · **ProjectReport** (보고 JSONB) · **AgentSecurityLog** (allow/deny)
- **PendingCommand** (UUID, 머신 명령) · **MachineProjectAssignment** (머신↔프로젝트 배정)

> Nexus(`/api/nexus/*`)는 별도 DB(asyncpg 직접 연결)로 SQLAlchemy 모델 외부. 마이그레이션 9종이 스키마 점진 구성.

## ER 다이어그램
[원본 §5-3 →](2026-06-14_pab_conductor_03_features_source.md#5-3-er-다이어그램)

`projects`를 중심으로 8개 테이블의 FK 관계(CASCADE/SET NULL)를 mermaid `erDiagram`으로 표현. `projects → project_instructions/agent_executions/project_reports/machine_project_assignments`, `machines → agent_executions/pending_commands`. (원본에 mermaid 다이어그램)

## 시퀀스 다이어그램 (5)
[원본 §5-4 →](2026-06-14_pab_conductor_03_features_source.md#5-4-기능-시퀀스-다이어그램)

핵심 흐름 5종을 mermaid `sequenceDiagram`으로 도식화:
1. **인증** (OTP → JWT): `pyotp.TOTP.verify` → `jwt.encode(HS256, 24h)`
2. **Execution 생성** (지시 → 실행 → 보고): 머신 온라인 게이트 → INSERT pending → [[이벤트 버스]] → Long Poll → Claude 실행 → 보고
3. **에이전트 heartbeat + 슬라이딩 토큰 회전**: 60초 heartbeat, 잔여 TTL < threshold 시 토큰 갱신
4. **[[보안 게이트]]** (Telegram 명령 검증): Rate Limit → 화이트리스트 → OTP → BLOCKED/CONFIRM 패턴
5. **머신 연결 검증** (PendingCommand 폴링): INSERT check_path → 에이전트 실행 → Redis 결과(TTL 120s) → FE 폴링

(원본에 mermaid 다이어그램 5개)
