<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Trip extends Model
{
    use HasFactory;

    protected $fillable = [
        'driver_id',
        'tractor_id',
        'trailor_id', // Make sure this column name matches your migration
        'total_quantity',
        'total_trip_miles',
        'status'
    ];

    public function driver()
    {
        return $this->belongsTo(AppUser::class, 'driver_id');
    }

    public function stops()
    {
        return $this->hasMany(Stop::class)->orderBy('sequence_number', 'asc');
    }

    // These relationships are required for the `show` view
    public function tractor()
    {
        return $this->belongsTo(Tractor::class);
    }

    public function trailer()
    {
        return $this->belongsTo(Trailer::class, 'trailor_id');
    }
}