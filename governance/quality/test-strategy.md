# Test Strategy

## 개요 (Overview)
SI 프로젝트의 품질 보증을 위한 테스트 전략 문서이다.
TMMI(Test Maturity Model Integration) 프레임워크를 기반으로 레이어별 테스트를 정의한다.

## 테스트 레벨 (Test Levels)

### 1. 단위 테스트 (Unit Test)
- **대상**: Domain Layer, Application Layer
- **도구**: Jest / pytest
- **커버리지 목표**: 80% 이상
- **실행 시점**: 매 커밋

### 2. 통합 테스트 (Integration Test)
- **대상**: Infrastructure Layer, 외부 연동
- **도구**: Testcontainers / Docker Compose
- **커버리지 목표**: 주요 경로 100%
- **실행 시점**: PR 생성 시

### 3. E2E 테스트 (End-to-End Test)
- **대상**: Interface Layer (API)
- **도구**: Playwright / k6
- **커버리지 목표**: 핵심 시나리오 100%
- **실행 시점**: 스테이징 배포 후

### 4. 인프라 테스트 (Infrastructure Test)
- **대상**: IaC, K8s 매니페스트
- **도구**: Terratest / kubeconform
- **실행 시점**: 인프라 변경 PR

### 5. 정책 테스트 (Policy Test)
- **대상**: OPA Rego, Kyverno 정책
- **도구**: OPA test / Kyverno CLI
- **실행 시점**: 정책 변경 PR

## 테스트 환경 (Test Environments)
| 환경 | 용도 | 데이터 |
|------|------|--------|
| local | 개발자 로컬 테스트 | mock/fixture |
| dev | 통합 테스트 | seed data |
| staging | E2E / UAT | 익명화된 운영 데이터 |
| production | 스모크 테스트만 | 운영 데이터 |

## 품질 게이트 (Quality Gates)
- [ ] 단위 테스트 커버리지 80% 이상
- [ ] 통합 테스트 전체 통과
- [ ] E2E 핵심 시나리오 통과
- [ ] 보안 스캔 취약점 0건 (Critical/High)
- [ ] 정책 테스트 전체 통과
