#!/usr/bin/env sh

set -e

cd /var/www

prevent_multiple_execution()
{
    if [ -f /tmp/prepare_distribution_already_run.txt ]; then
        echo "Script has already been executed. Bailling out"
        exit
    fi
    sudo -u ez touch /tmp/prepare_distribution_already_run.txt
}

# $1 is description
set_splash_screen()
{
    if [ ! -f "${INDEX_SCRIPT}.org" ]; then
        mv ${INDEX_SCRIPT} ${INDEX_SCRIPT}.org
    fi
    echo "<html><body>$1</body></html>" > ${INDEX_SCRIPT}
}

remove_splash_screen()
{
    mv ${INDEX_SCRIPT}.org ${INDEX_SCRIPT}
}

prevent_multiple_execution


if [ -f /var/www/web/index.php ]; then
    INDEX_SCRIPT=/var/www/web/index.php
else
    INDEX_SCRIPT=/var/www/web/app.php
fi

set_splash_screen "Waiting for db connection"

./scripts/wait_for_db.php

remove_splash_screen

cd - > /dev/null
