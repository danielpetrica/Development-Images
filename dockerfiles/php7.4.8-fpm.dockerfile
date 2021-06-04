FROM php:7.4.8-fpm

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
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions, only output error and warnings
RUN set -x
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip  > /dev/null

# Enable opchache to reduce TTFB
RUN docker-php-ext-install opcache > /dev/null && docker-php-ext-configure opcache --enable-opcache

# Configure pecl and install
# command pecl install will not enable your extension after installation, so you'll have to run docker-php-ext-enable [extension]
RUN pecl config-set php_ini "${PHP_INI_DIR}/php.ini"
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

RUN bash && "$HOME/.nvm/nvm.sh" install --lts && "$HOME/.nvm/nvm.sh" use lts

#COPY . /var/www
# Copy existing application directory permissions
#COPY --chown=phpuser:phpuser . /var/www

# Change current user to www
USER phpuser

#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
##\
## && export NVM_DIR="$HOME/.nvm" \
##  [ -s "$HOME/.nvm/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
## && export [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#
#RUN bash && "$HOME/.nvm/nvm.sh" install --lts && "$HOME/.nvm/nvm.sh" use lts

# Install nvm to install npm and node.js
ENV NVM_DIR /root/.nvm
ENV NODE_VERSION lts/*
RUN mkdir $HOME/.nvm && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash && \
    chmod +x $HOME/.nvm/nvm.sh && \
    . $HOME/.nvm/nvm.sh && \
    nvm install --latest-npm "$NODE_VERSION" && \
    nvm alias default "$NODE_VERSION" && \
    nvm use default && \
    DEFAULT_NODE_VERSION=$(nvm version default) && \
    ln -sf /root/.nvm/versions/node/$DEFAULT_NODE_VERSION/bin/node /usr/bin/nodejs && \
    ln -sf /root/.nvm/versions/node/$DEFAULT_NODE_VERSION/bin/node /usr/bin/node && \
    ln -sf /root/.nvm/versions/node/$DEFAULT_NODE_VERSION/bin/npm /usr/bin/npm


# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD ["php-fpm"]
