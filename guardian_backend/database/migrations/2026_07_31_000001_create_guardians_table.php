<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Guardian accounts for the mobile app.
 *
 * Guardians did not exist as their own entity before — they were only names
 * and phone numbers stored on tuitions/assignments. This creates a real,
 * self-owned account so a guardian can log in from the app, see the teacher
 * assigned to them, apply for a tutor, and review their teacher.
 *
 * The link to "which teacher is assigned to me" is done by matching this
 * guardian's phone against the guardian phone stored on assignments/tuitions
 * (see GuardianController@myTeachers), so no existing table is modified.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('guardians', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->unique();        // primary login + link key
            $table->string('email')->nullable();
            $table->string('password');               // hashed
            $table->string('city')->nullable();
            $table->string('area')->nullable();
            $table->string('address')->nullable();
            $table->timestamp('phone_verified_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('guardians');
    }
};
