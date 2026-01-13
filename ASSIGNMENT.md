# Отчет по выполнению задания

## Задание 1: Docker Registry

### Часть 1: Docker registry for Linux Part 1

**Задание**: Выполнить задание "Docker registry for Linux Part 1" и продемонстрировать содержимое registry после публикации образа hello-world.

**Выполнение**:

1. Запуск registry контейнера с внешним хранилищем:
```bash
docker run -d -p 5000:5000 \
  --restart=always \
  --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  registry:2
```

2. Публикация образа hello-world в registry:
```bash
# Тегирование образа
docker tag hello-world localhost:5000/hello-world

# Публикация в registry
docker push localhost:5000/hello-world
```

3. Проверка содержимого registry:
```bash
# Просмотр содержимого директории registry
ls -la registry-data/docker/registry/v2/repositories/hello-world/
```

**Скриншот**: Необходимо сделать скриншот содержимого директории `registry-data` после публикации образа.

### Часть 2: Docker registry for Linux Parts 2 & 3

**Задание**: Выполнить задание "Authenticating with the Registry" и продемонстрировать подключение по HTTPS с аутентификацией.

**Выполнение**:

1. Создание сертификатов для HTTPS:
```bash
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key -x509 -days 365 \
  -out certs/domain.crt \
  -subj "/C=RU/ST=State/L=City/O=Organization/CN=localhost"
```

2. Создание файла паролей для аутентификации:
```bash
mkdir -p auth
docker run --rm --entrypoint htpasswd httpd:2 \
  -Bbn testuser testpass > auth/htpasswd
```

3. Запуск registry с HTTPS и аутентификацией:
```bash
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
```

4. Аутентификация:
```bash
# Успешная аутентификация
docker login localhost:5000 -u testuser -p testpass

# Неудачная аутентификация (неверный пароль)
docker login localhost:5000 -u testuser -p wrongpass
```

**Демонстрация**: 
- Скриншот успешной аутентификации
- Скриншот неудачной аутентификации
- Проверка HTTPS соединения: `curl -k https://localhost:5000/v2/`

## Задание 2: Docker Orchestration Hands-on Lab

**Задание**: Выполнить все шаги и продемонстрировать характеристику узлов в режиме Active и Drain.

**Выполнение**:

1. Инициализация Swarm:
```bash
docker swarm init
```

2. Добавление worker узлов (если есть):
```bash
docker swarm join-token worker
```

3. Просмотр узлов:
```bash
docker node ls
```

4. Установка узла в режим Drain:
```bash
docker node update --availability drain <node-id>
```

5. Просмотр характеристик узла в режиме Drain:
```bash
docker node inspect <node-id> --pretty
```

6. Восстановление узла в режим Active:
```bash
docker node update --availability active <node-id>
```

**Ответы на вопросы**:

1. **Восстановилась ли работа запущенного сервиса на этом узле?**
   - Нет, сервисы не восстанавливаются автоматически при переводе узла в режим Active. Docker Swarm не перемещает задачи обратно на узел автоматически.

2. **Что необходимо сделать, чтобы запустить работу службы на этом узле снова?**
   - Необходимо выполнить обновление сервиса (scale или update), чтобы Swarm перераспределил задачи:
   ```bash
   docker service update --force <service-name>
   ```
   или
   ```bash
   docker service scale <service-name>=<replicas>
   ```

**Скриншоты**:
- Узлы в режиме Active
- Узлы в режиме Drain
- Характеристики узла в обоих режимах

## Задание 3: Swarm stack introduction

**Задание**: Изучить материал и выполнить действия. Зафиксировать конфигурацию количества нодов и проверку жизнеспособности сервисов.

### Конфигурация количества нодов в стэке

В файле `docker-compose.swarm.yml` количество реплик настраивается через параметр `deploy.replicas`:

```yaml
services:
  app:
    deploy:
      replicas: 4  # Количество инстансов Flask
```

Для изменения количества реплик можно:
1. Изменить значение `replicas` в docker-compose.swarm.yml и выполнить `docker stack deploy`
2. Использовать команду `docker service scale counter_app=4`

### Проверка жизнеспособности сервисов

Проверка жизнеспособности настраивается через `deploy.healthcheck`:

```yaml
deploy:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/api/counter"]
    interval: 30s      # Интервал проверки
    timeout: 10s       # Таймаут проверки
    retries: 3         # Количество повторных попыток
    start_period: 40s  # Период запуска (время на инициализацию)
```

Docker Swarm автоматически:
- Проверяет здоровье контейнеров с указанным интервалом
- Перезапускает нездоровые контейнеры
- Распределяет нагрузку только на здоровые контейнеры

