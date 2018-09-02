# Versions 3.8 and 3.7 are current stable supported versions.
FROM alpine:3.8

RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

# trust this project public key to trust the packages.
ADD https://php.codecasts.rocks/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# make sure you can use HTTPS
RUN apk --update add ca-certificates

# add the repository, make sure you replace the correct versions if you want.
RUN echo "@php https://php.codecasts.rocks/v3.8/php-7.2" >> /etc/apk/repositories

# install php and some extensions
# notice the @php is required to avoid getting default php packages from alpine instead.
RUN apk add --update --no-cache \
    php@php \
    php7-mysqlnd@php \
    php-fpm@php \
    php-mbstring@php \
    php-memcached@php \
    php-curl@php \
    apache2 \
    apache2-proxy && \
    # remove LiteSpeed
    rm /usr/bin/lsphp7 && \
    # remove apk cache
    rm -r /var/cache/apk/*

    # set the 'ServerName' directive globally 
RUN  sed -i 's/^#ServerName .*/ServerName localhost/gI' /etc/apache2/httpd.conf && \
     # create new server root
    mkdir /var/www/html && \
    # change default root to /var/www/html
    sed -i 's/^DocumentRoot "\/var\/www\/.*/DocumentRoot "\/var\/www\/html"/gI' /etc/apache2/httpd.conf && \
    sed -i 's/^<Directory "\/var\/www\/.*>/<Directory "\/var\/www\/html">/gI' /etc/apache2/httpd.conf&& \
    # allow .htaccess file to override default config
    sed -i 's/AllowOverride None/AllowOverride All/gI' /etc/apache2/httpd.conf && \
    # change apache user and group to www-data
    sed -i 's/^User apache/User www-data/g' /etc/apache2/httpd.conf && \
    sed -i 's/^Group apache/Group www-data/g' /etc/apache2/httpd.conf && \
    # look for index.php first
    sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/g' /etc/apache2/httpd.conf && \
    # proxypass php files to php-fpm server
    echo "ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/var/www/html/$1" > /etc/apache2/conf.d/php-fpm.conf && \
    # diable mpm_prefork since we're not using mod_php
    sed -i 's/^LoadModule mpm_prefork/#LoadModule mpm_prefork/gI' /etc/apache2/httpd.conf && \
    # enable mpm_event for php-fpm
    sed -i 's/^#LoadModule mpm_event/LoadModule mpm_event/gI' /etc/apache2/httpd.conf && \
    # enable rewrite module
    sed -i 's/^#LoadModule rewrite_/LoadModule rewrite_/gI' /etc/apache2/httpd.conf && \
    # enable xslotmem_shm slotmem_shm
    echo "LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" > /etc/apache2/conf.d/slotmem_shm.conf && \
    # fix some module loading ordering in proxy conf
    echo "$(head -5 /etc/apache2/conf.d/proxy.conf)" >> /etc/apache2/conf.d/proxy.conf && \
    echo "$(tail -n +6 /etc/apache2/conf.d/proxy.conf)" > /etc/apache2/conf.d/proxy.conf && \
    # apache doesn't start if this directory doesn't exist
    mkdir -p /run/apache2 && \
    # create startup script
    echo "#!/bin/sh" > /run.sh && \
    echo "exec /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf &" >> /run.sh && \
    echo "exec /usr/sbin/php-fpm7 -F" >> /run.sh && \
    chmod +x /run.sh

EXPOSE 80

#ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["/run.sh"]
