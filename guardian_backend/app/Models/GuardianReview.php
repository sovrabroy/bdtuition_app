<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GuardianReview extends Model
{
    protected $table = 'guardian_reviews';

    protected $fillable = [
        'guardian_id',
        'teacher_id',
        'assignment_id',
        'rating',
        'comment',
    ];

    public function guardian()
    {
        return $this->belongsTo(Guardian::class);
    }
}
