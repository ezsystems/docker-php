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



printf "\Integration: Behat testing on ez_php:latest and ez_php:latest-dev with eZ Platform"
export COMPOSE_FILE="doc/docker-compose/base-prod.yml:doc/docker-compose/selenium.yml" SYMFONY_ENV="behat" SYMFONY_DEBUG="1" PHP_IMAGE="ez_php:latest" PHP_IMAGE_DEV="ez_php:latest-dev"
git clone --depth 1 --single-branch --branch master https://github.com/ezsystems/ezplatform.git
cd ezplatform

docker-compose -f doc/docker-compose/install.yml up --abort-on-container-exit

docker-compose up -d
docker-compose exec --user www-data app sh -c "php /scripts/wait_for_db.php; php bin/behat -vv --profile=rest --suite=fullJson --tags=~@broken"
docker-compose down -v
