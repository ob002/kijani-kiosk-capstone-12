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
