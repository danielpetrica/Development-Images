FROM php:8.0-fpm


# Copy composer.lock and composer.json
#COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www


# Install and then remove cache
RUN apt-get update > /dev/null  && apt-get install -y -qq \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libmcrypt-dev \
    libssl-dev \
    zip \
    unzip  > /dev/null \
    && apt-get clean  > /dev/null && rm -rf /var/lib/apt/lists/*

# Install extensions, only output error and warnings
RUN set -x
RUN docker-php-ext-install pdo_mysql exif pcntl bcmath gd zip  > /dev/null

# Enable opchache to reduce TTFB
RUN docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache

# Configure pecl and install
# command pecl install will not enable your extension after installation, so you'll have to run docker-php-ext-enable [extension]
RUN pecl config-set php_ini "${PHP_INI_DIR}/php.ini" \
 && pecl install mongodb   > /dev/null \
 && docker-php-ext-enable mongodb  > /dev/null \
 && pecl install redis  > /dev/null \
 && rm -rf /tmp/pear \
 && docker-php-ext-enable redis  > /dev/null
# I don't need mongo db so i can disable it
#\

# Get latest Composer
COPY --from=composer:1 /usr/bin/composer /usr/bin/composer

# Add user for laravel application
RUN useradd -G www-data,root -u 1000 -d /home/phpuser phpuser \
	&& mkdir -p /home/phpuser/.composer \
	&& chown -R phpuser:phpuser /home/phpuser

#COPY . /var/www
# Copy existing application directory permissions
#COPY --chown=phpuser:phpuser . /var/www

# Change current user to www
USER phpuser

# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD ["php-fpm"]
