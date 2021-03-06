FROM php:7.3-fpm-stretch

# Copy composer.lock and composer.json
#COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www

# Install and then remove cache
RUN apt-get update > /dev/null && \
 apt-get install -y -qq \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libmcrypt-dev \
    libssl-dev \
    libjpeg62-turbo-dev \
    zip \
    unzip > /dev/null && \
 apt-get clean > /dev/null && \
 rm -rf /var/lib/apt/lists/*
# Use the default production configuration
RUN mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini && \
 echo "include_path=${PHP_INI_DIR}/custom.d/ " >> "${PHP_INI_DIR}/php.ini"

# Install extensions, only output error and warnings
RUN set -x
#  gd --with-freetype-dir --with-jpeg-dir for PHP <7.4
#  gd --with-freetype--with-jpeg for PHP > 7.4
RUN docker-php-ext-configure gd --with-jpeg-dir > /dev/null
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip  > /dev/null

# Enable opchache to reduce TTFB
RUN docker-php-ext-install opcache > /dev/null && docker-php-ext-configure opcache --enable-opcache

# Configure pecl and install
# command pecl install will not enable your extension after installation,
# so you'll have to run docker-php-ext-enable [extension]

RUN pecl config-set php_ini "${PHP_INI_DIR}/php.ini" \
 && pecl install redis  > /dev/null \ &&  rm -rf /tmp/pear \ && docker-php-ext-enable redis  > /dev/null
# I don't need mongo db so i can disable it
#\

# Get latest Composer
COPY --from=composer:1 /usr/bin/composer /usr/bin/composer

RUN composer global require hirak/prestissimo

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
