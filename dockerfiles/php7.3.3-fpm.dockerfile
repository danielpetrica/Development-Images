FROM php:7.3.3-fpm-stretch

# Copy composer.lock and composer.json
#COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www

COPY php-fpm-config/www.conf /usr/local/etc/php-fpm.d/www.conf

# Install and then remove cache
RUN apt-get update && apt-get install -y -qq \
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
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini  \
 && echo "include_path=${PHP_INI_DIR}/custom.d/ " >> "${PHP_INI_DIR}/php.ini"

# Install extensions, only output error and warnings
RUN set -x
#  gd --with-freetype-dir --with-jpeg-dir for PHP <7.4
#  gd --with-freetype--with-jpeg for PHP > 7.4
RUN docker-php-ext-configure gd --with-jpeg-dir > /dev/null
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip calendar > /dev/null

# Enable opchache to reduce TTFB
RUN docker-php-ext-install opcache > /dev/null && docker-php-ext-configure opcache --enable-opcache

# Configure pecl and install
# command pecl install will not enable your extension after installation, so you'll have to run docker-php-ext-enable [extension]
RUN pecl config-set php_ini "${PHP_INI_DIR}/php.ini" \
  && pecl install redis  > /dev/null \
  && rm -rf /tmp/pear \
  && docker-php-ext-enable redis  > /dev/null
# I don't need mongo db so i can disable it
#\
# && pecl install mongodb  > /dev/null \
# && docker-php-ext-enable mongodb  > /dev/null

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Add user for laravel application
RUN useradd -G www-data,root -u 1000 -d /home/phpuser phpuser \
	&& mkdir -p /home/phpuser/.composer \
	&& chown -R phpuser:phpuser /home/phpuser


RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
#\
# && export NVM_DIR="$HOME/.nvm" \
#  [ -s "$HOME/.nvm/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
# && export [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

RUN export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" \
  && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
  && nvm install --lts && nvm use --lts
# This loads nvm

#COPY . /var/www
# Copy existing application directory permissions
#COPY --chown=phpuser:phpuser . /var/www

# Change current user to www
USER phpuser

# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD ["php-fpm"]
