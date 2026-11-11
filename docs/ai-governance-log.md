# AI Governance Log

> This log records every instance where AI tooling was used during this capstone, what it produced, what was wrong with it, and what human action was taken. Undisclosed AI use is an academic integrity violation per the course policy.

---

## Entry 1

| Field | Detail |
|-------|--------|
| **Date** | 2026-11-09 |
| **Tool Used** | LLM (Amazon Q) |
| **Task** | Generate initial Kubernetes Deployment manifests for staging and production namespaces |
| **Prompt Given** | "Generate a Kubernetes Deployment YAML for a Flask app in a namespace called kijani-staging with a liveness probe on /health" |
| **What It Produced** | A valid `staging-deployment.yaml` with namespace, 2 replicas, liveness probe, and env var injection |
| **What It Got Wrong** | Production manifest was identical to staging — no resource requests/limits, same replica count. This would cause node starvation in a real cluster. |
| **Human Action Taken** | Manually added `resources.requests` (128Mi / 100m) and `resources.limits` (256Mi / 250m) to `prod-deployment.yaml`, increased replicas to 3. Committed in `77fad28`. |
| **Governance Checklist** | ✅ Reviewed line-by-line · ✅ Tested locally · ✅ Adapted for context · ✅ Disclosed here |

---

## Entry 2

| Field | Detail |
|-------|--------|
| **Date** | 2026-11-09 |
| **Tool Used** | LLM (Amazon Q) |
| **Task** | Generate GitHub Actions CI/CD pipeline with a manual approval gate |
| **Prompt Given** | "Generate a GitHub Actions workflow with build, deploy-staging, and deploy-production jobs where production requires manual approval" |
| **What It Produced** | A 3-job workflow using `environment: production` to trigger the approval gate |
| **What It Got Wrong** | Workflow was placed in `pipeline/deploy.yml` — GitHub Actions only reads from `.github/workflows/`. The pipeline would never trigger automatically. Also missing `workflow` scope note for the PAT. |
| **Human Action Taken** | Documented the correct path requirement in README. Added `workflow_dispatch` trigger so it can be manually triggered for demo purposes. Flagged PAT scope requirement explicitly. |
| **Governance Checklist** | ✅ Reviewed line-by-line · ✅ Tested trigger manually · ✅ Adapted for context · ✅ Disclosed here |

---

## Entry 3

| Field | Detail |
|-------|--------|
| **Date** | 2026-11-11 |
| **Tool Used** | LLM (Amazon Q) |
| **Task** | Generate Kubernetes Deployment and Jenkinsfile for Minikube-based CI/CD |
| **Prompt Given** | "Generate a Jenkinsfile with build, staging deploy, smoke test, approval gate and production deploy stages for a Flask app on Minikube" |
| **What It Produced** | A Deployment manifest with no `imagePullPolicy` field, and a Jenkinsfile smoke test that used a dynamic ClusterIP lookup — but no Service manifest was generated at all |
| **What It Got Wrong** | Two failures discovered during diagnostic testing: (1) Minikube cannot pull an image that only exists in the local Docker daemon without `imagePullPolicy: IfNotPresent` — the pod would enter `ImagePullBackOff`. (2) The smoke test port-forward targeted `svc/kk-payments` which did not exist because no Service manifest was ever generated — the port-forward would fail immediately with "service not found". Neither failure would be caught until the pipeline actually ran. |
| **Human Action Taken** | Added `imagePullPolicy: IfNotPresent` to `infra/k8s/deployment.yaml`. Created `infra/k8s/service.yaml` — ClusterIP Service named `kk-payments` on port 5000. Updated both Deploy stages in the Jenkinsfile to apply `service.yaml` before the Deployment. Verified by running `grep imagePullPolicy infra/k8s/deployment.yaml` and `cat infra/k8s/service.yaml`. Committed in PR #4, commit `794d21d`. |
| **Governance Checklist** | ✅ Reviewed line-by-line · ✅ Tested locally · ✅ Adapted for context · ✅ Disclosed here |

---

## Entry 4

| Field | Detail |
|-------|--------|
| **Date** | 2026-11-11 |
| **Tool Used** | LLM (Amazon Q) |
| **Task** | Load a locally built Docker image into Minikube so Kubernetes pods can pull it |
| **Prompt Given** | "How do I load a local Docker image into Minikube so kubectl can use it?" |
| **What It Produced** | The command `docker save $IMAGE \| docker exec -i minikube docker load` |
| **What It Got Wrong** | Minikube's container runtime is containerd (confirmed via `minikube start` output: `containerd 2.3.4`), not Docker. The `docker load` command targets the Docker daemon inside the Minikube VM, which does not exist. Running it produced "unrecognized image format" because containerd does not understand the Docker load protocol. |
| **Human Action Taken** | Identified the correct containerd import command: `docker save $IMAGE \| docker exec -i minikube ctr -n k8s.io images import -`. Tested manually: `docker save kijani-kiosk:test \| docker exec -i minikube ctr -n k8s.io images import -` confirmed `docker.io/library/kijani-kiosk:test` visible in `minikube ctr -n k8s.io images ls`. Updated the Jenkinsfile Build stage accordingly. Committed in PR #6, `b9e80b8`. |
| **Governance Checklist** | ✅ Reviewed line-by-line · ✅ Tested with real image · ✅ Adapted for context · ✅ Disclosed here |

---

## Entry 5

| Field | Detail |
|-------|--------|
| **Date** | 2026-11-12 |
| **Tool Used** | LLM (Amazon Q) |
| **Task** | Add a receipt chain verification stage to the Jenkinsfile |
| **Prompt Given** | "Add a stage after Deploy to Production that verifies the receipt chain fired by POSTing to /checkout and checking for a 201 response" |
| **What It Produced** | A `Verify Receipt Chain` stage that port-forwarded to staging on port 5001, POSTed to `/checkout`, and checked for HTTP 201 |
| **What It Got Wrong** | Three problems: (1) The stage ran after Deploy to Production — if it failed, `post { failure }` would roll back the staging deployment while the broken build stayed live in production, leaving production in a worse state than before. (2) The stage used a different port (5001) from the smoke test (5000) with no explanation, which would fail if port 5001 was already in use. (3) The stage only checked that `/checkout` returned 201 — it never verified that a message was actually written to `kk-payments-receipts-staging`. A 201 from the app proves nothing about the receipt chain. The receipt chain integration itself was never built (no S3 write in `app.py`), so the stage was testing something that did not exist. |
| **Human Action Taken** | Removed the `Verify Receipt Chain` stage entirely. Documented the receipt chain as a Production Gap in `README.md` with a specific fix: add `boto3` S3 write in `/checkout`, add bucket notification to trigger the serverless chain. Committed in PR #9. |
| **Governance Checklist** | ✅ Reviewed line-by-line · ✅ Failure mode identified before running · ✅ Removed rather than left as misleading · ✅ Disclosed here |
