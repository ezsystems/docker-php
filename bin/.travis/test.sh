#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/functions

function createVolumeDirectory
{
    if [ -d volumes/ezplatform ]; then
        sudo rm -Rf volumes/ezplatform
    fi
    mkdir -p volumes/ezplatform
    sudo chown 10000:10000 volumes/ezplatform
}

function dockerPush
{
    # We'll only push to docker hub if we are processing a tag
    if [ "$TRAVIS_TAG" != "" ]; then
        docker images
        docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
        echo Pushing docker image : ${IMAGE_ORGANIZATION}/${IMAGE_TAG}
        docker push ${IMAGE_ORGANIZATION}/${IMAGE_TAG}
        echo "Pushing image ${IMAGE_ORGANIZATION}/${IMAGE_TAG} succeeded"
    else
        echo "Not processing a git tag, skipped push to docker hub"
    fi
}

generateDockerTag
createVolumeDirectory

docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/composer-auth.json:/home/ez/.composer/auth.json \
  ${IMAGE_ORGANIZATION}/${IMAGE_TAG} \
  bash -c "composer create-project --no-dev --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www dev-master"

docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ${IMAGE_ORGANIZATION}/${IMAGE_TAG} \
  bash -c "php testSymfonyRequirements.php"

dockerPush
