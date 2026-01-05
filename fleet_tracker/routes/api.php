<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TripController; 
use App\Http\Controllers\Api\VehicleInspectionController; 
use App\Http\Controllers\Api\TankRepairController; 


/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Authentication routes
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:api')->group(function () {
   

    // --- NEW: Route to get the driver's pending trip ---
    Route::post('/trip/pending', [TripController::class, 'getPendingTrip']);
    Route::post('/trip/update-vehicles', [TripController::class, 'updateTractorAndTrailer']);
    Route::post('/trip/stop/in-progress', [TripController::class, 'getInProgressStop']);
    Route::post('/trip/stop/update', [TripController::class, 'updateStopDetails']);
    Route::post('/trip/stop/complete', [TripController::class, 'completeStop']);
    Route::post('/trip/stop/update-odometer', [TripController::class, 'updateOdometer']);
    Route::post('/trip/send-report', [TripController::class, 'sendReport']);
    Route::get('/inspection-checklist', [VehicleInspectionController::class, 'getChecklist']);
    Route::post('/inspection-report', [VehicleInspectionController::class, 'submitReport']);
    Route::get('/trip/{tripId}/inspection-reports', [VehicleInspectionController::class, 'getReportsForTrip']);
    Route::get('/inspection-report/{inspection}', [VehicleInspectionController::class, 'getReport']);
    Route::get('/inspection-reports/by-vehicle/{vehicle_number}', [VehicleInspectionController::class, 'getReportsByVehicleNumber']);

    /**
     * Get list of tank repairs (for main app screen)
     * GET /api/tank-repairs?status=new&search=123
     */
    Route::get('/tank-repairs', [TankRepairController::class, 'getReports']);

    /**
     * Submit a new tank repair report (with files)
     * POST /api/tank-repair
     */
    Route::post('/tank-repair', [TankRepairController::class, 'submitReport']);

});
