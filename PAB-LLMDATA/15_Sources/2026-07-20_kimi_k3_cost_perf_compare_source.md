---
title: "Kimi Code Overview (kimi.com 공식 문서 원문)"
description: "Kimi Code 공식 문서 개요 페이지 원문 — Kimi K3(k3) 모델·API·멤버십 플랫폼 비교 캡처본"
created: 2026-07-20 23:32
updated: 2026-07-20 23:32
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[PUBLIC_AI]]", "[[MODEL_COMPARISON]]"]
tags: [source, kimi-k3, kimi-code, moonshot]
keywords: [Kimi Code, Kimi K3, k3, Moonshot AI, kimi-for-coding, membership, OpenAI compatible, Anthropic compatible]
sources: ["https://www.kimi.com/code/docs/en/"]
aliases: ["Kimi Code 원문", "Kimi K3 docs source"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 페치 2026-07-20 · 출처 https://www.kimi.com/code/docs/en/

# Kimi Code Overview — 원문 캡처

## What is Kimi Code

"Kimi Code is an intelligent programming service for developers included in Kimi membership benefits. Built on Kimi's latest flagship models, it provides AI-assisted capabilities—such as code reading, file editing, and command execution—through product forms like CLI and VS Code extension."

## Core Advantages

- **Continuous model upgrades**: Access to Kimi's latest flagship models with current code understanding capabilities
- **Two speed tiers, switch freely**: Standard and HighSpeed options; HighSpeed approximately 5–6× faster
- **Broad compatibility**: Works with Kimi Code CLI, VS Code, Claude Code, and other development tools
- **Ultra-fast response**: Output speed up to 100 Tokens/s
- **High-frequency concurrency**: Supports approximately 300–1,200 requests per 5-hour window, up to 30 concurrent requests

## Getting Started

### Official Client Options

**Kimi Code CLI**
- For terminal-based development
- Installation commands provided for macOS/Linux and Windows PowerShell
- Uses `/login` command for authentication

**Kimi Code for VS Code**
- For VS Code editor integration
- Currently limited to legacy Python CLI users for new installations
- Search "Kimi Code" in VS Code Extensions marketplace

## API Access

### Service Endpoints

| Protocol | Base URL | Example Endpoint |
|----------|----------|------------------|
| OpenAI Compatible | `https://api.kimi.com/coding/v1` | `https://api.kimi.com/coding/v1/chat/completions` |
| Anthropic Compatible | `https://api.kimi.com/coding/` | `https://api.kimi.com/coding/v1/messages` |

### API Key Management

Members can create up to 5 API Keys in the Kimi Code Console; each displays only once upon creation.

## Available Models

- **k3**: Kimi K3 (Moderato members+); supports `low`/`high`/`max` thinking levels
- **kimi-for-coding**: Kimi K2.7 Code (all members)
- **kimi-for-coding-highspeed**: Kimi K2.7 Code HighSpeed (Allegretto members+)

## Platform Comparison

| Item | Kimi Code Platform | Kimi Platform |
|------|-------------------|---------------|
| Base URL | OpenAI/Anthropic compatible URLs | `https://api.moonshot.cn/v1` |
| Billing | Monthly/annual membership subscription | Pay-as-you-go model |
| Best For | Terminal/IDE agent programming | Product integration, enterprise use |

## Navigation Links

Model Configuration · Membership Benefits · What's New · Community Guidelines · FAQ · Error Reference · Contact & Feedback · Getting Started (CLI) · Common Use Cases · Configuration Files · Model Context Protocol · kimi Command Reference · Changelog · VS Code Quick Start · Claude Code Integration
