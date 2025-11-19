# ========== Stage 1: Builder ==========
FROM python:3.11.9-slim AS builder

WORKDIR /app

# Устанавливаем только то, что нужно для сборки
RUN pip install --upgrade pip
COPY app/requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# ========== Stage 2: Final ==========
FROM python:3.11.9-slim

# Создаём непривилегированного пользователя
RUN adduser --disabled-password --gecos '' appuser

WORKDIR /app

# Копируем только необходимые файлы
COPY --from=builder /root/.local /home/appuser/.local
COPY app/app.py .

# Делаем бинарники доступными
ENV PATH=/home/appuser/.local/bin:$PATH

# Порт и переменные
EXPOSE 5000
ENV FLASK_APP=app.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000

# Переключаемся на непривилегированного пользователя
USER appuser

# Healthcheck (Flask должен отвечать)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:5000/health || exit 1

CMD ["flask", "run"]
