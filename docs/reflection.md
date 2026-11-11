# Capstone Reflection

## 1. The specific technical decision I got wrong
I placed the GitHub Actions workflow at `pipeline/deploy.yml` instead of `.github/workflows/deploy.yml`. GitHub Actions only reads from `.github/workflows/` — the pipeline was completely inert for the first several commits. I only discovered this when attempting to trigger a `workflow_dispatch` via the API and getting a 404. The fix was straightforward, but it meant the CI/CD pipeline was never actually running during the early development phase, which undermined the "pipeline-first" intent of Track A.

## 2. One concept I learned and how my thinking changed
I came into this project thinking "infrastructure" meant Kubernetes manifests and a CI/CD file. The rubric's four-layer model (infrastructure, delivery, runtime, intelligence) changed that. The intelligence layer — Prometheus alerting on real application signals like error rate and pod restarts — is what separates a deployment pipeline from a production-grade system. I now think of observability not as an add-on but as a first-class deliverable that should be scoped and committed alongside the manifests from day one.

## 3. Specific changes I would make on a second pass
- **Add Ansible from the start.** Configuration management was out of scope here but the rubric expects it. On a second pass I would write an Ansible playbook to configure the staging namespace immediately after Terraform provisions it, rather than treating them as separate concerns.
- **Use feature branches from commit one.** All commits in this project landed directly on `main`. On a second pass I would open a branch per feature (e.g., `feat/k8s-manifests`, `feat/ci-pipeline`) and merge via PR so the git history tells a readable story and satisfies Dimension 5 without retrofitting.
- **Write the test plan before writing any code.** I wrote the test plan after the implementation. Writing it first would have caught the `.github/workflows/` path issue before it was committed.
