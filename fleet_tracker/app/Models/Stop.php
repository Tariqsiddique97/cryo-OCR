<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Stop extends Model {
    use HasFactory;
    protected $fillable = [
        'sequence_number', 'trip_id', 'name', 'start_time', 'end_time', 'tank_information_image',
        'tank_information_image_time', 'tank_number', 'full_trycock', 'attn_driver_maintain',
        'tank_level_image', 'tank_level_image_time', 'psi_value', 'levels_value', 'level_before_image',
        'level_before_image_time', 'level_before_value', 'level_after_image', 'level_after_image_time',
        'level_after_value', 'psi_before_image', 'psi_before_image_time', 'psi_before_value', 'psi_after_image',
        'psi_after_image_time', 'psi_after_value', 'quantity_image', 'quantity_image_time', 'quantity_value',
        'quantity_um', 'odometer_image', 'odometer_image_time', 'odometer_value', 'is_tank_verified', 'status','address', 'latitude', 'longitude'
    ];
    public function trip() {
        return $this->belongsTo(Trip::class);
    }
}