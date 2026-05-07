FROM php:8.2-fpm

WORKDIR /var/www

# Обновляем репозитории и устанавливаем зависимости
# Используем libjpeg-dev вместо libjpeg62-turbo-dev для Debian 12
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libfreetype-dev \
    libjpeg-dev \
    zip \
    unzip \
    postgresql-client \
    gnupg \
    procps \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Настраиваем и устанавливаем расширения PHP
# Флаг --with-webp удален, так как в PHP 8.2+ он часто вызывает конфликты, 
# поддержка webp обычно включена через libwebp-dev автоматически или не требуется явного флага в этой версии
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd zip intl \
    && docker-php-ext-enable gd intl

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Настраиваем права пользователя (важно для Linux/Mac хостов)
RUN usermod -u 1000 www-data || true

EXPOSE 9000

CMD ["php-fpm"]

