FROM php:8.2-fpm

WORKDIR /var/www

# Установка системных зависимостей
# Используем apt-get clean и rm -rf для уменьшения размера образа
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    postgresql-client \
    gnupg \
    procps \
    && docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Настройка пользователя (опционально, для прав доступа)
# usermod -u 1000 www-data

EXPOSE 9000

CMD ["php-fpm"]
