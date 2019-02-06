<?php

// This script will resolve any hosts in SYMFONY_TRUSTED_PROXIES and output them
// so if you have SYMFONY_TRUSTED_PROXIES="192.168.0.1,varnish,google.com,2a00:1450:400f:807::200e"
// it will output something like "192.168.0.1,192.168.64.5,216.58.211.14,2a00:1450:400f:807::200e"
if ($symfonyTrustedProxies = getenv('SYMFONY_TRUSTED_PROXIES')) {
    $proxies = explode(',', $symfonyTrustedProxies);
    $resolvedProxies = [];
    foreach ($proxies as $proxy) {
        if (filter_var($proxy, FILTER_VALIDATE_IP) !== false) {
            // no resolving needed
            $resolvedProxies[] = $proxy;
        } else {
            // resolve host
            do {
                $resolvedHost = gethostbyname($proxy);
                if ($resolvedHost === $proxy) {
                    // If hostname do not contain any dots we assume this is the hostname of a different container
                    // which needs to resolve. We'll therefore wait indefinitely until it resolves
                    if (strpos($proxy, '.') === false) {
                        fwrite(STDERR, "Unable to resolve trusted proxy '$proxy', retrying\n");
                        sleep(5);
                        $done = false;
                    } else {
                        fwrite(STDERR, "Unable to resolve trusted proxy '$proxy', skipping\n");
                        $done = true;
                    }
                } else {
                    $resolvedProxies[] = $resolvedHost;
                    $done = true;
                }

            } while (!$done);
        }
    }
    $symfonyTrustedProxies = implode(',', $resolvedProxies);
    echo($symfonyTrustedProxies);
}

