#!/bin/bash

#This script contains code for waiting for mysql db to get up

# Let's try to connect to db for 2 minutes ( 24 * 5 sec intervalls )
MAXTRY=24

function waitForDatabaseToGetUp
{
    local DBUP
    local TRY
    DBUP=false
    TRY=1
    while [ $DBUP == "false" ]; do
        echo "Checking if mysql is up yet, attempt :$TRY"
        echo "show databases" | mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -h $MYSQL_HOST > /dev/null && DBUP="true"

        let TRY=$TRY+1
        if [ $TRY -eq $MAXTRY ]; then
            echo Max limit reached. Not able to connect to mysql. Running installer will likely fail
            exit 1
        else
            sleep 5;
        fi
    done
}


source /default_mysql_settings.sh
waitForDatabaseToGetUp
