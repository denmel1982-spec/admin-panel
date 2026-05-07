
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
    libfreetype-dev \
    libjpeg-dev \
    libwebp-dev \
    zip \
    unzip \
    postgresql-client \
    gnupg \
    procps \
    libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd zip intl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Копирование Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Настройка прав для www-data
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]
