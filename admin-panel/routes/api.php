<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::prefix('auth')->group(function (): void {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('register', [AuthController::class, 'register']);
});

// Protected routes
Route::middleware('jwt.auth')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('refresh', [AuthController::class, 'refresh']);
        Route::get('me', [AuthController::class, 'me']);
    });

    // Admin only routes
    Route::middleware('role:admin')->group(function (): void {
        Route::apiResource('users', UserController::class);
        
        // Additional user management routes
        Route::post('users/{user}/restore', [UserController::class, 'restore'])
            ->whereNumber('user')
            ->withTrashed();
        Route::delete('users/{user}/force-delete', [UserController::class, 'forceDelete'])
            ->whereNumber('user')
            ->withTrashed();
    });
});
