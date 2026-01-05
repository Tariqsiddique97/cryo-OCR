<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Models\VehicleInspection;
use App\Services\InspectionChecklistService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Arr;
use App\Models\Tractor;
use App\Models\Trailer;


class VehicleInspectionController extends Controller
{
    protected $checklistService;

    // Inject the service
    public function __construct(InspectionChecklistService $checklistService)
    {
        $this->checklistService = $checklistService;
    }

    /**
     * API 1: Get the inspection checklist.
     */
    public function getChecklist(Request $request)
    {
        $type = $request->query('type'); // 'tractor' or 'trailer'
        if (!$type || !in_array($type, ['tractor', 'trailer'])) {
            return response()->json(['status' => false, 'message' => 'A valid type (tractor or trailer) is required.'], 400);
        }
        $checklist = $this->checklistService->getChecklist($type);
        return response()->json(['status' => true, 'type' => $type, 'checklist' => $checklist], 200);
    }

    /**
     * API 2: Submit a new inspection report.
     * This is the updated logic.
     */

    public function submitReport(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'vehicle_type' => 'required|string|in:tractor,trailer',
            'vehicle_number' => 'required|string|max:255',
            'location_name' => 'nullable|string|max:255',
            'driver_name' => 'required|string|max:255',
            'odometer_reading' => 'nullable|integer',
            'inspection_date' => 'required|date',
            'comments' => 'nullable|string',
            
            // Validate the new simple string format. It can be null or empty.
            'inspection_checks' => 'nullable|string', 
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        // --- 1. Find Vehicle and Trip ---
        $validatedData = $validator->validated();
        $vehicle_id = null;

        if($request->vehicle_type === 'tractor') {
            $tractor = Tractor::where('number', $request->vehicle_number)->first();
            
            if (!$tractor) {
                return response()->json(['status' => false, 'message' => 'Tractor not found.'], 404);
            }
            $vehicle_id = $tractor->id;
        }
        else if($request->vehicle_type === 'trailer') {
            $trailer = Trailer::where('number', $request->vehicle_number)->first();
            
            if (!$trailer) {
                return response()->json(['status' => false, 'message' => 'Trailer not found.'], 404);
            }
            $vehicle_id = $trailer->id;
        }

        // Find the PENDING trip (status 0) for this vehicle.
        // Assumes your Trip model has 'tractor_id' and 'trailer_id' columns
        $trip = Trip::where('status', 0)->where($request->vehicle_type.'_id', $vehicle_id)->with('driver')->first();
        
        if (!$trip) {
            return response()->json(['status' => false, 'message' => 'No active trip (status 0) found for this vehicle.'], 404);
        }

        // Add the found trip_id and driver_name to our data
        $validatedData['trip_id'] = $trip->id;
        //$validatedData['driver_name'] = $trip->driver->name ?? 'N/A'; // Get driver name from trip

        // --- 2. Check for Duplicate Inspection ---
        // $check = VehicleInspection::where('trip_id', $trip->id)
        //             ->where('vehicle_type', $request->vehicle_type)
        //             ->where('vehicle_number', $request->vehicle_number)
        //             ->first();

        // if ($check) {
        //     return response()->json(['status' => false, 'message' => 'An inspection report for this vehicle and trip has already been submitted.'], 409); // 409 Conflict
        // }   

        // --- 3. Process Inspection & Red Flag Logic ---
        
        // Get the master checklist
        $masterChecklist = $this->checklistService->getChecklist($validatedData['vehicle_type']);
        
        // Create a "safety map" of all safety-critical items
        $safetyMap = $this->buildSafetyMap($masterChecklist);

        // Convert the input string "wipers,brake_air_lines" into an array
        $defective_ids_string = $request->input('inspection_checks', '');
        $defective_ids_array = $defective_ids_string ? explode(',', $defective_ids_string) : [];

        $has_defects = !empty($defective_ids_array);
        $has_safety_defects = false; // This is the "Red Flag"

        // Loop through *only* the defective IDs
        if ($has_defects) {
            foreach ($defective_ids_array as $defective_id) {
                // Check if this defective item is in our safety map
                if (isset($safetyMap[$defective_id])) {
                    $has_safety_defects = true; // RED FLAG!
                    break; // No need to check further
                }
            }
        }

        // 4. Prepare data for saving
        $saveData = $validatedData;
        $saveData['no_defects'] = !$has_defects;
        $saveData['has_safety_defects'] = $has_safety_defects;
        
        // Save the *array* of defective IDs to the JSON column, not the string
        $saveData['inspection_checks'] = $defective_ids_array; 

        // 5. Create the report
        $inspection = VehicleInspection::create($saveData);

        return response()->json([
            'status' => true,
            'message' => 'Inspection report submitted successfully.',
            'report' => $inspection->fresh(), // 'fresh()' reloads from DB
        ], 201);
    }

    /**
     * Helper function to build a fast-lookup map of safety items.
     * (This function is unchanged)
     */
    private function buildSafetyMap(array $masterChecklist): array
    {
        $map = [];
        foreach ($masterChecklist as $group) {
            foreach ($group['items'] as $item) {
                if ($item['is_safety']) {
                    $map[$item['id']] = true;
                }
            }
        }
        return $map;
    }


