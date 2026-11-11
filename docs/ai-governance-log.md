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
