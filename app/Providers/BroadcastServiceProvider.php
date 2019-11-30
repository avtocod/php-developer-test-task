<?php

declare(strict_types = 1);

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Broadcasting\BroadcastManager;

class BroadcastServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap any application services.
     *
     * @param BroadcastManager $manager
     *
     * @return void
     */
    public function boot(BroadcastManager $manager): void
    {
        $manager->routes();
    }
}
