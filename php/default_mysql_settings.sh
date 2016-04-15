#!/bin/bash

# usage : source /default_mysql_settings.sh

# This file sets the following environment variables if they do not already exists
# MYSQL_HOST="db"
# MYSQL_PORT="3306"
# MYSQL_DATABASE="ezp"
# MYSQL_USER="ezp"
# MYSQL_PASSWORD="youmaychangethis"

if [ "$MYSQL_HOST" == "" ]; then
    MYSQL_HOST="db"
fi

if [ "$MYSQL_PORT" == "" ]; then
    if [ "$DB_PORT_3306_TCP_PORT" == "" ]; then
        DB_PORT_3306_TCP_PORT=3306
    fi
    MYSQL_PORT="$DB_PORT_3306_TCP_PORT"
fi

if [ "$MYSQL_DATABASE" == "" ]; then
    MYSQL_DATABASE="ezp"
fi

if [ "$MYSQL_USER" == "" ]; then
    MYSQL_USER="ezp"
fi

if [ "$MYSQL_PASSWORD" == "" ]; then
    MYSQL_PASSWORD="youmaychangethis"
fi

export MYSQL_HOST MYSQL_PORT DB_PORT_3306_TCP_PORT MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD

