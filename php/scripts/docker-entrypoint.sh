#!/usr/bin/env bash

set -e

# See:
# - Doc: https://docs.docker.com/engine/reference/builder/#entrypoint
# - Example: https://github.com/docker-library/mariadb/blob/master/10.1/docker-entrypoint.sh
#
# Example use:
# ./docker-entrypoint.sh php-fpm


## Clear container on start by default
if [ "$NO_FORCE_SF_CONTAINER_REFRESH" != "" ]; then
    logger "NO_FORCE_SF_CONTAINER_REFRESH set, skipping Symfony container clearing on startup."
elif [ -d var/cache ]; then
    logger "Symfony 3.x structure detected, container is not cleared on startup, use 3.2+ env variables support and warmup container during build."
elif [ -d ezpublish/cache ]; then
    logger "Deleting ezpublish/cache/*/*ProjectContainer.php to make sure environment variables are picked up"
    rm -f ezpublish/cache/*/*ProjectContainer.php
elif [ -d app/cache ]; then
    logger "Deleting app/cache/*/*ProjectContainer.php to make sure environment variables are picked up"
    rm -f app/cache/*/*ProjectContainer.php
fi

## Adjust behat.yml if asked for from localhost setup to use defined hosts
if [ "$BEHAT_SELENIUM_HOST" != "" ] && [ "$BEHAT_WEB_HOST" != "" ]; then
    logger "Copying behat.yml.dist to behat.yml and updating selenium and web hosts"
    if [ -f behat.yml.dist ]; then
        cp -f behat.yml.dist behat.yml
        if [ "$MINK_DEFAULT_SESSION" != "" ]; then sed -i "s@javascript_session: selenium@javascript_session: ${MINK_DEFAULT_SESSION}@" behat.yml; fi
        sed -i "s@localhost:4444@${BEHAT_SELENIUM_HOST}:4444@" behat.yml
        if [ "$BEHAT_CHROMIUM_HOST" != "" ]; then sed -i "s@localhost:9222@${BEHAT_CHROMIUM_HOST}:9222@" behat.yml; fi
        sed -i "s@localhost@${BEHAT_WEB_HOST}@" behat.yml
    else
        logger "No behat.yml.dist found, skipping"
    fi
fi

## Enable xdebug if ENABLE_XDEBUG env is defined
if [ ! -f ${PHP_INI_DIR}/conf.d/xdebug.ini ] && [ "${ENABLE_XDEBUG}" != "" ]; then
    logger "Enabling xdebug"
    mv ${PHP_INI_DIR}/conf.d/xdebug.ini.disabled ${PHP_INI_DIR}/conf.d/xdebug.ini
fi

## Auto adjust log folder for xdebug if enabled
if [ ! -d app ] && [ -f ${PHP_INI_DIR}/conf.d/xdebug.ini ]; then
    if [ -d ezpublish/log ]; then
        logger "Auto adjusting xdebug settings to log in ezpublish/log"
        sed -i "s@/var/www/app/log@/var/www/ezpublish/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
    elif [ -d var/log ]; then
        logger "Auto adjusting xdebug settings to log in var/log"
        sed -i "s@/var/www/app/log@/var/www/var/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
    fi
fi

# docker-entrypoint-initdb.d, as provided by most official images allows for direct usage and extended images to
# extend behaviour without modifying this file.
for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
        *.sh)     logger "$0: running $f"; . "$f" ;;
        "/docker-entrypoint-initdb.d/*") ;;
        *)        logger "$0: ignoring $f" ;;
    esac
done

# Scan for environment variables prefixed with PHP_INI_ENV_ and inject those into ${PHP_INI_DIR}/conf.d/zzz_custom_settings.ini
# Environment variable names cannot contain dots, so use two underscores in that case:
# PHP_INI_ENV_session__gc_maxlifetime=2592000  --> session.gc_maxlifetime=2592000
if [ -f ${PHP_INI_DIR}/conf.d/zzz_custom_settings.ini ]; then rm ${PHP_INI_DIR}/conf.d/zzz_custom_settings.ini; fi
env | while IFS='=' read -r name value ; do
  if (echo $name|grep -E "^PHP_INI_ENV">/dev/null); then
    # remove PHP_INI_ENV_ prefix
    name=`echo $name | cut -f 4- -d "_"`
    # Replace __ with .
    name=${name//__/.}
    echo $name=$value >> ${PHP_INI_DIR}/conf.d/zzz_custom_settings.ini
  fi
done

# Scan for environment variables prefixed with PHP_FPM_INI_ENV_ and inject those into /usr/local/etc/php-fpm.d/zzz_custom_settings.conf
# Environment variable names cannot contain dots, so use two underscores in that case:
# PHP_FPM_INI_ENV_pm__max_children=10  --> pm.max_children=10
if [ -f /usr/local/etc/php-fpm.d/zzz_custom_settings.conf ]; then rm /usr/local/etc/php-fpm.d/zzz_custom_settings.conf; fi
echo '[www]' > /usr/local/etc/php-fpm.d/zzz_custom_settings.conf
env | while IFS='=' read -r name value ; do
  if (echo $name|grep -E "^PHP_FPM_INI_ENV">/dev/null); then
    # remove PHP_FPM_INI_ENV_ prefix
    name=`echo $name | cut -f 5- -d "_"`
    # Replace __ with .
    name=${name//__/.}
    echo $name=$value >> /usr/local/etc/php-fpm.d/zzz_custom_settings.conf
  fi
done

exec "$@"
