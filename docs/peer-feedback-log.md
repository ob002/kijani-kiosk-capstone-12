# Peer Feedback Log

**Reviewer Name:** Peer Reviewer  
**Date of Review:** November 10, 2026  
**Repository State Reviewed:** Commit `cf8bb27` (Initial boilerplate)

## Feedback Item 1: Missing `.dockerignore` (RESOLVED ✅)
- **Observation:** The `app/` directory had no `.dockerignore`. Local virtual environments or `.DS_Store` files could accidentally be copied into the Docker image, bloating the build.
- **Action Taken:** Created `app/.dockerignore` with `__pycache__/`, `*.pyc`, and `.env` entries.

## Feedback Item 2: Production Resource Limits (RESOLVED ✅)
- **Observation:** `staging-deployment.yaml` and `prod-deployment.yaml` were identical. Production deployments should have explicit CPU/Memory requests and limits to prevent node starvation.
- **Action Taken:** Updated `prod-deployment.yaml` to include `resources.requests` and `resources.limits`, and increased replica count to 3.

## Feedback Item 3: Smoke Test Script Permissions (RESOLVED ✅)
- **Observation:** `scripts/smoke-test.sh` was added but the README did not mention making it executable, which would cause a "Permission denied" error in CI.
- **Action Taken:** Added a "Local Testing" section to `README.md` explicitly stating to run `chmod +x scripts/smoke-test.sh`.

## Summary
All 3 pieces of feedback were reviewed, deemed valid, and implemented. The repository is now more robust and production-ready.
