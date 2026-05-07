FROM php:8.2-fpm

WORKDIR /var/www

# 1. Установка всех системных зависимостей
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
    libicu-dev \
    libpq-dev \
    zip \
    unzip \
    postgresql-client \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Настройка GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# 3. Установка расширений по группам (для лучшей отладки)
RUN docker-php-ext-install pdo_pgsql mbstring
RUN docker-php-ext-install exif pcntl bcmath
RUN docker-php-ext-install gd
RUN docker-php-ext-install zip
RUN docker-php-ext-install intl

# 4. Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Права доступа
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]
