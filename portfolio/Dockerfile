FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    git unzip zip curl \
    libzip-dev libicu-dev libonig-dev libxml2-dev

RUN docker-php-ext-install pdo pdo_mysql intl zip

RUN a2enmod rewrite

# ----------------------------
# Apache config propre (IMPORTANT)
# ----------------------------
COPY site.conf /etc/apache2/sites-available/000-default.conf

RUN a2ensite 000-default.conf

RUN sed -ri -e 's!/var/www/html!/var/www/html/public!g' \
    /etc/apache2/apache2.conf

# ----------------------------
# Composer
# ----------------------------
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ----------------------------
# FIX IMPORTANT : FORCE LATEST GIT VERSION (FIRST BUILD)
# ----------------------------

ARG CACHEBUST=1

RUN git clone --depth=1 https://github.com/nath421/EPORTFOLIO.git .

RUN composer install --no-interaction --prefer-dist || true

RUN mkdir -p var && chmod -R 777 var

EXPOSE 80

CMD ["apache2-foreground"]