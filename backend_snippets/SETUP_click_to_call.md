# Issabel Click-to-Call (masked guardian calling) — Setup (FINAL)

Works with your EXISTING Issabel setup — no new trunks, no new extensions, no
dialplan changes. We only add a `bridge` mode to the call.php you already run
on the PBX (144.79.218.25), then the teacher app's backend POSTs to it exactly
like your admin panel already does.

How a teacher call works:
1. Teacher taps **Call Guardian** in the app.
2. Panel backend looks up the guardian number server-side (never sent to app)
   and POSTs `mode=bridge` + teacher number + guardian number to the PBX.
3. PBX rings the teacher's mobile; on answer it dials the guardian and bridges.

---

## 1. PBX server (144.79.218.25) — replace /var/www/html/call.php

The new `call.php` in this folder is a drop-in replacement:
- Old behaviour (staff `extension` + `number`) — **unchanged**.
- New `mode=bridge` (`teacher_number` + `guardian_number`) — added.

Already tested: two mobiles bridge correctly (first answers → second rings).

Back up the old file first, then copy:
```
cp /var/www/html/call.php /var/www/html/call.php.bak
```
Then upload the new `call.php` to `/var/www/html/call.php`.

### Optional quick sanity test (on the PBX, using your own two phones):
```
curl -k -X POST https://144.79.218.25/call.php \
  -H "Content-Type: application/json" \
  -d '{"secret":"BDTuition2026","mode":"bridge","teacher_number":"017XXXXXXXX","guardian_number":"018YYYYYYYY"}'
```
Check `/var/www/html/pbx_debug.txt` for "BRIDGE MODE" + AMI output.

---

## 2. Panel backend (panel.bdtuition.com) — controller method

Take `call_guardian_controller_method.php` → paste the `call()` method into the
guardian controller the Flutter app already uses (same one as `reveal`).
Confirm the `// <-- CHECK` table/column names against your schema
(`tuition_assignments`, `tuitions`, `gurdian_number`, `teacher_id`,
`phone_number`).

Route in `routes/api.php` (inside the auth:sanctum group):
```php
Route::post('guardians/{assignmentId}/call', [GuardianController::class, 'call']);
```

---

## 3. Flutter app (already done)

- `api_config.dart`  → `guardianCall(id)` endpoint added.
- `api_service.dart` → `callGuardian(assignmentId)` added.
- `teacher_provider.dart` → `callGuardian()` added.
- `guardian_list_screen.dart` → "Reveal Number" **removed**, replaced by
  "Call Guardian" (card + details sheet). Phone number no longer shown.

No further app changes needed. Just push + build the APK.

---

## 4. Optional audit table (ties into your fraud dashboard)

```php
Schema::create('guardian_call_logs', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('teacher_id')->index();
    $table->unsignedBigInteger('assignment_id')->index();
    $table->boolean('success')->default(false);
    $table->timestamps();
});
```
The controller writes to it best-effort (wrapped in try/catch).

---

## 5. Security note

`call.php` checks the shared secret (`BDTuition2026`). For an extra layer, you
can also restrict this call to only the panel server's IP — but keep the secret
at minimum. AMI port 5038 stays localhost-only (it already is: `nc 127.0.0.1
5038`), so nothing to open.
```
