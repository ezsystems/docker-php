<?php

echo ("Running testSymfonyRequirements.php...\n");

require_once dirname(__FILE__) . '/var/SymfonyRequirements.php';

$symfonyRequirements = new SymfonyRequirements();

$majorProblems = $symfonyRequirements->getFailedRequirements();

// Skip temporarily while ICU is an issue: https://github.com/sensiolabs/SensioDistributionBundle/issues/277
//$minorProblems = $symfonyRequirements->getFailedRecommendations();

$error = false;

if (!empty($majorProblems)) {
    var_dump($majorProblems);
    $error = true;
}

if (!empty($minorProblems)) {
    var_dump($minorProblems);
    $error = true;
}

if ( $error ) {
    echo "FAILED: See above for failed requirements and/or recommendations!\n";
    exit(1);
} else {
    echo "OK: No failed requirements or recommendations found!\n";
}
