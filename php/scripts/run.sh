#!/usr/bin/env sh

# Script accepts the following optional arguments:
# --dev-mode                    If set web/var folder is created, assetic:dump is done and var/www is owned by "ez".
# --legacy-kickstart-template=* If set attempt to generate eZ legacy kickstart file using this template.
#
# Example for dev use:
# ./run.sh --dev-mode

DEV_MODE="false"
EZ_KICKSTART_TEMPLATE=""

## Parse arguments
for i in "$@"; do
case $i in
    --dev-mode)
        DEV_MODE="true"
        ;;
    --legacy-kickstart-template=*)
        EZ_KICKSTART_TEMPLATE="${i#*=}"
        ;;
    *)
        printf "Not recognised argument: ${i}, only supported arguments are: --dev-mode and --legacy-kickstart-template=*"
        exit 1
        ;;
esac
done


# EZP5: If using Dockerfile-dev and we are dealing with ezp 5.4 we'll need to replace xdebug.ini
if [ -d ezpublish ] && [ -f ${PHP_INI_DIR}/conf.d/xdebug.ini ]; then
    sed -i "s@/var/www/app/log@/var/www/ezpublish/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
fi

# EZP5: Prepare for eZ Publish legacy setup wizard if requested
if [ "$EZ_KICKSTART_TEMPLATE" != "" ]; then
    /scripts/generate_kickstart_file.sh $EZ_KICKSTART_TEMPLATE
fi

if [ "$DEV_MODE" = "true" ]; then
    APP_FOLDER="app"

    # EZP5: By default app folder is "app", but "ezpublish" is selected if found for bc.
    if [ -d ezpublish ]; then
        APP_FOLDER="ezpublish"
    fi

    if [ ! -d web/var ]; then
        echo "Creating web/var as it was missing"
        sudo -u ez mkdir -m 2775 web/var
    fi

    echo "Clearing cache directories '$APP_FOLDER/cache/*/*' so new settings gets picked up"
    rm -Rf $APP_FOLDER/cache/*/*

    if [ ! -d $APP_FOLDER/cache/$SYMFONY_ENV ]; then
        echo "Creating cache folder for $SYMFONY_ENV as it was missing"
        sudo -u ez mkdir -m 2775 $APP_FOLDER/cache/$SYMFONY_ENV
    fi

    if [ "$SYMFONY_ENV" != "dev" ] && [ "$SYMFONY_ENV" != "" ]; then
        echo "Re-generate symlink assets in case rsync was used so asstets added during setup wizards are reachable"
        sudo -u ez php $APP_FOLDER/console assetic:dump
    fi

    /scripts/set_permissions.sh --dev
else
    /scripts/set_permissions.sh
fi

# Start php-fpm
if [ -x /usr/local/sbin/php-fpm ]; then
    exec /usr/local/sbin/php-fpm
else
    exec /usr/sbin/php5-fpm
fi
