#!/bin/bash

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/functions

function dockerPush
{
    if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
        docker images
        docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
        echo docker push ${DOCKER_ACCOUNT}/${IMAGE_TAG}
        docker push ${DOCKER_ACCOUNT}/${IMAGE_TAG}
        result=$?
        if [ "$result" -eq 0 ]; then
            echo "Pushing image ${DOCKER_ACCOUNT}/${IMAGE_TAG} succeeded"
        else
            echo "Pushing image ${DOCKER_ACCOUNT}/${IMAGE_TAG} FAILED !!!"
            exit $result
        fi
    fi
}

generateDockerTag
dockerPush

