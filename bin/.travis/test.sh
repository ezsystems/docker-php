#!/bin/bash

set -e

if [ "$1" == "" ]; then
    echo "Argument 1 for image tag missing. Bailling out !"
    exit 1
fi

IMAGE_TAG="$1"

if [ -d volumes/ezplatform ]; then
    sudo rm -Rf volumes/ezplatform
fi

mkdir -p volumes/ezplatform
sudo chown 10000:10000 volumes/ezplatform

docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  ${IMAGE_TAG} \
  sh -c "composer config -g github-oauth.github.com \"d0285ed5c8644f30547572ead2ed897431c1fc09\"; \
           composer create-project --no-dev --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www"

docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ${IMAGE_TAG} \
  sh -c "php testSymfonyRequirements.php"

# TODO: Run behat suite with defaults? Maybe when we have verified that it works with sqlite and
# TODO: php-internal-web-server, to avoid pulling in full docker-compose setup.
