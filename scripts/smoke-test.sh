#!/bin/bash
# Simple smoke test for KijaniKiosk
# Usage: ./smoke-test.sh <URL>

URL=${1:-"http://localhost:5000"}

echo "Running smoke test against $URL..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL/health")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ SUCCESS: Health check passed (HTTP 200)"
    exit 0
else
    echo "❌ FAILURE: Health check failed (HTTP $HTTP_CODE)"
    exit 1
fi
