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

if [ "$FORMAT_VERSION" = "" ]; then
    FORMAT_VERSION="v1"
fi

if [ "$EZ_VERSION" = "" ]; then
    EZ_VERSION="@alpha"
fi


if [ "$REUSE_VOLUME" = "0" ]; then
    printf "\n(Re-)Creating volumes/ezplatform for fresh checkout, needs sudo to delete old and chmod new folder\n"
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
      bash -c "composer create-project --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www $EZ_VERSION"
fi



printf "\nMinimal testing on ez_php:latest for use with ez user\n"
docker run -ti --rm \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ez_php:latest \
  bash -c "php testSymfonyRequirements.php"


printf "\nMinimal testing on ez_php:latest-dev for use with ez user\n"
docker run -ti --rm \
  -v $(pwd)/volumes/ezplatform:/var/www \
  -v $(pwd)/bin/.travis/testSymfonyRequirements.php:/var/www/testSymfonyRequirements.php \
  ez_php:latest-dev \
  bash -c "php testSymfonyRequirements.php"


printf "\Integration: Behat testing on ez_php:latest and ez_php:latest-dev with eZ Platform"
cd volumes/ezplatform


# Tag image as eZ Platform extends on of these exact images and we don't want it to pull in remote
docker tag ez_php:latest "ezsystems/php:7.1-${FORMAT_VERSION}"
docker tag ez_php:latest "ezsystems/php:7.0-${FORMAT_VERSION}"


export COMPOSE_FILE="doc/docker-compose/base-prod.yml:doc/docker-compose/redis.yml:doc/docker-compose/selenium.yml" SYMFONY_ENV="behat" SYMFONY_DEBUG="0" PHP_IMAGE="ez_php:latest" PHP_IMAGE_DEV="ez_php:latest-dev"
docker-compose -f doc/docker-compose/install.yml up --abort-on-container-exit

docker-compose up -d --build --force-recreate
docker-compose exec --user www-data app sh -c "php /scripts/wait_for_db.php; php app/console cache:warmup; php bin/behat -vv --profile=platformui --tags='@common'"
docker-compose down -v

# Remove custom tag
docker rmi "ezsystems/php:7.1-${FORMAT_VERSION}"
docker rmi "ezsystems/php:7.0-${FORMAT_VERSION}"
