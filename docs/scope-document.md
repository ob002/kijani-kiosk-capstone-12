# KijaniKiosk Capstone: Project Scope Document

## 1. Project Overview
**Project Name:** KijaniKiosk Infrastructure Pipeline  
**Chosen Track:** Track A (Infrastructure-First)  
**Business Context:** KijaniKiosk is a mock eco-friendly ticketing and point-of-sale API. This capstone focuses exclusively on building the production-grade DevOps infrastructure, CI/CD pipelines, and observability required to support it.

## 2. Core Objective
To deliver a fully automated, secure, and observable infrastructure pipeline such that a new engineer can clone the repository, understand the architecture, and deploy a meaningful change to the staging environment within their first day.

## 3. Technology Stack
- **Application:** Python 3.12 (Flask)
- **Containerization:** Docker
- **Infrastructure as Code (IaC):** Terraform
- **Orchestration:** Kubernetes (Minikube/Kind for local, EKS/GKE ready) with namespace isolation (`kijani-staging` and `kijani-production`)
- **CI/CD:** GitHub Actions (with manual approval gates for production)
- **Observability:** Prometheus + Grafana, with at least one active alert rule

## 4. Environment Strategy
- **Staging (`kijani-staging`):** Auto-deployed on every push/merge to `main`. Runs automated smoke tests post-deployment.
- **Production (`kijani-production`):** Requires a manual approval gate. Only tagged releases (`v*`) are deployed here.

## 5. AI Governance & Integrity
AI tools were used to generate boilerplate Kubernetes manifests and Terraform scaffolding. All AI-generated code has been manually reviewed, tested, and documented to ensure security and compliance with academic integrity policies.

## 6. Success Criteria (Definition of Done)
- [ ] Repository is cleanly structured with a comprehensive README
- [ ] CI/CD pipeline successfully builds, tests, and deploys to staging
- [ ] Manual approval gate blocks automatic production deployment
- [ ] Prometheus is scraping metrics and at least one alert is configured
- [ ] Peer feedback has been logged and at least one actionable improvement has been merged
