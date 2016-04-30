#!/usr/bin/env sh

set -e

PARAM_DEV="false"
PARAM_IMMUTABLE="false"

usage()
{
    # General help text
    cat << EOF
Script for setting ownership and permissions inside eZ Platform containers

By default set permission and ownership of the files the web server needs write access to ( var/web/www, app/cache etc ).
With options additional rights on the whole installation can be set as well.

Help (this text):
/set_permissions.sh [-h|--help]

Usage:
/set_permissions.sh [ options ]...

Options:

  [--dev]            : Set permission and ownership for development use. All source files will to be writable by ez user.
  [--immutable]      : Set permission and ownership for immutable production use. All source files to be owned by root.
  [-h|--help]        : This help screen

EOF
}


parse_commandline_arguments()
{
    # Based on http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash, comment by Shane Day answered Jul 1 '14 at 1:20
    while [ -n "$1" ]; do
        # Copy so we can modify it (can't modify $1)
        OPT="$1"
        # Detect argument termination
        if [ x"$OPT" = x"--" ]; then
            shift
            for OPT ; do
                REMAINS="$REMAINS \"$OPT\""
            done
            break
        fi
        # Parse current opt
        while [ x"$OPT" != x"-" ] ; do
            case "$OPT" in
                # Handle --flag=value opts like this
                -h | --help )
                    usage
                    exit 0
                    ;;
                --dev )
                    PARAM_DEV="true"
                    ;;
                --immutable )
                    PARAM_IMMUTABLE="true"
                    ;;
                # Anything unknown is recorded for later
                * )
                    REMAINS="$REMAINS \"$OPT\""
                    break
                    ;;
            esac
            # Check for multiple short options
            # NOTICE: be sure to update this pattern to match valid options
            NEXTOPT="${OPT#-[st]}" # try removing single short opt
            if [ x"$OPT" != x"$NEXTOPT" ] ; then
                OPT="-$NEXTOPT"  # multiple short opts, keep going
            else
                break  # long form, exit inner loop
            fi
        done
        # Done with that param. move to next
        shift
    done
    # Set the non-parameters back into the positional parameters ($1 $2 ..)
    eval set -- $REMAINS
}

validate_commandline_arguments()
{
    if [ "$PARAM_DEV" = "true" ] && [ "$PARAM_IMMUTABLE" = "true" ]; then
        usage
        echo "Error : You cannot provide both --dev and --immutable at the same time"
    fi
}

set_permissions_dev()
{
    if [ "$PARAM_DEV" = "true" ]; then
        chmod a+w -R /var/www
        chown ez:ez -R /var/www
    fi

    # ezpublish 5.x needs access to write to config folder
    if [ -d ezpublish/config ]; then
        chown :www-data -R ezpublish/config
        chmod 775 ezpublish/config
        chmod 664 ezpublish/config/*
    fi
}

set_permissions_immutable()
{
    if [ "$PARAM_IMMUTABLE" = "true" ]; then
        chmod og-w -R /var/www
        chown root:root -R /var/www
    fi
}

set_permissions_www_data()
{
    local APP_FOLDER
    APP_FOLDER="app"
    if [ -d ezpublish ]; then
        APP_FOLDER="ezpublish"
    fi

    if [ ! -d web/var ]; then
        sudo -u ez mkdir -m 2775 web/var
    fi

    setfacl -R -m u:www-data:rwX -m u:ez:rwX ${APP_FOLDER}/cache ${APP_FOLDER}/logs web/var
    setfacl -dR -m u:www-data:rwX -m u:ez:rwX ${APP_FOLDER}/cache ${APP_FOLDER}/logs web/var

    # eZ Publish 5.4 stuff
    if [ -d ezpublish/sessions ]; then
        setfacl -R -m u:www-data:rwX -m u:ez:rwX ezpublish/sessions
        setfacl -dR -m u:www-data:rwX -m u:ez:rwX ezpublish/sessions
    fi

    # ezpublish-legacy stuff
    if [ -d ezpublish_legacy ]; then
        setfacl -R -m u:www-data:rwX -m u:ez:rwX ezpublish_legacy/design ezpublish_legacy/extension ezpublish_legacy/settings ezpublish_legacy/var
        setfacl -dR -m u:www-data:rwX -m u:ez:rwX ezpublish_legacy/design ezpublish_legacy/extension ezpublish_legacy/settings ezpublish_legacy/var
    fi
}

parse_commandline_arguments "$@"
validate_commandline_arguments

cd /var/www
set_permissions_dev
set_permissions_immutable
set_permissions_www_data
cd - > /dev/null
