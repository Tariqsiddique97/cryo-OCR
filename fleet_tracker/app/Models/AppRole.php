<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class AppRole extends Model {
    use HasFactory;
    protected $fillable = ['name'];
    public function appUsers() { return $this->hasMany(AppUser::class); } // Relationship to users
}