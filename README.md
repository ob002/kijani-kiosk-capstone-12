# 🌿 KijaniKiosk Infrastructure Pipeline

[![CI/CD Pipeline](https://github.com/ob002/kijani-kiosk-capstone/actions/workflows/deploy.yml/badge.svg)](https://github.com/ob002/kijani-kiosk-capstone/actions/workflows/deploy.yml)

> **Core Objective:** A new engineer should be able to clone this repository, understand the architecture, and deploy a meaningful change to the staging environment within their first day.

---

## 1. 🗺️ Architecture

![Architecture Diagram](docs/architecture.png)

**Four-Layer Flow:**

| Layer | Component |
|-------|-----------|
| Infrastructure | Terraform provisions namespaces · Ansible configures staging |
| Delivery | GitHub Actions: build → test → staging deploy → smoke test → approval gate → prod deploy |
| Runtime | Kubernetes: `kijani-staging` (2 replicas) · `kijani-production` (3 replicas + resource limits) |
| Intelligence | Prometheus scrapes pod metrics · Grafana alerts on error rate > 5% or CrashLoopBackOff |

---

## 2. 🛠️ Technology Stack

- **App:** Python 3.12 (Flask)
- **Container:** Docker (with `.dockerignore`)
- **IaC:** Terraform + Ansible
- **Orchestration:** Kubernetes — namespace isolated (`kijani-staging` / `kijani-production`)
- **CI/CD:** GitHub Actions with Environment Protection Rules (manual approval gate)
- **Observability:** Prometheus + Grafana — alert rules committed to `infra/prometheus-alerts.yaml`

---

## 3. 🚀 Getting Started (Local Development)

### Prerequisites
- Python 3.12+
- Docker
- `kubectl` + Minikube or Kind

### Run the app locally
```bash
cd app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```
Visit `http://localhost:5000/health` to verify.

### Build and run with Docker
```bash
docker build -t kijani-kiosk:local ./app
docker run -p 5000:5000 -e ENVIRONMENT=local kijani-kiosk:local
```

### Run smoke tests
```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh http://localhost:5000
```

---

## 4. 🏗️ Deployment Pipeline

1. Push to `main` → triggers `build-and-test` and `deploy-staging` automatically
2. Smoke test runs post-staging deploy
3. `deploy-production` is blocked by a **Manual Approval Gate** (GitHub Settings → Environments → `production` → Required reviewers: `ob002`)
4. Kubernetes manifests in `infra/k8s/` are environment-specific — production enforces resource limits and 3 replicas via ConfigMap

### Fault Scenario (Demo)
```bash
# Kill a staging pod — Kubernetes restarts it automatically
kubectl delete pod -l app=kijani-kiosk -n kijani-staging
# Watch recovery
kubectl get pods -n kijani-staging -w
```

---

## 5. 📂 Repository Structure

```text
├── app/                        # Flask app, Dockerfile, .dockerignore
├── docs/
│   ├── scope-document.md       # CAP-1: project scope, four layers, success criteria
│   ├── ai-governance-log.md    # CAP-3: every AI use, what it got wrong, human action
│   ├── test-plan.md            # CAP-6: written before peer review session
│   ├── peer-feedback-log.md    # CAP-6: 3 issues, severity, commit evidence
│   ├── reflection.md           # CAP-8: specific wrong decision, changed thinking
│   └── architecture.png        # Generated from Mermaid
├── infra/
│   ├── ansible/
│   │   └── configure-staging.yml   # Ansible: configure staging post-Terraform
│   ├── k8s/
│   │   ├── staging-configmap.yaml  # DB_HOST=kk-payments-staging-db
│   │   ├── staging-deployment.yaml
│   │   ├── prod-configmap.yaml     # DB_HOST=kk-payments-prod-db
│   │   └── prod-deployment.yaml    # 3 replicas + resource limits
│   └── prometheus-alerts.yaml      # Alert rules on kk-payments signals
├── pipeline/
│   └── deploy.yml              # GitHub Actions workflow (copy — canonical: .github/workflows/)
└── scripts/
    └── smoke-test.sh
```

---

## 6. 🔑 Key Decisions & Trade-offs

| Decision | Chosen | Alternative | Reason |
|----------|--------|-------------|--------|
| CI/CD tool | GitHub Actions | Jenkins | No separate server to provision; native GitHub integration; `environment:` block gives approval gate for free |
| Local K8s | Minikube/Kind | EKS/GKE | Zero cost for capstone; same manifest format works on cloud with no changes |
| Config management | Ansible | Helm | Ansible is already in the course stack; Helm adds templating complexity not needed at this scale |

---

## 7. 🚧 Production Gaps (What's Not Done Yet)

| Gap | What's Needed to Fix It |
|-----|------------------------|
| TLS/HTTPS | Add cert-manager + Let's Encrypt Issuer to `infra/k8s/` |
| Real DB | Replace mock in-memory store with a provisioned PostgreSQL StatefulSet |
| Horizontal Pod Autoscaler | Add HPA manifest targeting CPU > 70% |
| Secrets management | Replace ConfigMap DB_HOST with Kubernetes Secrets or AWS Secrets Manager |
| Multi-day commit history | Feature branches and PRs from day one (see reflection) |

---

## 🤝 Peer Feedback & Governance

- [docs/peer-feedback-log.md](docs/peer-feedback-log.md) — 3 issues, all resolved with commit evidence
- [docs/ai-governance-log.md](docs/ai-governance-log.md) — every AI use disclosed with "what it got wrong"
- [docs/test-plan.md](docs/test-plan.md) — written before peer review session

<details>
<summary><strong>📊 Architecture Diagram (Mermaid source)</strong></summary>

```mermaid
graph TD
    subgraph Developer
        A[Developer] -->|git push / PR| B(GitHub Repository)
    end
    subgraph CI_CD_Pipeline
        B -->|Trigger on main| C[Build & Test]
        C -->|Success| D[Build Docker Image]
        D -->|Push to Registry| E[(Container Registry)]
        E --> F[Deploy to Staging]
        F --> G[Run Smoke Tests]
        G -->|Pass| H{Manual Approval Gate}
        H -->|Approved| I[Deploy to Production]
    end
    subgraph Kubernetes_Cluster
        subgraph kijani-staging
            F --> J[(Staging Pod)]
        end
        subgraph kijani-production
            I --> K[(Production Pod)]
        end
    end
    subgraph Observability
        L[Prometheus] -.->|Scrape Metrics| J
        L -.->|Scrape Metrics| K
        L -->|Alert on High Error Rate| M[Grafana / Alertmanager]
    end
    style H fill:#f9f,stroke:#333,stroke-width:2px
    style M fill:#ff9,stroke:#333,stroke-width:2px
```
</details>
