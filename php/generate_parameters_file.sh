#!/bin/bash
# Reconfigured parameters.yml on every startup on docker as config might change while volume stays the same

echo "Re-configuring parameters.yml"

function generate_secret
{
    local secret
    secret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32|head -n 1)
    echo $secret
}

SECRET=`generate_secret`

APP_FOLDER="app"
if [ -d ezpublish ]; then
    APP_FOLDER="ezpublish"
fi

source /default_mysql_settings.sh

sed -i "s@secret:.*@secret: $SECRET@" $APP_FOLDER/config/parameters.yml
sed -i "s@database_driver:.*@database_driver: pdo_mysql@" $APP_FOLDER/config/parameters.yml
sed -i "s@database_port:.*@database_port: $MYSQL_PORT@" $APP_FOLDER/config/parameters.yml
sed -i "s@database_host:.*@database_host: $MYSQL_HOST@" $APP_FOLDER/config/parameters.yml
sed -i "s@database_name:.*@database_name: $MYSQL_DATABASE@" $APP_FOLDER/config/parameters.yml
sed -i "s@database_user:.*@database_user: $MYSQL_USER@" $APP_FOLDER/config/parameters.yml
sed -i "s@database_password:.*@database_password: $MYSQL_PASSWORD@" $APP_FOLDER/config/parameters.yml





if [ "$EZ_MAILER_TRANSPORT" != "" ]; then
    sed -i "s@mailer_transport:.*@mailer_transport: $EZ_MAILER_TRANSPORT@" $APP_FOLDER/config/parameters.yml
fi

if [ "$EZ_MAILER_HOST" != "" ]; then
    sed -i "s@mailer_host:.*@mailer_host: $EZ_MAILER_HOST@" $APP_FOLDER/config/parameters.yml
fi

if [ "$EZ_MAILER_USER" != "" ]; then
    sed -i "s@mailer_user:.*@mailer_user: $EZ_MAILER_USER@" $APP_FOLDER/config/parameters.yml
fi

if [ "$EZ_MAILER_PASSWORD" != "" ]; then
    sed -i "s@mailer_password:.*@mailer_password: $EZ_MAILER_PASSWORD@" $APP_FOLDER/config/parameters.yml
fi


if [ "$SOLR_PORT_8983_TCP_ADDR" != "" ]; then
    sed -i "s@search_engine:.*@search_engine: solr@" $APP_FOLDER/config/parameters.yml
    sed -i "s@solr_dsn:.*@solr_dsn: http://$SOLR_PORT_8983_TCP_ADDR:8983/solr@" $APP_FOLDER/config/parameters.yml
else
    sed -i "s@search_engine:.*@search_engine: legacy@" $APP_FOLDER/config/parameters.yml
fi

cat $APP_FOLDER/config/parameters.yml
