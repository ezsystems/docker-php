#!/bin/bash

# Copy and prepare behat config if selenium is present
if [ "$SELENIUM_PORT_4444_TCP_ADDR" != "" ]; then
    cp -f behat.yml.dist behat.yml
    sed -i "s@wd_host: 'http://localhost:4444/@wd_host: 'http://selenium:4444/@" behat.yml
    sed -i "s@http://localhost@http://web@" behat.yml
fi


