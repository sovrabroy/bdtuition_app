<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * Guardian account model. Uses Sanctum tokens just like the Teacher API so the
 * mobile app authenticates the same way (Bearer token).
 */
class Guardian extends Authenticatable
{
    use HasApiTokens, Notifiable;

    protected $table = 'guardians';

    protected $fillable = [
        'name',
        'phone',
        'email',
        'password',
        'city',
        'area',
        'address',
        'phone_verified_at',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'phone_verified_at' => 'datetime',
    ];

    public function reviews()
    {
        return $this->hasMany(GuardianReview::class);
    }

    public function tutorRequests()
    {
        return $this->hasMany(GuardianTutorRequest::class);
    }
}
