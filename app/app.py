from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import os
import logging
import json
import time

app = Flask(__name__)
ENVIRONMENT = os.getenv("ENVIRONMENT", "unknown")
FAULT_HEALTH = os.getenv("FAULT_HEALTH", "false").lower() == "true"

# Structured JSON logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'kk_payments_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)
REQUEST_LATENCY = Histogram(
    'kk_payments_request_latency_seconds',
    'HTTP request latency',
    ['endpoint']
)


def log_request(endpoint, status, duration):
    logger.info(json.dumps({
        "endpoint": endpoint,
        "status": status,
        "duration_ms": round(duration * 1000, 2),
        "environment": ENVIRONMENT
    }))


@app.route('/health')
def health():
    start = time.time()
    if FAULT_HEALTH:
        REQUEST_COUNT.labels('GET', '/health', '500').inc()
        log_request('/health', 500, time.time() - start)
        return jsonify({"status": "error", "environment": ENVIRONMENT}), 500
    REQUEST_COUNT.labels('GET', '/health', '200').inc()
    log_request('/health', 200, time.time() - start)
    return jsonify({"status": "healthy", "environment": ENVIRONMENT}), 200


@app.route('/checkout')
def checkout():
    start = time.time()
    REQUEST_COUNT.labels('GET', '/checkout', '201').inc()
    log_request('/checkout', 201, time.time() - start)
    return jsonify({"message": "Ticket purchased successfully!", "environment": ENVIRONMENT}), 201


@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
