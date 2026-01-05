<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void {
        Schema::create('app_users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('username')->unique();
            $table->string('email')->unique();
            $table->string('country_code')->nullable();
            $table->string('phone_number')->nullable();
            $table->foreignId('app_role_id')->nullable()->constrained('app_roles')->onDelete('set null'); // The relationship
            $table->string('password');
            $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('app_users'); }
};