#!/usr/bin/env sh

set -e

# See:
# - Doc: https://docs.docker.com/engine/reference/builder/#entrypoint
# - Example: https://github.com/docker-library/mariadb/blob/master/10.1/docker-entrypoint.sh
#
# Example use:
# ./docker-entrypoint.sh php-fpm


## Clear container on start by default
if [ "$NO_FORCE_SF_CONTAINER_REFRESH" != "" ]; then
    echo "NO_FORCE_SF_CONTAINER_REFRESH set, skipping Symfony container clearing on startup."
elif [ -d var/cache ]; then
    echo "Symfony 3.x structure detected, container is not cleared on startup, use 3.2+ env variables support and warmup container during build."
elif [ -d ezpublish/cache ]; then
    echo "Deleting ezpublish/cache/*/*ProjectContainer.php to make sure environment variables are picked up"
    rm -f ezpublish/cache/*/*ProjectContainer.php
elif [ -d app/cache ]; then
    echo "Deleting app/cache/*/*ProjectContainer.php to make sure environment variables are picked up"
    rm -f app/cache/*/*ProjectContainer.php
fi

## Adjust behat.yml if asked for from localhost setup to use defined hosts
if [ "$BEHAT_SELENIUM_HOST" != "" ] && [ "$BEHAT_WEB_HOST" != "" ]; then
    echo "Copying behat.yml.dist to behat.yml and updating selenium and web hosts"
    if [ -f behat.yml.dist ]; then
        cp -f behat.yml.dist behat.yml
        sed -i "s@localhost:4444@${BEHAT_SELENIUM_HOST}:4444@" behat.yml
        sed -i "s@localhost@${BEHAT_WEB_HOST}@" behat.yml
    else
        echo "No behat.yml.dist found, skipping"
    fi
fi


## Auto adjust log folder for xdebug if enabled
if [ ! -d app ] && [ -f ${PHP_INI_DIR}/conf.d/xdebug.ini ]; then
    if [ -d ezpublish/log ]; then
        echo "Auto adjusting xdebug settings to log in ezpublish/log"
        sed -i "s@/var/www/app/log@/var/www/ezpublish/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
    elif [ -d var/log ]; then
        echo "Auto adjusting xdebug settings to log in var/log"
        sed -i "s@/var/www/app/log@/var/www/var/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
    fi
fi

# docker-entrypoint-initdb.d, as provided by most official images allows for direct usage and extended images to
# extend behaviour without modifying this file.
for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
        *.sh)     echo "$0: running $f"; . "$f" ;;
        *)        echo "$0: ignoring $f" ;;
    esac
    echo
done


exec "$@"
