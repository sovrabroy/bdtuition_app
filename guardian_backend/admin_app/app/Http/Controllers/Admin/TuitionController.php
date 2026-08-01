<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Imports\TuitionsImport;
use App\Mail\TuitionNotification;
use App\Models\Agent;
use App\Models\Area;
use App\Models\Teacher;
use App\Models\Tuition;
use App\Services\FcmV1;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Maatwebsite\Excel\Facades\Excel;
use App\Jobs\SendWhatsappJob;
class TuitionController extends Controller
{
    /**
     * Display a listing of tuitions.
     */
    public function index(Request $request)
    {
        if ($this->isPendingCancellationCheckerRequest($request)) {
            abort_unless(has_permission('tuitions.pending-cancellations.view'), 403);
        }

        $query = $this->buildFilteredQuery($request);
        $tuitions = $query->orderBy('id', 'desc')->paginate(15);
        $agents = Agent::all();

        // dd($tuitions);
        return view('admin.tuitions.tuitions', compact('tuitions', 'agents'));
    }

    public function copy(Request $request): JsonResponse
    {
        $tuitions = $this->buildFilteredQuery($request)
            ->orderBy('id', 'desc')
            ->get();
        $text = $tuitions
            ->map(fn (Tuition $tuition): string => $this->formatTuitionCopyBlock($tuition))
            ->implode("\n\n--------------------\n\n");

        return response()->json([
            'success' => true,
            'text' => $text,
        ]);
    }

    protected function isPendingCancellationCheckerRequest(Request $request): bool
    {
        return $request->input('status') === 'Available'
            && $request->input('explanation_approval') === 'pending';
    }

