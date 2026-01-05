<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TankRepair extends Model
{
    use HasFactory;

    protected $fillable = [
        'trip_id',
        'latitude',
        'longitude',
        'photos', // Updated
        'videos', // Updated
        'notes',
        'status',
    ];

    protected $casts = [
        'photos' => 'array', // Cast JSON to array
        'videos' => 'array', // Cast JSON to array
        'latitude' => 'float',
        'longitude' => 'float',
    ];
}