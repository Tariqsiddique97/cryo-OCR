<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable; // <-- 1. IMPORT Authenticatable
use Illuminate\Notifications\Notifiable;
use Laravel\Passport\HasApiTokens;

class AppUser extends Authenticatable // <-- 2. EXTEND Authenticatable
{
    // Your HasApiTokens for Passport is correct and is kept here
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The table associated with the model.
     * We'll add this just in case, it's good practice.
     * @var string
     */
    protected $table = 'app_users';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'username',
        'email',
        'country_code',
        'phone_number',
        'password',
        'app_role_id'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
    ];

    /**
     * Get the role associated with the user.
     */
    public function appRole()
    {
        return $this->belongsTo(AppRole::class); // Relationship to role
    }
}