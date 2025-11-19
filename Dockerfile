# syntax = docker/dockerfile:1.7-labs
FROM python:3.11.9-slim AS builder

WORKDIR /app
COPY app/requirements.txt .
# Самое важное — ставим в /usr/local, а не в --user
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

FROM python:3.11.9-slim

# Устанавливаем только wget для healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/* && \
    adduser --disabled-password --gecos '' appuser

WORKDIR /app
COPY app/app.py .

# Копируем готовые пакеты из builder в финальный образ
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

ENV PATH=/usr/local/bin:$PATH \
    FLASK_APP=app.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000

EXPOSE 5000
USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --spider -q http://localhost:5000/health || exit 1

CMD ["flask", "run"]