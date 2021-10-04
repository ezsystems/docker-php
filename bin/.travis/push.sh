#!/usr/bin/env sh

set -e

# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-node

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

if [ "$2" = "" ]; then
    echo "Argument 2 variable VERSION_FORMAT is not set, format: ezsystems/php. Bailing out !"
    exit 1
fi

REMOTE_IMAGE="$1"
VERSION_FORMAT="$2"

PHP_VERSION=`docker -l error run ez_php:latest php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"`
NODE_VERSION=`docker -l error run ez_php:latest-node node -e "console.log(process.versions.node)"` 
NODE_VERSION=`echo $NODE_VERSION | cut -f 1 -d "."`

docker images
echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

## TAGS
echo "About to tag remote image '${REMOTE_IMAGE}' with php version '${PHP_VERSION}' and Node '${NODE_VERSION}'"

# "7.0"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}"
docker tag ez_php:latest-node "${REMOTE_IMAGE}:${PHP_VERSION}-node${NODE_VERSION}"

# "7.0-v0"
docker tag ez_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}-${VERSION_FORMAT}"
docker tag ez_php:latest-node "${REMOTE_IMAGE}:${PHP_VERSION}-${VERSION_FORMAT}-node${NODE_VERSION}"

# "latest" (optional)
if [ "$LATEST_PHP" = "$PHP_VERSION" ]; then
    docker tag ez_php:latest "${REMOTE_IMAGE}:latest"
    docker tag ez_php:latest-node "${REMOTE_IMAGE}:latest-node${NODE_VERSION}"
    if [ "$LATEST_NODE" = "$NODE_VERSION" ]; then
        docker tag ez_php:latest-node "${REMOTE_IMAGE}:latest-node"
    fi
fi

echo "Pushing docker image with all tags : ${REMOTE_IMAGE}"
docker push --all-tags "${REMOTE_IMAGE}"
