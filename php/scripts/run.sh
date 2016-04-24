#!/usr/bin/env sh

# Script accepts the following environment variable:
# - EZ_KICKSTART ( "true" or "false" )
# - EZ_KICKSTART_FROM_TEMPLATE ( template file )
#   Note that the value of this setting passed on to this script is the filename outside the container. Inside the container, the actuall file will always be named /kickstart_template.ini
#   Therefore, the value of this setting will be rewritten internally in the script
#
# Parameters can also be given as options, in the same order:
# ./run.sh [ EZ_KICKSTART ] [ EZ_KICKSTART_FROM_TEMPLATE ]

parseCommandlineOptions()
{
    if [ "$1" != "" ]; then
        EZ_KICKSTART=$1
    fi
    if [ "$2" != "" ]; then
        EZ_KICKSTART_FROM_TEMPLATE="/kickstart_template.ini"
    fi

    if [ "$APACHE_RUN_USER" = "" ]; then
        APACHE_RUN_USER=www-data
    fi

    # You might set SKIP_INITIALIZING_VAR=true if you would like to setup web/var from outside this container
    if [ "$SKIP_INITIALIZING_VAR" = "true" ]; then
        VARDIR=""
    else
        SKIP_INITIALIZING_VAR="false"
        VARDIR=" web"
    fi
}

# By default app folder is "app", but "ezpublish" is selected if found for bc.
getAppFolder()
{
    APP_FOLDER="app"
    if [ -d ezpublish ]; then
        APP_FOLDER="ezpublish"
    fi
}

parseCommandlineOptions $1 $2
getAppFolder

umask 002

# If using Dockerfile-dev and we are dealing with ezp 5.4 we'll need to replace xdebug.ini
if [ "$APP_FOLDER" = "ezpublish" ] && [ -f ${PHP_INI_DIR}/conf.d/xdebug.ini ]; then
    sed -i "s@/var/www/app/log@/var/www/ezpublish/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
fi

# Prepare for setup wizard if requested
if [ "$EZ_KICKSTART" = "true" ]; then
  /generate_kickstart_file.sh $EZ_KICKSTART_FROM_TEMPLATE
fi

if [ ! -d web/var ] && [ "$SKIP_INITIALIZING_VAR" = "false" ]; then
    echo "Creating web/var as it was missing"
    sudo -u ez mkdir -m 2775 web/var
fi

if [ ! -d app/cache/$SYMFONY_ENV ]; then
    echo "Creating cache folder for $SYMFONY_ENV as it was missing"
    sudo -u ez mkdir -m 2775 app/cache/$SYMFONY_ENV
fi


# Start php-fpm
if [ -x /usr/local/sbin/php-fpm ]; then
    exec /usr/local/sbin/php-fpm
else
    exec /usr/sbin/php5-fpm
fi
