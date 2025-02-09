FROM php:8.0-apache

# Install PostgreSQL extension for PHP
RUN apt-get update && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql

COPY . /var/www/html/FROM php:8.0-apache

# Install dependencies for PHP AMQP extension
RUN apt-get update && apt-get install -y \
    librabbitmq-dev \
    libssl-dev \
    && pecl install amqp \
    && docker-php-ext-enable amqp

RUN a2enmod rewrite

WORKDIR /var/www/html

COPY . /var/www/html/

RUN chown -R www-data:www-data /var/www/html
