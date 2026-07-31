# Push Notifications — Setup Checklist

The teacher app now has **two halves** of the "nearby tuition" notification feature.

## ✅ Already working (shipped in this update — no setup needed)

**In-app popup while the app is open.** When a new tuition is posted in one of the
teacher's selected *expected areas*, a nice popup appears with the code, area,
and salary, plus a **View** button that opens the tuition. This is real: it polls
the live tuitions API every ~3 minutes and never shows fake alerts. It works with
your current backend unchanged.

Files added/wired for this:
- `lib/services/nearby_tuition_notifier.dart` (new — the watcher)
- `lib/screens/dashboard/home_screen.dart` (wired the popup in)

Nothing else is required for this part. Once the APK rebuilds from GitHub Actions,
it just works.

---

## ⏳ Needs your setup — system notification when the app is CLOSED / offline

A notification that appears in the phone's top notification tray **while the app
isn't running** cannot be done from the app alone. Android only delivers those
through **Firebase Cloud Messaging (FCM)**, and your server has to send the push.

### ✅ Done on the app side (shipped in this update)
- `google-services.json` is in `android/app/` (Firebase project `bdtuition-1fad3`).
- Gradle wired: `com.google.gms.google-services` plugin, core-library desugaring,
  `minSdk` raised to 23, desugar dependency.
- Packages added: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`.
- `lib/services/push_service.dart` — initialises FCM, creates the "Tuition Alerts"
  notification channel, shows foreground alerts, and sends the device token to the
  backend `POST /fcm-token` after login (and on token refresh).
- `AndroidManifest.xml` — `POST_NOTIFICATIONS` permission for Android 13+.
- `main.dart` — Firebase init + background handler, all guarded so a misconfig
  can never stop the app from launching.

Once the APK rebuilds from GitHub Actions, each logged-in device registers its
token automatically. **All that's left is the two cPanel backend pieces below.**

> **Confirmed against the live DB (`mohaqtzn_wp37`):**
> - `teachers` table → `expected_area` (teacher's desired area), plus `fcm_token` (added below)
> - `tuitions` table → `area`, `tuition_code`, `salary`
> The code below already uses these exact names — no adjustment needed.

### Step 1 — Backend: store each teacher's device token (cPanel)
Add the `fcm_token` column to the `teachers` table:

```sql
ALTER TABLE teachers ADD COLUMN fcm_token VARCHAR(255) NULL;
```

Add the endpoint the app already calls (`POST /api/fcm-token`) to save it:

```php
// routes/api.php  (panel.bdtuition.com)
Route::middleware('auth:sanctum')->post('/fcm-token', function (\Illuminate\Http\Request $request) {
    $request->user()->update(['fcm_token' => $request->input('token')]);
    return response()->json(['success' => true]);
});
```

### Step 2 — Backend: send a push when a matching tuition is posted (cPanel)
Where a new tuition is saved (the tuition store controller), add this right
after the tuition is created. It finds teachers whose `expected_area` contains
the tuition's `area` and pushes to their `fcm_token`:

```php
$area = $tuition->area;

$teachers = \DB::table('teachers')
    ->whereNotNull('fcm_token')
    ->where('expected_area', 'like', "%{$area}%")
    ->get();

foreach ($teachers as $teacher) {
    \Illuminate\Support\Facades\Http::withHeaders([
        'Authorization' => 'key=' . env('FCM_SERVER_KEY'),
        'Content-Type'  => 'application/json',
    ])->post('https://fcm.googleapis.com/fcm/send', [
        'to' => $teacher->fcm_token,
        'notification' => [
            'title' => 'নতুন টিউশন আপনার এলাকায়!',
            'body'  => "{$tuition->tuition_code} — {$tuition->area}, ৳{$tuition->salary}/মাস",
        ],
        'data' => [
            'tuition_id'   => (string) $tuition->id,
            'tuition_code' => (string) $tuition->tuition_code,
            'area'         => (string) $tuition->area,
        ],
    ]);
}
```

Get `FCM_SERVER_KEY` from Firebase Console → **Project settings** → **Cloud
Messaging** → server key, and add `FCM_SERVER_KEY=...` to the cPanel `.env`.

### Step 3 — Rebuild & test
After your backend deploy, the APK from GitHub Actions already has the app side.
Install it, log in (token registers automatically), then post a test tuition in
an expected area to confirm the tray notification arrives with the app fully closed.
