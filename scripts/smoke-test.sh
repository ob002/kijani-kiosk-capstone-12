#!/bin/bash
set -e

BASE_URL=${1:-"http://localhost:5000"}

echo "Running smoke tests against $BASE_URL..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
if [ "$STATUS" != "200" ]; then
  echo "FAIL: /health returned $STATUS"
  exit 1
fi
echo "PASS: /health returned 200"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/checkout")
if [ "$STATUS" != "201" ]; then
  echo "FAIL: /checkout returned $STATUS"
  exit 1
fi
echo "PASS: /checkout returned 201"

echo "All smoke tests passed."
