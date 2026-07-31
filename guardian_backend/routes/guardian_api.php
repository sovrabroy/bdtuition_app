<?php
/*
|--------------------------------------------------------------------------
| GUARDIAN ROUTES (standalone include)
|--------------------------------------------------------------------------
| This whole file is included from routes/api.php with one line:
|
|     require __DIR__.'/guardian_api.php';
|
| Fully-qualified class names are used, so NO `use` imports are needed
| in api.php. Nothing in your existing api.php is touched.
*/

use Illuminate\Support\Facades\Route;

// Guardian: public auth (no token needed)
Route::post('/guardian/register', [\App\Http\Controllers\Api\GuardianAuthController::class, 'register']);
Route::post('/guardian/login',    [\App\Http\Controllers\Api\GuardianAuthController::class, 'login']);

// Guardian: authenticated (Sanctum token required)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/guardian/logout',   [\App\Http\Controllers\Api\GuardianAuthController::class, 'logout']);
    Route::get('/guardian/profile',   [\App\Http\Controllers\Api\GuardianAuthController::class, 'profile']);

    Route::get('/guardian/teachers',  [\App\Http\Controllers\Api\GuardianController::class, 'myTeachers']);
    Route::post('/guardian/apply',    [\App\Http\Controllers\Api\GuardianController::class, 'applyForTutor']);
    Route::get('/guardian/requests',  [\App\Http\Controllers\Api\GuardianController::class, 'myRequests']);
    Route::post('/guardian/review',   [\App\Http\Controllers\Api\GuardianController::class, 'submitReview']);
    Route::get('/guardian/reviews',   [\App\Http\Controllers\Api\GuardianController::class, 'myReviews']);
});
