FROM php:8.3.15-apache AS base
WORKDIR /var/www/html
RUN apt-get update
ARG S6_OVERLAY_VERSION=3.2.0.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
COPY --chmod=755 ./.docker/s6 /etc/services.d
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions intl
RUN install-php-extensions opcache
RUN install-php-extensions zip
RUN install-php-extensions pdo_pgsql
RUN install-php-extensions @composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY ./.docker/apache/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

FROM base AS dev
ENV APP_ENV=dev
RUN install-php-extensions pcov
RUN cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b  /usr/local/bin
ADD --chmod=0755 ./.docker/entrypoint.dev.sh /usr/local/bin/entrypoint.sh

FROM base AS prod
ENV APP_ENV=prod
ENV APP_DEBUG=0
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY . .
ADD --chmod=0755 ./.docker/entrypoint.prod.sh /usr/local/bin/entrypoint.sh
RUN composer install --no-dev --optimize-autoloader --no-interaction
RUN php bin/console cache:clear && php bin/console cache:warmup
RUN composer dump-env prod --empty
RUN chown -R www-data:www-data ./var
EXPOSE 80
