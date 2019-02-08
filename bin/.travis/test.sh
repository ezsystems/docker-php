#!/usr/bin/env sh

set -e
# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-node
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
    # pull in latest stable by default
    EZ_VERSION="^2.4"
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
      bash -c "composer -v && composer create-project --prefer-dist --no-progress --no-interaction ezsystems/ezplatform /var/www $EZ_VERSION"
fi

printf "\nMake sure Node.js and Yarn are included in latest-node and latest-dev\n"
docker -l error run -a stderr ez_php:latest-node node -e "process.versions.node"
docker -l error run -a stderr ez_php:latest-dev node -e "process.versions.node"
docker -l error run -a stderr ez_php:latest-node bash -c "yarn -v"
docker -l error run -a stderr ez_php:latest-dev bash -c "yarn -v"

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


printf "\nVersion and module information about php build\n"
docker run -ti --rm ez_php:latest-dev bash -c "php -v; php -m"


printf "\Integration: Behat testing on ez_php:latest and ez_php:latest-dev with eZ Platform\n"
cd volumes/ezplatform

# Tag image alias for what (exactly) eZ Platform is currently using in order to be able to test across branches
## As we don't want it to pull in remote, but rather use what we just built here
## NOTE: On larger changes to this images, we would need to pull in custom branches with adaptions on Platform side as well as below
## TODO: The tag aliases here will not be needed once eZ Platform uses PHP_IMAGE variable within Dockerfile's from section
docker tag ez_php:latest "ezsystems/php:7.2-v1"
docker tag ez_php:latest "ezsystems/php:7.1-v1"
docker tag ez_php:latest "ezsystems/php:7.0-v1"

export COMPOSE_FILE="doc/docker/base-dev.yml:doc/docker/redis.yml:doc/docker/selenium.yml" SYMFONY_ENV="behat" SYMFONY_DEBUG="0" PHP_IMAGE="ez_php:latest" PHP_IMAGE_DEV="ez_php:latest-dev"
docker-compose -f doc/docker/install.yml up --abort-on-container-exit

docker-compose up -d --build --force-recreate
if [ -f bin/console ]; then
    echo '> Workaround for v2 test issues: Change ownership of files inside docker container'
    docker-compose exec app sh -c 'chown -R www-data:www-data /var/www'

    docker-compose exec --user www-data app sh -c "php /scripts/wait_for_db.php; php bin/console cache:warmup; php bin/behat -v --profile=rest --suite=fullJson --tags=~@broken"
else
    docker-compose exec --user www-data app sh -c "php /scripts/wait_for_db.php; php app/console cache:warmup; php bin/behat -v --profile=platformui --tags='@common'"
fi

docker-compose down -v

# Remove custom tag aliases used for Platform testing
docker rmi "ezsystems/php:7.2-v1"
docker rmi "ezsystems/php:7.1-v1"
docker rmi "ezsystems/php:7.0-v1"
