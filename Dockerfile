# ---- Stage 1: Build frontend assets ----
FROM node:18-alpine AS frontend
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build

# ---- Stage 2: Install PHP dependencies ----
FROM composer:2 AS vendor
WORKDIR /app
COPY database/ database/
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --ignore-platform-reqs

# ---- Stage 3: Final runtime image ----
FROM php:8.1-fpm

RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer only existed in the "vendor" stage above - copy the binary
# itself into this final image since dump-autoload below needs it.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .
COPY --from=vendor /app/vendor/ ./vendor/
COPY --from=frontend /app/public/build/ ./public/build/
COPY --from=frontend /app/public/tinymce/ ./public/tinymce/

RUN composer dump-autoload --optimize --no-dev

RUN mkdir -p bootstrap/cache storage/logs storage/framework/sessions \
    storage/framework/views storage/framework/cache \
    && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Keep a pristine backup of the public folder inside the image.
# The named volume mounted at runtime will be empty at first and would
# otherwise hide these files - entrypoint.sh restores them from here.
RUN cp -r /var/www/public /var/www/public-src

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]