    // public function submitReport(Request $request)
    // {
    //     $validator = Validator::make($request->all(), [
    //         // 'trip_id' => 'required|integer|exists:trips,id',
    //         'vehicle_type' => 'required|string|in:tractor,trailer',
    //         'vehicle_number' => 'required|string|max:255',
    //         'location_name' => 'nullable|string|max:255',
    //         'odometer_reading' => 'nullable|integer',
    //         'driver_name' => 'required|string|max:255',
    //         'inspection_date' => 'required|date',
    //         'comments' => 'nullable|string',
            
    //         // Validate the new array structure
    //         'inspection_checks' => 'required|array|min:1',
    //         'inspection_checks.*.id' => 'required|string',
    //         'inspection_checks.*.status' => 'required|string|in:ok,defective',
    //     ]);

    //     if ($validator->fails()) {
    //         return response()->json(['status' => false, 'message' => 'Validation failed', 'errors' => $validator->errors()], 422);
    //     }


    //     if($request->vehicle_type === 'tractor') {
    //         $tractor = Tractor::where('number', $request->vehicle_number)->first();
            
    //         if (!$tractor) {
    //             return response()->json(['status' => false, 'message' => 'Tractor not found.'], 404);
    //         }
    //         $vehicle_id = $tractor->id;
    //     }
    //     else if($request->vehicle_type === 'trailer') {
    //         $trailer = Trailer::where('number', $request->vehicle_number)->first();
            
    //         if (!$trailer) {
    //             return response()->json(['status' => false, 'message' => 'Trailer not found.'], 404);
    //         }
    //         $vehicle_id = $trailer->id;
    //     }


    //     $trip = Trip::where('status', 0)->where($request->vehicle_type.'_id',$vehicle_id )->first();
    //     if (!$trip) {
    //         return response()->json(['status' => false, 'message' => 'No active trip found for this vehicle.'], 404);
    //     }

    //     $validatedData = $validator->validated();
    //     $validatedData['trip_id'] = $trip->id;
    //     $validatedData['driver_name'] = $trip->driver->name;

    //     $check = VehicleInspection::where('trip_id', $trip->id)
    //                 ->where('vehicle_type', $request->vehicle_type)
    //                 ->where('vehicle_number', $request->vehicle_number)
    //                 ->first();

    //     if ($check) {
    //         return response()->json(['status' => false, 'message' => 'An inspection report for this vehicle and trip has already been submitted.'], 409);
    //     }   


    //     // --- Process Inspection & Red Flag Logic ---
        
    //     // 1. Get the master checklist from the service
    //     $masterChecklist = $this->checklistService->getChecklist($validatedData['vehicle_type']);
        
    //     // 2. Create a "safety map" of all safety-critical items
    //     $safetyMap = $this->buildSafetyMap($masterChecklist);

    //     $has_defects = false;
    //     $has_safety_defects = false; // This is the "Red Flag"

    //     // 3. Loop through the checks sent from the app
    //     foreach ($validatedData['inspection_checks'] as $check) {
    //         if ($check['status'] === 'defective') {
    //             $has_defects = true;
                
    //             // Check if this defective item is in our safety map
    //             if (isset($safetyMap[$check['id']])) {
    //                 $has_safety_defects = true; // RED FLAG!
    //             }
    //         }
    //     }

    //     // 4. Add the calculated fields to the data
    //     $saveData = $validatedData;
    //     $saveData['no_defects'] = !$has_defects;
    //     $saveData['has_safety_defects'] = $has_safety_defects;

    //     // 5. Create the report
    //     $inspection = VehicleInspection::create($saveData);

    //     return response()->json([
    //         'status' => true,
    //         'message' => 'Inspection report submitted successfully.',
    //         'report' => $inspection->fresh(), // 'fresh()' reloads from DB
    //     ], 201);
    // }

    /**
     * Helper function to build a fast-lookup map of safety items.
     * @param array $masterChecklist
     * @return array
     */
    // private function buildSafetyMap(array $masterChecklist): array
    // {
    //     $map = [];
    //     foreach ($masterChecklist as $group) {
    //         foreach ($group['items'] as $item) {
    //             if ($item['is_safety']) {
    //                 $map[$item['id']] = true;
    //             }
    //         }
    //     }
    //     return $map;
    // }

    /**
     * API 3: Fetch all reports for a specific Trip ID.
     */
    public function getReportsForTrip(Request $request, $tripId)
    {
        $reports = VehicleInspection::where('trip_id', $tripId)
                                    ->orderBy('created_at', 'desc')
                                    ->get();
        return response()->json(['status' => true, 'reports' => $reports], 200);
    }

    /**
     * API 4: Fetch a specific submitted report by its ID.
     */
    public function getReport(VehicleInspection $inspection)
    {
        // Uses route-model binding
        return response()->json(['status' => true, 'report' => $inspection], 200);
    }

    /**
     * API 5: Fetch all reports for a specific vehicle number (Tractor or Trailer).
     */
    public function getReportsByVehicleNumber($vehicle_number)
    {
        $reports = VehicleInspection::where('vehicle_number', $vehicle_number)
                                    ->orderBy('created_at', 'desc') // Show most recent first
                                    ->get();

        if ($reports->isEmpty()) {
            return response()->json(['status' => false, 'message' => 'No inspection reports found for vehicle ' . $vehicle_number, 'reports' => []], 404);
        }

        return response()->json(['status' => true, 'reports' => $reports], 200);
    }
}