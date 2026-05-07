FROM php:8.2-fpm

WORKDIR /var/www

# Установка системных зависимостей
# libpq-dev нужен для pdo_pgsql, libzip-dev для zip, libicu-dev для intl
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libicu-dev \
    libpq-dev \
    zip \
    unzip \
    postgresql-client \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Настройка и установка расширений PHP
# Разбиваем на этапы, чтобы видеть, где именно ошибка, если она повторится
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd zip intl

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Создание пользователя и права (опционально, но полезно для Linux хостов)
# Для Windows/Mac это не критично, но лучше оставить
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]
