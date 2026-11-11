# KijaniKiosk Capstone: Project Scope Document

## 1. Project Overview
**Project Name:** KijaniKiosk Infrastructure Pipeline  
**Chosen Track:** Track A (Infrastructure-First)  
**Business Context:** KijaniKiosk is a mock eco-friendly ticketing and point-of-sale API. This capstone builds the production-grade DevOps infrastructure, CI/CD pipeline, and observability stack required to support it reliably.

## 2. Core Objective
Deliver a fully automated, secure, and observable infrastructure pipeline such that a new engineer can clone the repository, understand the architecture, and deploy a meaningful change to the staging environment within their first day.

## 3. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Infrastructure** | Terraform | Provision namespaces and cluster resources |
| **Configuration** | Ansible | Configure the staging environment post-provision |
| **Application** | Python 3.12 (Flask) | Stateless kiosk API |
| **Containerisation** | Docker | Reproducible, portable builds |
| **Orchestration** | Kubernetes | Namespace-isolated staging and production runtimes |
| **CI/CD** | GitHub Actions | Automated build, test, deploy, and approval gate |
| **Observability** | Prometheus + Grafana | Metrics scraping and alerting on kk-payments signals |

## 4. Four-Layer Architecture Map (Dimension 2)

- **Infrastructure layer:** Terraform provisions `kijani-staging` and `kijani-production` namespaces. Ansible configures environment-specific settings post-provision.
- **Delivery layer:** GitHub Actions pipeline — build → test → deploy-staging → smoke test → manual approval gate → deploy-production.
- **Runtime layer:** Kubernetes Deployments with strict namespace isolation. Production enforces 3 replicas and CPU/memory resource limits. Staging runs 2 replicas with relaxed limits.
- **Intelligence layer:** Prometheus scrapes pod metrics from both namespaces. Grafana alert fires when the kk-payments error rate exceeds 5% or a pod enters CrashLoopBackOff. Alert config is committed to the repo.

## 5. Environment Strategy

| Environment | Namespace | Trigger | Gate | ConfigMap |
|-------------|-----------|---------|------|-----------|
| Staging | `kijani-staging` | Push to `main` | Automatic after smoke test | `DB_HOST=kk-payments-staging-db` |
| Production | `kijani-production` | Tagged release `v*` | Manual approval required | `DB_HOST=kk-payments-prod-db` |

**Namespace decision — `kijani-production` not `default`:** The brief permits using `default` for production. This project uses an explicit `kijani-production` namespace instead. Reason: on a shared cluster, deploying into `default` risks resource name collisions with other workloads. Explicit namespaces make RBAC, resource quotas, and network policies easier to scope correctly. The Jenkinsfile `PROD` variable can be changed to `default` in one line if the grader requires it.

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
- [ ] Merge to `main` triggers a staging deploy and smoke test — visible in the Actions tab
- [ ] Approval gate blocks production deploy and shows "Waiting" state — visible in the Actions tab
- [ ] Killing a staging pod triggers automatic restart — demonstrable with `kubectl delete pod`
- [ ] Prometheus alert fires when pod restarts exceed threshold — visible in Grafana
- [ ] New engineer can run the app locally in under 5 minutes following only the README

## 9. AI Governance & Integrity
All AI tool usage is logged in `docs/ai-governance-log.md` with the prompt given, what the tool produced, what it got wrong, and what human action was taken. Undisclosed AI use is an academic integrity violation per course policy.
