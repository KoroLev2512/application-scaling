# Быстрая настройка секретов GitHub Actions

## Шаг 1: Создание SSH ключа

Выполните на вашем компьютере:

```bash
chmod +x setup-ssh-key.sh
./setup-ssh-key.sh
```

Или вручную:

```bash
ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions
```

## Шаг 2: Добавление секретов в GitHub

На странице **Settings → Secrets and variables → Actions** нажмите **"New repository secret"** и добавьте:

### 1. SSH_PRIVATE_KEY
- **Имя:** `SSH_PRIVATE_KEY`
- **Значение:** Скопируйте весь приватный ключ (вывод команды `cat ~/.ssh/github_actions`)
  - Должен начинаться с `-----BEGIN OPENSSH PRIVATE KEY-----`
  - И заканчиваться на `-----END OPENSSH PRIVATE KEY-----`

### 2. SERVER_USER
- **Имя:** `SERVER_USER`
- **Значение:** Имя пользователя для SSH (например: `root`, `ubuntu`, `deploy`)

### 3. SERVER_IP
- **Имя:** `SERVER_IP`
- **Значение:** IP адрес или домен вашего сервера (например: `192.168.1.100` или `example.com`)

### 4. DEPLOY_PATH
- **Имя:** `DEPLOY_PATH`
- **Значение:** Путь на сервере для развертывания (например: `/var/www/app` или `/home/deploy/app`)

### 5. SSH_KNOWN_HOSTS (опционально)
- **Имя:** `SSH_KNOWN_HOSTS`
- **Значение:** Выполните `ssh-keyscan -H ВАШ_IP_СЕРВЕРА` и скопируйте вывод

## Шаг 3: Добавление публичного ключа на сервер

На вашем сервере выполните:

```bash
# Создайте директорию .ssh если её нет
mkdir -p ~/.ssh

# Добавьте публичный ключ
echo "ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ" >> ~/.ssh/authorized_keys

# Установите правильные права
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

Чтобы получить публичный ключ:
```bash
cat ~/.ssh/github_actions.pub
```

## Шаг 4: Проверка подключения

Проверьте SSH подключение:

```bash
ssh -i ~/.ssh/github_actions SERVER_USER@SERVER_IP
```

Если подключение успешно, можно переходить к следующему шагу.

## Шаг 5: Проверка Docker на сервере

Убедитесь, что на сервере установлены Docker и Docker Compose:

```bash
ssh SERVER_USER@SERVER_IP "docker --version && docker-compose --version"
```

Если не установлены, установите:
```bash
# Для Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin
```

## Шаг 6: Запуск workflow

После настройки всех секретов:

1. Перейдите в **Actions** в репозитории
2. Выберите workflow **CI & Deploy**
3. Нажмите **Run workflow**
4. Выберите ветку **main**
5. Нажмите **Run workflow**

Или просто сделайте push в ветку `main` - workflow запустится автоматически.

## Проверка результата

После успешного выполнения workflow:

1. Проверьте статус в **Actions**
2. На сервере проверьте запущенные контейнеры:
   ```bash
   ssh SERVER_USER@SERVER_IP "cd DEPLOY_PATH && docker-compose ps"
   ```

## Устранение проблем

### Ошибка: "The ssh-private-key argument is empty"
- Убедитесь, что секрет `SSH_PRIVATE_KEY` добавлен и скопирован полностью (включая BEGIN и END)

### Ошибка: "Permission denied (publickey)"
- Проверьте, что публичный ключ добавлен в `~/.ssh/authorized_keys` на сервере
- Проверьте права доступа: `chmod 600 ~/.ssh/authorized_keys`

### Ошибка: "Host key verification failed"
- Добавьте секрет `SSH_KNOWN_HOSTS` или убедитесь, что он содержит правильный fingerprint

### Ошибка: "docker-compose: command not found"
- Установите Docker Compose на сервере или используйте `docker compose` (без дефиса)
