# KijaniKiosk Capstone: Project Scope

**Track:** A (Infrastructure-First) · **Repo:** `ob002/kijani-kiosk-capstone` · **Revised:** 2026-11-12 (original plan named GitHub Actions; Track A requires Jenkins, so the pipeline was rebuilt in Jenkins)

## Problem Statement
kk-payments had a single environment and no gated release path: every change went live untested, and nobody was told when it started returning errors. This project adds an isolated staging environment, a Jenkins pipeline that blocks production until staging passes a smoke test and a named person approves, and a Prometheus alert on the kk-payments 5xx rate.

## In Scope (5)
1. Terraform creates `kijani-staging` and `kijani-production`; Ansible configures staging (labels, ConfigMap, Service, `DB_HOST` assertion).
2. Jenkins pipeline: build → deploy staging → smoke test → approval gate with reason → deploy production, with automatic staging rollback on failure.
3. One shared `deployment.yaml` (probes, resource limits, 2 replicas) with a per-environment ConfigMap (`DB_HOST` differs).
4. Prometheus scrapes kk-payments `/metrics` in both namespaces; `HighErrorRate` fires when 5xx exceeds 5% for 2 minutes.
5. Peer review against a written test plan, plus an AI governance log recording what each AI tool got wrong.

## Out of Scope
- **Receipt chain (S3 write to `kk-payments-receipts-staging`)** — needs cloud credentials and a bucket this local Minikube setup does not have; listed in README Production Gaps with the fix.
- **TLS / ingress** — the app is reached through `kubectl port-forward` only; no external traffic reaches it.
- **Real database** — kk-payments uses an in-memory mock; `DB_HOST` proves configuration separation, not a connection.
- **Grafana / Alertmanager** — alerts are visible in Prometheus but not routed to anyone (Production Gap).

## Success Criteria (each shown in the demo or in `docs/evidence/`)
- [x] A change on `main` starts the pipeline with no manual trigger — Jenkins build #2, "Started by an SCM change".
- [x] A failing staging smoke test skips both production stages and rolls staging back — build #3 (`INJECT_FAULT=true`).
- [x] Production deploy waits for a person, and Jenkins records their name and reason — build #2 approval.
- [x] Staging and production read different `DB_HOST` values — Ansible assertion passes (`ansible-01-configure-staging.txt`).
- [x] `HighErrorRate` fires for `kijani-staging` only within 5 minutes of a staging fault, and clears after rollback — `prometheus-01-alert-fires.txt`.
- [x] Deleting both staging pods restores 2 Ready pods within 60 seconds — 34 s (`selfheal-01-pod-delete.txt`).

## Key Decision: `kijani-production`, not `default`
The brief allows `default` for production. An explicit namespace avoids name collisions with other workloads on a shared cluster and lets RBAC, quotas and network policies be scoped per environment. Cost: every `kubectl` command and the Jenkinsfile must pass `-n`.

## Architecture
See `docs/architecture.png` (four layers, every connection labelled). Mermaid source is in the README.
