#!/bin/bash

set -e

# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-dev

function validateEnvironment
{
    if [ "$DOCKER_EMAIL" == "" ]; then
        echo "Environment variable DOCKER_EMAIL is not set. Bailing out !"
        exit 1
    fi
    if [ "$DOCKER_USERNAME" == "" ]; then
        echo "Environment variable DOCKER_USERNAME is not set. Bailing out !"
        exit 1
    fi
    if [ "$DOCKER_PASSWORD" == "" ]; then
        echo "Environment variable DOCKER_PASSWORD is not set. Bailing out !"
        exit 1
    fi
}

validateEnvironment

if [ "$1" == "" ]; then
    echo "Argument 1 variable REMOTE_IMAGE is not set, format: ezsystems/php. Bailing out !"
    exit 1
fi
if [ "$2" == "" ]; then
    echo "Argument 2 variable GIT_TAG is not set, format: v1.2.3. Bailing out !"
    exit 1
fi

REMOTE_IMAGE="$1"
GIT_TAG="$2"
PHP_VERSION=`docker -l error run ez_php:latest php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"`

docker images
docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

## TAGS

# "7.0"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}"
docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-dev"

# "7.0-v1.2.3"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}-${GIT_TAG}"
docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-${GIT_TAG}-dev"

# "7.0-v1.2"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}-${GIT_TAG%.[[:digit:]]}"
docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-${GIT_TAG%.[[:digit:]]}-dev"

# "7.0-v1"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}-${GIT_TAG%.[[:digit:]].[[:digit:]]}"
docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-${GIT_TAG%.[[:digit:]].[[:digit:]]}-dev"

# "latest" (optional)
if [ "$LATEST" == "$PHP_VERSION" ]; then
    docker tag ez_php:latest "${REMOTE_IMAGE}:latest"
fi


# "7.0.4"
#PHP_VERSION=`docker -l error run ez_php:latest php -r "echo PHP_VERSION;"`
#docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}"
#docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-dev"

echo Pushing docker image with all tags : ${REMOTE_IMAGE}
docker push "${REMOTE_IMAGE}"
