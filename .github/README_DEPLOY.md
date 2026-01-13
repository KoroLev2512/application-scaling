# Инструкция по настройке деплоя

## Проблема: "The ssh-private-key argument is empty"

Эта ошибка возникает, когда секрет `SSH_PRIVATE_KEY` не настроен в GitHub репозитории.

## Быстрое решение

### Шаг 1: Настройка секретов в GitHub

1. Откройте репозиторий: https://github.com/KoroLev2512/-application-scaling
2. Перейдите в **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**
4. Добавьте следующие секреты:

#### SSH_PRIVATE_KEY
Ваш приватный SSH ключ. Если у вас его нет:

```bash
# Создайте новый SSH ключ
ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions

# Скопируйте приватный ключ (для секрета SSH_PRIVATE_KEY)
cat ~/.ssh/github_actions

# Скопируйте публичный ключ (добавьте на сервер)
cat ~/.ssh/github_actions.pub
```

**На сервере выполните:**
```bash
# Добавьте публичный ключ в authorized_keys
mkdir -p ~/.ssh
echo "ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

#### SERVER_USER
Имя пользователя для SSH (например: `root`, `ubuntu`, `deploy`)

#### SERVER_IP
IP адрес или домен вашего сервера (например: `192.168.1.100` или `example.com`)

#### DEPLOY_PATH
Путь на сервере для развертывания (например: `/var/www/app` или `/home/deploy/app`)

#### SSH_KNOWN_HOSTS (опционально)
Fingerprint сервера. Если не указан, будет использован `ssh-keyscan`:

```bash
ssh-keyscan -H ВАШ_IP_СЕРВЕРА
```

### Шаг 2: Проверка подключения

Проверьте SSH подключение вручную:

```bash
ssh -i ~/.ssh/github_actions SERVER_USER@SERVER_IP
```

### Шаг 3: Запуск workflow

После настройки секретов:

1. Перейдите в **Actions** в репозитории
2. Выберите workflow **CI & Deploy**
3. Нажмите **Run workflow**
4. Выберите ветку **main**
5. Нажмите **Run workflow**

## Альтернатива: Деплой без SSH

Если у вас нет доступа к серверу или не хотите использовать SSH, можно использовать другие методы:

### Вариант 1: Docker Hub

1. Соберите образ локально или в CI
2. Запушьте в Docker Hub
3. На сервере используйте `docker-compose pull`

### Вариант 2: GitHub Container Registry

Используйте встроенный registry GitHub для хранения образов.

## Подробная инструкция

См. файл `.github/SECRETS_SETUP.md` для подробной инструкции по настройке всех секретов.
