#!/bin/bash

# Скрипт для создания SSH ключа для GitHub Actions

set -e

echo "=== Создание SSH ключа для GitHub Actions ==="
echo ""

KEY_NAME="github_actions"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Проверка существования ключа
if [ -f "$KEY_PATH" ]; then
    echo "⚠️  Ключ $KEY_PATH уже существует!"
    read -p "Перезаписать? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Отменено."
        exit 1
    fi
    rm -f "$KEY_PATH" "$KEY_PATH.pub"
fi

# Создание ключа
echo "Создание SSH ключа..."
ssh-keygen -t rsa -b 4096 -C "github-actions" -f "$KEY_PATH" -N ""

echo ""
echo "✅ SSH ключ создан!"
echo ""
echo "=== ПРИВАТНЫЙ КЛЮЧ (для секрета SSH_PRIVATE_KEY в GitHub) ==="
echo "Скопируйте весь текст ниже (включая BEGIN и END):"
echo ""
cat "$KEY_PATH"
echo ""
echo ""
echo "=== ПУБЛИЧНЫЙ КЛЮЧ (для добавления на сервер) ==="
echo "Скопируйте этот ключ и добавьте на сервер в ~/.ssh/authorized_keys:"
echo ""
cat "$KEY_PATH.pub"
echo ""
echo ""
echo "=== ИНСТРУКЦИЯ ==="
echo "1. Скопируйте ПРИВАТНЫЙ ключ выше"
echo "2. В GitHub: Settings → Secrets → New repository secret"
echo "   Имя: SSH_PRIVATE_KEY"
echo "   Значение: вставьте приватный ключ"
echo ""
echo "3. Скопируйте ПУБЛИЧНЫЙ ключ выше"
echo "4. На сервере выполните:"
echo "   mkdir -p ~/.ssh"
echo "   echo 'ПУБЛИЧНЫЙ_КЛЮЧ' >> ~/.ssh/authorized_keys"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo "   chmod 700 ~/.ssh"
echo ""
echo "5. Добавьте остальные секреты в GitHub:"
echo "   - SERVER_USER (например: root, ubuntu)"
echo "   - SERVER_IP (IP или домен сервера)"
echo "   - DEPLOY_PATH (путь на сервере, например: /var/www/app)"
echo ""
