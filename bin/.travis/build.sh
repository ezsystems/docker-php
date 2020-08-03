#!/usr/bin/env sh

# Builds ez_php:latest and ez_php:latest-node locally to avoid issues when pushing.

set -e

if [ "$1" = "" ]; then
    echo "Argument 1 variable PHP_VERSION (and default tag) is not set, format: 7.0. Bailing out !"
    exit 1
fi

if [ "$2" = "" ]; then
    echo "Argument 2 variable NODE_VERSION (and default tag) is not set, format: 10. Bailing out !"
    exit 1
fi

PHP_VERSION="$1"
NODE_VERSION="$2"

# Build prod container
docker build --network=host --no-cache --rm=true --pull -f php/Dockerfile-${PHP_VERSION}  -t ez_php:latest php/

# Build container with Node (will extend ez_php:latest, hence why --pull is skipped)
docker build --network=host --no-cache --rm=true -f  php/Dockerfile-node${NODE_VERSION} -t ez_php:latest-node php/
