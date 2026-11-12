# Jenkins Pipeline Evidence

Captured 2026-11-11 on the local Jenkins (2.580.2) + minikube setup.

## Build #2 — green run (triggered by SCM change, commit `a708884`)

| File | What it proves |
|------|----------------|
| `green-01-stage-view.png` | All stages passed: Checkout → Build → Deploy to Staging → Smoke Test → Approve Production → Deploy to Production. "Started by an SCM change". |
| `green-02-console-scm-trigger.png` | Jenkinsfile obtained from GitHub `main`, checked out `a708884`. |
| `green-03-console-build.png` | Image built and tagged with the commit SHA (`kijani-kiosk:a708884`). |
| `green-04-console-image-import.png` | Image saved and imported into minikube's containerd. |
| `green-05-console-deploy-staging.png` | Staging deploy and rollout status succeeded. |
| `green-06-console-smoke-pass-approval.png` | Smoke test returned HTTP 200; manual approval recorded with approver name and reason. |
| `green-07-console-deploy-production.png` | Production namespace created config, service and deployment; rollout succeeded. |
| `green-08-console-finished-success.png` | `Finished: SUCCESS`. |
| `green-09-production-pods.png` | Two production pods `1/1 Running` after the deploy. |

## Build #3 — fault injection (`INJECT_FAULT=true`)

| File | What it proves |
|------|----------------|
| `fault-01-parameters.png` | Build was run with `INJECT_FAULT` ticked. |
| `fault-02-stage-view.png` | Smoke Test failed; Approve Production and Deploy to Production were skipped; Post Actions ran. |
| `fault-03-console-injected.png` | `FAULT_HEALTH=true` set on the staging deployment. |
| `fault-04-console-500-skipped.png` | Health check returned HTTP 500; both production stages skipped due to the failure. |
| `fault-05-console-rollback.png` | `post { failure }` ran `kubectl rollout undo` on staging; `Finished: FAILURE`. |
| `fault-06-recovery-check.txt` | After rollback: staging pods healthy, `FAULT_HEALTH` no longer set, `/health` returns 200, production pods unchanged since build #2. Generated at 2026-11-11 16:59 EAT by an AI assistant (Claude Code) running the `kubectl`/`curl` commands shown in the file against the local minikube cluster; not a Jenkins artifact. |

Rollout history on staging shows revisions 1, 3, 4: revision 3 was the faulty spec, and the undo re-applied the previous good spec as revision 4 (Kubernetes drops the old revision number when it is reused).

## Ansible and Prometheus (2026-11-12)

Run against the same minikube cluster. Commands were executed by Claude Code (AI assistant) at the user's request; output is unedited.

| File | What it proves |
|------|----------------|
| `ansible-01-configure-staging.txt` | `ansible-playbook infra/ansible/configure-staging.yml` ran: 7 ok, 0 failed. Namespace labelled `configured-by=ansible`; ConfigMap and Service applied; assert confirms staging `DB_HOST=kk-payments-staging-db`. |
| `prometheus-00-targets-and-rules.txt` | Prometheus pod running in `monitoring`; all 4 kk-payments pods (2 staging, 2 production) scraped and `up`; 3 alert rules loaded with `health=ok`. |
| `prometheus-01-alert-fires.txt` | `FAULT_HEALTH=true` set on staging at 18:11:19. `HighErrorRate` went active at 18:11:58 and **firing** by 18:14:01, labelled `namespace=kijani-staging` only (5xx ratio ≈ 0.36). `kubectl rollout undo` at 18:14:09; alert cleared by 18:18:46. |
