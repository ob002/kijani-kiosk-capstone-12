# KijaniKiosk Infrastructure Pipeline

[![CI/CD Pipeline](https://github.com/ob002/kijani-kiosk-capstone/actions/workflows/deploy.yml/badge.svg)](https://github.com/ob002/kijani-kiosk-capstone/actions/workflows/deploy.yml)

Welcome to the KijaniKiosk Capstone Project. This repository contains the production-grade DevOps infrastructure, CI/CD pipelines, and observability configurations for the KijaniKiosk eco-friendly ticketing API.

> **Core Objective:** A new engineer should be able to clone this repository, understand the architecture, and deploy a meaningful change to the staging environment within their first day.

## Architecture

![Architecture Diagram](docs/architecture.png)

**High-Level Flow:**  
`GitHub Push` → `GitHub Actions (Build/Test)` → `Deploy to Staging` → `Smoke Test` → `Manual Approval Gate` → `Deploy to Production` → `Prometheus/Grafana Monitoring`

## Technology Stack
- **App:** Python 3.12 (Flask)
- **Container:** Docker
- **Orchestration:** Kubernetes (Namespace isolated: `kijani-staging` & `kijani-production`)
- **CI/CD:** GitHub Actions (with Environment Protection Rules)
- **Observability:** Prometheus + Grafana

## Getting Started (Local Development)

### Prerequisites
- Python 3.12+
- Docker
- `kubectl` and a local Kubernetes cluster (Minikube or Kind)

### 1. Run the App Locally
```bash
cd app
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```
Visit `http://localhost:5000/health` to verify.

### 2. Build and Test the Docker Image
```bash
docker build -t kijani-kiosk:local ./app
docker run -p 5000:5000 -e ENVIRONMENT=local kijani-kiosk:local
```

### 3. Run Smoke Tests
```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh http://localhost:5000
```

## Deployment Pipeline
This project uses GitHub Actions (`pipeline/deploy.yml`).
1. Pushing to `main` triggers the `build-and-test` and `deploy-staging` jobs automatically.
2. The `deploy-production` job is protected by a **Manual Approval Gate** (configured in GitHub Settings → Environments → `production`).
3. Kubernetes manifests are separated by environment in `infra/k8s/`, with production enforcing stricter resource limits and higher replica counts.

## Repository Structure
```text
├── app/                  # Python Flask application & Dockerfile
├── docs/                 # Scope, Architecture, Peer Feedback, Reflection
├── infra/k8s/            # Kubernetes manifests (staging & production)
├── pipeline/             # GitHub Actions CI/CD workflow
├── scripts/              # Automation and smoke test scripts
└── README.md             # You are here!
```

## Peer Feedback & Governance
- See [docs/peer-feedback-log.md](docs/peer-feedback-log.md) for resolved improvements.
- See [docs/scope-document.md](docs/scope-document.md) for AI governance and integrity statements.

---
<details>
<summary><strong>📊 Architecture Diagram (Mermaid)</strong></summary>

```mermaid
graph TD
    subgraph Developer
        A[Developer] -->|git push / PR| B(GitHub Repository)
    end
    subgraph CI/CD Pipeline - GitHub Actions
        B -->|Trigger on main| C[Build & Test]
        C -->|Success| D[Build Docker Image]
        D -->|Push to Registry| E[(Container Registry)]
        E --> F[Deploy to Staging]
        F --> G[Run Smoke Tests]
        G -->|Pass| H{Manual Approval Gate}
        H -->|Approved| I[Deploy to Production]
    end
    subgraph Kubernetes Cluster
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
