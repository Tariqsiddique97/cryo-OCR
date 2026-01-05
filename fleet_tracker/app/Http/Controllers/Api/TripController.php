<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tractor;
use App\Models\Trailer;
use App\Models\Trip;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use App\Models\Stop;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Mail;
use App\Mail\TripReportMail;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Log;

class TripController extends Controller
{
    /**
     * Get the currently assigned pending trip for the authenticated driver.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    // public function getPendingTrip(Request $request)
    // {
    //     // Get the currently authenticated user (the driver)
    //     $driver = auth()->user();

    //     // Find the pending trip for this driver, including its stops and vehicles
    //     $pendingTrip = Trip::with(['stops', 'tractor', 'trailer']) // Eager load relationships
    //         ->where('driver_id', $driver->id)
    //         ->where('status', 0) // 0 = Pending
    //         ->first();

    //     // If no trip is found, return a success response with a message
    //     if (!$pendingTrip) {
    //         return response()->json([
    //             'message' => 'No pending trip found for this driver.',
    //             'trip' => null,
    //             'status' => false,
    //         ], 200);
    //     }

    //     // If a trip is found, format it and return it
    //     $tripData = [
    //         'id' => $pendingTrip->id,
    //         'status' => $pendingTrip->status,
    //         'tractor_number' => $pendingTrip->tractor->number ?? null,
    //         'trailer_number' => $pendingTrip->trailer->number ?? null,
    //         'total_quantity' => $pendingTrip->total_quantity,
    //         'total_trip_miles' => $pendingTrip->total_trip_miles,
    //         'stops' => $pendingTrip->stops->map(function ($stop) {
    //             return [
    //                 'id' => $stop->id,
    //                 'sequence_number' => $stop->sequence_number,
    //                 'name' => $stop->name,
    //                 'status' => $stop->status,
    //             ];
    //         })
    //     ];

    //     return response()->json([
    //         'trip' => $tripData,
    //         'status' => true,
    //     ], 200);
    // }
    public function getPendingTrip(Request $request)
    {
        // Validate that tractor and trailer numbers are provided and exist
        $validated = $request->validate([
            'tractor_number' => 'required|string|exists:tractors,number',
            'trailer_number' => 'required|string|exists:trailers,number',
        ]);
        $driver = auth()->user();



        // Find the pending trip using the vehicle numbers
        $pendingTrip = Trip::with(['stops', 'tractor', 'trailer', 'driver']) // Eager load relationships
            ->where('status', 0) // 0 = Pending
            ->whereHas('tractor', function ($query) use ($validated) {
                $query->where('number', $validated['tractor_number']);
            })
            ->whereHas('trailer', function ($query) use ($validated) {
                $query->where('number', $validated['trailer_number']);
            })
            ->first();

        // If no trip is found, return a success response with a message
        if (!$pendingTrip) {
            return response()->json([
                'message' => 'No pending trip found for the specified tractor and trailer.',
                'trip' => null,
                'status' => false,
            ], 200);
        }
        if ($pendingTrip->driver == null) {
            // Assign the current authenticated driver to the pending trip
            $pendingTrip->update(['driver_id' => $driver->id]);
        }

       

        if ($pendingTrip->driver_id !== $driver->id) {
            return response()->json([
                'message' => 'This trip is assigned to a different driver.',
                //'trip' => null,
                'status' => false,
            ], 403);
        }

        // If a trip is found, format it and return it
        $tripData = [
            'id' => $pendingTrip->id,
            'status' => $pendingTrip->status,
            'driver_name' => $pendingTrip->driver->name ?? 'N/A', // Including driver name is useful
            'tractor_number' => $pendingTrip->tractor->number ?? null,
            'trailer_number' => $pendingTrip->trailer->number ?? null,
            'total_quantity' => $pendingTrip->total_quantity,
            'total_trip_miles' => $pendingTrip->total_trip_miles,
            'stops' => $pendingTrip->stops,
            // ->map(function ($stop) {
            //     return [
            //         'id' => $stop->id,
            //         'sequence_number' => $stop->sequence_number,
            //         'name' => $stop->name,
            //         'status' => $stop->status,
            //     ];
            // })
        ];

        return response()->json([
            'trip' => $tripData,
            'status' => true,
        ], 200);
    }

    /**
     * Update the tractor and/or trailer for the driver's pending trip using vehicle numbers.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateTractorAndTrailer(Request $request)
    {
        // Validate the request data using vehicle numbers
        $validated = $request->validate([
            'tractor_number' => 'sometimes|nullable|string|exists:tractors,number',
            'trailer_number' => 'sometimes|nullable|string|exists:trailers,number',
        ]);

        $driver = auth()->user();

        // Find the pending trip for this driver
        $trip = Trip::where('driver_id', $driver->id)
            ->where('status', 0) // 0 = Pending
            ->first();

        if (!$trip) {
            return response()->json(['message' => 'No pending trip found to update.'], 404);
        }

        $updateData = [];

        // --- Tractor Handling ---
        if ($request->has('tractor_number')) {
            $tractorNumber = $request->input('tractor_number');
            if ($tractorNumber) {
                $tractor = Tractor::where('number', $tractorNumber)->first();

                // Availability Check
                $isTractorTaken = Trip::where('tractor_id', $tractor->id)
                    ->where('id', '!=', $trip->id) // Exclude the current trip
                    ->whereIn('status', [0, 1]) // 0=Pending, 1=In-Progress
                    ->exists();

                if ($isTractorTaken) {
                    return response()->json(['message' => 'This tractor is already assigned to another trip.'], 422);
                }
                $updateData['tractor_id'] = $tractor->id;
            } else {
                $updateData['tractor_id'] = null; // Unassign if number is null or empty
            }
        }

        // --- Trailer Handling ---
        if ($request->has('trailer_number')) {
            $trailerNumber = $request->input('trailer_number');
            if ($trailerNumber) {
                $trailer = Trailer::where('number', $trailerNumber)->first();
                // Availability Check
                $isTrailerTaken = Trip::where('trailor_id', $trailer->id)
                    ->where('id', '!=', $trip->id) // Exclude the current trip
                    ->whereIn('status', [0, 1]) // 0=Pending, 1=In-Progress
                    ->exists();

                if ($isTrailerTaken) {
                    return response()->json(['message' => 'This trailer is already assigned to another trip.'], 422);
                }
                $updateData['trailor_id'] = $trailer->id;
            } else {
                $updateData['trailor_id'] = null; // Unassign if number is null or empty
            }
        }

        // Update the trip with the new vehicle IDs
        if (!empty($updateData)) {
            $trip->update($updateData);
        }

        return response()->json([
            'message' => 'Trip updated successfully!',
            'trip' => $trip->load(['tractor', 'trailer']), // Return trip with updated vehicle info
            'status' => true,
        ], 200);
    }
    // public function getInProgressStop(Request $request)
    // {
    //     $driver = auth()->user();

    //     // Find the stop with status 1 that belongs to an active trip (status 1) for the current driver.
    //     $inProgressStop = Stop::where('status', 1) // 1 = In-Progress
    //         ->whereHas('trip', function ($query) use ($driver) {
    //             $query->where('driver_id', $driver->id)
    //                   ->where('status', 0); // 1 = Trip is In-Progress
    //         })
    //         ->first();

    //     if (!$inProgressStop) {
    //         return response()->json([
    //             'message' => 'No in-progress stop found.',
    //             'stop' => null,
    //             'status' => false,
    //         ], 200);
    //     }

    //     return response()->json([
    //         'stop' => $inProgressStop,
    //         'status' => true,
    //     ], 200);
    // }

    public function getInProgressStop(Request $request)
    {
        // Validate that tractor and trailer numbers are provided and exist
        $validated = $request->validate([
            'tractor_number' => 'required|string|exists:tractors,number',
            'trailer_number' => 'required|string|exists:trailers,number',
        ]);

        // Find the stop with status 1 (In-Progress) that belongs to an active trip (status 1)
        // which is associated with the given tractor and trailer.
        $inProgressStop = Stop::where('status', 1) // 1 = Stop is In-Progress
            ->whereHas('trip', function ($query) use ($validated) {
                $query->where('status', 0) // 1 = Trip is In-Progress
                    ->whereHas('tractor', function ($q) use ($validated) {
                        $q->where('number', $validated['tractor_number']);
                    })
                    ->whereHas('trailer', function ($q) use ($validated) {
                        $q->where('number', $validated['trailer_number']);
                    });
            })
            ->first();

        if (!$inProgressStop) {
            return response()->json([
                'message' => 'No in-progress stop found for the specified tractor and trailer.',
                'stop' => null,
                'status' => false,
            ], 200);
        }

        return response()->json([
            'stop' => $inProgressStop,
            'status' => true,
        ], 200);
    }


     
    public function updateStopDetails(Request $request)
    {
        $stop = Stop::where('name', $request->tank_number)->first();
        if (!$stop) {
            return response()->json([
                'message' => 'Stop not found with the provided tank number.',
                'tank_number' => $request->tank_number,
                'status' => false
            ], 404);
        }
        
        // Authorization
        if ($stop->trip->driver_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }
        
        $dateTimeFormat = 'Y-m-d\TH:i:s.uP';

        // 1. Validate NON-IMAGE fields first
        $validatedData = $request->validate([
            'tank_number' => 'nullable|string',
            'start_time' => 'nullable|date_format:' . $dateTimeFormat,
            'end_time' => 'nullable|date_format:' . $dateTimeFormat,
            'tank_information_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'full_trycock' => 'nullable|string',
            'attn_driver_maintain' => 'nullable|string',
            'tank_level_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'psi_value' => 'nullable|numeric',
            'levels_value' => 'nullable|numeric',
            'level_before_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'level_before_value' => 'nullable|numeric',
            'level_after_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'level_after_value' => 'nullable|numeric',
            'psi_before_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'psi_before_value' => 'nullable|numeric',
            'psi_after_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'psi_after_value' => 'nullable|numeric',
            'quantity_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'quantity_value' => 'nullable|numeric',
            'quantity_um' => 'nullable|string',
            'odometer_image_time' => 'nullable|date_format:' . $dateTimeFormat,
            'odometer_value' => 'nullable|numeric',
            
            // Image fields are handled MANUALLY below
        ]);

        // 2. --- Robust Image Handling (File or Base64) ---
        
        // Define all keys that could be images
        $imageKeys = [
            'tank_information_image',
            'tank_level_image',
            'level_before_image',
            'level_after_image',
            'psi_before_image',
            'psi_after_image',
            'quantity_image',
            'odometer_image',
        ];

        if($stop->start_time == null)
        {
            $stop->start_time = now('America/Chicago')->format($dateTimeFormat);
            $stop->save();
        }

        
        $allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

        foreach ($imageKeys as $key) {
            $filePath = null;

            try {
                // --- SCENARIO 1: It's a File Upload (multipart/form-data) ---
                if ($request->hasFile($key)) {
                    
                    // Validate the file
                    $request->validate([
                        $key => 'image|mimes:jpeg,png,jpg,gif,webp|max:40240' // 10MB max, adjust as needed
                    ]);
                    
                    $file = $request->file($key);
                    $extension = $file->getClientOriginalExtension();
                    $fileName = Str::uuid() . '.' . $extension;
                    $path = "stops/{$stop->id}";

                    // Store the file and get the path
                    $storedPath = $file->storeAs($path, $fileName, 'public');
                    $filePath = '/storage/' . $storedPath;

                } 
                // --- SCENARIO 2: It's a Base64 String ---
                elseif ($request->filled($key) && is_string($request->input($key))) {
                    
                    $value = $request->input($key);
                    
                    // Check if it's a valid data URI
                    if (!preg_match('/^data:image\/(\w+);base64,(.+)$/', $value, $matches)) {
                        // If it's a string but not base64, it might be an existing URL.
                        // If you want to allow *keeping* old URLs, you could add logic here.
                        // For now, we'll assume a non-base64 string is an error or should be skipped.
                        // Let's assume it's an invalid format if it's not a file and not a valid data URI
                        if (!filter_var($value, FILTER_VALIDATE_URL)) {
                             return response()->json(['message' => "Invalid image format for field '{$key}'. Must be a file upload or base64 string.", 'status' => false], 422);
                        }
                        // If it IS a valid URL, maybe it's an old one being re-submitted.
                        // We'll just re-assign it.
                        $validatedData[$key] = $value;
                        continue; // Skip to next image key
                    }

                    $extension = strtolower($matches[1]); // e.g., 'png', 'jpeg'
                    $image_data = $matches[2];          // The actual base64 data
                    $image_base64 = base64_decode($image_data);

                    if (!in_array($extension, $allowed_extensions)) {
                        return response()->json(['message' => "Unsupported image type '{$extension}' for field '{$key}'.", 'status' => false], 422);
                    }
                    
                    $fileName = Str::uuid() . '.' . $extension;
                    $path = "stops/{$stop->id}/{$fileName}";
                    
                    Storage::disk('public')->put($path, $image_base64);
                    $filePath = '/storage/' . $path;
                }

                // If a new file path was generated (from file or base64), add it to validated data.
                if ($filePath) {
                    $validatedData[$key] = $filePath;
                }

            } catch (\Illuminate\Validation\ValidationException $e) {
                // Catch file validation errors
                return response()->json(['message' => $e->getMessage(), 'errors' => $e->errors(), 'status' => false], 422);
            } catch (\Exception $e) {
                // Log::error("Image processing failed for key {$key}: " . $e->getMessage());
                return response()->json(['message' => "Error processing image for field '{$key}'.", 'status' => false], 422);
            }
        } // End foreach image key


        // 3. --- Database Transaction ---
        
        // Logic: if name and tank number match, is_tank_verified is 1
        $validatedData['is_tank_verified'] = ($stop->name === $request->input('tank_number'));

        try {
            DB::transaction(function () use ($stop, $validatedData, $request) {
                // 1. Update the parent trip with quantity and mileage
                $trip = $stop->trip;
                
                // Odometer / Mileage Calculation
                if ($request->filled('odometer_value')) {
                    $previousStop = Stop::where('trip_id', $stop->trip_id)
                                        ->where('sequence_number', '<', $stop->sequence_number)
                                        ->orderBy('sequence_number', 'desc')
                                        ->first();

                    if ($previousStop && !is_null($previousStop->odometer_value)) {
                        $milesDifference = (float)$request->input('odometer_value') - (float)$previousStop->odometer_value;
                        if ($milesDifference > 0) {
                            $trip->increment('total_trip_miles', $milesDifference);
                        }
                    }
                }

                // Update total quantity
                if ($request->filled('quantity_value')) {
                    $trip->increment('total_quantity', (float)$request->input('quantity_value'));
                }

                // 2. Update the Stop model with all validated data (including image URLs)
                // We use $validatedData here, which now contains *all* fields
                $stop->update($validatedData); 
                $stop->update(['status' => 1]); // Mark stop as Completed
            });
        } catch (\Exception $e) {
            // Log::error($e->getMessage());
            return response()->json(['message' => 'An error occurred while updating the stop.', 'error' => $e->getMessage(), 'status' => false], 500);
        }

        return response()->json([
            'message' => 'Stop updated successfully!',
            'stop' => $stop->fresh(), // Return the updated stop data
            'status' => true,
        ], 200);
    }


    public function updateOdometer(Request $request)
    {
        // 1. Find and Authorize Stop
        $stop = Stop::where('name', $request->tank_number)->first();
        if (!$stop) {
            return response()->json([
                'message' => 'Stop not found with the provided tank number.',
                'tank_number' => $request->tank_number,
                'status' => false
            ], 404);
        }


        
        if ($stop->trip->driver_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        // 2. Validate Odometer-specific fields
        $dateTimeFormat = 'Y-m-d\TH:i:s.uP';
        $validatedData = $request->validate([
            'tank_number' => 'required|string', // Need this for the lookup
            'odometer_value' => 'nullable|string',
            'odometer_image_time' => 'nullable|date_format:' . $dateTimeFormat,
        ]);

        // 3. Handle Odometer Image (File or Base64)
        $imageKeys = ['odometer_image'];
        $allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

        foreach ($imageKeys as $key) {
            $filePath = null;
            try {
                if ($request->hasFile($key)) {
                    $request->validate([
                        $key => 'image|mimes:jpeg,png,jpg,gif,webp|max:40240'
                    ]);
                    $file = $request->file($key);
                    $extension = $file->getClientOriginalExtension();
                    $fileName = Str::uuid() . '.' . $extension;
                    $path = "stops/{$stop->id}";
                    $storedPath = $file->storeAs($path, $fileName, 'public');
                    $filePath = '/storage/' . $storedPath;
                } 
                elseif ($request->filled($key) && is_string($request->input($key))) {
                    $value = $request->input($key);
                    if (!preg_match('/^data:image\/(\w+);base64,(.+)$/', $value, $matches)) {
                        if (!filter_var($value, FILTER_VALIDATE_URL)) {
                             return response()->json(['message' => "Invalid image format for field '{$key}'. Must be a file upload or base64 string.", 'status' => false], 422);
                        }
                        $validatedData[$key] = $value;
                        continue; 
                    }
                    $extension = strtolower($matches[1]);
                    $image_data = $matches[2];
                    $image_base64 = base64_decode($image_data);
                    if (!in_array($extension, $allowed_extensions)) {
                        return response()->json(['message' => "Unsupported image type '{$extension}' for field '{$key}'.", 'status' => false], 422);
                    }
                    $fileName = Str::uuid() . '.' . $extension;
                    $path = "stops/{$stop->id}/{$fileName}";
                    Storage::disk('public')->put($path, $image_base64);
                    $filePath = '/storage/' . $path;
                }

                if ($filePath) {
                    $validatedData[$key] = $filePath;
                }
            } catch (\Illuminate\Validation\ValidationException $e) {
                return response()->json(['message' => $e->getMessage(), 'errors' => $e->errors(), 'status' => false], 422);
            } catch (\Exception $e) {
                // Log::error("Image processing failed for key {$key}: " . $e->getMessage());
                return response()->json(['message' => "Error processing image for field '{$key}'.", 'status' => false], 422);
            }
        } // End foreach

        // 4. Database Transaction
        try {
            DB::transaction(function () use ($stop, $validatedData) {
                // 1. Update the parent trip with mileage
                $trip = $stop->trip;
                $odometerValue = (float)$validatedData['odometer_value'];
                
                $previousStop = Stop::where('trip_id', $stop->trip_id)
                                    ->where('sequence_number', '<', $stop->sequence_number)
                                    ->orderBy('sequence_number', 'desc')
                                    ->first();

                if ($previousStop && !is_null($previousStop->odometer_value)) {
                    $milesDifference = $odometerValue - (float)$previousStop->odometer_value;
                    if ($milesDifference > 0) {
                        $trip->increment('total_trip_miles', $milesDifference);
                    }
                }

                // 2. Update the Stop model with odometer data
                // Unset 'tank_number' as we don't want to update that field on the stop model
                unset($validatedData['tank_number']);
                
                $stop->update($validatedData); 
            });
        } catch (\Exception $e) {
            // Log::error($e->getMessage());
            return response()->json(['message' => 'An error occurred while updating the odometer.', 'error' => $e->getMessage(), 'status' => false], 500);
        }

        return response()->json([
            'message' => 'Odometer updated successfully!',
            'stop' => $stop->fresh(),
            'status' => true,
        ], 200);
    }


    public function completeStop(Request $request)
    {
        // IMPORTANT: The format MUST be changed from \Z to P
        $dateTimeFormat = 'Y-m-d\TH:i:s.uP'; // P = offset (e.g., -05:00)

        // 1. Validate the incoming request
        $validatedData = $request->validate([
            'tank_number' => 'required|string',
        ]);

        // 2. Find the stop by its tank number
        $stop = Stop::where('name', $validatedData['tank_number'])->first();

        if (!$stop) {
            return response()->json([
                'message' => 'Stop not found with the provided tank number.',
                'tank_number' => $validatedData['tank_number'],
                'status' => false
            ], 404);
        }

        // 3. Authorization
        if ($stop->trip->driver_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }
        
        // 4. Check if stop is already completed
        if ($stop->status == 2) {
             return response()->json([
                'message' => 'This stop has already been completed.',
                'stop' => $stop,
                'status' => true
            ], 200);
        }

        // 5. Update the stop
        try {
            // Get the current time in the 'America/Chicago' timezone
            $autoEndTime = now('America/Chicago')->format($dateTimeFormat);

            $stop->update([
                'end_time' => $autoEndTime, // Use the Chicago timestamp with offset
                'status' => 2 // Set status to 2 (Completed)
            ]);
        } catch (\Exception $e) {
            // Log::error("Failed to complete stop: " . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred while completing the stop.',
                'status' => false
            ], 500);
        }

        // 6. Return the successful response
        return response()->json([
            'message' => 'Stop completed successfully!',
            'stop' => $stop->fresh(),
            'status' => true,
        ], 200);
    }


    public function sendReport(Request $request)
    {
        $trip = Trip::find($request->trip_id);
        if (!$trip) {
            return response()->json([
                'status' => false,
                'message' => 'Trip not found.',
            ], 404);
        }
        try {
            // 1. Load the necessary relationships for the PDF
            $trip->load('driver', 'tractor', 'trailer', 'stops');

            // 2. Generate the PDF
            // We use a dedicated Blade view for the PDF ('pdf.trip_report')
            // This view does NOT include the layout or statuses
            $pdf = Pdf::loadView('pdf.trip_report', ['trip' => $trip]);
            
            // 3. Define the recipient
            $recipientEmail = 'radheshyammaheria@gmail.com';

            // 4. Send the email with the PDF attached
            Mail::to($recipientEmail)->send(new TripReportMail($trip, $pdf->output()));

            // 5. Update the trip status to 1 (In Progress)
            $trip->status = 1;
            $trip->save();

            return response()->json([
                'status' => true,
                'message' => 'Trip report successfully generated and sent.',
                'trip_id' => $trip->id,
            ], 200);

        } catch (\Exception $e) {
            // Log the error for debugging
            Log::error("Failed to send trip report for Trip ID {$trip->id}: " . $e->getMessage());

            return response()->json([
                'status' => false,
                'message' => 'Failed to send trip report.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }


}

