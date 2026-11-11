# 🌿 KijaniKiosk Infrastructure Pipeline

[![Jenkins Pipeline](https://img.shields.io/badge/Jenkins-Pipeline-blue?logo=jenkins)](https://github.com/ob002/kijani-kiosk-capstone/blob/main/Jenkinsfile)

> **Core Objective:** A new engineer should be able to clone this repository, understand the architecture, and deploy a meaningful change to the staging environment within their first day.

---

## 1. 🗺️ Architecture

![Architecture Diagram](docs/architecture.png)

**Four-Layer Flow:**

| Layer | Component |
|-------|-----------|
| Infrastructure | Terraform provisions namespaces · Ansible playbook written, not yet executed |
| Delivery | Jenkins: build → staging deploy → smoke test → approval gate → prod deploy |
| Runtime | Kubernetes: `kijani-staging` and `kijani-production`, both 2 replicas with the same CPU/memory requests and limits (one shared manifest) |
| Intelligence | Prometheus + Grafana (planned) — alert rules written in `infra/prometheus-alerts.yaml`, not yet deployed |

---

## 2. 🛠️ Technology Stack

- **App:** Python 3.12 (Flask)
- **Container:** Docker (with `.dockerignore`)
- **IaC:** Terraform (applied: creates both namespaces) · Ansible (playbook written, not yet executed)
- **Orchestration:** Kubernetes — namespace isolated (`kijani-staging` / `kijani-production`)
- **CI/CD:** Jenkins (Pipeline job, "Pipeline script from SCM", polls `main` every 2 min — `Jenkinsfile` at repo root, manual approval gate that records a reason)
- **Observability:** Prometheus + Grafana (planned) — alert rules committed to `infra/prometheus-alerts.yaml`; deployment of `kube-prometheus-stack` and ServiceMonitor is a Production Gap

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

The pipeline is defined in `Jenkinsfile` at the repo root. A Jenkins Pipeline job ("Pipeline script from SCM") polls `main` every 2 minutes and runs it on change.

1. Push to `main` → Jenkins runs **Checkout → Build → Deploy to Staging → Smoke Test**
2. Smoke test must pass (HTTP 200 from `/health`) before the pipeline proceeds
3. **Approval Gate** pauses the pipeline; Jenkins records who approved and the reason they entered (the reason field is not yet enforced as non-empty)
4. Both namespaces use the same `infra/k8s/deployment.yaml` (2 replicas, same resource limits); only the ConfigMap differs per environment
5. If any stage fails, `post { failure }` runs `kubectl rollout undo` on staging

### Pipeline Stages
```
Checkout → Build Docker Image → Deploy to Staging → Smoke Test → Approve Production → Deploy to Production
```
There is no unit-test stage yet (see Production Gaps).

### Fault Scenario (Demo)
Run **Build with Parameters** with `INJECT_FAULT` ticked. The pipeline sets `FAULT_HEALTH=true` on staging, `/health` returns 500, the smoke test fails, both production stages are skipped and staging is rolled back. Evidence: [docs/evidence/](docs/evidence/README.md).

Self-healing check (separate from the pipeline):
```bash
# Delete a staging pod — the ReplicaSet recreates it to keep 2 replicas
kubectl delete pod -l app=kk-payments -n kijani-staging --wait=false
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
│   │   └── configure-staging.yml   # Ansible playbook (written, not yet executed)
│   ├── k8s/
│   │   ├── deployment.yaml         # Shared by both namespaces: 2 replicas + resource limits
│   │   ├── service.yaml
│   │   ├── staging-configmap.yaml  # DB_HOST=kk-payments-staging-db
│   │   └── prod-configmap.yaml     # DB_HOST=kk-payments-prod-db
│   ├── terraform/                  # Creates kijani-staging and kijani-production namespaces
│   └── prometheus-alerts.yaml      # Alert rules (not deployed)
├── scripts/
│   └── smoke-test.sh
└── Jenkinsfile                     # The pipeline
```

---

## 6. 🔑 Key Decisions & Trade-offs

| Decision | Chosen | Alternative | Reason |
|----------|--------|-------------|--------|
| CI/CD tool | Jenkins | GitHub Actions | Track A explicitly requires Jenkins; approval gate implemented via `input()` step that records the approver and a reason |
| Local K8s | Minikube/Kind | EKS/GKE | Zero cost for capstone; same manifest format works on cloud with no changes |
| Config management | Ansible | Helm | Ansible is already in the course stack; Helm adds templating complexity not needed at this scale |

---

## 7. 🚧 Production Gaps (What's Not Done Yet)

| Gap | Specific Fix |
|-----|--------------|
| **Prometheus not deployed** | `/metrics` endpoint and `infra/prometheus-alerts.yaml` exist. Fix: install `kube-prometheus-stack` via Helm, add a `ServiceMonitor` for `kk-payments`, verify alert fires when error rate > 5% |
| **Receipt chain not integrated** | `kk-payments` has no S3 write. Fix: add `boto3` call in `/checkout` to write to `kk-payments-receipts-staging` bucket, add bucket notification to trigger the serverless receipt chain |
| **No unit tests** | The pipeline has no test stage; the only automated check is the staging smoke test. Fix: write `pytest` tests for `/health` and `/checkout` and add a `Test` stage running `python -m pytest tests/ -v` before Deploy to Staging |
| **Ansible not executed** | `infra/ansible/configure-staging.yml` is written but has never been run against the cluster. Fix: run it after `terraform apply`, or remove it if the ConfigMaps already cover staging config |
| **Prod identical to staging** | Both namespaces use the same manifest (2 replicas, same limits). Fix: Kustomize overlay or a `prod-deployment.yaml` with 3 replicas and stricter limits |
| **Approval reason not enforced** | An empty reason is accepted. Fix: `if (!env.APPROVAL_REASON?.trim()) { error('Approval reason required') }` |
| **TLS/HTTPS** | App runs plain HTTP. Fix: add `cert-manager` + Let's Encrypt `Issuer` to `infra/k8s/` |
| **Horizontal Pod Autoscaler** | No HPA. Fix: add HPA manifest targeting CPU > 70% |

---

## 📸 Evidence

Jenkins pipeline runs are documented in [docs/evidence/](docs/evidence/README.md):
- **Build #2 (green):** triggered by an SCM change, passed the smoke test and manual approval, deployed to production.
- **Build #3 (fault injection):** `INJECT_FAULT=true` made the staging health check return 500, the pipeline stopped before the approval gate, and staging was rolled back automatically. Production was not touched.

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
    subgraph Observability_PLANNED["Observability (planned, not deployed)"]
        L[Prometheus] -.->|Scrape Metrics - planned| J
        L -.->|Scrape Metrics - planned| K
        L -.->|Alert on High Error Rate - planned| M[Grafana / Alertmanager]
    end
    style H fill:#f9f,stroke:#333,stroke-width:2px
    style M fill:#ff9,stroke:#333,stroke-width:2px
```
</details>
