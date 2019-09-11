FROM php:7.2-fpm-alpine3.10

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php
ENV RUNTIME_DEPS \
        cyrus-sasl-dev \
        bash \
        freetype-dev \
        file \
        gettext-dev \
        git \
        gmp-dev \
        icu-dev \
        libjpeg-turbo-dev \
        libmemcached-dev \
        libmcrypt-dev \
        libpng-dev \
        libressl-dev \
        libxml2-dev \
        openldap-dev \
        openssl-dev \
        patch \
        re2c \
        unzip \
        zlib-dev \
        zlib-dev \
        zip 

RUN apk add --update --no-cache $RUNTIME_DEPS \
    && apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv \
    # fix work iconv library with alphine
    && apk add libmhash-dev --repository https://dl-4.alpinelinux.org/alpine/edge/testing --allow-untrusted \
	&& ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
	&& docker-php-ext-configure gmp \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/ \
    && docker-php-ext-install \
        bcmath \
        #bz2 \
        #calendar \
        #dba \
        #enchant \
        exif \
        gd \
        gettext \
        gmp \
        #imap \
        #interbase \
        intl \
        ldap \
        #mcrypt \
        mysqli \
        #oci8 \
        #odbc \
        opcache \
        #pcntl \
        #pdo_dblib \
        #pdo_firebird \
        pdo_mysql \
        #pdo_oci \
        #pdo_odbc \
        #pdo_pgsql \
        #pgsql \
        #pspell \
        #recode \
        #shmop \
        #snmp \
        soap \
        sockets \
        #sysvmsg \
        #sysvsem \
        #sysvshm \
        #tidy \
        #wddx \
        #xmlrpc \
        #xsl \
        zip \
    && pecl install memcached redis xdebug \
    && apk del .phpize-deps \
    && rm -rf /var/cache/apk/* \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer