FROM php:8.2-fpm

WORKDIR /var/www

# Установка системных зависимостей
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
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Установка расширений PHP
# GD уже включен в PHP 8.2, но пересобираем с нужными библиотеками
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath zip \
    && docker-php-ext-install gd \
    && docker-php-ext-install intl

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Настройка прав пользователя
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]
