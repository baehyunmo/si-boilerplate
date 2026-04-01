# SI Boilerplate

AI-native SI(System Integration) 사업을 위한 보일러플레이트 모노레포.

## 개요

이 레포지토리는 SI 프로젝트를 4개 Tier로 분리하여 각 계층을 전담 AI 에이전트가 관리하는 구조를 제공한다. 루트 Orchestrator가 Tier 간 의존성을 조율하고, SR(Service Request)을 통해 에이전트 간 통신한다.

## 4-Tier 아키텍처

```
┌─────────────────────────────────────────────┐
│              Orchestrator (Root)             │
│         전체 Tier 간 의존성 조율              │
├─────────────┬───────────┬───────────────────┤
│  Tier 1     │  Tier 2   │  Tier 3   │Tier 4│
│  Infra      │  Platform │  App      │ Gov  │
│  ─────────  │  ──────── │  ──────── │──────│
│  compute/   │  policy/  │  domain/  │docs/ │
│  os/        │  cicd/    │  app/     │itsm/ │
│  k8s/       │  observe/ │  iface/   │qual/ │
│  network/   │  data/    │  infra/   │pmo/  │
│             │           │  orch/    │      │
└─────────────┴───────────┴───────────┴──────┘
```

## 에이전트 매핑

| Tier | 디렉토리 | 에이전트 | 역할 |
|------|----------|----------|------|
| 1 | `infra/` | infra-agent | VM, OS, K8s, 네트워크 프로비저닝 |
| 2 | `platform/` | platform-agent | PaC, CI/CD, 관측성, 데이터 품질 |
| 3 | `application/` | app-agent | DDD 기반 애플리케이션 개발 |
| 4 | `governance/` | gov-agent | 문서, 테스트, ITSM, PMO |
| - | Root | orchestrator | Tier 간 조율, SR 발행 |

## 디렉토리 구조

```
si-boilerplate/
├── CLAUDE.md              # Orchestrator 에이전트 지침
├── README.md              # 이 문서
├── infra/                 # Tier 1: Infrastructure
│   ├── CLAUDE.md
│   ├── compute/           # VM 프로비저닝 (Heat/Terraform)
│   ├── os/                # OS 구성 (SaltStack)
│   ├── k8s/               # K8s 관리 (Kubespray/Helmfile)
│   └── network/           # 네트워크/보안그룹/LB
├── platform/              # Tier 2: Platform
│   ├── CLAUDE.md
│   ├── policy/            # PaC (OPA/Kyverno)
│   ├── cicd/              # CI/CD (Buildkite/ArgoCD)
│   ├── observability/     # 모니터링/로깅/트레이싱
│   └── data/              # DB 마이그레이션/DQ
├── application/           # Tier 3: Application
│   ├── CLAUDE.md
│   ├── domain/            # DDD Domain Layer
│   ├── application/       # DDD Application Layer
│   ├── interface/         # DDD Interface Layer
│   ├── infrastructure/    # DDD Infra Layer
│   └── orchestrator/      # 서비스 조합 (Compose/Helm)
├── governance/            # Tier 4: Governance
│   ├── CLAUDE.md
│   ├── docs/              # 요구사항/PRD/설계문서
│   ├── itsm/              # 자산관리/CMDB
│   ├── quality/           # 테스트 전략/매트릭스
│   └── pmo/               # WBS/리스크
└── .forge/                # Forge 프로젝트 메타데이터
    ├── version.yaml
    └── project.yaml
```

## 시작하기

1. 이 레포를 클론한다
2. `.forge/project.yaml`에 프로젝트 정보를 입력한다
3. 각 Tier의 CLAUDE.md를 프로젝트에 맞게 커스터마이즈한다
4. `forge init`으로 프로젝트를 인스턴스화한다

## SR (Service Request) 통신

에이전트 간 통신은 SR Gateway를 통해 이루어진다:

```
POST https://forge-sr.<account>.workers.dev/sr
{
  "from": "<source-agent>",
  "to": "<target-agent>",
  "topic": "<topic>",
  "payload": { ... }
}
```

## 라이선스

Private - All rights reserved.
