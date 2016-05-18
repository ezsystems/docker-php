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

    echo "Clearing cache '$APP_FOLDER/cache/*/*' to make sure env variables are taken into account for settings"
    rm -Rf $APP_FOLDER/cache/*/*

    if [ ! -f auth.json ] && [ ! -f ${COMPOSER_HOME}/auth.json ]; then
        echo "WARNING: No auth.json in project dir or in composer home dir, composer install might take longer or fail!"
    fi

    echo "Run composer post-install-cmd with correct env in case it changed; for cache clear/warmup & asset dump"
    composer run-script --no-interaction post-install-cmd

    # Will set ez as owner of the newly generated files
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
