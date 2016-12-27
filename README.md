# PHP Docker image for use with eZ Platform

> **Beta**: Instructions and Tools in this repository is currently in Beta for community testing & contribution, and might change without notice.
> See [online Docker Tools documentation](https://doc.ez.no/display/DEVELOPER/Docker+Tools) for known issues and further information.


This Git repository contains source code for eZ Systems provided Docker PHP images [avaiable on Docker Hub](https://hub.docker.com/r/ezsystems/php/) that in the future will be supported and recommended by [eZ Systems](http://ez.no/) for use with [eZ Platform](http://ezplatform.com/) and [eZ Studio](http://ezstudio.com/).

The Docker images here extends [official PHP images](https://hub.docker.com/_/php/) and includes php-cli, php-fpm, [composer](https://getcomposer.org/), [blackfire](https://blackfire.io/), tweaks and extensions for optimal use with any advance Symfony applications *(like eZ Platform and eZ Studio)*.


## Overview

PHP image that aims to technically support running:
- eZ Platform
- eZ Studio
- eZ Publish 5.4 *(might not be officially supported for php7, will either way require latest version)*
- Symfony *(As in any symfony-standard like app that have same or less requirements then eZ Platform)*

## Images

This repository contains several images for different versions of PHP\*:
- [7.1](php/Dockerfile-7.1) *(Recommended version for testing newest versions of eZ Platform)*
- [7.0](php/Dockerfile-7.0)
- [5.6](php/Dockerfile-5.6)
- [5.5](php/Dockerfile-5.5) *(EOL, so only meant for compatibility testing for older maintenance releases)*

-\* *Primarily: Since this is also used to run functional testing against several PHP versions, for any other usage use the recommended image.*

### Dev image

For each php version there is an additional `-dev` flavour with additional tools for when you need to be able to login and work towards the installation. It contains tools like vim, git, xdebug, ... [and others](php/Dockerfile-dev).


### Format version

To be able to improve the image in the future, we have added a format version number that we will increase on future changes *(for instance move to Alpine Linux)*. Current version number is `v0` signaling the image is in beta.

It is recommended to specificy a tag with this format version number in your Docker / docker-compose use to avoid breaks in your application.


## Usage

This image has been made so it can be used directly for development and built with your application for production use, this
allows you to use the same image across all whole DevOps life cycle *(dev, build, testing, staging and production)*.

Before you start, you can test the image to see if you get which php version it is running:
```bash
docker run --rm ezsystems/php:7.0-v0 php -v
```

This should result in something like:
```
PHP 7.0.6 (cli) (built: May  4 2016 04:48:45) ( NTS )
Copyright (c) 1997-2016 The PHP Group
Zend Engine v3.0.0, Copyright (c) 1998-2016 Zend Technologies
    with blackfire v1.10.5, https://blackfire.io, by Blackfireio Inc.
```

### Production use

In your application folder, you'll need to add a `Dockerfile` where you customize it, including adding your application.
For example see for instance [Dockerfile in ezsystems/ezplatform](https://github.com/ezsystems/ezplatform/blob/master/Dockerfile).


Then for building it you can for instance execute:
```bash
docker build -t mycompany/myapp_volume:latest .
```

And by now you can execute some *(see below to attach database, ..)* commands to test it:
```bash
docker run --rm mycompany/myapp_volume app/console list
```

### Development use

*Warning: As of December 2016, avoid using Docker for Mac beta for this setup, as it's load times are typically 60-90 seconds because of IO issues way worse then what Virtualbox ever had when doing shared folder. Which is essentially what is being used here when not on Linux, and when using what Docker calls host mounted volumes.*

To get started, lets set permissions for dev use, and make sure to install composer packages:
```bash
sudo mkdir -p web/var
sudo find {app/{cache,logs},web/var} -type d | xargs sudo chmod -R 777
sudo find {app/{cache,logs},web/var} -type f | xargs sudo chmod -R 666
docker run --rm -u www-data -v `pwd`:/var/www -e SYMFONY_ENV=dev ezsystems/php:7.0-v0 composer install --no-progress --no-interaction --prefer-dist
```


Now you can run some *(see below to attach database, ..)* commands to test it:
```bash
docker run --rm -u www-data -v `pwd`:/var/www -e SYMFONY_ENV=dev ezsystems/php:7.0-v0 app/console list
```


### Use with full setup (database, ..)

For setting up a full setup with database and so on, see [ezplatform:doc/docker-compose](https://github.com/ezsystems/ezplatform/tree/master/doc/docker-compose) for further examples and instructions.


## Roadmap for this PHP image

- PHP plugins:
 - memcached; *once [stable for 7.0](https://github.com/php-memcached-dev/php-memcached/releases)* OR
 - redis/predis
 - pdo_pgsql + pdo_sqlite
- env variable to set session handler, ...
- Alpine Linux; *To drop image size, once all other official images exists with alpine flavours, and when blackfire supports it*

## Copyright & license
Copyright [eZ Systems AS](http://ez.no/), for copyright and license details see provided LICENSE file.
