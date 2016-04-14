#!/bin/bash

set -e

# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-dev

echo "(Re-)Creating volumes/ezplatform for fresh checkout, needs sudo to set UID/GID"
if [ -d volumes/ezplatform ]; then
    sudo rm -Rf volumes/ezplatform
fi

mkdir -p volumes/ezplatform
sudo chown 10000:10000 volumes/ezplatform

echo "Building on ez_php:latest, composer will implicit check requirements"
docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  ez_php:latest \
  bash -c "composer config -g github-oauth.github.com \"d0285ed5c8644f30547572ead2ed897431c1fc09\"; \
           composer create-project --no-dev --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www"

echo "Minimal testing on ez_php:latest"
docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ez_php:latest \
  bash -c "php testSymfonyRequirements.php"

echo "Minimal testing on ez_php:latest-dev"
docker run -ti --rm --user=ez \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ez_php:latest-dev \
  bash -c "php testSymfonyRequirements.php"

# TODO: Run behat suite with defaults? Maybe when we have verified that it works with sqlite and
# TODO: php-internal-web-server, to avoid pulling in full docker-compose setup.
