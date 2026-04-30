FROM php:8.2-fpm-bookworm

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

# PHP-FPM escuta local (Nginx acessa internamente)
RUN sed -ri 's/^listen = .*/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf

# Config Nginx
COPY docker/nginx/default.conf /etc/nginx/sites-enabled/getfy.conf

# Copia aplicação
COPY . .

# Permissões Laravel
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache \
    && chmod -R 777 storage bootstrap/cache

# 🔥 Cria config do supervisord (sem depender de arquivo externo)
RUN mkdir -p /etc/supervisor

RUN printf "[supervisord]\nnodaemon=true\n\n[program:php-fpm]\ncommand=docker-php-entrypoint php-fpm\nautostart=true\nautorestart=true\n\n[program:nginx]\ncommand=nginx -g 'daemon off;'\nautostart=true\nautorestart=true\n" > /etc/supervisor/supervisord.conf

EXPOSE 80

# 🔥 SEM entrypoint (elimina 100% dos erros que você teve)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
