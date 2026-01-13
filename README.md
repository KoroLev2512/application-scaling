# Counter Deploy - Кластеризованное развертывание приложения счетчик

Проект для демонстрации кластеризованного развертывания приложения счетчик с использованием Docker Swarm и Kubernetes.

## Структура проекта

```
counter-deploy/
├── backend/              # Flask приложение
│   ├── app.py           # Основной код приложения
│   ├── requirements.txt # Python зависимости
│   └── .env            # Переменные окружения
├── frontend/            # Vue.js фронтенд
│   └── src/
│       └── App.vue     # Компонент счетчика
├── k8s/                 # Kubernetes конфигурации
│   └── deployment.yaml # Манифесты для k3s
├── docker-compose.yml           # Локальное развертывание
├── docker-compose.swarm.yml     # Docker Swarm конфигурация
├── Dockerfile                   # Образ приложения
├── registry-setup.sh            # Скрипт настройки Docker Registry
├── swarm-deploy.sh              # Скрипт развертывания в Swarm
├── swarm-commands.sh            # Полезные команды Swarm
├── load-test.py                 # Скрипт нагрузочного тестирования
├── load-test.sh                 # Альтернативный скрипт тестирования
├── ASSIGNMENT.md                # Отчет по выполнению заданий
└── README.md                    # Этот файл
```

## Быстрый старт

### Локальное развертывание

```bash
# Запуск приложения локально
docker-compose up -d

# Приложение доступно на http://localhost
```

### Развертывание в Docker Swarm

```bash
# 1. Инициализация Swarm (если еще не инициализирован)
docker swarm init

# 2. Развертывание стека
./swarm-deploy.sh

# Или вручную:
docker build -t counter-app:latest .
docker stack deploy -c docker-compose.swarm.yml counter

# 3. Проверка статуса
docker service ls
docker service ps counter_app

# 4. Приложение доступно на http://localhost (порт 80)
```

### Развертывание в Kubernetes (k3s)

```bash
# 1. Установка k3s (если не установлен)
curl -sfL https://get.k3s.io | sh -

# 2. Применение конфигурации
kubectl apply -f k8s/deployment.yaml

# 3. Проверка статуса
kubectl get pods
kubectl get services

# 4. Получение внешнего IP (для LoadBalancer)
kubectl get svc counter-app-service
```

## Выполнение заданий

### Задание 1: Docker Registry

#### Часть 1: Простой registry с внешним хранилищем

```bash
# Запуск registry
docker run -d -p 5000:5000 \
  --restart=always \
  --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  registry:2

# Публикация образа hello-world
docker pull hello-world
docker tag hello-world localhost:5000/hello-world
docker push localhost:5000/hello-world

# Просмотр содержимого registry
ls -la registry-data/docker/registry/v2/repositories/hello-world/
```

#### Части 2 и 3: HTTPS и аутентификация

Используйте готовый скрипт:
```bash
./registry-setup.sh
```

Или выполните вручную (см. `ASSIGNMENT.md`)

### Задание 2: Docker Orchestration

```bash
# Просмотр узлов
docker node ls

# Установка узла в режим Drain
docker node update --availability drain <node-id>

# Просмотр характеристик узла
docker node inspect <node-id> --pretty

# Восстановление узла в режим Active
docker node update --availability active <node-id>

# Обновление сервиса для перераспределения задач
docker service update --force counter_app
```

Подробные команды см. в `swarm-commands.sh`

### Задание 3: Swarm Stack

Конфигурация количества реплик находится в `docker-compose.swarm.yml`:

```yaml
services:
  app:
    deploy:
      replicas: 4  # Измените это значение
```

Health checks настроены через:
```yaml
deploy:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/api/counter"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### Задание 4: Кластеризованное развертывание

#### Развертывание с 4 инстансами Flask

```bash
# Развертывание стека
./swarm-deploy.sh

# Проверка количества реплик
docker service ls | grep counter_app
```

#### Нагрузочное тестирование

```bash
# Установка зависимостей (если нужно)
pip install requests

# Запуск тестирования
python load-test.py http://localhost/api/counter 1000 10

# Или используйте bash скрипт
./load-test.sh http://localhost/api/counter 1000 10
```

#### Репликация Redis

В текущей конфигурации:
- 1 master (redis-master) - используется для записи и чтения
- 2 replica (redis-replica) - используются для резервного копирования

**Важно**: Приложение подключается только к master для гарантии консистентности данных счетчика.

Подробности об особенностях работы с реплицированной БД см. в `ASSIGNMENT.md`

### Задание 5: Kubernetes

Конфигурация для k3s находится в `k8s/deployment.yaml`:

```bash
# Применение конфигурации
kubectl apply -f k8s/deployment.yaml

# Просмотр статуса
kubectl get pods -l app=counter-app
kubectl get statefulsets
kubectl get services
```

## Полезные команды

### Docker Swarm

```bash
# Просмотр всех сервисов
docker service ls

# Детали сервиса
docker service ps counter_app
docker service logs counter_app

# Масштабирование
docker service scale counter_app=4

# Обновление сервиса
docker service update --force counter_app

# Удаление стека
docker stack rm counter
```

### Kubernetes

```bash
# Просмотр подов
kubectl get pods

# Логи пода
kubectl logs -f deployment/counter-app

# Масштабирование
kubectl scale deployment counter-app --replicas=4

# Описание ресурса
kubectl describe deployment counter-app
kubectl describe service counter-app-service
```

## Переменные окружения

Создайте файл `backend/.env`:

```env
REDIS_HOST=redis-master
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=changeme
PORT=8000
```

## Требования

- Docker 20.10+
- Docker Compose 2.0+
- Python 3.8+ (для нагрузочного тестирования)
- curl (для health checks)
- openssl (для настройки registry с HTTPS)

## Документация

Подробный отчет по выполнению всех заданий см. в `ASSIGNMENT.md`

## Лицензия

MIT
