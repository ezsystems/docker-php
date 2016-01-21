FROM php:7.0-fpm

# Container containing php-fpm and php-cli to run and interact with eZ Platform
#
# It has two modes of operation:
# - (default run.sh cmd) Reconfigure eZ Platform/Publish based on provided env variables and start php-fpm
# - (bash|php|composer) Allows to execute composer, php or bash against the install

# Set defaults for variables used by run.sh
# If you change MAX_EXECUTION TIME, also change fastcgi_read_timeout accordingly in nginx!
ENV DEBIAN_FRONTEND=noninteractive \
    TIMEZONE=Europe/Warsaw \
    MEMORY_LIMIT=256M \
    MAX_EXECUTION_TIME=90 \
    PORT=9000 \
    COMPOSER_HOME=/home/ez/.composer

## Get packages
### unzip needed due to https://github.com/composer/composer/issues/4471
RUN apt-get update -q -y \
 && apt-get install -q -y --force-yes --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libxpm-dev \
        libpng12-dev \
        libicu-dev \
        libxslt1-dev \
        mysql-client \
        curl \
        wget \
        ca-certificates \
        less \
        vim \
        git \
        acl \
        sudo \
        tree \
        unzip \
        && rm -rf /var/lib/apt/lists/*

# Install and configure php plugins
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd \
 && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ --with-xpm-dir=/usr/include/ --enable-gd-native-ttf --enable-gd-jis-conv \
 && docker-php-ext-install exif gd mbstring intl xsl zip mysqli pdo_mysql \
 && docker-php-ext-enable opcache

# Set timezone
RUN echo $TIMEZONE > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

# Set some php.ini config
RUN cp /usr/src/php/php.ini-production /usr/local/etc/php/php.ini \
 && echo "date.timezone = $TIMEZONE" >> /usr/local/etc/php/php.ini \
 && echo "memory_limit = $MEMORY_LIMIT" >> /usr/local/etc/php/php.ini \
 && echo "realpath_cache_size = 256k" >> /usr/local/etc/php/php.ini \
 && echo "max_execution_time = $MAX_EXECUTION_TIME" >> /usr/local/etc/php/php.ini

# Disable daemonizeing php-fpm
#RUN sed -i "s@^;daemonize = yes*@daemonize = no@" /usr/local/etc/php-fpm.conf

# Add pid file to be able to restart php-fpm
RUN sed -i "s@^\[global\]@\[global\]\n\npid = /run/php-fpm.pid@" /usr/local/etc/php-fpm.conf

# Set listen socket for php-fpm
RUN sed -i "s@^listen = 127.0.0.1:9000@listen = $PORT@" /usr/local/etc/php-fpm.d/www.conf.default \
 && sed -i "s@^user = nobody@user = www-data@" /usr/local/etc/php-fpm.d/www.conf.default \
 && sed -i "s@^group = nobody@group = www-data@" /usr/local/etc/php-fpm.d/www.conf.default

RUN groupadd -g 10000 ez && useradd -g ez -u 10000 ez --create-home
# Create Composer directory (cache and auth files)
RUN mkdir -p $COMPOSER_HOME && chown ez:ez $COMPOSER_HOME

# Get Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin && mv /usr/local/bin/composer.phar /usr/local/bin/composer

# As application is put in as volume we do all needed operation on run
ADD run.sh /run.sh
ADD generate_kickstart_file.sh /generate_kickstart_file.sh
ADD generate_parameters_file.sh /generate_parameters_file.sh
ADD prepare_distribution_volume.sh /prepare_distribution_volume.sh
ADD prepare_behat.sh /prepare_behat.sh

#/usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
#ADD config/opcache.ini /usr/local/php7/etc/conf.d/opcache.ini

RUN chmod 755 /*.sh


WORKDIR /var/www

CMD /run.sh

EXPOSE 9000
