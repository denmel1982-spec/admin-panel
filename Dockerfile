# PHP 8.2 FPM
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    postgresql-client \
    && docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user
RUN useradd -G www-data,root -u 1000 -d /home/appuser appuser \
    && mkdir -p /home/appuser/.composer \
    && chown -R appuser:appuser /home/appuser

# Set working directory
WORKDIR /var/www/html

# Copy existing application directory
COPY --chown=appuser:appuser . /var/www/html

USER appuser

EXPOSE 9000
CMD ["php-fpm"]
