# Инструкции по выполнению заданий

## Что было подготовлено

### Файлы конфигурации:
1. **docker-compose.swarm.yml** - конфигурация для Docker Swarm с 4 инстансами Flask и репликацией Redis
2. **k8s/deployment.yaml** - конфигурация для Kubernetes (k3s)
3. **ASSIGNMENT.md** - подробный отчет по выполнению всех заданий

### Скрипты:
1. **registry-setup.sh** - автоматическая настройка Docker Registry с HTTPS и аутентификацией
2. **swarm-deploy.sh** - развертывание приложения в Docker Swarm
3. **load-test.py** - нагрузочное тестирование на Python
4. **load-test.sh** - альтернативный скрипт тестирования на bash
5. **swarm-commands.sh** - справочник команд Docker Swarm

### Документация:
1. **README.md** - общее описание проекта
2. **QUICK_START.md** - быстрое руководство по выполнению заданий
3. **ASSIGNMENT.md** - подробный отчет с ответами на все вопросы

## Порядок выполнения заданий

### 1. Docker Registry (Части 1-3)

**Быстрый способ:**
```bash
./registry-setup.sh
```

**Что нужно зафиксировать:**
- Скриншот содержимого `registry-data/` после публикации hello-world
- Скриншот успешной аутентификации (`docker login localhost:5000 -u testuser -p testpass`)
- Скриншот неудачной аутентификации (`docker login localhost:5000 -u testuser -p wrongpass`)
- Результат проверки HTTPS (`curl -k https://localhost:5000/v2/`)

### 2. Docker Orchestration

**Выполнение:**
```bash
# Инициализация Swarm
docker swarm init

# Просмотр узлов
docker node ls

# Получение ID узла
NODE_ID=$(docker node ls -q | head -1)

# Просмотр в режиме Active
docker node inspect $NODE_ID --pretty

# Перевод в режим Drain
docker node update --availability drain $NODE_ID

# Просмотр в режиме Drain
docker node inspect $NODE_ID --pretty

# Восстановление в Active
docker node update --availability active $NODE_ID
```

**Что нужно зафиксировать:**
- Скриншот `docker node ls` с узлами в режиме Active
- Скриншот `docker node inspect` с характеристиками в режиме Drain
- Скриншот после восстановления в Active

**Ответы на вопросы:**
1. Нет, сервисы не восстанавливаются автоматически
2. Нужно выполнить `docker service update --force <service-name>`

### 3. Swarm Stack

**Конфигурация количества реплик:**
- В `docker-compose.swarm.yml` параметр `deploy.replicas: 4`
- Можно изменить через `docker service scale counter_app=4`

**Health checks:**
- Настроены через `deploy.healthcheck` в `docker-compose.swarm.yml`
- Проверка: `docker service ps counter_app` (смотрим статус HEALTHY/UNHEALTHY)

### 4. Кластеризованное развертывание

**Развертывание:**
```bash
./swarm-deploy.sh
```

**Нагрузочное тестирование:**
```bash
# Тест с 4 инстансами
python load-test.py http://localhost/api/counter 1000 10
```

**Репликация Redis:**
- 1 master (используется приложением)
- 2 replica (для резервного копирования)

**Особенности реплицированного Redis:**
1. Приложение подключается только к master (консистентность)
2. Replica не используются для чтения
3. При падении master приложение перестанет работать

**Пути разрешения:**
- Использовать Redis Sentinel для автоматического failover
- Использовать Redis Cluster
- Изменить код для чтения с replica (риск потери консистентности)

### 5. Kubernetes

**Развертывание:**
```bash
kubectl apply -f k8s/deployment.yaml
kubectl get pods
kubectl get services
```

**Отличия от Swarm:**
- YAML манифесты вместо docker-compose.yml
- `livenessProbe` и `readinessProbe` вместо `healthcheck`
- Явное указание ресурсов (CPU/память)
- Использование Kubernetes Secrets
- StatefulSet для Redis

## Важные замечания

1. **Переменные окружения**: Убедитесь, что файл `backend/.env` существует с необходимыми переменными
2. **Порты**: Приложение доступно на порту 80 после развертывания в Swarm
3. **Health checks**: Убедитесь, что `curl` установлен в образе для health checks
4. **Redis пароль**: По умолчанию используется `changeme`, измените в production

## Дополнительные материалы

- Docker Registry: https://docs.docker.com/registry/
- Docker Swarm: https://docs.docker.com/engine/swarm/
- Kubernetes: https://kubernetes.io/docs/
- Play with Docker: https://training.play-with-docker.com/
