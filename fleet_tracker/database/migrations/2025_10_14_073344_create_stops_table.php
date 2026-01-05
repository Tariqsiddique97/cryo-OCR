<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void {
        Schema::create('stops', function (Blueprint $table) {
            $table->id();
            $table->integer('sequence_number')->default(0);
            $table->foreignId('trip_id')->constrained('trips')->onDelete('cascade');
            $table->string('name');
            $table->string('start_time')->nullable();
            $table->string('end_time')->nullable();
            $table->string('tank_information_image')->nullable();
            $table->string('tank_information_image_time')->nullable();
            $table->string('tank_number')->nullable();
            $table->string('full_trycock')->nullable();
            $table->string('attn_driver_maintain')->nullable();
            $table->string('tank_level_image')->nullable();
            $table->string('tank_level_image_time')->nullable();
            $table->string('psi_value')->nullable();
            $table->string('levels_value')->nullable();
            $table->string('level_before_image')->nullable();
            $table->string('level_before_image_time')->nullable();
            $table->string('level_before_value')->nullable();
            $table->string('level_after_image')->nullable();
            $table->string('level_after_image_time')->nullable();
            $table->string('level_after_value')->nullable();
            $table->string('psi_before_image')->nullable();
            $table->string('psi_before_image_time')->nullable();
            $table->string('psi_before_value')->nullable();
            $table->string('psi_after_image')->nullable();
            $table->string('psi_after_image_time')->nullable();
            $table->string('psi_after_value')->nullable();
            $table->string('quantity_image')->nullable();
            $table->string('quantity_image_time')->nullable();
            $table->string('quantity_value')->nullable();
            $table->string('quantity_um')->nullable();
            $table->string('odometer_image')->nullable();
            $table->string('odometer_image_time')->nullable();
            $table->string('odometer_value')->nullable();
            $table->string('is_tank_verified')->nullable();
            $table->tinyInteger('status')->default(0); // 0: Pending, 1: In Progress, 2: Completed
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('stops');
    }
};