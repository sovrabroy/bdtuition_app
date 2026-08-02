<?php
// ============================================================================
// TEACHER APP — masked "Call Guardian" endpoint
//
// PASTE this `call()` method into your PANEL app's teacher-side guardian
// controller  (panel.bdtuition.com  — the API backend the Flutter app talks
// to, NOT the manage/admin panel).  It mirrors EXACTLY how your admin panel
// already calls guardians (Http POST to the PBX call.php), just in "bridge"
// mode so the teacher's mobile is rung first instead of a SIP extension.
//
// Route (routes/api.php, inside auth:sanctum group):
//     Route::post('guardians/{assignmentId}/call', [GuardianController::class, 'call']);
//
// Adjust the parts marked  // <-- CHECK  to your real table/column names.
// ============================================================================

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

/**
 * POST /api/guardians/{assignmentId}/call
 *
 * Masked click-to-call. The guardian's number is read on the server and NEVER
 * returned to the app. The PBX rings the teacher's own mobile first; on answer
 * it bridges to the guardian.
 */
public function call($assignmentId)
{
    $teacher = auth()->user();
    if (!$teacher) {
        return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);
    }

    // Teacher's own mobile — the leg that rings first.
    $teacherPhone = $teacher->phone_number ?? null;               // <-- CHECK column
    if (empty($teacherPhone)) {
        return response()->json([
            'success' => false,
            'message' => 'Your phone number is missing from your profile.',
        ], 422);
    }

    // Look up the guardian number from the approved assignment and make sure it
    // belongs to THIS teacher. This is the security gate.
    $row = DB::table('tuition_assignments as a')                  // <-- CHECK table
        ->join('tuitions as t', 't.id', '=', 'a.tuition_id')      // <-- CHECK
        ->where('a.id', $assignmentId)
        ->where('a.teacher_id', $teacher->id)                     // <-- CHECK column
        ->whereIn('a.status', ['approved', 'active', 'confirmed'])// <-- CHECK values
        ->select('t.gurdian_number as guardian_number')           // <-- CHECK column (note spelling: gurdian_number)
        ->first();

    if (!$row || empty($row->guardian_number)) {
        return response()->json([
            'success' => false,
            'message' => 'This guardian is not available to call.',
        ], 403);
    }

    try {
        // Same PBX endpoint the admin panel uses — bridge mode.
        $response = Http::withoutVerifying()->asForm()->post(
            'https://144.79.218.25/call.php',
            [
                'secret'          => 'BDTuition2026',
                'mode'            => 'bridge',
                'teacher_number'  => $teacherPhone,
                'guardian_number' => $row->guardian_number,
            ]
        );

        Log::info('Teacher app click-to-call', [
            'status'        => $response->status(),
            'body'          => $response->body(),
            'teacher_id'    => $teacher->id,
            'assignment_id' => $assignmentId,
        ]);

        if (!$response->successful()) {
            throw new \Exception('PBX request failed');
        }
    } catch (\Throwable $e) {
        Log::error('Teacher app click-to-call failed', [
            'teacher_id'    => $teacher->id,
            'assignment_id' => $assignmentId,
            'error'         => $e->getMessage(),
        ]);
        return response()->json([
            'success' => false,
            'message' => 'Could not place the call. Please try again.',
        ], 502);
    }

    // Optional audit trail (ties into the fraud dashboard). Best-effort.
    try {
        DB::table('guardian_call_logs')->insert([
            'teacher_id'    => $teacher->id,
            'assignment_id' => $assignmentId,
            'success'       => 1,
            'created_at'    => now(),
            'updated_at'    => now(),
        ]);
    } catch (\Throwable $e) {
        // table may not exist yet — ignore.
    }

    return response()->json([
        'success' => true,
        'message' => 'Connecting… your phone will ring in a few seconds.',
    ]);
}
