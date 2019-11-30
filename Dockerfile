# More info: <https://habr.com/ru/post/461687/>
FROM composer:1.9.1 AS composer
FROM 512k/roadrunner:1.5.1 AS roadrunner

FROM php:7.3.12-alpine

ENV \
    COMPOSER_ALLOW_SUPERUSER="1" \
    COMPOSER_HOME="/tmp/composer" \
    PS1='\[\033[1;32m\]\[\033[1;36m\][\u@\h] \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'

# persistent / runtime deps
ENV PHPIZE_DEPS \
    build-base \
    autoconf \
    libc-dev \
    pcre-dev \
    pkgconf \
    cmake \
    make \
    file \
    re2c \
    g++ \
    gcc

# repmanent deps
ENV PERMANENT_DEPS \
    postgresql-dev \
    gettext-dev \
    icu-dev \
    libintl

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=roadrunner /usr/bin/rr /usr/bin/rr

RUN set -x \
    && apk add --no-cache ${PERMANENT_DEPS} \
    && apk add --no-cache --virtual .build-deps ${PHPIZE_DEPS} \
    # https://github.com/docker-library/php/issues/240
    && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv \
    && docker-php-ext-configure mbstring --enable-mbstring \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-configure pdo_pgsql --with-pgsql \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        mbstring \
        sockets \
        gettext \
        opcache \
        bcmath \
        pcntl \
        intl \
    && apk del .build-deps \
    && rm -rf /app /home/user ${COMPOSER_HOME} /var/cache/apk/* \
    && mkdir /app /home/user ${COMPOSER_HOME} \
    && composer global require 'hirak/prestissimo' --no-interaction --no-suggest --prefer-dist \
    && ln -s /usr/bin/composer /usr/bin/c

WORKDIR /app

COPY ./composer.* /app/

RUN set -x \
    && composer install --no-interaction --no-ansi --no-suggest --prefer-dist  --no-autoloader --no-scripts \
    && composer install --no-dev --no-interaction --no-ansi --no-suggest --prefer-dist  --no-autoloader --no-scripts \
    && chmod -R 777 /home/user ${COMPOSER_HOME}

COPY . /app

RUN set -x \
    && composer --version \
    && php -v \
    && php -m \
    && rr -h \
    && composer dump

EXPOSE 8080

CMD ["rr", "serve", "-d", "-o", "http.workers.command='php ./vendor/bin/rr-worker'", "-o", "http.address=:8080"]
