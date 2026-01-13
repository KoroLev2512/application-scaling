# Быстрое руководство по выполнению заданий

## Задание 1: Docker Registry

### Часть 1: Registry с внешним хранилищем

```bash
# Запуск registry
docker run -d -p 5000:5000 \
  --restart=always \
  --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  registry:2

# Публикация hello-world
docker pull hello-world
docker tag hello-world localhost:5000/hello-world
docker push localhost:5000/hello-world

# Просмотр содержимого (для скриншота)
ls -la registry-data/docker/registry/v2/repositories/hello-world/
tree registry-data/  # если установлен tree
```

**Скриншот**: Сделайте скриншот содержимого `registry-data/` после публикации образа.

### Части 2 и 3: HTTPS и аутентификация

```bash
# Используйте готовый скрипт
./registry-setup.sh
```

Или выполните вручную:

```bash
# 1. Создание сертификатов
mkdir -p certs auth
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key -x509 -days 365 \
  -out certs/domain.crt \
  -subj "/C=RU/ST=State/L=City/O=Organization/CN=localhost"

# 2. Создание файла паролей
docker run --rm --entrypoint htpasswd httpd:2 \
  -Bbn testuser testpass > auth/htpasswd

# 3. Запуск защищенного registry
docker stop registry 2>/dev/null || true
docker rm registry 2>/dev/null || true

docker run -d -p 5000:5000 \
  --restart=always \
  --name registry-secure \
  -v $(pwd)/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -v $(pwd)/certs:/certs \
  -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
  -e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
  -v $(pwd)/registry-data:/var/lib/registry \
  registry:2

# 4. Настройка insecure-registries (для самоподписанного сертификата)
# macOS: Docker Desktop -> Settings -> Docker Engine -> добавить:
#   "insecure-registries": ["localhost:5000"]
# Linux: /etc/docker/daemon.json -> добавить то же самое, затем:
#   sudo systemctl restart docker

# 5. Тестирование аутентификации
# Успешная:
docker login localhost:5000 -u testuser -p testpass

# Неудачная:
docker login localhost:5000 -u testuser -p wrongpass

# Проверка HTTPS
curl -k https://localhost:5000/v2/
```

**Скриншоты**: 
- Успешная аутентификация
- Неудачная аутентификация
- Результат `curl -k https://localhost:5000/v2/`

## Задание 2: Docker Orchestration

```bash
# 1. Инициализация Swarm (если еще не инициализирован)
docker swarm init

# 2. Просмотр узлов
docker node ls

# 3. Получение ID узла
NODE_ID=$(docker node ls -q | head -1)

# 4. Просмотр характеристик в режиме Active
docker node inspect $NODE_ID --pretty

# 5. Установка узла в режим Drain
docker node update --availability drain $NODE_ID

# 6. Просмотр характеристик в режиме Drain
docker node inspect $NODE_ID --pretty

# 7. Восстановление узла в режим Active
docker node update --availability active $NODE_ID

# 8. Если есть запущенные сервисы, обновление для перераспределения
docker service update --force <service-name>
```

**Скриншоты**:
- `docker node ls` - узлы в режиме Active
- `docker node inspect <node-id> --pretty` - характеристики в режиме Drain
- `docker node inspect <node-id> --pretty` - характеристики после восстановления в Active

**Ответы на вопросы**:
1. Нет, сервисы не восстанавливаются автоматически
2. Нужно выполнить `docker service update --force <service-name>` или `docker service scale <service-name>=<replicas>`

## Задание 3: Swarm Stack

### Конфигурация количества нодов

В `docker-compose.swarm.yml`:
```yaml
services:
  app:
    deploy:
      replicas: 4  # Количество инстансов
```

Изменение:
```bash
# Способ 1: Изменить файл и переразвернуть
docker stack deploy -c docker-compose.swarm.yml counter

# Способ 2: Масштабирование через команду
docker service scale counter_app=4
```

### Health checks

В `docker-compose.swarm.yml`:
```yaml
deploy:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/api/counter"]
    interval: 30s      # Интервал проверки
    timeout: 10s       # Таймаут
    retries: 3         # Количество попыток
    start_period: 40s  # Период запуска
```

Проверка здоровья:
```bash
docker service ps counter_app
# Смотрим статус HEALTHY/UNHEALTHY
```

## Задание 4: Кластеризованное развертывание

### Развертывание с 4 инстансами Flask

```bash
# 1. Инициализация Swarm
docker swarm init

# 2. Развертывание
./swarm-deploy.sh

# Или вручную:
docker build -t counter-app:latest .
docker stack deploy -c docker-compose.swarm.yml counter

# 3. Проверка
docker service ls
docker service ps counter_app
# Должно быть 4 реплики
```

### Нагрузочное тестирование

```bash
# До кластеризации (1 инстанс)
# Запустите с одним инстансом, затем:
python load-test.py http://localhost/api/counter 1000 10

# После кластеризации (4 инстанса)
# Запустите с 4 инстансами, затем:
python load-test.py http://localhost/api/counter 1000 10

# Сравните результаты:
# - Requests per second (должно увеличиться)
# - Time per request (должно уменьшиться)
```

### Репликация Redis

Текущая конфигурация:
- 1 master (redis-master) - используется приложением
- 2 replica (redis-replica) - для резервного копирования

**Особенности**:
1. Приложение подключается только к master (консистентность данных)
2. Replica не используются для чтения (нет распределения нагрузки на чтение)
3. При падении master приложение перестанет работать

**Пути разрешения**:
1. Использовать Redis Sentinel для автоматического failover
2. Использовать Redis Cluster для распределения данных
3. Изменить код для чтения с replica (риск потери консистентности)

Подробнее см. `ASSIGNMENT.md`

## Задание 5: Kubernetes

### Развертывание в k3s

```bash
# 1. Установка k3s (если не установлен)
curl -sfL https://get.k3s.io | sh -

# 2. Проверка установки
kubectl get nodes

# 3. Применение конфигурации
kubectl apply -f k8s/deployment.yaml

# 4. Проверка статуса
kubectl get pods
kubectl get services
kubectl get statefulsets

# 5. Просмотр логов
kubectl logs -f deployment/counter-app

# 6. Масштабирование
kubectl scale deployment counter-app --replicas=4
```

### Отличия от Swarm

1. **Конфигурация**: YAML манифесты вместо docker-compose.yml
2. **Health checks**: `livenessProbe` и `readinessProbe` вместо `healthcheck`
3. **Ресурсы**: Явное указание limits и requests для CPU/памяти
4. **Секреты**: Использование Kubernetes Secrets для паролей
5. **StatefulSet**: Для Redis используется StatefulSet вместо обычного сервиса

Конфигурация находится в `k8s/deployment.yaml`
