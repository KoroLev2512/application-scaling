#!/bin/bash

# Полезные команды для работы с Docker Swarm

echo "=== Docker Swarm - Полезные команды ==="
echo ""

echo "1. Инициализация Swarm:"
echo "   docker swarm init"
echo ""

echo "2. Просмотр узлов:"
echo "   docker node ls"
echo ""

echo "3. Просмотр детальной информации об узле:"
echo "   docker node inspect <node-id> --pretty"
echo ""

echo "4. Установка узла в режим Drain:"
echo "   docker node update --availability drain <node-id>"
echo ""

echo "5. Восстановление узла в режим Active:"
echo "   docker node update --availability active <node-id>"
echo ""

echo "6. Развертывание стека:"
echo "   docker stack deploy -c docker-compose.swarm.yml counter"
echo ""

echo "7. Просмотр сервисов:"
echo "   docker service ls"
echo ""

echo "8. Просмотр задач сервиса:"
echo "   docker service ps counter_app"
echo ""

echo "9. Масштабирование сервиса:"
echo "   docker service scale counter_app=4"
echo ""

echo "10. Обновление сервиса (для перераспределения задач):"
echo "    docker service update --force counter_app"
echo ""

echo "11. Просмотр логов сервиса:"
echo "    docker service logs counter_app"
echo ""

echo "12. Удаление стека:"
echo "    docker stack rm counter"
echo ""

echo "13. Просмотр сетей:"
echo "    docker network ls"
echo ""

echo "14. Просмотр volumes:"
echo "    docker volume ls"
echo ""
