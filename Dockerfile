FROM php:8.3-cli-bookworm

ARG COMPOSER_VERSION=2.8.12

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

COPY --from=composer:${COMPOSER_VERSION} /usr/bin/composer /usr/bin/composer

RUN echo "pcov.enabled=1" > /usr/local/etc/php/conf.d/pcov.ini \
    && echo "pcov.directory=/app" >> /usr/local/etc/php/conf.d/pcov.ini \
    && echo "memory_limit=-1" > /usr/local/etc/php/conf.d/tooling.ini \
    && echo "date.timezone=Europe/Berlin" >> /usr/local/etc/php/conf.d/tooling.ini

WORKDIR /app

CMD ["php", "-v"]
