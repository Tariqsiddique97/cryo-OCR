<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('vehicle_inspections', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('trip_id');
            $table->string('vehicle_type'); // 'tractor' or 'trailer'
            $table->string('vehicle_number');
            $table->string('location_name')->nullable();
            $table->integer('odometer_reading')->nullable(); // Only for tractor
            
            // Server-calculated fields
            $table->boolean('no_defects')->default(false); 
            $table->boolean('has_safety_defects')->default(false); // The "Red Flag"

            // This column stores the FULL report, e.g. [{"id": "wipers", "status": "defective"}, ...]
            $table->json('inspection_checks'); 
            
            $table->text('comments')->nullable();
            $table->string('driver_name');
            $table->date('inspection_date');
            $table->timestamps();

            // Assumes you have a 'trips' table
            $table->foreign('trip_id')->references('id')->on('trips')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('vehicle_inspections');
    }
};