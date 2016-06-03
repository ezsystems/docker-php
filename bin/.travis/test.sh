#!/usr/bin/env sh

set -e
# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-dev
REUSE_VOLUME=0

## Parse arguments
for i in "$@"; do
case $i in
    --reuse-volume)
        REUSE_VOLUME=1
        ;;
    *)
        printf "Not recognised argument: ${i}, only supported argument is: --reuse-volume"
        exit 1
        ;;
esac
done

if [ "$SYMFONY_ENV" = "" ]; then
    SYMFONY_ENV="prod"
fi

if [ "$REUSE_VOLUME" = "0" ]; then
    printf "\n(Re-)Creating volumes/ezplatform for fresh checkout, needs sudo to delete old and chmod new folder"
    sudo rm -Rf volumes/ezplatform
    # Use mode here so this can be run on Mac
    mkdir -pm 0777 volumes/ezplatform

    if [ "$COMPOSER_HOME" = "" ]; then
        COMPOSER_HOME=~/.composer
    fi

    printf "\nBuilding on ez_php:latest, composer will implicit check requirements\n"
    docker run -ti --rm \
      -e SYMFONY_ENV \
      -v $(pwd)/volumes/ezplatform:/var/www \
      -v  $COMPOSER_HOME:/root/.composer \
      ez_php:latest \
      bash -c "composer create-project --no-dev --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www"
fi



printf "\nMinimal testing on ez_php:latest for use with ez user"
docker run -ti --rm \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ez_php:latest \
  bash -c "php testSymfonyRequirements.php"

printf "\nMinimal testing on ez_php:latest-dev for use with ez user"
docker run -ti --rm \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ez_php:latest-dev \
  bash -c "php testSymfonyRequirements.php"


printf "\nDetached testing on ez_php:latest with nginx"
docker run -d -v $(pwd)/volumes/ezplatform:/var/www --name ezphp ez_php:latest
docker exec -it ezphp php -v
#docker inspect --format '{{ .NetworkSettings.IPAddress }}' ezphp
# TODO: Run behat suite with defaults? Maybe when we have verified that it works with sqlite and
# TODO: php-internal-web-server, to avoid pulling in full docker-compose setup.
#       however like partially done here we need to make sure run.sh gets coverage
docker stop ezphp
docker rm ezphp
