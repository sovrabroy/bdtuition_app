<?php
/*
|--------------------------------------------------------------------------
| GUARDIAN ROUTES — ADD THESE LINES to panel.bdtuition.com/routes/api.php
|--------------------------------------------------------------------------
| Do NOT replace your existing api.php. Just paste the blocks below.
| Paste the two `use` lines near the other use-statements at the very top,
| then paste the route block anywhere at the bottom of the file.
*/

// ---- 1) add near the top with the other `use` imports ----
use App\Http\Controllers\Api\GuardianAuthController;
use App\Http\Controllers\Api\GuardianController;

// ---- 2) add at the bottom of routes/api.php ----

// Guardian: public auth (no token needed)
Route::post('/guardian/register', [GuardianAuthController::class, 'register']);
Route::post('/guardian/login',    [GuardianAuthController::class, 'login']);

// Guardian: authenticated (Sanctum token required)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/guardian/logout',   [GuardianAuthController::class, 'logout']);
    Route::get('/guardian/profile',   [GuardianAuthController::class, 'profile']);

    Route::get('/guardian/teachers',  [GuardianController::class, 'myTeachers']);
    Route::post('/guardian/apply',    [GuardianController::class, 'applyForTutor']);
    Route::get('/guardian/requests',  [GuardianController::class, 'myRequests']);
    Route::post('/guardian/review',   [GuardianController::class, 'submitReview']);
    Route::get('/guardian/reviews',   [GuardianController::class, 'myReviews']);
});
