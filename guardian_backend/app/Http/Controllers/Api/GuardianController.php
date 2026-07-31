<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GuardianReview;
use App\Models\GuardianTutorRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * Guardian data endpoints: see the teacher(s) assigned to me, apply for a
 * tutor, and review my teacher.
 *
 * IMPORTANT LINKING LOGIC (matches your real schema):
 *   - A guardian's phone is stored on the TUITION as `tuitions.gurdian_number`
 *     (note the spelling "gurdian" — that is how the column is actually named).
 *   - `assignments` has NO guardian phone; it links via `assignments.tuition_id`
 *     to the tuition, and carries `assignments.teacher_id`.
 *   - So: my phone -> tuitions.gurdian_number -> tuition.id
 *          -> assignments.tuition_id -> assignments.teacher_id -> teacher.
 *
 * Everything is read with the query builder and defensive column fallbacks so
 * it does not depend on Eloquent models we don't control, and touches nothing
 * that already exists.
 */
class GuardianController extends Controller
{
    /** Teacher table columns we try, in order, for each display field. */
    private array $teacherNameCols  = ['name', 'full_name', 'teacher_name'];
    private array $teacherPhoneCols = ['phone', 'phone_number', 'mobile', 'contact'];
    private array $teacherCodeCols  = ['teacher_code', 'code'];
    private array $teacherPhotoCols = ['personal_photo', 'photo', 'image', 'avatar'];

    public function myTeachers(Request $request)
    {
        $guardian = $request->user();
        $phone = $this->normalizePhone($guardian->phone);

        // 1) Find tuitions whose guardian number matches this guardian's phone.
        //    Compare on digits only so 017.. / +88017.. / 8801.. all match.
        $tuitions = DB::table('tuitions')
            ->get(['id', 'tuition_code', 'city', 'area', 'tuition_address',
                   'class', 'medium', 'prefered_subjects', 'salary',
                   'gurdian_name', 'gurdian_number', 'status'])
            ->filter(function ($t) use ($phone) {
                return $t->gurdian_number
                    && $this->normalizePhone($t->gurdian_number) === $phone;
            });

        if ($tuitions->isEmpty()) {
            return response()->json([
                'success'  => true,
                'teachers' => [],
                'message'  => 'No assigned teacher found for your number yet.',
            ]);
        }

        $tuitionIds = $tuitions->pluck('id')->all();
        $tuitionById = $tuitions->keyBy('id');

        // 2) Assignments for those tuitions -> teacher_id.
        $assignments = DB::table('assignments')
            ->whereIn('tuition_id', $tuitionIds)
            ->get(['id', 'teacher_id', 'tuition_id', 'status',
                   'due_ammount', 'next_payment', 'date']);

        if ($assignments->isEmpty()) {
            return response()->json([
                'success'  => true,
                'teachers' => [],
                'message'  => 'Your tuition is posted but no teacher is assigned yet.',
            ]);
        }

        // 3) Load teacher rows and shape the response.
        $teacherIds = $assignments->pluck('teacher_id')->filter()->unique()->all();
        $teacherCols = $this->existingColumns('teachers', array_merge(
            ['id'], $this->teacherNameCols, $this->teacherPhoneCols,
            $this->teacherCodeCols, $this->teacherPhotoCols,
            ['university', 'department', 'gender']
        ));
        $teachers = DB::table('teachers')
            ->whereIn('id', $teacherIds)
            ->get($teacherCols)
            ->keyBy('id');

        $result = [];
        foreach ($assignments as $a) {
            $t = $teachers->get($a->teacher_id);
            $tuition = $tuitionById->get($a->tuition_id);
            $result[] = [
                'assignment_id' => $a->id,
                'status'        => $a->status,
                'due_amount'    => $a->due_ammount,
                'next_payment'  => $a->next_payment,
                'assigned_date' => $a->date,
                'tuition' => $tuition ? [
                    'tuition_code' => $tuition->tuition_code,
                    'class'        => $tuition->class,
                    'subjects'     => $tuition->prefered_subjects,
                    'area'         => $tuition->area,
                    'city'         => $tuition->city,
                    'address'      => $tuition->tuition_address,
                    'salary'       => $tuition->salary,
                ] : null,
                'teacher' => $t ? [
                    'id'    => $t->id,
                    'name'  => $this->pick($t, $this->teacherNameCols),
                    'phone' => $this->pick($t, $this->teacherPhoneCols),
                    'code'  => $this->pick($t, $this->teacherCodeCols),
                    'photo' => $this->pick($t, $this->teacherPhotoCols),
                    'university' => $t->university ?? null,
                    'department' => $t->department ?? null,
                    'gender'     => $t->gender ?? null,
                ] : null,
            ];
        }

        return response()->json([
            'success'  => true,
            'teachers' => $result,
        ]);
    }

