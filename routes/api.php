<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ChatbotController;
use App\Http\Controllers\FilesController;
use App\Http\Controllers\TelegramWebhookController;
use App\Http\Controllers\N8nApiController;

// Auth user endpoint
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/files/metrics', [FilesController::class, 'metrics'])->name('api.files.metrics');

    // Telegram user management
    Route::prefix('telegram')->group(function () {
        Route::post('/generate-code', [TelegramWebhookController::class, 'generateVerificationCode']);
        Route::post('/unlink', [TelegramWebhookController::class, 'unlinkAccount']);
        Route::post('/toggle-notifications', [TelegramWebhookController::class, 'toggleNotifications']);
        Route::get('/status', [TelegramWebhookController::class, 'getStatus']);
    });
});


// Telegram webhook (public, authenticated by secret token)
Route::post('/telegram/webhook', [TelegramWebhookController::class, 'webhook']);
Route::get('/telegram/test', [TelegramWebhookController::class, 'test']);

// n8n API endpoints (authenticated by bearer token)
Route::prefix('n8n')->middleware('throttle:120,1')->group(function () {
    Route::get('/upcoming-classes', [N8nApiController::class, 'upcomingClasses']);
    Route::get('/all-classes', [N8nApiController::class, 'allClasses']);
    Route::get('/telegram-users', [N8nApiController::class, 'telegramUsers']);
    Route::get('/health', [N8nApiController::class, 'health']);
});

// AI Chatbot Routes
Route::middleware(['web'])->group(function () {
    Route::post('/chatbot/query', [ChatbotController::class, 'queryRequest'])
        ->name('api.chatbot.query');
    
    Route::post('/chatbot/stream', [ChatbotController::class, 'streamChat'])
        ->name('api.chatbot.stream');
    
    Route::get('/chatbot/status', [ChatbotController::class, 'status'])
        ->name('api.chatbot.status');
});