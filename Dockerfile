# check=skip=SecretsUsedInArgOrEnv
FROM serversideup/php:8.3-cli

USER root

ENV MYSQL_ROOT_PASSWORD=root \
    MYSQL_DATABASE=shopware \
    SHOW_WELCOME_MESSAGE=false

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.2.3.0/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.2.3.0/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# 1. PHP Extensions und MariaDB installieren
RUN install-php-extensions gd intl pdo_mysql zip \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       mariadb-server \
       mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -1sLf 'https://dl.cloudsmith.io/public/friendsofshopware/stable/setup.deb.sh' | bash \
    && apt-get update \
    && apt-get install -y --no-install-recommends shopware-cli \
    && rm -rf /var/lib/apt/lists/*

# 2. S6 Service-Scripte kopieren
COPY --chmod=755 .docker/s6-rc.d/ /etc/s6-overlay/s6-rc.d/

# 3. CRITICAL: S6-Struktur explizit root zuweisen, damit der Service als System-Service läuft
RUN chown -R root:root /etc/s6-overlay/s6-rc.d/ \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/mariadb

# 4. Verzeichnisse vorbereiten
RUN mkdir -p /var/run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# s6 must run as root so supervised system services can prepare runtime
# directories and drop privileges themselves.
USER root

WORKDIR /var/www/html
RUN composer create-project shopware/production . --no-interaction --no-scripts \
    && sed -i 's#^DATABASE_URL=.*#DATABASE_URL=mysql://root:root@127.0.0.1:3306/shopware#' .env \
    && sed -i 's#^APP_ENV=.*#APP_ENV=dev#' .env

#RUN bin/console system:install --basic-setup
RUN composer require --dev phpstan/phpstan "phpunit/phpunit:^12.5" shopwarelabs/phpstan-shopware friendsofphp/php-cs-fixer --no-interaction --no-progress -W



CMD ["/init"]
