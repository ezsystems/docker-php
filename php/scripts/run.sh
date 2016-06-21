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
    if [ ! -d web/var ]; then
        echo "Creating web/var as it was missing"
        mkdir -m 2775 web/var && chown www-data -R web/var
    fi

    echo "Deleting container to make sure environment variables are picked up"
    if [ -d bin/cache ]; then
        rm bin/cache/*/*ProjectContainer.php
    elif [ -d ezpublish/cache ]; then
        rm ezpublish/cache/*/*ProjectContainer.php
    else
        rm app/cache/*/*ProjectContainer.php
    fi
fi

# Start php-fpm
if [ -x /usr/local/sbin/php-fpm ]; then
    exec /usr/local/sbin/php-fpm
else
    exec /usr/sbin/php5-fpm
fi
