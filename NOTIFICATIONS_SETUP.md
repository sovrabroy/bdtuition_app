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
This is why it isn't finished yet — it needs your Firebase project and a small
backend addition on cPanel. Here is the exact checklist.

### Step 1 — Create a Firebase project (free)
1. Go to https://console.firebase.google.com → **Add project** → name it e.g. `BDTuition`.
2. Add an **Android app**. Package name must match the app's. Find it in
   `android/app/build.gradle` under `applicationId`.
3. Download the generated **`google-services.json`**.
4. Place it at `android/app/google-services.json` in the repo and commit it.

### Step 2 — Get the server key
1. Firebase Console → **Project settings** → **Cloud Messaging**.
2. Copy the **Server key** (or set up the newer HTTP v1 service-account JSON).
   You'll paste this into the cPanel backend in Step 5.

### Step 3 — Tell me it's done
Once `google-services.json` is in the repo, send me a message. I will then:
- Add `firebase_messaging` + `flutter_local_notifications` to `pubspec.yaml`.
- Add the Gradle plugin lines to `android/build.gradle` and `android/app/build.gradle`.
- Create a `PushService` that registers the device token and shows tray
  notifications.
- Send the token to your existing `/fcm-token` endpoint (already stubbed in
  `ApiConfig`).

> I'm holding off on adding these packages until `google-services.json` exists,
> because adding Firebase without it **breaks the GitHub Actions build**.

### Step 4 — Backend: store each teacher's device token (cPanel)
Add a column to the teachers table (adjust the table name if different):

```sql
ALTER TABLE teachers ADD COLUMN fcm_token VARCHAR(255) NULL;
```

Add the endpoint the app already calls (`POST /api/fcm-token`) to save it:

```php
// routes/api.php  (panel.bdtuition.com)
Route::middleware('auth:sanctum')->post('/fcm-token', function (Request $r) {
    $r->user()->update(['fcm_token' => $r->input('token')]);
    return response()->json(['success' => true]);
});
```

### Step 5 — Backend: send a push when a matching tuition is posted (cPanel)
When a new tuition is created, find teachers whose `expected_area` contains the
tuition's area and push to their `fcm_token`. Sketch:

```php
// After a tuition is saved (e.g. in the tuition store controller)
$area = $tuition->area;

// Adjust the column/match to however expected_area is stored (CSV vs JSON).
$teachers = Teacher::whereNotNull('fcm_token')
    ->where('expected_area', 'like', "%{$area}%")
    ->get();

foreach ($teachers as $teacher) {
    Http::withHeaders([
        'Authorization' => 'key=' . env('FCM_SERVER_KEY'),
        'Content-Type'  => 'application/json',
    ])->post('https://fcm.googleapis.com/fcm/send', [
        'to' => $teacher->fcm_token,
        'notification' => [
            'title' => 'New Tuition Near You',
            'body'  => "{$tuition->tuition_code} — {$tuition->area}, ৳{$tuition->salary}",
        ],
        'data' => ['tuition_id' => (string) $tuition->id],
    ]);
}
```

Add `FCM_SERVER_KEY=...` (from Step 2) to the cPanel `.env`.

> **Column names to confirm:** `expected_area`, `area`, `tuition_code`, `salary`,
> and the teachers table name. Change them in the SQL/PHP above if yours differ.

### Step 6 — Rebuild
After my code changes + your backend deploy, push to GitHub so Actions rebuilds
the APK. Install it, log in, and the token registers automatically. Post a test
tuition in an expected area to confirm the tray notification arrives with the
app fully closed.
