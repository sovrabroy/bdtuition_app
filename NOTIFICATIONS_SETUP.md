# Push Notifications — cPanel Setup (সহজ বাংলা গাইড)

অ্যাপের দিকের সব কাজ **শেষ** (Firebase কোড, google-services.json, token পাঠানো — সব বসানো হয়ে গেছে)।
এখন শুধু **cPanel-এ ৩টা কাজ** বাকি। নিচে একদম ধাপে ধাপে দেওয়া হলো।

> ⚠️ **খুব জরুরি:** গত রাতে যে পুরনো পদ্ধতি (`fcm.googleapis.com/fcm/send` আর `Authorization: key=...`)
> লেখা ছিল, সেটা Google **২০২৪ সালের জুনে বন্ধ করে দিয়েছে** — আর কাজ করে না।
> তাই আমরা এখন **নতুন v1 পদ্ধতি** ব্যবহার করছি। এর জন্য "server key"-এর বদলে
> Firebase থেকে একটা **Service Account JSON ফাইল** লাগবে (নিচে কীভাবে নিতে হয় দেখানো আছে)।

---

## অ্যাপে যা যা আগে থেকেই করা আছে (তোমার কিছু করতে হবে না)
- `google-services.json` → `android/app/`-এ আছে (Firebase project `bdtuition-1fad3`)।
- Gradle-এ plugin, desugaring, `minSdk 23` বসানো।
- Package: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`।
- `lib/services/push_service.dart` → FCM চালু করে, "Tuition Alerts" (channel id: `tuition_alerts`)
  channel বানায়, login-এর পর device token backend-এ `POST /api/fcm-token`-এ পাঠায়।
- `AndroidManifest.xml` → Android 13+ এর জন্য `POST_NOTIFICATIONS` permission।
- `main.dart` → Firebase init + background handler।

> **লাইভ DB (`mohaqtzn_wp37`)-এ যা confirmed:**
> - `teachers` টেবিল → `expected_area`, এবং `fcm_token` (নিচে যোগ করব)
> - `tuitions` টেবিল → `area`, `tuition_code`, `salary`

---

# ধাপ ১ — teachers টেবিলে fcm_token কলাম যোগ করা + route

## ১ক) phpMyAdmin-এ SQL চালাও
cPanel → **phpMyAdmin** → বাঁ পাশ থেকে `mohaqtzn_wp37` database → উপরে **SQL** ট্যাব →
এই লাইনটা পেস্ট করে **Go** চাপো:

```sql
ALTER TABLE teachers ADD COLUMN fcm_token VARCHAR(255) NULL;
```

এতে প্রতিটা টিচারের ফোনের token জমা রাখার জায়গা তৈরি হলো।

## ১খ) route যোগ করো (panel.bdtuition.com)
`routes/api.php` ফাইলে (cPanel → File Manager → panel.bdtuition.com এর ফোল্ডার → `routes/api.php`)
এই route যোগ করো — অ্যাপ এই ঠিকানাতেই token পাঠায়:

```php
Route::middleware('auth:sanctum')->post('/fcm-token', function (\Illuminate\Http\Request $request) {
    $request->user()->update(['fcm_token' => $request->input('token')]);
    return response()->json(['success' => true]);
});
```

---

# ধাপ ২ — Firebase থেকে Service Account JSON নেওয়া

1. https://console.firebase.google.com → তোমার project **bdtuition-1fad3** খোলো।
2. উপরে গিয়ার আইকন ⚙️ → **Project settings**।
3. **Service accounts** ট্যাব → **Generate new private key** বাটন → **Generate key**।
4. একটা `.json` ফাইল ডাউনলোড হবে (নাম যেমন `bdtuition-1fad3-xxxx.json`)।

### এই ফাইলটা cPanel-এ আপলোড করো — কিন্তু নিরাপদ জায়গায়
এটা যেন কেউ ব্রাউজার দিয়ে ডাউনলোড করতে না পারে, তাই **public_html-এর বাইরে** রাখো।
cPanel → File Manager → `/home/mohaqtzn/` এ একটা নতুন ফোল্ডার বানাও `firebase`, তার ভিতরে
ফাইলটা আপলোড করো। মানে পুরো path হবে যেমন:

```
/home/mohaqtzn/firebase/bdtuition-service-account.json
```

> নাম যা খুশি রাখতে পারো, শুধু নিচের `.env`-এ ঠিক ওই path-টাই বসাও।

### .env-এ path যোগ করো
cPanel → File Manager → panel.bdtuition.com এর মূল ফোল্ডারে `.env` ফাইল খোলো, নিচে যোগ করো:

```
FCM_SERVICE_ACCOUNT=/home/mohaqtzn/firebase/bdtuition-service-account.json
```

সেভ করার পর একবার cache পরিষ্কার করলে ভালো (Terminal থাকলে):
`php artisan config:clear`

---

# ধাপ ৩ — নতুন টিউশন হলে notification পাঠানো

আমি তোমার জন্য দুইটা রেডি ফাইল বানিয়ে দিয়েছি (প্রজেক্টের `guardian_backend/` ফোল্ডারে):

- **`FcmV1.php`** — এটাই আসল কাজটা করে (নতুন v1 পদ্ধতিতে notification পাঠায়)। কিছু বুঝতে হবে না।
- **`send_tuition_push.php`** — এখান থেকে কোডের অংশটা তোমার controller-এ বসাতে হবে।

## যা করবে:
1. `FcmV1.php` ফাইলটা cPanel-এ আপলোড করো — যে ফোল্ডারে তোমার tuition controller/route আছে,
   বা `app/Services/` এর মতো সুবিধাজনক জায়গায়। (path মনে রাখো।)
2. যেখানে **নতুন টিউশন সেভ হয়** (tuition store controller, `$tuition` তৈরি হওয়ার ঠিক পরে),
   সেখানে `send_tuition_push.php`-এর `---- paste from here ----` থেকে `---- paste up to here ----`
   পর্যন্ত অংশটা বসাও। উপরে `require_once` লাইনে `FcmV1.php`-এর সঠিক path দাও।

এই কোড নিজে থেকে:
- ওই এলাকার (`expected_area` মিলে যাওয়া) সব টিচার খুঁজে বের করে,
- যাদের `fcm_token` আছে, তাদের ফোনে notification পাঠায় —
  **টাইটেল:** নতুন টিউশন আপনার এলাকায়! · **বডি:** `CODE — এলাকা, ৳বেতন/মাস`
- কোনো একটা token নষ্ট হলেও টিউশন তৈরি আটকাবে না (সব guard করা আছে)।

---

# ধাপ ৪ — টেস্ট

1. backend-এ উপরের সব বসানোর পর, GitHub Actions থেকে আসা নতুন APK ফোনে install করো।
2. অ্যাপে **login** করো — এতে ওই ফোনের token আপনাআপনি `teachers.fcm_token`-এ জমা হবে
   (phpMyAdmin-এ teachers টেবিল খুলে দেখতে পারো token বসেছে কিনা)।
3. অ্যাপটা **পুরো বন্ধ** করে দাও।
4. admin panel থেকে ওই টিচারের `expected_area`-এর সাথে মিলে এমন এলাকায় একটা **টেস্ট টিউশন**
   পোস্ট করো।
5. ফোনের উপরের notification bar-এ notification আসা উচিত — অ্যাপ বন্ধ থাকলেও।

কোথাও আটকে গেলে বা error দেখলে আমাকে error লেখাটা পাঠাও — আমি ঠিক করে দেব।

---

## এক নজরে চেকলিস্ট
- [ ] phpMyAdmin-এ `ALTER TABLE teachers ADD COLUMN fcm_token ...` চালানো
- [ ] `routes/api.php`-এ `/fcm-token` route যোগ
- [ ] Firebase থেকে Service Account JSON ডাউনলোড
- [ ] JSON ফাইল public_html-এর বাইরে আপলোড
- [ ] `.env`-এ `FCM_SERVICE_ACCOUNT=...` যোগ
- [ ] `FcmV1.php` আপলোড
- [ ] tuition controller-এ `send_tuition_push.php`-এর অংশ পেস্ট
- [ ] নতুন APK install → login → অ্যাপ বন্ধ করে টেস্ট
