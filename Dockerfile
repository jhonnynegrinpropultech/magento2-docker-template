FROM php:8.3-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid


LABEL maintainer="DevOps Team"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    cron \
    default-mysql-client \
    git \
    gnupg \
    gzip \
    libbz2-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libonig-dev \
    libpng-dev \
    libsodium-dev \
    libssh2-1-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    lsof \
    procps \
    unzip \
    vim \
    wget \
    zip

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    bz2 \
    calendar \
    exif \
    gd \
    gettext \
    intl \
    mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    sodium \
    sysvmsg \
    sysvsem \
    sysvshm \
    xsl \
    zip

# Install additional PHP extensions
RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN pecl install redis && docker-php-ext-enable redis

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user


# Set recommended PHP.ini settings
RUN cd /usr/local/etc/php/conf.d/ && \
    echo 'memory_limit = 1G' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    echo 'max_execution_time = 30' >> /usr/local/etc/php/conf.d/docker-php-maxexectime.ini && \
    echo 'max_input_vars = 10000' >> /usr/local/etc/php/conf.d/docker-php-maxinputvars.ini && \
    echo 'upload_max_filesize = 100M' >> /usr/local/etc/php/conf.d/docker-php-uploadmaxfilesize.ini && \
    echo 'post_max_size = 100M' >> /usr/local/etc/php/conf.d/docker-php-postmaxsize.ini && \
    echo 'date.timezone = UTC' >> /usr/local/etc/php/conf.d/docker-php-timezone.ini && \
    echo 'display_errors = Off' >> /usr/local/etc/php/conf.d/docker-php-errors.ini && \
    echo 'log_errors = On' >> /usr/local/etc/php/conf.d/docker-php-errors.ini

# Configure opcache
RUN echo 'opcache.memory_consumption=512' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo 'opcache.interned_strings_buffer=64' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo 'opcache.max_accelerated_files=60000' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo 'opcache.validate_timestamps=0' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo 'opcache.enable_cli=1' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo 'opcache.revalidate_freq=0' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
    

# Configure xdebug (commented out by default)
RUN echo 'xdebug.mode=off' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo '#xdebug.mode=develop,debug' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo '#xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo '#xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo '#xdebug.log=/var/log/xdebug.log' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini


# Create app directory
WORKDIR /var/www/html

USER $user

# Use this Dockerfile as part of a docker-compose setup with other services

EXPOSE 9000
CMD ["php-fpm"]
