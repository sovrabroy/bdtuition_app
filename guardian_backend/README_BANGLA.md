# Guardian Backend — cPanel-এ বসানোর নিয়ম (বাংলা)

এই ফোল্ডারের সব ফাইল **`panel.bdtuition.com`** অ্যাপে যাবে — কারণ মোবাইল অ্যাপ
`https://panel.bdtuition.com/api` কে কল করে। `manage.bdtuition.com`-এ নয়।
(teacher/tuition/assignment টেবিল panel-এও আছে, কারণ teacher API ওগুলো পড়ে।)

⚠️ কোনো পুরনো ফাইল মুছবেন না বা বদলাবেন না। শুধু নিচের নতুন ফাইলগুলো কপি করবেন
আর routes/api.php-তে কয়েকটা লাইন যোগ করবেন।

---

## ধাপ ১ — ফাইলগুলো এই জায়গায় আপলোড করুন

cPanel File Manager দিয়ে (বা scp দিয়ে) এই ফাইলগুলো ঠিক এই path-এ রাখুন:

| এই ফোল্ডারের ফাইল | panel.bdtuition.com-এ যেখানে যাবে |
|---|---|
| `app/Models/Guardian.php` | `app/Models/Guardian.php` |
| `app/Models/GuardianReview.php` | `app/Models/GuardianReview.php` |
| `app/Models/GuardianTutorRequest.php` | `app/Models/GuardianTutorRequest.php` |
| `app/Http/Controllers/Api/GuardianAuthController.php` | `app/Http/Controllers/Api/GuardianAuthController.php` |
| `app/Http/Controllers/Api/GuardianController.php` | `app/Http/Controllers/Api/GuardianController.php` |
| `database/migrations/2026_07_31_000001_create_guardians_table.php` | `database/migrations/` (একই নামে) |
| `database/migrations/2026_07_31_000002_create_guardian_reviews_table.php` | `database/migrations/` |
| `database/migrations/2026_07_31_000003_create_guardian_tutor_requests_table.php` | `database/migrations/` |

## ধাপ ২ — routes যোগ করুন

`ROUTES_TO_ADD.php` ফাইলটা খুলুন। ভেতরের নির্দেশ অনুযায়ী:
- উপরের ২টা `use ...` লাইন → `panel.bdtuition.com/routes/api.php`-এর উপরে অন্য
  use লাইনগুলোর পাশে বসান।
- route ব্লকটা → ওই ফাইলের একদম নিচে বসান।

## ধাপ ৩ — migration চালান (নতুন টেবিল বানাবে)

SSH/cPanel Terminal-এ:

```bash
cd ~/panel.bdtuition.com
php artisan migrate
php artisan config:clear
php artisan route:clear
php artisan cache:clear
```

`php artisan migrate` চালালে ৩টা নতুন টেবিল হবে: guardians, guardian_reviews,
guardian_tutor_requests। পুরনো কোনো টেবিলে হাত পড়বে না।

## ধাপ ৪ — কাজ করছে কিনা পরীক্ষা করুন

```bash
php artisan route:list | grep guardian
```
৭টা guardian route দেখা উচিত (register, login, logout, profile, teachers,
apply, requests, review, reviews)।

তারপর register টেস্ট (নিজের ফোন দিয়ে):
```bash
curl -X POST https://panel.bdtuition.com/api/guardian/register \
  -H "Accept: application/json" \
  -d "name=Test&phone=01700000000&password=1234"
```
`"success":true` আর একটা `token` ফেরত এলে backend তৈরি।

---

## গুরুত্বপূর্ণ: "assigned teacher" খুঁজে পাওয়ার শর্ত

Guardian যে ফোন দিয়ে register করবে, সেই ফোনটা `tuitions.gurdian_number`
কলামে থাকতে হবে (যে tuition-এ teacher assign করা আছে)। মিললে অ্যাপে সেই
teacher-এর details দেখা যাবে। ফোন নম্বরের ফরম্যাট আলাদা হলেও (017.. / +88017..)
কোড শুধু সংখ্যা মিলিয়ে দেখে, তাই সমস্যা হবে না।
