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
        Schema::create('tank_repairs', function (Blueprint $table) {
            $table->id();
            
            // Optional link to a trip
            $table->unsignedBigInteger('trip_id')->nullable();
            
            // Location data
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            
            // --- SPLIT MEDIA COLUMNS ---
            $table->json('photos')->nullable(); // Stores array of image URLs
            $table->json('videos')->nullable(); // Stores array of video URLs
            
            $table->text('notes')->nullable();
            
            // Status: "On Site", "New", "Update"
            $table->string('status')->nullable();
            
            $table->timestamps();
            
            // Optional foreign key
            // $table->foreign('trip_id')->references('id')->on('trips');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tank_repairs');
    }
};