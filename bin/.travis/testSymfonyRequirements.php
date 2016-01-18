<?php

echo ( "Running testSymfonyRequirements.php...\n" );

require_once dirname(__FILE__).'/app/SymfonyRequirements.php';

$symfonyRequirements = new SymfonyRequirements();

$majorProblems = $symfonyRequirements->getFailedRequirements();
$minorProblems = $symfonyRequirements->getFailedRecommendations();

$error = false;

if ( count ( $majorProblems ) > 0 )
{
    var_dump( $majorProblems );
    $error = true;
}

if ( count ( $minorProblems ) > 0 )
{
    var_dump( $minorProblems );
    $error = true;
}

if ( $error )
    exit( 1 );
