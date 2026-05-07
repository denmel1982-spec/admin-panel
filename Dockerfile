FROM php:8.2-fpm

WORKDIR /var/www

# Минимальный набор зависимостей для Laravel + PostgreSQL
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
    && rm -rf /var/lib/apt/lists/*

# Установка основных расширений
RUN docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath zip intl

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Настройка прав пользователя
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]
