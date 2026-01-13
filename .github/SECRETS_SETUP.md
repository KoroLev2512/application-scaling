# Настройка секретов для GitHub Actions

Для работы workflow деплоя необходимо настроить следующие секреты в GitHub репозитории.

## Как добавить секреты в GitHub

1. Перейдите в ваш репозиторий на GitHub
2. Откройте **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**
4. Добавьте каждый секрет по отдельности

## Необходимые секреты

### 1. SSH_PRIVATE_KEY

Приватный SSH ключ для подключения к серверу.

**Как получить:**
```bash
# Если у вас уже есть SSH ключ на сервере
cat ~/.ssh/id_rsa

# Или создайте новый ключ (если нужно)
ssh-keygen -t rsa -b 4096 -C "github-actions"
cat ~/.ssh/id_rsa
```

**Важно:** Скопируйте весь ключ, включая строки `-----BEGIN OPENSSH PRIVATE KEY-----` и `-----END OPENSSH PRIVATE KEY-----`

**Добавьте публичный ключ на сервер:**
```bash
# На вашем компьютере
cat ~/.ssh/id_rsa.pub

# На сервере (выполните эту команду)
mkdir -p ~/.ssh
echo "ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 2. SSH_KNOWN_HOSTS

Fingerprint сервера для проверки подлинности.

**Как получить:**
```bash
# Выполните на вашем компьютере
ssh-keyscan -H ВАШ_IP_СЕРВЕРА

# Или
ssh-keyscan -H ВАШ_ДОМЕН_СЕРВЕРА
```

Скопируйте весь вывод (обычно 1-3 строки).

### 3. SERVER_USER

Имя пользователя для SSH подключения к серверу.

**Пример:** `root`, `ubuntu`, `deploy`, `admin`

### 4. SERVER_IP

IP адрес или доменное имя сервера.

**Пример:** `192.168.1.100`, `example.com`, `deploy.example.com`

### 5. DEPLOY_PATH

Путь на сервере, куда будет развернуто приложение.

**Пример:** `/var/www/counter-app`, `/home/deploy/app`, `/opt/counter-deploy`

## Проверка настройки

После добавления всех секретов:

1. Убедитесь, что публичный SSH ключ добавлен на сервер
2. Проверьте подключение вручную:
   ```bash
   ssh SERVER_USER@SERVER_IP
   ```
3. Убедитесь, что на сервере установлены Docker и Docker Compose:
   ```bash
   docker --version
   docker-compose --version
   ```
4. Запустите workflow вручную через **Actions** → **CI & Deploy** → **Run workflow**

## Альтернативный вариант (без SSH)

Если у вас нет доступа к серверу или не хотите использовать SSH, можно настроить деплой через:

1. **Docker Hub** - пушить образы в registry и деплоить оттуда
2. **GitHub Container Registry** - использовать встроенный registry GitHub
3. **Другие CI/CD платформы** - GitLab CI, Jenkins, etc.

## Устранение проблем

### Ошибка: "The ssh-private-key argument is empty"

**Решение:** Убедитесь, что секрет `SSH_PRIVATE_KEY` добавлен в GitHub и имеет правильное имя (без пробелов, регистр важен).

### Ошибка: "Permission denied (publickey)"

**Решение:** 
1. Проверьте, что публичный ключ добавлен в `~/.ssh/authorized_keys` на сервере
2. Проверьте права доступа: `chmod 600 ~/.ssh/authorized_keys`
3. Убедитесь, что приватный ключ скопирован полностью (включая заголовки)

### Ошибка: "Host key verification failed"

**Решение:** Убедитесь, что секрет `SSH_KNOWN_HOSTS` содержит правильный fingerprint сервера.

### Ошибка: "docker-compose: command not found"

**Решение:** Установите Docker Compose на сервере:
```bash
# Для Docker Compose V2 (рекомендуется)
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Или используйте docker compose (без дефиса) в workflow
```
