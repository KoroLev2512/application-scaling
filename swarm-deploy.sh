#!/bin/bash

# Скрипт для развертывания приложения в Docker Swarm

set -e

echo "=== Развертывание приложения в Docker Swarm ==="

# Проверка, что Docker Swarm инициализирован
if ! docker info | grep -q "Swarm: active"; then
    echo "Инициализация Docker Swarm..."
    docker swarm init
fi

# Сборка образа
echo "Сборка образа приложения..."
docker build -t counter-app:latest .

# Развертывание стека
echo "Развертывание стека..."
docker stack deploy -c docker-compose.swarm.yml counter

echo "Ожидание запуска сервисов..."
sleep 10

# Показ статуса сервисов
echo ""
echo "=== Статус сервисов ==="
docker service ls

echo ""
echo "=== Детали сервиса app ==="
docker service ps counter_app

echo ""
echo "=== Детали сервиса redis-master ==="
docker service ps counter_redis-master

echo ""
echo "=== Детали сервиса redis-replica ==="
docker service ps counter_redis-replica

echo ""
echo "=== Проверка здоровья сервисов ==="
docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"

echo ""
echo "Развертывание завершено!"
echo "Приложение доступно на порту 80 (если настроен порт в docker-compose.swarm.yml)"
