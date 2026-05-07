FROM php:8.2-fpm

WORKDIR /var/www

# 1. Установка всех необходимых системных зависимостей
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
    zip \
    unzip \
    postgresql-client \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Настройка GD (графика)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# 3. Установка расширений PHP раздельно для избежания конфликтов
RUN docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath
RUN docker-php-ext-install gd
RUN docker-php-ext-install zip
RUN docker-php-ext-install intl

# 4. Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Настройка прав пользователя
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]
