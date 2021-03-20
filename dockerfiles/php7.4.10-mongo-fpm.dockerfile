FROM ghcr.io/danielpetrica/php:7.4.10

USER root


# Configure pecl and install
# command pecl install will not enable your extension after installation, so you'll have to run docker-php-ext-enable [extension]
RUN pecl config-set php_ini "${PHP_INI_DIR}/php.ini" \
 && pecl install mongodb   > /dev/null \
 && docker-php-ext-enable mongodb  > /dev/null

#COPY . /var/www
# Copy existing application directory permissions
#COPY --chown=phpuser:phpuser . /var/www

# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD ["php-fpm"]
