# More info: <https://habr.com/ru/post/461687/>
FROM php:7.3.19-alpine

ENV \
    COMPOSER_ALLOW_SUPERUSER="1" \
    COMPOSER_HOME="/tmp/composer" \
    PS1='\[\033[1;32m\]\[\033[1;36m\][\u@\h] \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'

COPY --from=composer:1.10.7 /usr/bin/composer /usr/bin/composer
COPY --from=spiralscout/roadrunner:1.8.1 /usr/bin/rr /usr/bin/rr

RUN set -x \
    && apk add --no-cache \
        postgresql-dev \
        gettext-dev \
        icu-dev \
        libintl \
    && apk add --no-cache --virtual .build-deps \
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
        gcc \
    # https://github.com/docker-library/php/issues/240
    && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv \
    && ( docker-php-ext-configure mbstring --enable-mbstring \
        && docker-php-ext-configure opcache --enable-opcache \
        && docker-php-ext-configure bcmath --enable-bcmath \
        && docker-php-ext-configure pcntl --enable-pcntl \
        && docker-php-ext-configure intl --enable-intl ) 1>/dev/null \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        mbstring \
        sockets \
        gettext \
        opcache \
        bcmath \
        pcntl \
        intl \
        pdo \
        1>/dev/null \
    && apk del .build-deps \
    && rm -rf /app /home/user ${COMPOSER_HOME} /var/cache/apk/* \
    && mkdir --mode=777 /app /home/user ${COMPOSER_HOME} \
    && composer global require 'hirak/prestissimo' --no-interaction --no-suggest --prefer-dist \
    && ln -s /usr/bin/composer /usr/bin/c

WORKDIR /app

COPY ./composer.* /app/

RUN set -x \
    && composer install --no-interaction --no-ansi --no-suggest --prefer-dist --no-autoloader --no-scripts \
    && composer install --no-dev --no-interaction --no-ansi --no-suggest --prefer-dist --no-autoloader --no-scripts \
    && chmod -R 777 ${COMPOSER_HOME}

COPY . /app

RUN set -x \
    && composer --version \
    && php -v \
    && rr -h \
    && composer dump

EXPOSE 8080

# RoadRunner worker package: <https://github.com/spiral/roadrunner-laravel>
# Config example: <https://github.com/spiral/roadrunner/blob/v1.8.1/.rr.yaml>
CMD [ \
    "rr", "serve", "-d", \
    "-o", "http.workers.command='php ./vendor/bin/rr-worker'", \
    "-o", "http.address=:8080", \
    "-o", "http.workers.pool.maxJobs=1", \
    "-o", "env.APP_REFRESH=true", \
    "-o", "static.dir=public" \
]
