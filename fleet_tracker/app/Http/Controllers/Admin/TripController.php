<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppUser;
use App\Models\Tractor;
use App\Models\Trailer;
use App\Models\Trip;
use App\Models\Stop;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TripController extends Controller
{
    public function index() {
        $trips = Trip::with('driver')->orderBy('created_at', 'desc')->get();
        return view('admin.trips.index', compact('trips'));
    }

    public function create()
    {
        $tractors = Tractor::orderBy('number')->get();
        $trailers = Trailer::orderBy('number')->get();

        $unavailableTractorIds = Trip::where('status', 0)->whereNotNull('tractor_id')->pluck('tractor_id')->toArray();
        $unavailableTrailerIds = Trip::where('status', 0)->whereNotNull('trailor_id')->pluck('trailor_id')->toArray();

        $googleMapsApiKey = config('services.google.maps_api_key') ?? env('GOOGLE_MAPS_API_KEY', 'AIzaSyAocbSLfNBPGEElNem-VEPyIdNTwHSY7m8');

        return view('admin.trips.create', compact('tractors', 'trailers', 'unavailableTractorIds', 'unavailableTrailerIds', 'googleMapsApiKey'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'tractor_id' => [
                'nullable',
                'exists:tractors,id',
                function ($attribute, $value, $fail) {
                    if ($value) {
                        $hasPendingTrip = Trip::where('tractor_id', $value)->where('status', 0)->exists();
                        if ($hasPendingTrip) {
                            $fail('This tractor already has a pending trip.');
                        }
                    }
                },
            ],
            'trailor_id' => [
                'nullable',
                'exists:trailers,id',
                function ($attribute, $value, $fail) {
                    if ($value) {
                        $hasPendingTrip = Trip::where('trailor_id', $value)->where('status', 0)->exists();
                        if ($hasPendingTrip) {
                            $fail('This trailer already has a pending trip.');
                        }
                    }
                },
            ],
            'stops' => 'required|array|min:1',
            'stops.*.name' => 'required|string|max:255',
            'stops.*.address' => 'nullable|string|max:1000',
            'stops.*.latitude' => 'nullable|numeric',
            'stops.*.longitude' => 'nullable|numeric',
        ]);

        $trip = Trip::create([
            'tractor_id' => $validated['tractor_id'] ?? null,
            'trailor_id' => $validated['trailor_id'] ?? null,
            'status' => 0,
        ]);

        foreach ($validated['stops'] as $index => $stopData) {
            $trip->stops()->create([
                'name' => $stopData['name'],
                'sequence_number' => $index + 1,
                'status' => 0,
                'is_tank_verified' => 0,
                'address' => $stopData['address'] ?? null,
                'latitude' => $stopData['latitude'] ?? null,
                'longitude' => $stopData['longitude'] ?? null,
            ]);
        }

        return redirect()->route('admin.trips.index')->with('success', 'Trip created successfully.');
    }

    public function show(Trip $trip) {
        $trip->load('driver', 'tractor', 'trailer', 'stops');

        $googleMapsApiKey = config('services.google.maps_api_key') ?? env('GOOGLE_MAPS_API_KEY', 'AIzaSyAocbSLfNBPGEElNem-VEPyIdNTwHSY7m8');

        return view('admin.trips.show', compact('trip', 'googleMapsApiKey'));
    }

    public function edit(Trip $trip)
    {
        $trip->load('stops');
        $tractors = Tractor::orderBy('number')->get();
        $trailers = Trailer::orderBy('number')->get();

        $unavailableTractorIds = Trip::where('status', 0)
            ->where('id', '!=', $trip->id)
            ->whereNotNull('tractor_id')
            ->pluck('tractor_id')
            ->toArray();
            
        $unavailableTrailerIds = Trip::where('status', 0)
            ->where('id', '!=', $trip->id)
            ->whereNotNull('trailor_id')
            ->pluck('trailor_id')
            ->toArray();

        $googleMapsApiKey = config('services.google.maps_api_key') ?? env('GOOGLE_MAPS_API_KEY', 'AIzaSyAocbSLfNBPGEElNem-VEPyIdNTwHSY7m8');

        return view('admin.trips.edit', compact('trip', 'tractors', 'trailers', 'unavailableTractorIds', 'unavailableTrailerIds', 'googleMapsApiKey'));
    }

    public function update(Request $request, Trip $trip)
    {
        $validated = $request->validate([
            'tractor_id' => [
                'nullable',
                'exists:tractors,id',
                function ($attribute, $value, $fail) use ($trip) {
                    if ($value) {
                        $hasOtherPendingTrip = Trip::where('tractor_id', $value)
                            ->where('status', 0)
                            ->where('id', '!=', $trip->id)
                            ->exists();
                        if ($hasOtherPendingTrip) {
                            $fail('This tractor already has a pending trip.');
                        }
                    }
                },
            ],
            'trailor_id' => [
                'nullable',
                'exists:trailers,id',
                function ($attribute, $value, $fail) use ($trip) {
                    if ($value) {
                        $hasOtherPendingTrip = Trip::where('trailor_id', $value)
                            ->where('status', 0)
                            ->where('id', '!=', $trip->id)
                            ->exists();
                        if ($hasOtherPendingTrip) {
                            $fail('This trailer already has a pending trip.');
                        }
                    }
                },
            ],
            'stops' => 'required|array|min:1',
            'stops.*.id' => 'sometimes|nullable|integer',
            'stops.*.name' => 'required|string|max:255',
            'stops.*.address' => 'nullable|string|max:1000',
            'stops.*.latitude' => 'nullable|numeric',
            'stops.*.longitude' => 'nullable|numeric',
        ]);

        $trip->update([
            'tractor_id' => $validated['tractor_id'] ?? null,
            'trailor_id' => $validated['trailor_id'] ?? null,
        ]);

        // Sync stops: update existing, create new, delete removed
        $existingStopIds = $trip->stops()->pluck('id')->toArray();
        $incomingStopIds = [];
        foreach ($validated['stops'] as $index => $stopData) {
            if (!empty($stopData['id'])) {
                $incomingStopIds[] = (int)$stopData['id'];
                $stop = Stop::find($stopData['id']);
                if ($stop) {
                    $stop->update([
                        'name' => $stopData['name'],
                        'sequence_number' => $index + 1,
                        'address' => $stopData['address'] ?? $stop->address,
                        'latitude' => $stopData['latitude'] ?? $stop->latitude,
                        'longitude' => $stopData['longitude'] ?? $stop->longitude,
                    ]);
                }
            } else {
                $newStop = $trip->stops()->create([
                    'name' => $stopData['name'],
                    'sequence_number' => $index + 1,
                    'status' => 0,
                    'is_tank_verified' => 0,
                    'address' => $stopData['address'] ?? null,
                    'latitude' => $stopData['latitude'] ?? null,
                    'longitude' => $stopData['longitude'] ?? null,
                ]);
                $incomingStopIds[] = $newStop->id;
            }
        }
        Stop::destroy(array_diff($existingStopIds, $incomingStopIds));

        return redirect()->route('admin.trips.index')->with('success', 'Trip updated successfully.');
    }

    public function updateStopOrder(Request $request) {
        $request->validate(['order' => 'required|array']);
        foreach ($request->order as $index => $stopId) {
            Stop::where('id', $stopId)->update(['sequence_number' => $index + 1]);
        }
        return response()->json(['status' => 'success']);
    }

    /**
     * AJAX endpoint to update an existing stop location (address, lat, lng)
     */
    public function updateStopLocation(Request $request, Stop $stop)
    {
        $data = $request->validate([
            'address' => 'nullable|string|max:1000',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $stop->address = $data['address'] ?? null;
        $stop->latitude = $data['latitude'];
        $stop->longitude = $data['longitude'];
        $stop->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Stop location updated.',
            'stop' => $stop->only(['id', 'address', 'latitude', 'longitude']),
        ]);
    }
}
