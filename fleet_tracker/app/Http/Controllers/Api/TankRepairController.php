<?php

namespace App\Http\Controllers\Api;

use App\Models\TankRepair;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage; 
use Illuminate\Support\Str; 
use App\Http\Controllers\Controller;

class TankRepairController extends Controller
{
    /**
     * API 1: Get the list of repair reports
     */
    public function getReports(Request $request)
    {
        $columns = [
            'id',
            'trip_id',
            'latitude',
            'longitude',
            'notes',
            'status',
            'photos', 
            'videos',
            'created_at',
        ];

        $query = TankRepair::query()->select($columns)
                             ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->has('search')) {
            $searchTerm = $request->query('search');
            $query->where(function ($q) use ($searchTerm) {
                $q->where('notes', 'like', '%' . $searchTerm . '%')
                  ->orWhere('id', $searchTerm)
                  ->orWhere('trip_id', $searchTerm);
            });
        }

        $reports = $query->paginate(20);

        return response()->json([
            'status' => true,
            'reports' => $reports,
        ], 200);
    }

    /**
     * API 2: Submit a new repair report
     * Accepts 'photos' and 'videos' as separate arrays in the request.
     */
    public function submitReport(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'trip_id' => 'nullable|integer|exists:trips,id',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes' => 'nullable|string',
            //'status' => 'nullable|string|in:new,on_site,update,tank_repair',
            
            // Validate Photos separately
            'photos' => 'nullable|array',
            'photos.*' => 'file|mimes:jpg,jpeg,png,webp|max:20480', // Max 20MB images
            
            // Validate Videos separately
            'videos' => 'nullable|array',
            'videos.*' => 'file|mimes:mp4,mov,avi,wmv|max:102400', // Max 100MB videos
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        $validatedData = $validator->validated();
        
        // --- Handle Photos Upload ---
        $photoUrls = [];
        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $file) {
                $extension = $file->getClientOriginalExtension();
                $fileName = Str::uuid() . '.' . $extension;
                $path = $file->storeAs('repairs/photos', $fileName, 'public'); // Store in repairs/photos folder
                $photoUrls[] = Storage::url($path);
            }
        }

        // --- Handle Videos Upload ---
        $videoUrls = [];
        if ($request->hasFile('videos')) {
            foreach ($request->file('videos') as $file) {
                $extension = $file->getClientOriginalExtension();
                $fileName = Str::uuid() . '.' . $extension;
                $path = $file->storeAs('repairs/videos', $fileName, 'public'); // Store in repairs/videos folder
                $videoUrls[] = Storage::url($path);
            }
        }

        // Assign to data array
        $validatedData['photos'] = $photoUrls;
        $validatedData['videos'] = $videoUrls;
        
        // Set default status
        //$validatedData['status'] = $request->input('status', 'new');
        
        // Create record
        $repair = TankRepair::create($validatedData);

        return response()->json([
            'status' => true,
            'message' => 'Tank repair report submitted successfully.',
            'report' => $repair,
        ], 201);
    }
}