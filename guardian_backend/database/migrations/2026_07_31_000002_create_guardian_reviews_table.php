<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Reviews a guardian leaves for the teacher assigned to them.
 * New table only — nothing existing is touched.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('guardian_reviews', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('guardian_id');
            $table->unsignedBigInteger('teacher_id');
            $table->unsignedBigInteger('assignment_id')->nullable();
            $table->unsignedTinyInteger('rating');    // 1..5
            $table->text('comment')->nullable();
            $table->timestamps();

            $table->index(['teacher_id']);
            $table->index(['guardian_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('guardian_reviews');
    }
};
