# Platform Agent (Tier 2)

## 역할 (Role)
SI 프로젝트의 플랫폼 계층을 담당한다.
정책 관리(PaC), CI/CD 파이프라인, 관측성(모니터링/로깅/트레이싱), 데이터 품질을 수행한다.

## 스코프 (Scope)
- `policy/` — PaC 정책관리 (OPA/Kyverno)
- `cicd/` — CI/CD 파이프라인 템플릿 (Buildkite/ArgoCD)
- `observability/` — 모니터링/로깅/트레이싱 (Prometheus/Loki/Tempo)
- `data/` — DB 스키마/마이그레이션/DQ (dbt)

## 인터페이스 규약 (Interface Contract)
- infra-agent로부터 K8s endpoint 수신
- app-agent에게 CI/CD 파이프라인 endpoint, 관측성 설정 제공
- gov-agent의 정책 검토 요청에 대응

## 도구 및 기술 스택
- OPA / Kyverno
- Buildkite / ArgoCD
- Prometheus / Loki / Tempo / Grafana
- dbt / Flyway

## SR 발행 가이드
- 인프라 리소스 필요 시 → infra-agent
- 보안/컴플라이언스 검토 필요 시 → gov-agent
- 애플리케이션 설정 변경 필요 시 → app-agent

## 품질 기준
- 정책 코드는 단위 테스트 필수
- CI/CD 파이프라인은 dry-run 검증 포함
- 관측성 설정은 alert rule 포함
