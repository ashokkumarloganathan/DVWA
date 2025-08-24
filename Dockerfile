FROM docker.io/library/php:8-apache

LABEL org.opencontainers.image.source="https://github.com/digininja/DVWA"
LABEL org.opencontainers.image.description="DVWA pre-built image with Cloudflare Tunnel."
LABEL org.opencontainers.image.licenses="gpl-3.0"

WORKDIR /var/www/html

# Install dependencies
RUN apt-get update \
 && export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y zlib1g-dev libpng-dev libjpeg-dev libfreetype6-dev iputils-ping git wget \
 && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && a2enmod rewrite \
 && docker-php-ext-install gd mysqli pdo pdo_mysql

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copy DVWA source
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data config/config.inc.php.dist config/config.inc.php

# Install DVWA API dependencies
RUN cd /var/www/html/vulnerabilities/api \
 && composer install

# Install Cloudflare Tunnel
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
 && dpkg -i cloudflared-linux-amd64.deb \
 && rm cloudflared-linux-amd64.deb

# Expose Apache port
EXPOSE 80

# Start Apache and Cloudflare Tunnel
CMD service apache2 start && cloudflared tunnel --no-autoupdate --url http://localhost:80