    protected function buildFilteredQuery(Request $request): Builder
    {
        $query = Tuition::with(['agent']);

        if ($request->filled('gurdian_serial')) {
            $query->where('gurdian_serial', $request->gurdian_serial);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('gurdian_no_seen_by') && strtolower(trim($request->gurdian_no_seen_by)) !== 'all') {
            $query->where('gurdian_no_seen_by', trim($request->gurdian_no_seen_by));
        }

        if ($request->filled('search_date')) {
            $searchDate = trim($request->search_date);
            $dates = explode(' - ', $searchDate);

            if (count($dates) === 2 && trim($dates[0]) !== '' && trim($dates[1]) !== '') {
                $query->whereBetween('agent_seen_time', [
                    date('Y-m-d 00:00:00', strtotime(trim($dates[0]))),
                    date('Y-m-d 23:59:59', strtotime(trim($dates[1]))),
                ]);
            } else {
                $query->whereDate('agent_seen_time', date('Y-m-d', strtotime($searchDate)));
            }
        }

        if ($request->filled('city')) {
            $query->where('city', $request->city);
        }

        if ($request->filled('gender')) {
            $selectedGender = strtolower(trim($request->gender));

            $query->where(function (Builder $query) use ($selectedGender) {
                $normalizedGenderSql = "LOWER(COALESCE(prefered_gender, ''))";

                if ($selectedGender === 'female') {
                    $query->whereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])(female|lady|woman|women|girl|girls)([^a-z]|$)'")
                        ->orWhereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])(any|both)([^a-z]|$)'")
                        ->orWhere(function (Builder $subQuery) use ($normalizedGenderSql) {
                            $subQuery->whereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])male([^a-z]|$)'")
                                ->whereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])(female|lady|woman|women|girl|girls)([^a-z]|$)'");
                        });

                    return;
                }

                $query->whereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])male([^a-z]|$)'")
                    ->orWhereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])(any|both)([^a-z]|$)'")
                    ->orWhere(function (Builder $subQuery) use ($normalizedGenderSql) {
                        $subQuery->whereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])male([^a-z]|$)'")
                            ->whereRaw("$normalizedGenderSql REGEXP '(^|[^a-z])(female|lady|woman|women|girl|girls)([^a-z]|$)'");
                    });
            });
        }

        if ($request->filled('tuition_code')) {
            $query->where('tuition_code', $request->tuition_code);
        }

        if ($request->filled('tuition_address')) {
            $query->where(function ($query) use ($request) {
                $query->where('area', 'like', '%'.$request->tuition_address.'%')
                    ->orWhere('city', 'like', '%'.$request->tuition_address.'%')
                    ->orWhere('tuition_address', 'like', '%'.$request->tuition_address.'%');
            });
        }

        if ($request->filled('explanation_approval')) {
            $query->where('explanation_approval', $request->explanation_approval);
        }

        return $query;
    }

    protected function formatTuitionCopyBlock(Tuition $tuition): string
    {
        $titleParts = [];

        if (! empty($tuition->prefered_university)) {
            $titleParts[] = $this->normalizeCopyValue($tuition->prefered_university);
        }

        if (! empty($tuition->prefered_gender)) {
            $titleParts[] = $this->normalizeCopyValue($tuition->prefered_gender);
        }

        $titleParts[] = 'Tutor Wanted at';
        $titleParts[] = $this->normalizeCopyValue(collect([
            $tuition->tuition_address,
            $tuition->area,
            $tuition->city,
        ])->filter(fn (?string $value): bool => filled($value))->implode(', '));

        $lines = [
            implode(' ', array_filter($titleParts)),
            '',
            'Class: '.$this->normalizeCopyValue($tuition->class),
            'Medium: '.$this->normalizeCopyValue($tuition->medium),
            'Subject: '.$this->normalizeCopyValue($tuition->prefered_subjects),
            'Day: '.$this->normalizeCopyValue($tuition->day_per_week),
            'Time: '.$this->normalizeCopyValue($tuition->prefered_time),
            'Duration: '.$this->normalizeCopyValue($tuition->prefered_duration),
            'Salary: '.$this->normalizeCopyValue($tuition->formatted_salary),
            'Tuition code: '.$this->normalizeCopyValue($tuition->tuition_code),
            'Media Fee: '.$this->normalizeCopyValue(isset($tuition->media_fee) ? $tuition->media_fee.'%' : null),
            '',
            'Apply reference : Arko',
            'SMS your short CV to WhatsApp: '.$this->normalizeCopyValue(settings('phone_number')),
        ];

        return implode("\n", $lines);
    }

    protected function normalizeCopyValue(mixed $value): string
    {
        $normalizedValue = trim((string) $value);

        if ($normalizedValue === '') {
            return 'N/A';
        }

        return preg_replace('/\s+/u', ' ', str_replace(["\r\n", "\r", "\n", "\t"], [' ', ' ', ' ', ' '], $normalizedValue)) ?? 'N/A';
    }

    /**
     * Show the form for creating a new tuition.
     */
    public function create()
    {
        $tuition = new Tuition;
        $cities = [
            'Bagerhat',
            'Bandarban',
            'Barisal',
            'Barguna',
            'Bhola',
            'Bogura',
            'Brahmanbaria',
            'Chandpur',
            'Chapainawabganj',
            'Chattogram',
            'Chuadanga',
            'Comilla',
            'Cox\'s Bazar',
            'Dhaka',
            'Dinajpur',
            'Faridpur',
            'Feni',
            'Gaibandha',
            'Gazipur',
            'Gopalganj',
            'Habiganj',
            'Jaipurhat',
            'Jamalpur',
            'Jessore',
            'Jhalokati',
            'Jhenaidah',
            'Joypurhat',
            'Khagrachhari',
            'Khulna',
            'Kishoreganj',
            'Kurigram',
            'Kushtia',
            'Lalmonirhat',
            'Lakshmipur',
            'Madaripur',
            'Magura',
            'Manikganj',
            'Meherpur',
            'Moulvibazar',
            'Munshiganj',
            'Mymensingh',
            'Naogaon',
            'Narail',
            'Narayanganj',
            'Narsingdi',
            'Natore',
            'Netrokona',
            'Nilphamari',
            'Noakhali',
            'Pabna',
            'Panchagarh',
            'Patuakhali',
            'Pirojpur',
            'Rajbari',
            'Rajshahi',
            'Rangamati',
            'Rangpur',
            'Satkhira',
            'Shariatpur',
            'Sherpur',
            'Sirajganj',
            'Sunamganj',
            'Sylhet',
            'Tangail',
            'Thakurgaon',
        ];
        $areas = Area::orderBy('area')->pluck('area');

        return view('admin.tuitions.create', compact('tuition', 'cities', 'areas'));
    }

    /**
     * Store a newly created tuition.
     */
    public function store(Request $request)
    {
        $canManageStatus = has_permission('tuitions.status');

        $validated = $request->validate([
            'tuition_code' => 'required|unique:tuitions',
            'gurdian_serial' => 'required',
            'gurdian_name' => 'nullable',
            'gurdian_number' => 'nullable',
            'city' => 'required',
            'area' => 'required',
            'tuition_address' => 'nullable',
            'medium' => 'required',
            'class' => 'required',
            'group_of_study' => 'nullable',
            'prefered_subjects' => 'nullable',
            'prefered_university' => 'nullable',
            'prefered_gender' => 'required|in:Male/Female,Male,Female',
            'day_per_week' => 'required|numeric|min:1|max:7',
            'salary' => 'required|numeric|min:0',
            'media_fee' => 'required|numeric|min:0|max:100',
            'prefered_time' => 'nullable',
            'prefered_duration' => 'nullable',
            'status' => ($canManageStatus ? 'required' : 'nullable').'|in:Available,Booked,Cancelled,Pending,Processing,Sold',
            'explanation' => $canManageStatus ? 'required_if:status,Cancelled' : 'nullable',
        ]);

        try {
            $validated['group_of_stduy'] = $validated['group_of_study'] ?? null;
            unset($validated['group_of_study']);

            $validated['status'] = $canManageStatus ? ($validated['status'] ?? 'Available') : 'Available';

            if ($validated['status'] === 'Cancelled') {
                $validated['status'] = 'Available';
                $validated['explanation_approval'] = 'pending';
            } elseif ($validated['status'] !== 'Pending') {
                $validated['explanation_approval'] = null;
            }

            if ($validated['status'] !== 'Available') {
                $validated['status_changed_by'] = $this->statusActorName();
                $validated['status_changed_at'] = now();
            }

            $tuition = Tuition::create($validated);
            if ($request->has('send_notification')) {
                $this->sendNotificationsToTeachers($tuition);
            }

            $notifyMessage = $request->input('status') === 'Cancelled'
                ? 'Cancellation request submitted successfully. Tuition status is now Pending for admin approval.'
                : 'Tuition created successfully.';

            return redirect()->route('manage.tuitions.index')->with('notify', $notifyMessage);
        } catch (\Exception $e) {
            return back()->with('notify', 'Failed to create tuition. '.$e->getMessage())->withInput();
        }
    }

    /**
     * Show the form for editing the specified tuition.
     */
    public function edit(Tuition $tuition)
    {
        $tuition->area = $this->normalizeTextValue($tuition->area);
        $tuition->prefered_gender = $this->normalizePreferredGenderValue($tuition->prefered_gender);
        $tuition->day_per_week = $this->normalizeNumericInputValue($tuition->day_per_week);
        $tuition->salary = $this->normalizeNumericInputValue($tuition->salary);
        $tuition->media_fee = $this->normalizeNumericInputValue($tuition->media_fee);
        $tuition->group_of_study = $this->normalizeTextValue($tuition->group_of_stduy);
        $cities = [
            'Bagerhat',
            'Bandarban',
            'Barisal',
            'Barguna',
            'Bhola',
            'Bogura',
            'Brahmanbaria',
            'Chandpur',
            'Chapainawabganj',
            'Chattogram',
            'Chuadanga',
            'Comilla',
            'Cox\'s Bazar',
            'Dhaka',
            'Dinajpur',
            'Faridpur',
            'Feni',
            'Gaibandha',
            'Gazipur',
            'Gopalganj',
            'Habiganj',
            'Jaipurhat',
            'Jamalpur',
            'Jessore',
            'Jhalokati',
            'Jhenaidah',
            'Joypurhat',
            'Khagrachhari',
            'Khulna',
            'Kishoreganj',
            'Kurigram',
            'Kushtia',
            'Lalmonirhat',
            'Lakshmipur',
            'Madaripur',
            'Magura',
            'Manikganj',
            'Meherpur',
            'Moulvibazar',
            'Munshiganj',
            'Mymensingh',
            'Naogaon',
            'Narail',
            'Narayanganj',
            'Narsingdi',
            'Natore',
            'Netrokona',
            'Nilphamari',
            'Noakhali',
            'Pabna',
            'Panchagarh',
            'Patuakhali',
            'Pirojpur',
            'Rajbari',
            'Rajshahi',
            'Rangamati',
            'Rangpur',
            'Satkhira',
            'Shariatpur',
            'Sherpur',
            'Sirajganj',
            'Sunamganj',
            'Sylhet',
            'Tangail',
            'Thakurgaon',
        ];
        $areas = Area::pluck('area', 'area');

        if ($tuition->area !== '' && ! $areas->contains($tuition->area)) {
            $areas->prepend($tuition->area, $tuition->area);
        }

        return view('admin.tuitions.create', compact('tuition', 'cities', 'areas'));
    }

    /**
     * Update the specified tuition.
     */
    public function update(Request $request, Tuition $tuition)
    {
        $canManageStatus = has_permission('tuitions.status');
        $originalStatus = $tuition->status;

        $validated = $request->validate([
            'tuition_code' => 'required|unique:tuitions,tuition_code,'.$tuition->id,
            'gurdian_serial' => 'required',
            'gurdian_name' => 'nullable',
            'gurdian_number' => 'nullable',
            'city' => 'required',
            'area' => 'required',
            'tuition_address' => 'nullable',
            'medium' => 'required',
            'class' => 'required',
            'group_of_study' => 'nullable',
            'prefered_subjects' => 'nullable',
            'prefered_university' => 'nullable',
            'prefered_gender' => 'required|in:Male/Female,Male,Female',
            'day_per_week' => 'required|numeric|min:1|max:7',
            'salary' => 'required|numeric|min:0',
            'media_fee' => 'required|numeric|min:0|max:100',
            'prefered_time' => 'nullable',
            'prefered_duration' => 'nullable',
            'status' => ($canManageStatus ? 'required' : 'nullable').'|in:Available,Booked,Cancelled,Pending,Processing,Sold',
            'explanation' => $canManageStatus ? 'required_if:status,Cancelled' : 'nullable',
        ]);

        try {
            $validated['group_of_stduy'] = $validated['group_of_study'] ?? null;
            unset($validated['group_of_study']);

            if (! $canManageStatus) {
                $validated['status'] = $originalStatus;
            }

            $requestedStatus = $validated['status'] ?? $originalStatus;

            if ($requestedStatus === 'Cancelled' && $originalStatus !== 'Cancelled') {
                $validated['status'] = $originalStatus;
                $validated['explanation_approval'] = 'pending';
            } elseif (! in_array($requestedStatus, ['Pending', 'Cancelled'], true)) {
                $validated['explanation_approval'] = null;
            }

            if (($validated['status'] ?? $originalStatus) !== $originalStatus) {
                $validated['status_changed_by'] = $this->statusActorName();
                $validated['status_changed_at'] = now();
            }

            $tuition->update($validated);
            if ($request->has('send_notification')) {
                $this->sendNotificationsToTeachers($tuition);
            }

            $notifyMessage = $request->input('status') === 'Cancelled' && $originalStatus !== 'Cancelled'
                ? 'Cancellation request submitted successfully. Tuition status is now Pending for admin approval.'
                : 'Tuition updated successfully.';

            return redirect()->route('manage.tuitions.index')->with('notify', $notifyMessage);
        } catch (\Exception $e) {
            return back()->with('notify', 'Failed to update tuition. '.$e->getMessage())->withInput();
        }
    }

    /**
     * Remove the specified tuition.
     */
    public function destroy(Tuition $tuition)
    {
        $tuition->delete();

        return redirect()
            ->route('manage.tuitions.index')
            ->with('notify', 'Tuition deleted successfully');
    }

    /**
     * Update status for multiple tuitions
     */
    public function updateStatus(Request $request)
    {
        $validated = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:tuitions,id',
            'status' => 'required|in:Available,Booked,Cancelled,Pending,Processing',
        ]);

        Tuition::whereIn('id', $request->ids)->update([
            'status' => $request->status,
            'status_changed_by' => $this->statusActorName(),
            'status_changed_at' => now(),
        ]);

        return redirect()
            ->route('manage.tuitions.index')
            ->with('notify', count($request->ids).' Tuitions updated successfully');
    }

    /**
     * Delete multiple tuitions
     */
    public function destroyMultiple(Request $request)
    {
        $validated = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:tuitions,id',
        ]);

        Tuition::whereIn('id', $request->ids)->delete();

        return redirect()
            ->route('manage.tuitions.index')
            ->with('notify', count($request->ids).' Tuitions deleted successfully');
    }

    /**
     * Delete multiple tuitions
     */
    public function bulkDelete(Request $request)
    {
        $validated = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:tuitions,id',
        ]);

        $count = Tuition::whereIn('id', $request->ids)->delete();

        return response()->json([
            'notify' => true,
            'message' => $count.' tuitions deleted successfully',
        ]);
    }

    /**
     * Update status for multiple tuitions
     */
    public function bulkStatus(Request $request)
    {
        $validated = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:tuitions,id',
            'status' => 'required|in:Available,Booked,Cancelled,Pending,Processing',
        ]);

        $count = Tuition::whereIn('id', $request->ids)->update([
            'status' => $request->status,
            'status_changed_by' => $this->statusActorName(),
            'status_changed_at' => now(),
        ]);

        return response()->json([
            'notify' => true,
            'message' => $count.' tuitions updated successfully',
        ]);
    }

    /**
     * Upload tuitions from Excel file
     */
    public function uploadExcel(Request $request)
    {
        $request->validate([
            'excel_file' => 'required|mimes:xlsx,xls,csv|max:2048',
        ]);

        try {
            DB::beginTransaction();

            Excel::import(new TuitionsImport, $request->file('excel_file'));

            DB::commit();

            return back()->with('notify', 'Tuitions imported successfully.');
        } catch (\Exception $e) {
            DB::rollBack();

            return back()->with('notify', 'Failed to import tuitions: '.$e->getMessage());
        }
    }

    /**
     * Upload tuitions from CSV file
     */
    public function upload(Request $request)
    {
        $request->validate([
            'csv_file_input' => 'required|mimes:csv,txt|max:2048',
        ]);

        if (! $request->hasFile('csv_file_input')) {
            return back()->with('notify', 'Please upload a CSV file');
        }

        $file = $request->file('csv_file_input');
        $csvData = [];

        if (($handle = fopen($file->getPathname(), 'r')) !== false) {
            while (($data = fgetcsv($handle, 1000, ',')) !== false) {
                $csvData[] = $data;
            }
            fclose($handle);
        }

        // Remove header row
        array_shift($csvData);

        $successCount = 0;
        $errorCount = 0;

        DB::beginTransaction();
        try {
            foreach ($csvData as $row) {
                $row = array_map(
                    static fn (mixed $value): mixed => is_string($value) ? trim($value) : $value,
                    $row
                );

                if (count(array_filter($row, static fn (mixed $value): bool => $value !== null && $value !== '')) === 0) {
                    continue;
                }

                $tuition = Tuition::create([
                    'tuition_code' => $row[0] ?? null,
                    'gurdian_serial' => $row[1] ?? null,
                    'gurdian_number' => $row[2] ?? null,
                    'area' => $row[3] ?? null,
                    'city' => $row[4] ?? null,
                    'tuition_address' => $row[5] ?? null,
                    'medium' => $row[6] ?? null,
                    'class' => $row[7] ?? null,
                    'group_of_study' => $row[8] ?? null,
                    'prefered_subjects' => $row[9] ?? null,
                    'prefered_university' => $row[10] ?? null,
                    'prefered_gender' => $row[11] ?? null,
                    'day_per_week' => $row[12] ?? null,
                    'salary' => $row[13] ?? null,
                    'media_fee' => empty($row[14]) ? 60 : $row[14],
                    'prefered_time' => $row[15] ?? null,
                    'prefered_duration' => empty($row[16]) ? '2 Hours' : $row[16],
                    'status' => 'Available',
                ]);

                if ($tuition) {
                    $successCount++;
                } else {
                    $errorCount++;
                }
            }

            DB::commit();

            return redirect()->route('manage.tuitions.index')->with('notify', "Successfully imported {$successCount} records.");
        } catch (\Throwable $e) {
            DB::rollBack();

            return back()->with('notify', 'Failed to import tuitions: '.$e->getMessage());
        }
    }

    public function updateSeenBy(Request $request)
    {
        abort_unless(has_permission('tuitions.guardian-number.view'), 403);

        $tuition = Tuition::findOrFail($request->id);
        $viewerName = auth()->guard('agent')->user()?->name
            ?? auth()->guard('web')->user()?->username
            ?? 'Admin';

        if ($tuition->gurdian_no_seen_by) {
            return response()->json([
                'notify' => false,
                'guardian_number' => '',
            ]);
        }

        $tuition->update([
            'gurdian_no_seen_by' => $viewerName,
            'agent_seen_time' => now(),
        ]);

        return response()->json([
            'notify' => true,
            'guardian_number' => $tuition->gurdian_number,
        ]);
    }

    /**
     * Trigger a click-to-call between the logged-in agent and the tuition's
     * guardian. The guardian number is read on the server and never exposed
     * to the agent's browser, HTML source, or the JSON response.
     */
    public function clickToCall(Request $request): JsonResponse
    {
        Log::info('CLICK TO CALL HIT');

        abort_unless(has_permission('tuitions.guardian-number.view'), 403);

        $validated = $request->validate([
            'id' => 'required|exists:tuitions,id',
        ]);

        $caller = auth()->guard('agent')->user() ?? auth()->guard('web')->user();

        if (! $caller || empty($caller->extension)) {
            return response()->json([
                'success' => false,
                'message' => 'No calling extension is assigned to your account.',
            ]);
        }

        $tuition = Tuition::findOrFail($validated['id']);

        if (empty($tuition->gurdian_number)) {
            return response()->json([
                'success' => false,
                'message' => 'No guardian number is available for this tuition.',
            ]);
        }
        Log::info('BEFORE API CALL');

        try {

            $response = Http::withoutVerifying()->post(
                'https://144.79.218.25/call.php',
                [
                    'secret' => 'BDTuition2026',
                    'extension' => $caller->extension,
                    'number' => $tuition->gurdian_number,
                ]
            );

            Log::info('AFTER API CALL', [
                'status' => $response->status(),
                'body' => $response->body(),
                'extension' => $caller->extension,
                'number' => $tuition->gurdian_number,
            ]);

            if (! $response->successful()) {
                throw new \Exception('API request failed');
            }

        } catch (\Throwable $e) {

            Log::error('Click-to-call failed', [
                'tuition_id' => $tuition->id,
                'caller_id' => $caller->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Could not place the call. Please try again.',
            ]);
        }

        return response()->json([
            'success' => true,
        ]);
    }

    /**
     * Approve cancellation request
     */
    public function approveCancellation(Request $request)
    {
        $tuition = Tuition::findOrFail($request->id);

        if ($tuition->explanation_approval !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'This tuition does not have a pending cancellation request.',
            ]);
        }

        $tuition->update([
            'status' => 'Cancelled',
            'explanation_approval' => 'approved',
            'status_changed_by' => $this->statusActorName(),
            'status_changed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cancellation approved successfully. Tuition status set to Cancelled.',
        ]);
    }

    /**
     * Reset tuition to available
     */
    public function resetToAvailable(Request $request)
    {
        $tuition = Tuition::findOrFail($request->id);

        if ($tuition->explanation_approval !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'This tuition does not have a pending cancellation request.',
            ]);
        }

        $tuition->update([
            'status' => 'Available',
            'explanation_approval' => null,
            'explanation' => null,
            'status_changed_by' => $this->statusActorName(),
            'status_changed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tuition reset to Available successfully. Cancellation request cleared.',
        ]);
    }

    /**
     * Send notifications to matching teachers.
     */
    private function sendNotificationsToTeachers(Tuition $tuition)
    {
        $query = Teacher::query()
            ->where('city', $tuition->city)
            ->where(function ($q) use ($tuition) {
                $q->where('area', $tuition->area)
                    ->orWhere('expected_area', 'like', "%{$tuition->area}%");
            });

        if ($tuition->prefered_gender !== 'Male/Female') {
            $query->where('gender', $tuition->prefered_gender);
        }

        $matchingTeachers = $query->get();

        // ── FCM push (v1) — build the sender once, reuse for every teacher. ──
        // Guarded so a misconfigured service account can never break email/WhatsApp.
        $fcm = null;
        try {
            $serviceAccountPath = env('FCM_SERVICE_ACCOUNT');
            if ($serviceAccountPath && is_file($serviceAccountPath)) {
                $fcm = new FcmV1($serviceAccountPath);
            }
        } catch (\Throwable $e) {
            Log::warning('FCM init skipped: '.$e->getMessage());
        }

        foreach ($matchingTeachers as $teacher) {
            $template = settings('email_notify_template');

            $message = str_replace([
                '{{teacher_name}}',
                '{{tuition_name}}',
                '{{tuition_url}}',
            ], [
                $teacher->teacher_name,
                "{$tuition->prefered_gender} Tutor Wanted at {$tuition->tuition_address} in {$tuition->city} !!",
                route('available-tuition', ['tuition_code' => $tuition->tuition_code]),
            ], $template);

            Mail::to($teacher->email)
                ->send(new TuitionNotification($message));
                $whatsappNumber = !empty($teacher->whatsapp_number)
    ? $teacher->whatsapp_number
    : $teacher->phone_number;

if (!empty($whatsappNumber)) {

    $whatsappMessage = "🎓 New Tuition Available\n\n"
        . "Tutor: {$teacher->teacher_name}\n"
        . "Location: {$tuition->tuition_address}, {$tuition->city}\n"
        . "Preferred Tutor: {$tuition->prefered_gender}\n\n"
        . "View Details:\n"
        . route('available-tuition', [
            'tuition_code' => $tuition->tuition_code
        ]);

    SendWhatsappJob::dispatch(
        $whatsappNumber,
        $whatsappMessage
    );
}

            // ── Push notification to the teacher's phone (works even when the app is closed) ──
            if ($fcm && ! empty($teacher->fcm_token)) {
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
                    // one bad/expired token must never break the loop
                    Log::warning("FCM push failed for teacher {$teacher->id}: ".$e->getMessage());
                }
            }
        }

        return $matchingTeachers->count();
    }

    protected function statusActorName(): string
    {
        return auth()->guard('agent')->user()?->name
            ?? auth()->guard('web')->user()?->username
            ?? 'System';
    }

    protected function normalizeTextValue(mixed $value): string
    {
        return trim((string) ($value ?? ''));
    }

    protected function normalizePreferredGenderValue(mixed $value): string
    {
        $normalizedValue = strtolower(preg_replace('/[^a-z]/', '', (string) ($value ?? '')));

        return match ($normalizedValue) {
            'malefemale', 'femalemale', 'any', 'both' => 'Male/Female',
            'male', 'boy' => 'Male',
            'female', 'girl' => 'Female',
            default => trim((string) ($value ?? '')),
        };
    }

    protected function normalizeNumericInputValue(mixed $value): string
    {
        $stringValue = trim((string) ($value ?? ''));

        if ($stringValue === '') {
            return '';
        }

        if (preg_match('/-?\d+(?:\.\d+)?/', $stringValue, $matches) === 1) {
            return $matches[0];
        }

        return $stringValue;
    }
}
