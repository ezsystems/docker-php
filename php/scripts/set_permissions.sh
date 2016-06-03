#!/usr/bin/env sh
# Sets dev permissions using ACL, not really used anymore

set -e

set_permissions_www_data()
{
    local APP_FOLDER="app"
    if [ -d ezpublish ] &&  [ ! -d app ]; then
        APP_FOLDER="ezpublish"
    fi

    if [ ! -d web/var ]; then
        sudo -u www-data mkdir -m 2775 web/var
    fi

    # Support for cache and log dir being set by env var (you'll need to overload getCacheDir & getLogDir for this)
    if [ "$KERNEL_CACHE_DIR" = "" ]; then
        KERNEL_CACHE_DIR=${APP_FOLDER}/cache
    fi

    if [ "$KERNEL_LOGS_DIR" = "" ]; then
        KERNEL_LOGS_DIR=${APP_FOLDER}/logs
    fi

    setfacl -R -m u:www-data:rwX ${KERNEL_CACHE_DIR} ${KERNEL_LOGS_DIR} web/var
    setfacl -dR -m u:www-data:rwX ${KERNEL_CACHE_DIR} ${KERNEL_LOGS_DIR} web/var

    # eZ Publish 5.4 stuff
    if [ -d ezpublish/sessions ]; then
        setfacl -R -m u:www-data:rwX ezpublish/sessions
        setfacl -dR -m u:www-data:rwX ezpublish/sessions
    fi

    # eZ Publish 5.x needs access to write to config folder
    if [ -d ezpublish/config ]; then
        setfacl -R -m u:www-data:rwX ezpublish/config
        setfacl -dR -m u:www-data:rwX ezpublish/config
    fi

    # ezpublish-legacy stuff
    if [ -d ezpublish_legacy ]; then
        setfacl -R -m u:www-data:rwX ezpublish_legacy/design ezpublish_legacy/extension ezpublish_legacy/settings ezpublish_legacy/var
        setfacl -dR -m u:www-data:rwX ezpublish_legacy/design ezpublish_legacy/extension ezpublish_legacy/settings ezpublish_legacy/var
    fi
}

parse_commandline_arguments "$@"
validate_commandline_arguments

cd /var/www
set_permissions_www_data
cd - > /dev/null
