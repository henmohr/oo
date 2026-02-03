<?php

declare(strict_types=1);

namespace OOMonitor\BackgroundJob;

use OOMonitor\Service\OnlyOfficeMonitor;
use OCP\IConfig;
use OCP\BackgroundJob\TimedJob;
use OCP\ILogger;

class OnlyOfficeCheckJob extends TimedJob {
    private OnlyOfficeMonitor $monitor;
    private ILogger $logger;

    public function __construct(OnlyOfficeMonitor $monitor, ILogger $logger, IConfig $config) {
        parent::__construct();
        $this->monitor = $monitor;
        $this->logger = $logger;
        $interval = (int)$config->getAppValue('oo_monitor', 'check_interval', '900');
        $interval = $interval > 0 ? $interval : 900;
        $this->setInterval($interval);
    }

    protected function run($argument): void {
        $result = $this->monitor->checkAndReconnect();
        $this->logger->info('OnlyOffice scheduled check', [
            'app' => 'oo_monitor',
            'result' => $result,
        ]);
    }
}
