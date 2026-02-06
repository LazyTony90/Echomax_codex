FROM python:3.11-slim

# Рабочая директория
WORKDIR /app

# Полезные флаги Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Устанавливаем gcc (нужен для сборки некоторых колёс) и ffmpeg для перекодирования аудио
# --no-install-recommends держит образ компактнее
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Установка python-зависимостей
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копируем приложение
COPY . .

# Запуск
CMD ["python","-m","app.main"]
