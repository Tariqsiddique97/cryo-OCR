<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void {
        Schema::create('trips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->nullable()->constrained('app_users')->onDelete('set null');
            $table->foreignId('tractor_id')->nullable()->constrained('tractors')->onDelete('set null');
            $table->foreignId('trailor_id')->nullable()->constrained('trailers')->onDelete('set null'); // Corrected typo from trailor to trailer
            $table->string('total_quantity')->nullable();
            $table->string('total_trip_miles')->nullable();
            $table->tinyInteger('status')->default(0); // 0: Pending, 1: In Progress, 2: Completed
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('trips');
    }
};