    public function applyForTutor(Request $request)
    {
        $guardian = $request->user();

        $validator = Validator::make($request->all(), [
            'student_class'          => 'required|string|max:255',
            'subjects'               => 'required|string|max:500',
            'city'                   => 'nullable|string|max:255',
            'area'                   => 'nullable|string|max:255',
            'address'                => 'nullable|string|max:500',
            'preferred_tutor_gender' => 'nullable|string|max:20',
            'budget'                 => 'nullable|string|max:50',
            'note'                   => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $req = GuardianTutorRequest::create([
            'guardian_id'            => $guardian->id,
            'student_class'          => $request->student_class,
            'subjects'               => $request->subjects,
            'city'                   => $request->city ?? $guardian->city,
            'area'                   => $request->area ?? $guardian->area,
            'address'                => $request->address ?? $guardian->address,
            'preferred_tutor_gender' => $request->preferred_tutor_gender,
            'budget'                 => $request->budget,
            'note'                   => $request->note,
            'status'                 => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tutor request submitted. Our team will contact you.',
            'request' => $req,
        ], 201);
    }

    public function myRequests(Request $request)
    {
        $requests = GuardianTutorRequest::where('guardian_id', $request->user()->id)
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'success'  => true,
            'requests' => $requests,
        ]);
    }

    public function submitReview(Request $request)
    {
        $guardian = $request->user();

        $validator = Validator::make($request->all(), [
            'teacher_id'    => 'required|integer',
            'assignment_id' => 'nullable|integer',
            'rating'        => 'required|integer|min:1|max:5',
            'comment'       => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        // One review per guardian+teacher: update if it exists, else create.
        $review = GuardianReview::updateOrCreate(
            [
                'guardian_id' => $guardian->id,
                'teacher_id'  => $request->teacher_id,
            ],
            [
                'assignment_id' => $request->assignment_id,
                'rating'        => $request->rating,
                'comment'       => $request->comment,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Thank you for your review.',
            'review'  => $review,
        ]);
    }

    public function myReviews(Request $request)
    {
        $reviews = GuardianReview::where('guardian_id', $request->user()->id)
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'success' => true,
            'reviews' => $reviews,
        ]);
    }

    // ---- helpers ----------------------------------------------------------

    /** Keep only digits and drop a leading 88 country code for comparison. */
    private function normalizePhone(?string $phone): string
    {
        $digits = preg_replace('/\D+/', '', (string) $phone);
        if (strlen($digits) > 11 && str_starts_with($digits, '88')) {
            $digits = substr($digits, 2);
        }
        return $digits;
    }

    /** First non-empty column value from a candidate list. */
    private function pick($row, array $cols)
    {
        foreach ($cols as $c) {
            if (isset($row->$c) && $row->$c !== '' && $row->$c !== null) {
                return $row->$c;
            }
        }
        return null;
    }

    /** Intersect a wanted column list with columns that actually exist. */
    private function existingColumns(string $table, array $wanted): array
    {
        $have = \Schema::getColumnListing($table);
        $cols = array_values(array_unique(array_intersect($wanted, $have)));
        return empty($cols) ? ['*'] : $cols;
    }
}
