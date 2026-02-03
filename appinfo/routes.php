<?php

declare(strict_types=1);

return [
    'routes' => [
        ['name' => 'status#index', 'url' => '/', 'verb' => 'GET'],
        ['name' => 'status#check', 'url' => '/check', 'verb' => 'POST'],
        ['name' => 'status#backup', 'url' => '/backup', 'verb' => 'POST'],
        ['name' => 'status#settings', 'url' => '/settings', 'verb' => 'POST'],
        ['name' => 'status#testFile', 'url' => '/test-file', 'verb' => 'POST'],
    ],
];
