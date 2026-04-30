FROM php:8.2-fpm-bookworm AS php_base

# Instala dependências
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

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

FROM php_base AS app

# PHP-FPM escutando só local (Nginx acessa internamente)
RUN sed -ri 's/^listen = .*/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf

# Nginx config
COPY docker/nginx/default.conf /etc/nginx/sites-enabled/getfy.conf

# 🔥 Corrigido: usar config principal do supervisord
COPY docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# App
COPY . .

# Entrypoint
COPY docker/entrypoint.sh /usr/local/bin/getfy-entrypoint

RUN chmod +x /usr/local/bin/getfy-entrypoint \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache .docker \
    && chmod -R 777 storage bootstrap/cache .docker

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/getfy-entrypoint"]

# 🔥 Corrigido: apontar config do supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
