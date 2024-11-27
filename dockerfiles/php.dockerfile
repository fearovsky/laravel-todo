FROM php:8.3-fpm-alpine

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN addgroup -g ${GID} --system laravel
RUN adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel

RUN sed -i "s/user = www-data/user = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

RUN docker-php-ext-install pdo pdo_mysql

RUN mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/refs/tags/6.0.2.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && docker-php-ext-configure redis --enable-redis-json \
    && docker-php-ext-install redis
    
# Switch to laravel user
USER laravel
RUN composer global require laravel/installer
ENV PATH=/home/laravel/.composer/vendor/bin:$PATH
RUN echo 'export PATH="$PATH:/home/laravel/.composer/vendor/bin"' >> ~/.profile

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
