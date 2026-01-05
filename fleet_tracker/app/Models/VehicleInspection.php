<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VehicleInspection extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'trip_id',
        'vehicle_type',
        'vehicle_number',
        'location_name',
        'odometer_reading',
        'no_defects',         // Calculated by server
        'has_safety_defects', // Calculated by server
        'inspection_checks',
        'comments',
        'driver_name',
        'inspection_date',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'no_defects' => 'boolean',
        'has_safety_defects' => 'boolean', // Added
        'inspection_checks' => 'array', // Automatically handles JSON
        'inspection_date' => 'date',
    ];

    /**
     * Get the trip that this inspection belongs to.
     */
    public function trip()
    {
        return $this->belongsTo(Trip::class);
    }
}