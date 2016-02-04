#!/bin/bash

# Let's try to connect to db for 2 minutes ( 24 * 5 sec intervalls )
MAXTRY=24

cd /var/www


function prevent_multiple_execuition
{
    if [ -f /tmp/prepare_distribution_already_run.txt ]; then
        echo "Script has already been executed. Bailling out"
        exit
    fi
    sudo -u ez touch /tmp/prepare_distribution_already_run.txt
}

function getIndexScript
{
    if [ -f /var/www/web/index.php ]; then
        INDEX_SCRIPT=/var/www/web/index.php
    else
        INDEX_SCRIPT=/var/www/web/app.php
    fi
}

# $1 is description
function set_splash_screen
{
    if [ ! -f "${INDEX_SCRIPT}.org" ]; then
        sudo -u ez mv ${INDEX_SCRIPT} ${INDEX_SCRIPT}.org
    fi
    sudo -u ez echo "<html><body>$1</body></html>" > ${INDEX_SCRIPT}
}

function remove_splash_screen
{
    sudo -u ez mv ${INDEX_SCRIPT}.org ${INDEX_SCRIPT}
}

function set_permissions
{
    if [ "aa$APACHE_RUN_USER" == "aa" ]; then
        APACHE_RUN_USER=www-data
    fi

    if [ ! -d web/var ]; then
        sudo -u ez mkdir web/var
    fi

    if [ -d ezpublish ]; then
        setfacl -R -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX ezpublish/{cache,logs,sessions} web/var
        setfacl -dR -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX ezpublish/{cache,logs,sessions} web/var
    else
        setfacl -R -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX app/{cache,logs} web/var
        setfacl -dR -m u:$APACHE_RUN_USER:rwX -m u:ez:rwX app/{cache,logs} web/var
    fi

    if [ -d ezpublish_legacy ]; then
        setfacl -R -m u:$APACHE_RUN_USER:rwx -m u:ez:rwx ezpublish_legacy/{design,extension,settings,var} ezpublish/config web
        setfacl -dR -m u:$APACHE_RUN_USER:rwx -m u:ez:rwx ezpublish_legacy/{design,extension,settings,var} ezpublish/config web
    fi
}

function import_database
{
    local DBUP
    local TRY
    DBUP=false
    TRY=1
    while [ $DBUP == "false" ]; do
        echo Contacting mysql, attempt :$TRY
        set_splash_screen "Waiting for db connection"
        echo "ALTER DATABASE $MYSQL_DATABASE CHARACTER SET utf8 COLLATE utf8_general_ci" | mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -h db && DBUP="true"
        if [ $DBUP == "true" ]; then
            DBUP=false
            echo "Importing database"
            set_splash_screen "Importing database"
            sudo -u ez mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -h db< /dbdump/ezp.sql && DBUP="true"
        fi

        if [ $DBUP == "false" ]; then
            echo "Attempt $TRY failed. Waiting for db connection"
            set_splash_screen "Attempt $TRY failed. Waiting for db connection"
        else
            echo "Database import succeeded"
        fi
        let TRY=$TRY+1
        if [ $TRY -eq $MAXTRY ]; then
            echo Max limit reached. Not able to connect to mysql
            sudo -u ez rm /tmp/prepare_distribution_already_run.txt
            exit 1;
        fi
        sleep 5;
    done
}

function warm_cache
{
    APP_FOLDER="app"
    if [ -d ezpublish ]; then
        APP_FOLDER="ezpublish"
    fi
    sudo -u ez php $APP_FOLDER/console cache:warmup --env=$EZ_ENVIRONMENT
}

prevent_multiple_execuition
getIndexScript
set_splash_screen "Initializing"
set_permissions
set_splash_screen "Waiting for db connection"
import_database

if [ "$WARM_CACHE" != "false" ]; then
    set_splash_screen "Warming cache"
    warm_cache
fi

remove_splash_screen

cd - > /dev/null

