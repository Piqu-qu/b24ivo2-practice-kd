from flask import Flask, jsonify
import redis
import os
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

# Redis
r = redis.Redis(host=os.getenv('REDIS_HOST', 'redis'), port=6379, decode_responses=True)

# Prometheus метрики
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('app_request_latency_seconds', 'Request latency', ['endpoint'])
ERROR_COUNT = Counter('app_errors_total', 'Total errors', ['type'])

# Декораторы для метрик
def monitor_requests(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        start = time.time()
        try:
            resp = f(*args, **kwargs)
            status = resp.status_code if hasattr(resp, 'status_code') else 200
            REQUEST_COUNT.labels(method='GET', endpoint=f.__name__, status=status).inc()
            REQUEST_LATENCY.labels(endpoint=f.__name__).observe(time.time() - start)
            return resp
        except Exception as e:
            ERROR_COUNT.labels(type='exception').inc()
            raise e
    return decorated

@app.route("/")
@monitor_requests
def index():
    return jsonify({"message": "Welcome! Go to /count"})

@app.route("/count")
@monitor_requests
def count():
    count = r.incr("counter")
    return jsonify({"count": count})

@app.route("/health")
def health():
    try:
        r.ping()
        return "OK", 200
    except:
        return "ERROR", 500

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)