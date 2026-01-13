#!/bin/bash

# Скрипт для настройки Docker Registry (Части 1-3 задания)

set -e

echo "=== Настройка Docker Registry ==="

# Создание директорий
mkdir -p registry-data auth certs

# Часть 1: Простой registry с внешним хранилищем
echo ""
echo "=== Часть 1: Запуск registry с внешним хранилищем ==="

# Остановка существующего registry если запущен
docker stop registry 2>/dev/null || true
docker rm registry 2>/dev/null || true

# Запуск registry
docker run -d -p 5000:5000 \
  --restart=always \
  --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  registry:2

echo "Registry запущен на порту 5000"
echo "Ожидание запуска..."
sleep 3

# Публикация hello-world
echo ""
echo "Публикация образа hello-world..."
docker pull hello-world
docker tag hello-world localhost:5000/hello-world
docker push localhost:5000/hello-world

echo ""
echo "=== Проверка содержимого registry ==="
echo "Содержимое директории registry-data:"
ls -la registry-data/docker/registry/v2/repositories/hello-world/ 2>/dev/null || echo "Директория не найдена, проверьте путь"

echo ""
echo "=== Часть 2 и 3: Настройка HTTPS и аутентификации ==="

# Генерация сертификатов
echo ""
echo "Генерация SSL сертификатов..."
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key \
  -x509 -days 365 \
  -out certs/domain.crt \
  -subj "/C=RU/ST=State/L=City/O=Organization/CN=localhost" \
  2>/dev/null || {
    echo "Ошибка: openssl не установлен. Установите openssl."
    exit 1
  }

# Создание файла паролей
echo ""
echo "Создание файла паролей для аутентификации..."
docker run --rm --entrypoint htpasswd httpd:2 \
  -Bbn testuser testpass > auth/htpasswd 2>/dev/null || {
    echo "Ошибка: не удалось создать файл паролей. Убедитесь, что Docker запущен."
    exit 1
  }

# Остановка простого registry
docker stop registry
docker rm registry

# Запуск защищенного registry
echo ""
echo "Запуск защищенного registry с HTTPS и аутентификацией..."
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

echo "Защищенный registry запущен"
echo "Ожидание запуска..."
sleep 3

# Настройка Docker для работы с самоподписанным сертификатом
echo ""
echo "=== Настройка Docker для работы с самоподписанным сертификатом ==="
echo "Для macOS/Linux добавьте сертификат в систему доверенных:"
echo "  sudo cp certs/domain.crt /etc/docker/certs.d/localhost:5000/ca.crt"
echo "  sudo systemctl restart docker  # для Linux"
echo ""
echo "Или добавьте в /etc/docker/daemon.json:"
echo '  { "insecure-registries": ["localhost:5000"] }'

# Тестирование аутентификации
echo ""
echo "=== Тестирование аутентификации ==="
echo ""
echo "Попытка успешной аутентификации (testuser/testpass):"
docker login localhost:5000 -u testuser -p testpass || echo "Аутентификация не удалась (возможно, нужна настройка insecure-registries)"

echo ""
echo "Попытка неудачной аутентификации (testuser/wrongpass):"
docker login localhost:5000 -u testuser -p wrongpass 2>&1 | head -3 || echo "Ожидаемая ошибка аутентификации"

echo ""
echo "=== Проверка HTTPS соединения ==="
curl -k https://localhost:5000/v2/ 2>/dev/null && echo "HTTPS работает" || echo "HTTPS не работает (проверьте настройки)"

echo ""
echo "=== Настройка завершена ==="
echo "Registry доступен по адресу: https://localhost:5000"
echo "Учетные данные: testuser / testpass"
