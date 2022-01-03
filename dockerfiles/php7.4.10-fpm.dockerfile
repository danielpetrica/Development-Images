FROM php:7.4-fpm

# Copy composer.lock and composer.json
#COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www


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
    zip \
    libmagickwand-dev \
    libgmp-dev re2c libmhash-dev libmcrypt-dev file \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/
# Install extensions, only output error and warnings
RUN set -x
RUN docker-php-ext-install exif pdo_mysql mbstring exif pcntl bcmath gd zip  > /dev/null

# Enable opchache to reduce TTFB
RUN docker-php-ext-install opcache > /dev/null \
&& docker-php-ext-install intl gmp opcache > /dev/null


# Configure pecl and install
# command pecl install will not enable your extension after installation, so you'll have to run docker-php-ext-enable [extension]
RUN pecl config-set php_ini "${PHP_INI_DIR}/php.ini" \
&& pecl install redis  > /dev/null \
&& docker-php-ext-enable redis  > /dev/null \
&& pecl install imagick-beta  > /dev/null \
&& docker-php-ext-enable imagick > /dev/null \
&& rm -rf /tmp/pear


# I don't need mongo db so i can disable it
#\
# && pecl install mongodb  > /dev/null \
# && docker-php-ext-enable mongodb  > /dev/null
# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Add user for laravel application
RUN useradd -G www-data,root -u 1000 -d /home/phpuser phpuser \
	&& mkdir -p /home/phpuser/.composer \
	&& touch /home/phpuser/.bashrc \
	&& chown -R phpuser:phpuser /home/phpuser

#COPY . /var/www
# Copy existing application directory permissions
#COPY --chown=phpuser:phpuser . /var/www

# Change current user to www
USER phpuser

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
#\
# && export NVM_DIR="$HOME/.nvm" \
#  [ -s "$HOME/.nvm/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
# && export [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

RUN export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" \
  && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
  && nvm install --lts && nvm use --lts
# This loads nvm


# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD ["php-fpm"]
