<?php
/**
 * send_tuition_push.php — copy this INTO your tuition store controller.
 *
 * Put this block right AFTER a new tuition is saved (where $tuition is the
 * freshly-created row). It finds every teacher whose expected_area matches the
 * tuition's area and has a saved fcm_token, then pushes a notification.
 *
 * This uses the NEW FCM v1 API via FcmV1.php (the legacy key= method is dead).
 *
 * ── Requirements already handled elsewhere ──
 *   - teachers.fcm_token column exists (Step 1 SQL).
 *   - FcmV1.php is uploaded next to this file (or adjust the require path).
 *   - .env has:  FCM_SERVICE_ACCOUNT=/home/mohaqtzn/firebase/bdtuition-service-account.json
 */

require_once __DIR__ . '/FcmV1.php';

// ---- paste from here, inside your controller, after $tuition is created ----

try {
    $serviceAccountPath = env('FCM_SERVICE_ACCOUNT');

    if ($serviceAccountPath && is_file($serviceAccountPath)) {
        $fcm  = new \FcmV1($serviceAccountPath);
        $area = $tuition->area;

        $teachers = \DB::table('teachers')
            ->whereNotNull('fcm_token')
            ->where('fcm_token', '!=', '')
            ->where('expected_area', 'like', "%{$area}%")
            ->get();

        foreach ($teachers as $teacher) {
            try {
                $fcm->sendToToken(
                    $teacher->fcm_token,
                    'নতুন টিউশন আপনার এলাকায়!',
                    "{$tuition->tuition_code} — {$tuition->area}, ৳{$tuition->salary}/মাস",
                    [
                        'tuition_id'   => $tuition->id,
                        'tuition_code' => $tuition->tuition_code,
                        'area'         => $tuition->area,
                    ]
                );
            } catch (\Throwable $e) {
                // one bad/expired token must never break tuition creation
                \Log::warning('FCM push failed for teacher token: ' . $e->getMessage());
            }
        }
    }
} catch (\Throwable $e) {
    // whole push block is best-effort; tuition is already saved
    \Log::warning('FCM push block skipped: ' . $e->getMessage());
}

// ---- paste up to here ----
