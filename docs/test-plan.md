# Test Plan

**Written:** Before peer review session  
**Author:** ob002  
**Repo State:** Commit `77fad28`

## Scope
This test plan covers the smoke test, pipeline gate, and namespace isolation. It was written before the peer review session and shared with the reviewer so they could validate against it.

## Test Cases

| ID | Test | Method | Expected Result | Pass/Fail |
|----|------|--------|-----------------|-----------|
| T1 | `/health` returns 200 | `curl http://localhost:5000/health` | `{"status":"healthy","environment":"staging"}` HTTP 200 | ✅ Pass |
| T2 | `/checkout` returns 201 | `curl http://localhost:5000/checkout` | `{"message":"Ticket purchased successfully!"}` HTTP 201 | ✅ Pass |
| T3 | Docker image builds without error | `docker build -t kijani-kiosk:test ./app` | Exit code 0, no layer errors | ✅ Pass |
| T4 | Smoke test script exits 0 on healthy app | `./scripts/smoke-test.sh http://localhost:5000` | `✅ SUCCESS: Health check passed (HTTP 200)` | ✅ Pass |
| T5 | Smoke test script exits 1 on dead app | Run script against port with nothing listening | `❌ FAILURE: Health check failed` + exit code 1 | ✅ Pass |
| T6 | Staging manifest applies without error | `kubectl apply -f infra/k8s/staging-deployment.yaml --dry-run=client` | `configured (dry run)` | ✅ Pass |
| T7 | Production manifest has resource limits | Inspect `prod-deployment.yaml` | `resources.limits` block present with cpu and memory | ✅ Pass |
| T8 | Production approval gate blocks auto-deploy | Push to main, observe Actions tab | `deploy-production` shows "Waiting" not "Running" | ✅ Pass |

## Fault Scenario (Demo)

| ID | Fault | Method | Expected Behaviour |
|----|-------|--------|--------------------|
| F1 | Kill staging pod | `kubectl delete pod -l app=kijani-kiosk -n kijani-staging` | Kubernetes restarts pod automatically; liveness probe recovers within 30s |

## Out of Scope
- Load testing
- TLS/certificate validation
- Database persistence (app is stateless)

---

## Revision 2026-11-12: re-run against the current system

The tables above are the original plan, kept unchanged as the record of what the reviewer tested against. Since then the pipeline moved from GitHub Actions to Jenkins, the two manifests were merged into one `deployment.yaml`, and the app label changed to `app=kk-payments`. T6, T7, T8 and F1 no longer run as written. Replacements, re-run on 2026-11-12:

| ID | Replaces | Test | Method | Expected | Result |
|----|----------|------|--------|----------|--------|
| T6b | T6 | Shared manifest applies | `sed "s\|IMAGE_PLACEHOLDER\|x\|" infra/k8s/deployment.yaml \| kubectl apply --dry-run=client -n kijani-staging -f -` | `configured (dry run)` / `created (dry run)` | ✅ Pass |
| T7b | T7 | Resource limits present (both envs share them) | `grep -A6 resources infra/k8s/deployment.yaml` | cpu + memory requests and limits | ✅ Pass |
| T8b | T8 | Approval gate blocks production | Jenkins build #2 | Pipeline pauses at "Approve Production" until a person approves with a reason | ✅ Pass (`docs/evidence/green-06-*`) |
| T9 | new | Failed smoke test blocks production | Jenkins build #3 with `INJECT_FAULT=true` | Production stages skipped, staging rolled back | ✅ Pass (`docs/evidence/fault-*`) |
| T10 | new | Staging uses staging DB | `ansible-playbook infra/ansible/configure-staging.yml` | Assert `DB_HOST == kk-payments-staging-db` passes | ✅ Pass (`ansible-01-configure-staging.txt`) |
| T11 | new | Alert fires on staging errors | `kubectl set env deployment/kk-payments FAULT_HEALTH=true -n kijani-staging`, watch `:9090/alerts` | `HighErrorRate` firing for `kijani-staging` only within 5 min; clears after rollback | ✅ Pass (`prometheus-01-alert-fires.txt`) |
| F1b | F1 | Kill staging pods | `kubectl delete pod -l app=kk-payments -n kijani-staging` | ReplicaSet restores 2 Ready pods within 60 s | ✅ Pass, 34 s (`selfheal-01-pod-delete.txt`) |
