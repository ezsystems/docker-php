#!/bin/bash

set -e

function validateEnvironment
{
    if [ "$DOCKER_EMAIL" == "" ]; then
        echo "Environment variable DOCKER_EMAIL is not set. Bailling out !"
        exit 1
    fi
    if [ "$DOCKER_USERNAME" == "" ]; then
        echo "Environment variable DOCKER_USERNAME is not set. Bailling out !"
        exit 1
    fi
    if [ "$DOCKER_PASSWORD" == "" ]; then
        echo "Environment variable DOCKER_PASSWORD is not set. Bailling out !"
        exit 1
    fi
}

validateEnvironment

if [ "$1" == "" ]; then
    echo "Argument 1 variable IMAGE_NAME is not set, format: ezsystems/php. Bailling out !"
    exit 1
fi
if [ "$2" == "" ]; then
    echo "Argument 2 variable PHP_VERSION (and default tag) is not set, format: 7.0. Bailling out !"
    exit 1
fi
if [ "$3" == "" ]; then
    echo "Argument 3 variable GIT_TAG is not set, format: v1.2.3. Bailling out !"
    exit 1
fi

IMAGE_NAME="$1"
PHP_VERSION="$2"
GIT_TAG="$3"


##  Image in an existing tag we will also push
IMAGE_TAG="${IMAGE_NAME}:${PHP_VERSION}"


docker images
docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"


## TAGS

# "7.0-v1.2.3"
docker tag ${IMAGE_TAG} "${IMAGE_NAME}:${PHP_VERSION}-${GIT_TAG}"

# "7.0-v1.2"
docker tag ${IMAGE_TAG} "${IMAGE_NAME}:${PHP_VERSION}-${GIT_TAG%.[[:digit:]]}"

# "7.0-v1"
docker tag ${IMAGE_TAG} "${IMAGE_NAME}:${PHP_VERSION}-${GIT_TAG%.[[:digit:]].[[:digit:]]}"

# "latest" (optional)
if [ "$LATEST" == "$PHP_VERSION" ]; then
    docker tag ${IMAGE_TAG} "latest"
fi


# "7.0.4"
#PHP_VERSION=docker run ${IMAGE_NAME} php "-r 'echo PHP_VERSION;'"
#docker tag ${IMAGE_TAG} "${IMAGE_NAME}:${PHP_VERSION}"

echo Pushing docker image with all tags : ${IMAGE_NAME}
docker push "${IMAGE_NAME}"
