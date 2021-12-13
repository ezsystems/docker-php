#!/usr/bin/env sh

set -e
# Expects images from build.sh, as in:
# - ez_php:latest
# - ez_php:latest-node
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

APP_ENV=${APP_ENV:-prod}
SYMFONY_ENV=${SYMFONY_ENV:-prod}
PRODUCT_VERSION=${PRODUCT_VERSION:-^3.3.x-dev}
FORMAT_VERSION=${FORMAT_VERSION:-v2}

if [ "$REUSE_VOLUME" = "0" ]; then
    printf "\n(Re-)Creating volumes/ezplatform for fresh checkout, needs sudo to delete old and chmod new folder\n"
    rm -Rf volumes/ezplatform
    # Use mode here so this can be run on Mac
    mkdir -pm 0777 volumes/ezplatform

    if [ "$COMPOSER_HOME" = "" ]; then
        COMPOSER_HOME=~/.composer
    fi

    printf "\nBuilding on ez_php:latest, composer will implicit check requirements\n"
    if [ "$PRODUCT_VERSION" = "^2.5" ]; then
        docker run -ti --rm \
          -e SYMFONY_ENV \
          -e PHP_INI_ENV_memory_limit=3G \
          -v $(pwd)/volumes/ezplatform:/var/www \
          -v  $COMPOSER_HOME:/root/.composer \
          ez_php:latest-node \
          bash -c "
          composer --version &&
          composer create-project --no-progress --no-interaction ezsystems/ezplatform /var/www $PRODUCT_VERSION"
    elif [ "$PRODUCT_VERSION" = "^3.3.x-dev" ]; then
        docker run -ti --rm \
          -e APP_ENV \
          -e PHP_INI_ENV_memory_limit=3G \
          -v $(pwd)/volumes/ezplatform:/var/www \
          -v  $COMPOSER_HOME:/root/.composer \
          ez_php:latest-node \
          bash -c "
          composer --version &&
          composer create-project --no-progress --no-interaction $COMPOSER_OPTIONS ibexa/website-skeleton /var/www $PRODUCT_VERSION &&
          composer require ibexa/oss:$PRODUCT_VERSION -W  --no-scripts $COMPOSER_OPTIONS
          git init && git add . && git commit -m 'Init'
          composer recipes:install ibexa/oss --force -v
          composer require ibexa/docker $COMPOSER_OPTIONS &&
          composer require ezsystems/behatbundle:^8.3.x-dev --no-scripts --no-plugins $COMPOSER_OPTIONS &&
          composer recipes:install ezsystems/behatbundle --force"
    fi
fi

printf "\nMake sure Node.js and Yarn are included in latest-node\n"
docker -l error run -a stderr ez_php:latest-node node -e "process.versions.node"
docker -l error run -a stderr ez_php:latest-node bash -c "yarn -v"

printf "\nVersion and module information about php build\n"
docker run -ti --rm ez_php:latest-node bash -c "php -v; php -m"

printf "\nVersion and module information about php build with enabled xdebug\n"
docker run -ti --rm -e ENABLE_XDEBUG="1" ez_php:latest-node bash -c "php -v; php -m"

printf "\Integration: Behat testing on ez_php:latest and ez_php:latest-node with eZ Platform\n"
cd volumes/ezplatform

export COMPOSE_FILE="doc/docker/base-dev.yml:doc/docker/redis.yml:doc/docker/selenium.yml" 
export SYMFONY_ENV="behat" SYMFONY_DEBUG="1" 
export APP_ENV="behat" APP_DEBUG="1" 
export PHP_IMAGE="ez_php:latest-node" PHP_IMAGE_DEV="ez_php:latest-node"

if [ "$PRODUCT_VERSION" = "^2.5" ]; then
    docker-compose --env-file .env -f doc/docker/install-dependencies.yml -f doc/docker/install-database.yml up --abort-on-container-exit
    docker-compose --env-file .env up -d --build --force-recreate
    echo '> Workaround for test issues: Change ownership of files inside docker container'
    docker-compose --env-file=.env exec app sh -c 'chown -R www-data:www-data /var/www'
elif [ "$PRODUCT_VERSION" = "^3.3.x-dev" ]; then
    docker-compose --env-file .env up -d --build --force-recreate
    echo '> Workaround for test issues: Change ownership of files inside docker container'
    docker-compose --env-file=.env exec app sh -c 'chown -R www-data:www-data /var/www'
    # Rebuild Symfony container
    docker-compose --env-file=.env exec --user www-data app sh -c "rm -rf var/cache/*"
    docker-compose --env-file=.env exec --user www-data app php bin/console cache:clear
    # Install database & generate schema
    docker-compose --env-file=.env exec --user www-data app sh -c "php /scripts/wait_for_db.php; php bin/console ibexa:install"
    docker-compose --env-file=.env exec --user www-data app sh -c "php bin/console ibexa:graphql:generate-schema"
    docker-compose --env-file=.env exec --user www-data app sh -c "composer run post-install-cmd"
fi

docker-compose --env-file=.env exec --user www-data app sh -c "php /scripts/wait_for_db.php; php bin/console cache:warmup; $TEST_CMD"

docker-compose --env-file .env down -v
