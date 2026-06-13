# 1. Das ARG muss ganz nach oben (globaler Scope)
ARG COMPOSER_VERSION=2.8.12

# 2. Hier tricksen wir Buildx aus und weisen dem Composer-Image einen festen Alias zu
FROM composer:${COMPOSER_VERSION} AS composer_source

# 3. Jetzt startet dein eigentliches PHP-Image
FROM php:8.3-cli-bookworm

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer \
    PCOV_ENABLED=1 \
    PCOV_DIRECTORY=/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        zip \
        libzip-dev \
        libicu-dev \
        libxml2-dev \
        libonig-dev \
    && docker-php-ext-install \
        intl \
        mbstring \
        opcache \
        pdo_mysql \
        soap \
        zip \
    && pecl install pcov \
    && docker-php-ext-enable pcov \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

# 4. Hier kopierst du nun sauber aus dem statischen Alias statt aus der Variable
COPY --from=composer_source /usr/bin/composer /usr/bin/composer

RUN echo "pcov.enabled=1" > /usr/local/etc/php/conf.d/pcov.ini \
    && echo "pcov.directory=/app" >> /usr/local/etc/php/conf.d/pcov.ini \
    && echo "memory_limit=-1" > /usr/local/etc/php/conf.d/tooling.ini \
    && echo "date.timezone=Europe/Berlin" >> /usr/local/etc/php/conf.d/tooling.ini

WORKDIR /app

CMD ["php", "-v"]
