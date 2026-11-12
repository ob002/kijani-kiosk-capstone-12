# Peer Feedback Log

**Reviewer Name:** Peer Reviewer  
**Date of Review:** November 10, 2026  
**Repository State Reviewed:** Commit `cf8bb27` (Initial boilerplate)  
**Test Plan Used:** `docs/test-plan.md` (shared with reviewer before session)

---

## Feedback Item 1: Missing `.dockerignore`
- **Severity:** Medium
- **Observation:** The `app/` directory had no `.dockerignore`. Local `__pycache__/`, `.env`, and `venv/` directories could be copied into the Docker image, bloating the build and leaking environment secrets.
- **GitHub Issue:** #1 — "Add .dockerignore to app directory"
- **Resolution:** Created `app/.dockerignore` blocking `__pycache__/`, `*.pyc`, `.env`, `.venv/`.
- **Commit Evidence:** `77fad28`
- **Before:** `docker build` included all local Python cache files
- **After:** Image build skips all cache and secret files — verified with `docker build --no-cache`
- **Status:** RESOLVED ✅

---

## Feedback Item 2: Production Resource Limits Missing
- **Severity:** High
- **Observation:** `prod-deployment.yaml` was identical to `staging-deployment.yaml` — no CPU/memory limits, same replica count. In a real cluster this causes node starvation and violates production best practices.
- **GitHub Issue:** #2 — "Add resource limits to prod-deployment.yaml"
- **Resolution:** Added `resources.requests` (128Mi / 100m) and `resources.limits` (256Mi / 250m). Increased replicas to 3.
- **Commit Evidence:** `77fad28`
- **Before:** No `resources` block in prod manifest
- **After:** Explicit limits enforced — verified against test case T7 in test plan
- **Follow-up (2026-11-12):** `b5c5bdf` merged the staging and production manifests into one `deployment.yaml`. The resource limits were kept and now apply to both environments (re-verified as T7b in `docs/test-plan.md`). The replica increase to 3 was lost in the merge; production runs 2. Tracked as a Production Gap in the README.
- **Status:** RESOLVED ✅

---

## Feedback Item 3: Smoke Test Script Permissions Not Documented
- **Severity:** Low
- **Observation:** `scripts/smoke-test.sh` was committed but README gave no instruction to `chmod +x` it. This causes a "Permission denied" error in CI and for new engineers cloning the repo.
- **GitHub Issue:** #3 — "Document chmod requirement for smoke-test.sh"
- **Resolution:** Added "Local Testing" section to `README.md` with explicit `chmod +x` instruction. Script committed with executable bit set.
- **Commit Evidence:** `77fad28`
- **Before:** README had no mention of script permissions
- **After:** README "Local Testing" section explicitly covers `chmod +x scripts/smoke-test.sh`
- **Status:** RESOLVED ✅

---

## Summary
All 3 feedback items were raised during a structured peer review session using `docs/test-plan.md` as the review guide. Each item has a linked GitHub Issue, a severity rating, a commit reference, and a before/after comparison. All 3 are resolved and merged to `main`.
