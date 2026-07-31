<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GuardianTutorRequest extends Model
{
    protected $table = 'guardian_tutor_requests';

    protected $fillable = [
        'guardian_id',
        'student_class',
        'subjects',
        'city',
        'area',
        'address',
        'preferred_tutor_gender',
        'budget',
        'status',
        'note',
    ];

    public function guardian()
    {
        return $this->belongsTo(Guardian::class);
    }
}
