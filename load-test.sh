#!/bin/bash

# Скрипт для нагрузочного тестирования счетчика
# Использование: ./load-test.sh <URL> <количество_запросов> <параллельность>

URL=${1:-http://localhost/api/counter}
REQUESTS=${2:-1000}
CONCURRENCY=${3:-10}

echo "Нагрузочное тестирование счетчика"
echo "URL: $URL"
echo "Запросов: $REQUESTS"
echo "Параллельность: $CONCURRENCY"
echo ""

# Проверка наличия Apache Bench (ab)
if ! command -v ab &> /dev/null; then
    echo "Apache Bench не установлен. Устанавливаю..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install httpd
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y apache2-utils
    fi
fi

# Проверка наличия curl
if ! command -v curl &> /dev/null; then
    echo "curl не установлен. Пожалуйста, установите curl."
    exit 1
fi

echo "=== Тест 1: Получение значения счетчика ==="
ab -n $REQUESTS -c $CONCURRENCY "$URL" | grep -E "(Requests per second|Time per request|Transfer rate|Failed requests)"

echo ""
echo "=== Тест 2: Инкремент счетчика ==="
ab -n $REQUESTS -c $CONCURRENCY -p /dev/null -T application/json -m POST "$URL/increment" | grep -E "(Requests per second|Time per request|Transfer rate|Failed requests)"

echo ""
echo "=== Тест 3: Смешанная нагрузка (GET и POST) ==="
echo "Выполняю $REQUESTS запросов с параллельностью $CONCURRENCY..."

# Сброс счетчика перед тестом
curl -X POST "$URL/reset" > /dev/null 2>&1

# Запуск смешанной нагрузки
for i in $(seq 1 $REQUESTS); do
    if [ $((i % 2)) -eq 0 ]; then
        curl -s -X POST "$URL/increment" > /dev/null &
    else
        curl -s "$URL" > /dev/null &
    fi
    
    # Ограничение параллельности
    if [ $((i % CONCURRENCY)) -eq 0 ]; then
        wait
    fi
done
wait

echo "Тест завершен!"
