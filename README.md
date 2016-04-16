# About

Contains Docker PHP images that in the future will be supported and recommended by [eZ Systems](http://ez.no/)
for use with [eZ Platform](http://ezplatform.com/) and [eZ Studio](http://ezstudio.com/).

The Docker images here extends [official PHP images](https://hub.docker.com/_/php/) and includes php-cli, php-fpm, composer,
tweaks and extensions for optimal use with eZ Platform and eZ Studio, in addition several dev tools are included for convenience.


## Overview

This is part of our [ez-docker-tools](https://github.com/ezsystems/docker-tools), currently in beta, and hence images
here are tagged as v0.x.y.

Aim is to reach stable sometime in second half of 2016, after a periode of testing by community.

By then it will technically support running:
- eZ Platform
- eZ Studio
- eZ Publish 5.4 *(might not be supported for php7, will require latest version)*
- Symfony *(As in any symfony-standard like app that have same or less requirements)*

## Images

This repository contains several images for different versions of PHP\*:
- [7.0](php/Dockerfile-7.0) *(Will become the recommend version)*
- [5.6](php/Dockerfile-5.6)
- [5.5](php/Dockerfile-5.5)

\* *As we also use this for running functional testing of our software against several PHP versions.*

## Copyright & license
Copyright [eZ Systems AS](http://ez.no/), for copyright and license details see provided LICENSE file.
