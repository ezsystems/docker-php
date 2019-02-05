#!/usr/bin/env sh

set -e

# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-node
# - ez_php:latest-dev

validateEnvironment()
{
    if [ "$DOCKER_USERNAME" = "" ]; then
        echo "Environment variable DOCKER_USERNAME is not set. Bailing out !"
        exit 1
    fi
    if [ "$DOCKER_PASSWORD" = "" ]; then
        echo "Environment variable DOCKER_PASSWORD is not set. Bailing out !"
        exit 1
    fi
}

validateEnvironment

if [ "$1" = "" ]; then
    echo "Argument 1 variable REMOTE_IMAGE is not set, format: ezsystems/php. Bailing out !"
    exit 1
fi

REMOTE_IMAGE="$1"
PHP_VERSION=`docker -l error run ez_php:latest php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"`
NODE_VERSION=`docker -l error run ez_php:latest-node node -e "console.log(process.versions.node)"` 

docker images
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

## TAGS
echo "About to tag remote image '${REMOTE_IMAGE}' with php version '${PHP_VERSION}' and Node '${NODE_VERSION}'"

# "7.0"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}"
docker tag ez_php:latest-node "${REMOTE_IMAGE}:${PHP_VERSION}-node"
docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-dev"

# "7.0-v0"
if [ "$2" != "" ]; then
    docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}-${2}"
    docker tag ez_php:latest-node "${REMOTE_IMAGE}:${PHP_VERSION}-${2}-node"
    docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-${2}-dev"
fi

# "latest" (optional)
if [ "$LATEST" = "$PHP_VERSION" ]; then
    docker tag ez_php:latest "${REMOTE_IMAGE}:latest"
fi


# "7.0.4"
#PHP_VERSION=`docker -l error run ez_php:latest php -r "echo PHP_VERSION;"`
#docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}"
#docker tag ez_php:latest-dev "${REMOTE_IMAGE}:${PHP_VERSION}-dev"

echo "Pushing docker image with all tags : ${REMOTE_IMAGE}"
docker push "${REMOTE_IMAGE}"
