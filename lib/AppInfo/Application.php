<?php

declare(strict_types=1);

namespace OOMonitor\AppInfo;

use OOMonitor\BackgroundJob\OnlyOfficeCheckJob;
use OCP\AppFramework\App;
use OCP\BackgroundJob\IJobList;

class Application extends App {
    public const APP_ID = 'oo_monitor';

    public function __construct() {
        parent::__construct(self::APP_ID);

        $container = $this->getContainer();
        $jobList = $container->get(IJobList::class);
        $jobList->add(OnlyOfficeCheckJob::class);
    }
}
