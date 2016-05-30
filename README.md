# About

This Git repository contains source code for [eZ Systems provided Docker PHP images avaiable on Docker Hub](https://hub.docker.com/r/ezsystems/php/) that in the future will be supported and recommended by [eZ Systems](http://ez.no/) for use with [eZ Platform](http://ezplatform.com/) and [eZ Studio](http://ezstudio.com/).

The Docker images here extends [official PHP images](https://hub.docker.com/_/php/) and includes php-cli, php-fpm, [composer](https://getcomposer.org/), [blackfire](https://blackfire.io/), tweaks and extensions for optimal use with any advance Symfony applications *(like eZ Platform and eZ Studio)*.


## Overview

This is part of our eZ Docker- Tools, currently in alpha, and hence docker hub
tags is in the format `ezsystems/php:7.0-v0`.

Aim is to reach stable sometime in second half of 2016, after a periode of extensive testing and feedback by community and partners.

By then it will technically support running:
- eZ Platform
- eZ Studio
- eZ Publish 5.4 *(might not be offically supported for php7, will either way require latest version)*
- Symfony *(As in any symfony-standard like app that have same or less requirements then eZ Platform)*

## Images

This repository contains several images for different versions of PHP\*:
- [7.0](php/Dockerfile-7.0) *(Will become the recommend version)*
- [5.6](php/Dockerfile-5.6)
- [5.5](php/Dockerfile-5.5)

\* *As we also use this for running functional testing of our software against several PHP versions.*

### Dev image

For each php version there is an addtional `-dev` flavour with addtional tools for when you need to be able to login and work towards the installation. It contains tools like vim, git, xdebug, ... [and others](php/Dockerfile-dev).


### Format version

To be able to improve the image in the future, we have added a format version number that we will increase on future changes *(for instance move to Alpine Linux)*. Current version number is `v0` signaling the image is in beta.

It is recommended to specificy a tag with this format version number in your Docker / docker-compose use to avoid breaks in your application.

## Roadmap

- PHP plugins:
 - memcached; *once [stable for 7.0](https://github.com/php-memcached-dev/php-memcached/releases)*
 - redis/predis
 - pdo_pgsql + pdo_sqlite
- env variable to set session handler
- Alpine Linux; *once all other official images exists with alpine flavours to make sure users are the same, and when blackfire supports it*

## Copyright & license
Copyright [eZ Systems AS](http://ez.no/), for copyright and license details see provided LICENSE file.
