#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/functions


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
    if [ "$TRAVIS_BRANCH" == "" ]; then
        echo "Environment variable TRAVIS_BRANCH is not set. Bailling out !"
        exit 1
    fi
    # Docker image name is constructed like this : $IMAGE_ORGANIZATION/php:${TRAVIS_BRANCH|TRAVIS_TAG}. Example : ezsystems/php:7.0
    if [ "$IMAGE_ORGANIZATION" == "" ]; then
        echo "Environment variable IMAGE_ORGANIZATION is not set. Bailling out !"
        exit 1
    fi

}

function dockerBuild
{
    docker build --rm=true --pull -t ${IMAGE_ORGANIZATION}/${IMAGE_TAG} ezphp
}

function createVolumeDirectory
{
    mkdir -p volumes/ezplatform
    sudo chown 10000:10000 volumes/ezplatform
}

validateEnvironment
generateDockerTag
dockerBuild
createVolumeDirectory

