# KijaniKiosk Capstone: Project Scope Document

## 1. Project Overview
**Project Name:** KijaniKiosk Infrastructure Pipeline  
**Chosen Track:** Track A (Infrastructure-First)  
**Business Context:** KijaniKiosk is a mock eco-friendly ticketing and point-of-sale API. This capstone builds the production-grade DevOps infrastructure, CI/CD pipeline, and observability stack required to support it reliably.

## 2. Core Objective
Deliver a fully automated, secure, and observable infrastructure pipeline such that a new engineer can clone the repository, understand the architecture, and deploy a meaningful change to the staging environment within their first day.

> **Revision note (2026-11-11):** The original plan named GitHub Actions for CI/CD; Track A requires Jenkins, so the pipeline was rebuilt in Jenkins. The Status column and layer descriptions below reflect what is actually deployed. Planned-but-not-built items are listed under Production Gaps in the README.

## 3. Technology Stack

| Layer | Technology | Purpose | Status |
|-------|-----------|---------|--------|
| **Infrastructure** | Terraform | Provision namespaces and cluster resources | Applied (both namespaces) |
| **Configuration** | Ansible | Configure the staging environment post-provision | Playbook written, not yet executed |
| **Application** | Python 3.12 (Flask) | Stateless kiosk API | Running |
| **Containerisation** | Docker | Reproducible, portable builds | Built per commit by Jenkins |
| **Orchestration** | Kubernetes (Minikube) | Namespace-isolated staging and production runtimes | Running |
| **CI/CD** | Jenkins | Automated build, deploy, smoke test, and approval gate | Running (no unit-test stage yet) |
| **Observability** | Prometheus + Grafana | Metrics scraping and alerting on kk-payments signals | Planned, not deployed (alert rules written) |

## 4. Four-Layer Architecture Map (Dimension 2)

- **Infrastructure layer:** Terraform provisions `kijani-staging` and `kijani-production` namespaces. An Ansible playbook for staging configuration is written but not yet executed.
- **Delivery layer:** Jenkins pipeline — build → deploy-staging → smoke test → manual approval gate → deploy-production. On failure, staging is rolled back automatically.
- **Runtime layer:** Kubernetes Deployments with namespace isolation. Both namespaces currently run the same manifest: 2 replicas with CPU/memory requests and limits. Only the ConfigMap differs. (Planned: 3 replicas and stricter limits in production.)
- **Intelligence layer (planned, not deployed):** Alert rules for kk-payments error rate and pod restarts are committed in `infra/prometheus-alerts.yaml`. Prometheus and Grafana are not installed, so nothing is scraped and no alert can fire yet.

## 5. Environment Strategy

| Environment | Namespace | Trigger | Gate | ConfigMap |
|-------------|-----------|---------|------|-----------|
| Staging | `kijani-staging` | Push to `main` | Automatic after smoke test | `DB_HOST=kk-payments-staging-db` |
| Production | `kijani-production` | Approval-gated after staging smoke test passes | Manual approval required | `DB_HOST=kk-payments-prod-db` |

**Namespace decision — `kijani-production` not `default`:** The brief permits using `default` for production. This project uses an explicit `kijani-production` namespace instead. Reason: on a shared cluster, deploying into `default` risks resource name collisions with other workloads. Explicit namespaces make RBAC, resource quotas, and network policies easier to scope correctly.

## 6. In-Scope Items (5 maximum)
1. Automated CI/CD pipeline with build, test, staging deploy, and production approval gate
2. Kubernetes namespace isolation with environment-specific ConfigMaps
3. Prometheus alert on kk-payments error rate or pod restarts
4. Peer review session with test plan, GitHub Issues, and commit-linked resolutions
5. AI governance log with at least two entries including "what it got wrong"

## 7. Out-of-Scope Exclusions
- **TLS/certificate management:** Excluded because the app is stateless and runs behind a cluster ingress not provisioned in this capstone.
- **Database provisioning:** Excluded because kk-payments uses a mock in-memory store for the capstone scenario; real DB provisioning is a separate infrastructure concern.

## 8. Success Criteria (each demonstrable in the live demo)
- [x] Merge to `main` triggers a staging deploy and smoke test — visible in Jenkins (build #2, "Started by an SCM change"; see `docs/evidence/`)
- [x] Approval gate blocks production deploy until approved — visible in Jenkins (build #2 approval; build #3 shows production skipped after a failed smoke test)
- [ ] Killing a staging pod triggers automatic restart — demonstrable with `kubectl delete pod -l app=kk-payments -n kijani-staging`
- [ ] Prometheus alert fires when pod restarts exceed threshold — visible in Grafana (not met: Prometheus not deployed)
- [ ] New engineer can run the app locally in under 5 minutes following only the README

## 9. AI Governance & Integrity
All AI tool usage is logged in `docs/ai-governance-log.md` with the prompt given, what the tool produced, what it got wrong, and what human action was taken. Undisclosed AI use is an academic integrity violation per course policy.
