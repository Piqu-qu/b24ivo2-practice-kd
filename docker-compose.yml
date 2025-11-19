# docker-compose.yml (полностью закрывает Задание 1)
name: compose-counter

services:
  web:
    build: .
    ports:
      - "${HOST_PORT:-8080}:5000"
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      redis:
        condition: service_healthy
    restart: unless-stopped

    # ---------- Безопасность и ограничения ----------
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 128M
        reservations:
          cpus: "0.25"
          memory: 64M

  redis:
    image: redis:7.2-alpine          # зафиксированная версия
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 3s
      timeout: 2s
      retries: 10
    restart: unless-stopped

  redis-commander:
    image: rediscommander/redis-commander:latest
    environment:
      - REDIS_HOSTS=local:redis:6379
    ports:
      - "8081:8081"
    depends_on:
      redis:
        condition: service_healthy
    restart: unless-stopped

volumes:
  redis_data:
