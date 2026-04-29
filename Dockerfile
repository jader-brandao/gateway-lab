FROM php:8.2-fpm-bookworm AS php_base

# Debian Bookworm: nginx + extensões alinhadas ao PHP da imagem oficial.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl ca-certificates git unzip nginx supervisor \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
        libzip-dev libpq-dev libicu-dev libxml2-dev libonig-dev \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        gd pdo_pgsql zip exif intl mbstring opcache pcntl bcmath \
    && rm -f /etc/nginx/sites-enabled/default \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

FROM php_base AS app

# FPM só em loopback — Nginx no mesmo container.
RUN sed -ri 's/^listen = .*/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf

COPY docker/nginx/default.conf /etc/nginx/sites-enabled/getfy.conf
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/getfy.conf

COPY . .
COPY docker/entrypoint.sh /usr/local/bin/getfy-entrypoint

RUN chmod +x /usr/local/bin/getfy-entrypoint \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache .docker \
    && chmod -R 777 storage bootstrap/cache .docker

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/getfy-entrypoint"]
CMD ["/usr/bin/supervisord", "-n"]
