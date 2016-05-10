#!/bin/bash

# Builds ez_php:latest and ez_php:latest-dev locally to avoid issues when pushing.

set -e

if [ "$1" == "" ]; then
    echo "Argument 1 variable PHP_VERSION (and default tag) is not set, format: 7.0. Bailing out !"
    exit 1
fi

PHP_VERSION="$1"

# Build prod container
docker build --rm=true --pull -f php/Dockerfile-${PHP_VERSION}  -t ez_php:latest php/

# Build expanded dev container (will extend ez_php:latest, hence why --pull is skipped)
docker build --rm=true -f php/Dockerfile-dev  -t ez_php:latest-dev php/
