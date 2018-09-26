#!/usr/bin/env php
<?php
/**
 * This script contains code for waiting for db to get up for up to 2min
 *
 * Use:
 * - Main use case is with env variables as found below
 * - For testing against mysql db "ezp" it is possible to execute with `php /scripts/wait_for_db.php localhost user password
 *
 * Note: This container is for the time being only compiled with mysql support, so not all options below will work,
 *       it's here for those extending the container to reuse.
 */

// Let's try to connect to db for ~2 minutes ( 24 * 5 sec intervalls )
define('MAXTRY', 24);

/**
 * @var string $driver A valid pdo driver name w/o prefix, example mysql, sqlite, pgsql, sqlsrv & oci8 (mapped to oci)
 */
$driver = getenv('DATABASE_DRIVER') ?: 'mysql';
$host = getenv('DATABASE_HOST') ?: (!empty($argv[1]) ? $argv[1] : 'db');
$port = getenv('DATABASE_PORT');
$name = getenv('DATABASE_NAME') ?: 'ezp';



/**
 * Special handling for the different database drivers.
 *
 * - sqlite will just exit as it is local and we are not looking to validate db settings here.
 * - sqlsrv has a different dsn format.
 * - oci8 (as recommended by php/oracle/doctrine), will here use pdo_oci as we only need to check connection
 *   todo: it's probably better if oci8 is used in this case to not have to compile in broken pdo_oci.
 */
if ($driver === 'sqlite') {
    return true;
} else if ($driver === 'sqlsrv') {
    $dsn = "sqlsrv:Server=${host}" . ($port ? ",${port}" : '') . ";Database=${name};";
} else if ($driver === 'oci8') {
    $dsn = "oci:dbname=//${host}" . ($port ? ":${port}" : '') . "/${name};";
} else {
    $dsn = "${driver}:host=${host};" . ($port ? "port=${port};" : ''). "dbname=${name};";
}


/**
 * User credentials
 */
$user = getenv('DATABASE_USER') ?: (!empty($argv[2]) ? $argv[2] : 'ezp');
$password = getenv('DATABASE_PASSWORD') ?: (!empty($argv[3]) ? $argv[3] : 'pleasechangethis');

for ($try = 1; $try <= MAXTRY; $try++) {
    echo "Checking database is up, attempt: ${try}\n";
    try {
        $db = new PDO($dsn, $user, $password);
        $db = null;
        echo "Ok: Connection succeeded to ${driver} '${name}'.\n";
        exit(0);
    } catch (PDOException $e) {
        //echo $e->getCode() . ' ' . $e->errorInfo . ' ' . $e->getMessage() . "\n";
        if ($try < MAXTRY) sleep(5);
    }
}

echo "ERROR: Max limit reached, not able to connect to ${driver} '${name}', exiting with error code.\n";
exit(1);
