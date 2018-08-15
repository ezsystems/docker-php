# Example of PHP Docker image for use with eZ Platform

> **Example/Internal**: Instructions and Tools in this repository is provided as an example, which you can take and customize to your needs if you want to. This is something we use activly internally for QA and Demo use, and thus might change without notice _(we version the images, but only latests version receives updates)_.
>
> If you are looking to have a ready made Docker environment for local development see [eZ Launchpad](https://ezsystems.github.io/launchpad/)
>
> If you are looking for ready made, optimized, development and production hosted environment see [eZ Platform Cloud](https://ez.no/Blog/We-Are-Launching-eZ-Platform-Cloud-Speeding-Up-Development-of-Your-Projects)


This Git repository contains source code for eZ Systems provided Docker PHP images [available on Docker Hub](https://hub.docker.com/r/ezsystems/php/).

The Docker images here extends [official PHP images](https://hub.docker.com/_/php/) and includes php-cli, php-fpm, [composer](https://getcomposer.org/), [blackfire](https://blackfire.io/), tweaks and extensions for optimal use with any advance Symfony applications *(like eZ Platform and eZ Platform EE)*.

_NOTE: The images here, just like the official once they extend, are meant to follow Dockers 1 main process per container recommendation from Docker, adding additional services to the image is not recommended and probably won't work. If so start from scratch with something else instead of using this._


## Overview

PHP image that aims to technically support running:
- eZ Platform
- eZ Platform EE
- eZ Publish 5.4 *(5.4.11 or higher)*
- Symfony *(As in any symfony-standard like app that have same or less requirements then eZ Platform)*

## Images

This repository contains several images for different versions of PHP\*:
- [7.2](php/Dockerfile-7.2) *(NOTE: Based on debian:stretch-slim and not jessie like the others atm in v1 format)*
- [7.1](php/Dockerfile-7.1)
- [7.0](php/Dockerfile-7.0)
- [5.6](php/Dockerfile-5.6) *(Security fixes only, time to start to move to PHP7)*
- ~~[5.5](php/Dockerfile-5.5) *(End of Life, so only meant for compatibility testing for older maintenance releases)*~~

_Recommended version for testing newest versions of eZ Platform is PHP 7.2 for best performance, however if you are currently on jessie based images (5.5-7.1) then aiming to get to PHP 7.1 is a good choice too._

\* *Primarily: Since this is also used to run functional testing against several PHP versions, for any other usage use the recommended image.*

### Dev image

For each php version there is an additional `-dev` flavour with additional tools for when you need to be able to login and work towards the installation. It contains tools like vim, git, xdebug, ... [and others](php/Dockerfile-dev).


### Format version

To be able to improve the image in the future, we have added a format version number that we will increase on future changes *(for instance move to Alpine Linux)*.

It is recommended to specify a tag with this format version number in your Docker / docker-compose use to avoid breaks in your application.


## Usage

This image has been made so it can be used directly for development and built with your application for production use, this
allows you to use the same image across all whole DevOps life cycle *(dev, build, testing, staging and production)*.

Before you start, you can test the image to see if you get which php version it is running:
```bash
docker run --rm ezsystems/php:7.2 php -v
```

This should result in *something* like:
```
PHP 7.2.8 (cli) (built: Jul 21 2018 07:56:11) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.2.0, Copyright (c) 1998-2018 Zend Technologies
    with Zend OPcache v7.2.8, Copyright (c) 1999-2018, by Zend Technologies
    with blackfire v1.22.0~linux-x64-non_zts72, https://blackfire.io, by Blackfire
```

### Production use

In your application folder, you'll need to add a `Dockerfile` where you customize it, including adding your application.
For example see for instance [Dockerfile in ezsystems/ezplatform](https://github.com/ezsystems/ezplatform/blob/master/doc/docker/Dockerfile-app).


Then for building it you can for instance execute:
```bash
docker build -t mycompany/myapp_volume:latest .
```

And by now you can execute some *(see below to attach database, ..)* commands to test it:
```bash
docker run --rm mycompany/myapp_volume bin/console list
```

### Development use

*Warning: As of December 2016, avoid using Docker for Mac/Windows beta for this setup, as it's load times are typically 60-90 seconds because of IO issues way worse then what Virtualbox ever had when doing shared folder. Which is essentially what is being used here when not on Linux, and when using what Docker calls host mounted volumes.*

To get started, lets set permissions for dev use _(Symfony 3.x structure reflected in example)_, and make sure to install composer packages:
```bash
sudo mkdir -p web/var
sudo find web/var var -type d | xargs sudo chmod -R 777
sudo find web/var var -type f | xargs sudo chmod -R 666
docker run --rm -u www-data -v `pwd`:/var/www -e SYMFONY_ENV=dev ezsystems/php:7.2 composer install --no-progress --no-interaction --prefer-dist
```


Now you can run some *(see below to attach database, ..)* commands to test it:
```bash
docker run --rm -u www-data -v `pwd`:/var/www -e SYMFONY_ENV=dev ezsystems/php:7.2 bin/console list
```


### Use with full setup (database, ..)

For setting up a full setup with database and so on, see [ezplatform:doc/docker](https://github.com/ezsystems/ezplatform/tree/master/doc/docker) for further examples and instructions.


## Possible roadmap for this PHP image

- PHP plugins:
 - pdo_pgsql + pdo_sqlite
- env variable to set session handler, ...
- Apache + mod_php variant
- Alpine Linux; *To drop image size, assuming all other official images move to Alpine, incl when blackfire supports it.*

## Copyright & license
Copyright [eZ Systems AS](http://ez.no/), for copyright and license details see provided LICENSE file.