## Задание 4: Кластеризованное развертывание приложения

### Развертывание с 4 инстансами Flask

**Конфигурация**: Используется файл `docker-compose.swarm.yml` с 4 репликами сервиса `app`.

**Развертывание**:
```bash
# Сборка образа
docker build -t counter-app:latest .

# Развертывание стека
docker stack deploy -c docker-compose.swarm.yml counter

# Проверка статуса
docker service ls
docker service ps counter_app
```

### Нагрузочное тестирование

**До кластеризации** (1 инстанс):
```bash
python load-test.py http://localhost/api/counter 1000 10
```

**После кластеризации** (4 инстанса):
```bash
python load-test.py http://localhost/api/counter 1000 10
```

**Результаты**: 
- Потенциал обработки запросов должен увеличиться пропорционально количеству инстансов
- Время ответа должно уменьшиться за счет распределения нагрузки
- Пропускная способность (requests per second) должна увеличиться

**Вывод**: Кластеризация увеличивает потенциал обработки запросов за счет горизонтального масштабирования.

### Репликация Redis

**Конфигурация**: 
- 1 master (redis-master)
- 2 replica (redis-replica)

**Особенности работы реплицированного сервиса с БД**:

1. **Проблема консистентности данных**:
   - При записи в master и чтении с replica возможна задержка репликации (replication lag)
   - Для счетчика это критично, так как может привести к потере инкрементов

2. **Текущая реализация**:
   - Приложение подключается только к master (`REDIS_HOST=redis-master`)
   - Это гарантирует консистентность данных, но не использует преимущества репликации для чтения

3. **Пути разрешения**:

   **Вариант 1: Использование Redis Sentinel** (рекомендуется):
   - Автоматическое переключение на новый master при падении текущего
   - Высокая доступность
   - Требует изменения кода для поддержки Sentinel

   **Вариант 2: Использование Redis Cluster**:
   - Распределение данных по шардам
   - Автоматическая репликация
   - Требует изменения кода для поддержки Cluster

   **Вариант 3: Чтение с replica, запись в master**:
   - Улучшает производительность чтения
   - Требует изменения кода для разделения операций чтения/записи
   - Возможны проблемы с консистентностью

   **Вариант 4: Только master (текущая реализация)**:
   - Гарантирует консистентность
   - Простая реализация
   - Replica используются только для резервного копирования

**Рекомендация**: Для счетчика лучше использовать только master или Redis Sentinel для высокой доступности без потери данных.

## Задание 5: Kubernetes (k3s)

### Исследование различий между Swarm и Kubernetes

**Основные различия**:

1. **Архитектура**:
   - Swarm: проще, встроен в Docker
   - Kubernetes: более сложный, но более функциональный

2. **Масштабирование**:
   - Swarm: простое горизонтальное масштабирование
   - Kubernetes: более гибкое масштабирование (HPA, VPA)

3. **Сервисы**:
   - Swarm: overlay network, service discovery
   - Kubernetes: более продвинутый service mesh, ingress

4. **Конфигурация**:
   - Swarm: docker-compose.yml
   - Kubernetes: YAML манифесты (Deployment, Service, StatefulSet)

### Конфигурация для k3s

Файлы конфигурации находятся в директории `k8s/`:

- `deployment.yaml` - содержит:
  - Deployment для приложения (4 реплики)
  - Service для приложения (LoadBalancer)
  - StatefulSet для Redis master (1 реплика)
  - StatefulSet для Redis replica (2 реплики)
  - Service для Redis
  - Secret для пароля Redis

**Развертывание в k3s**:

```bash
# Применение конфигурации
kubectl apply -f k8s/deployment.yaml

# Проверка статуса
kubectl get pods
kubectl get services
kubectl get statefulsets

# Просмотр логов
kubectl logs -f deployment/counter-app
```

**Особенности конфигурации k3s**:

1. **Health checks**: Используются `livenessProbe` и `readinessProbe`
2. **Ресурсы**: Ограничения CPU и памяти для каждого контейнера
3. **Секреты**: Пароль Redis хранится в Secret
4. **StatefulSet**: Используется для Redis для гарантии персистентности

**Пример конфигурационного файла**: См. `k8s/deployment.yaml`

## Заключение

Выполнено кластеризованное развертывание приложения счетчика с использованием:
1. Docker Swarm с 4 инстансами Flask и репликацией Redis
2. Kubernetes (k3s) конфигурация для альтернативного развертывания
3. Нагрузочное тестирование для проверки производительности
4. Документация особенностей работы с реплицированной БД
