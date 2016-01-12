#!/bin/bash

# Script accepts the following environment variable:
# - EZ_KICKSTART ( "true" or "false" )
# - EZ_KICKSTART_FROM_TEMPLATE ( template file )
#   Note that the value of this setting passed on to this script is the filename outside the container. Inside the container, the actuall file will always be named /kickstart_template.ini
#   Therefore, the value of this setting will be rewritten internally in the script
#
# Parameters can also be given as options, in the same order:
# ./run.sh [ EZ_KICKSTART ] [ EZ_KICKSTART_FROM_TEMPLATE ]

function parseCommandlineOptions
{
    if [ "$1" != "" ]; then
        EZ_KICKSTART=$1
    fi
    if [ "$2" != "" ]; then
        EZ_KICKSTART_FROM_TEMPLATE="/kickstart_template.ini"
    fi

    if [ "$APACHE_RUN_USER" == "" ]; then
        APACHE_RUN_USER=www-data
    fi

    # You might set SKIP_INITIALIZING_VAR=true if you would like to setup web/var from outside this container
    if [ "$SKIP_INITIALIZING_VAR" == "true" ]; then
        VARDIR=""
    else
        SKIP_INITIALIZING_VAR="false"
        VARDIR=" web/var"
    fi
}

function getAppFolder
{
    APP_FOLDER="app"
    if [ -d ezpublish ]; then
        APP_FOLDER="ezpublish"
    fi
}

parseCommandlineOptions $1 $2
getAppFolder

# If using Dockerfile-dev and we are dealing with ezp 5.4 we'll need to replace xdebug.ini
if [[ "$APP_FOLDER" == "ezpublish" && -f /etc/php5/mods-available/xdebug.ini-ezp54 ]]; then
    cp /etc/php5/mods-available/xdebug.ini-ezp54 /etc/php5/mods-available/xdebug.ini
fi

# Prepare for setup wizard if requested
if [ "$EZ_KICKSTART" = "true" ]; then
  /generate_kickstart_file.sh $EZ_KICKSTART_FROM_TEMPLATE
fi

/generate_parameters_file.sh


echo "Setting permissions on eZ Publish folder as they might be broken if rsync is used"
if [ ! -d web/var ] && [ "$SKIP_INITIALIZING_VAR" == "false" ]; then
    sudo -u ez mkdir web/var
fi

if [ -d ezpublish ]; then
    setfacl -R -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX ezpublish/{cache,logs,sessions}${VARDIR}
    setfacl -dR -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX ezpublish/{cache,logs,sessions}${VARDIR}
else
    setfacl -R -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX app/{cache,logs}${VARDIR}
    setfacl -dR -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX app/{cache,logs}${VARDIR}
fi

if [ -d ezpublish_legacy ]; then
    setfacl -R -m u:$APACHE_RUN_USER:rwx -m u:ez:rwx ezpublish_legacy/{design,extension,settings,var} ezpublish/config web
    setfacl -dR -m u:$APACHE_RUN_USER:rwx -m u:ez:rwx ezpublish_legacy/{design,extension,settings,var} ezpublish/config web
fi

APP_FOLDER="app"
if [ -d ezpublish ]; then
    APP_FOLDER="ezpublish"
fi

echo "Clear cache after parameters where updated"
sudo -u ez php $APP_FOLDER/console cache:clear --env $EZ_ENVIRONMENT

if [ "$EZ_ENVIRONMENT" != "dev" ]; then
    echo "Re-generate symlink assets in case rsync was used so asstets added during setup wizards are reachable"
    sudo -u ez php $APP_FOLDER/console assetic:dump --env $EZ_ENVIRONMENT
fi

sudo -u ez php $APP_FOLDER/console assets:install --symlink --relative --env $EZ_ENVIRONMENT

if [ -d ezpublish_legacy ]; then
    sudo -u ez php $APP_FOLDER/console ezpublish:legacy:assets_install --symlink --relative --env $EZ_ENVIRONMENT
fi

# Start php-fpm
if [ -x /usr/local/sbin/php-fpm ]; then
    exec /usr/local/sbin/php-fpm
else
    exec /usr/sbin/php5-fpm
fi
