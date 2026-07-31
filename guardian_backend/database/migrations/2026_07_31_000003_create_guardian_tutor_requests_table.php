<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A tutor request a guardian submits from the app ("apply for a tutor").
 * New table only — nothing existing is touched. If you later want these to
 * feed your main tuition pipeline, you can copy rows into your tuitions table,
 * but this keeps guardian requests isolated and safe to start with.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('guardian_tutor_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('guardian_id');
            $table->string('student_class')->nullable();
            $table->string('subjects')->nullable();
            $table->string('city')->nullable();
            $table->string('area')->nullable();
            $table->string('address')->nullable();
            $table->string('preferred_tutor_gender')->nullable();
            $table->string('budget')->nullable();
            $table->string('status')->default('pending'); // pending/processing/done
            $table->text('note')->nullable();
            $table->timestamps();

            $table->index(['guardian_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('guardian_tutor_requests');
    }
};
