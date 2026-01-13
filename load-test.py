#!/usr/bin/env python3
"""
Скрипт для нагрузочного тестирования счетчика
Использование: python load-test.py <URL> <количество_запросов> <параллельность>
"""

import sys
import time
import requests
import concurrent.futures
from statistics import mean, median, stdev
from typing import List, Tuple

def make_request(url: str, method: str = 'GET') -> Tuple[float, bool]:
    """Выполняет HTTP запрос и возвращает время выполнения и статус успеха"""
    start = time.time()
    try:
        if method == 'GET':
            response = requests.get(url, timeout=5)
        elif method == 'POST':
            response = requests.post(url, timeout=5)
        elapsed = time.time() - start
        success = response.status_code == 200
        return elapsed, success
    except Exception as e:
        elapsed = time.time() - start
        return elapsed, False

def run_load_test(url: str, num_requests: int, concurrency: int, method: str = 'GET'):
    """Запускает нагрузочный тест"""
    print(f"\n=== Тест: {method} запросы ===")
    print(f"URL: {url}")
    print(f"Запросов: {num_requests}")
    print(f"Параллельность: {concurrency}")
    
    times: List[float] = []
    successes = 0
    failures = 0
    
    start_total = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(make_request, url, method) for _ in range(num_requests)]
        
        for future in concurrent.futures.as_completed(futures):
            elapsed, success = future.result()
            times.append(elapsed)
            if success:
                successes += 1
            else:
                failures += 1
    
    total_time = time.time() - start_total
    
    if times:
        print(f"\nРезультаты:")
        print(f"  Всего запросов: {num_requests}")
        print(f"  Успешных: {successes}")
        print(f"  Неудачных: {failures}")
        print(f"  Общее время: {total_time:.2f} сек")
        print(f"  Запросов в секунду: {num_requests / total_time:.2f}")
        print(f"  Среднее время ответа: {mean(times) * 1000:.2f} мс")
        print(f"  Медианное время ответа: {median(times) * 1000:.2f} мс")
        print(f"  Минимальное время: {min(times) * 1000:.2f} мс")
        print(f"  Максимальное время: {max(times) * 1000:.2f} мс")
        if len(times) > 1:
            print(f"  Стандартное отклонение: {stdev(times) * 1000:.2f} мс")
    else:
        print("Нет данных для анализа")

def main():
    url = sys.argv[1] if len(sys.argv) > 1 else 'http://localhost/api/counter'
    num_requests = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    concurrency = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    
    # Убираем trailing slash если есть
    url = url.rstrip('/')
    
    print("=" * 60)
    print("НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ СЧЕТЧИКА")
    print("=" * 60)
    
    # Тест 1: GET запросы
    run_load_test(f"{url}", num_requests, concurrency, 'GET')
    
    # Сброс перед тестом инкремента
    try:
        requests.post(f"{url}/reset", timeout=5)
    except:
        pass
    
    # Тест 2: POST запросы (инкремент)
    run_load_test(f"{url}/increment", num_requests, concurrency, 'POST')
    
    # Тест 3: Смешанная нагрузка
    print(f"\n=== Тест: Смешанная нагрузка (GET и POST) ===")
    print(f"Запросов: {num_requests * 2}")
    print(f"Параллельность: {concurrency}")
    
    try:
        requests.post(f"{url}/reset", timeout=5)
    except:
        pass
    
    times: List[float] = []
    successes = 0
    failures = 0
    
    start_total = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = []
        for i in range(num_requests * 2):
            if i % 2 == 0:
                futures.append(executor.submit(make_request, f"{url}/increment", 'POST'))
            else:
                futures.append(executor.submit(make_request, f"{url}", 'GET'))
        
        for future in concurrent.futures.as_completed(futures):
            elapsed, success = future.result()
            times.append(elapsed)
            if success:
                successes += 1
            else:
                failures += 1
    
    total_time = time.time() - start_total
    
    if times:
        print(f"\nРезультаты смешанной нагрузки:")
        print(f"  Всего запросов: {num_requests * 2}")
        print(f"  Успешных: {successes}")
        print(f"  Неудачных: {failures}")
        print(f"  Общее время: {total_time:.2f} сек")
        print(f"  Запросов в секунду: {(num_requests * 2) / total_time:.2f}")
        print(f"  Среднее время ответа: {mean(times) * 1000:.2f} мс")
        print(f"  Медианное время ответа: {median(times) * 1000:.2f} мс")
    
    print("\n" + "=" * 60)
    print("ТЕСТИРОВАНИЕ ЗАВЕРШЕНО")
    print("=" * 60)

if __name__ == '__main__':
    main()
