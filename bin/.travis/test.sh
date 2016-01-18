#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/functions

generateDockerTag

docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/composer-auth.json:/home/ez/.composer/auth.json \
  ${DOCKER_ACCOUNT}/${IMAGE_TAG} \
  bash -c "composer create-project --no-dev --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www dev-master"

docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ${DOCKER_ACCOUNT}/${IMAGE_TAG} \
  bash -c "php testSymfonyRequirements.php"
