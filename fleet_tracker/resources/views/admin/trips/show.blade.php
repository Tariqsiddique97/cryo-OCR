<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Trip Details') }}: #{{ $trip->id }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-6">
            <!-- Trip Information (same) -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-medium text-gray-900">Trip Information</h3>
                    <dl class="mt-4 divide-y divide-gray-200">
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                            <dt class="font-medium text-gray-500">Driver</dt>
                            <dd class="sm:col-span-2">{{ $trip->driver->name ?? 'N/A' }}</dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                            <dt class="font-medium text-gray-500">Tractor Number</dt>
                            <dd class="sm:col-span-2">{{ $trip->tractor->number ?? 'Not Assigned' }}</dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                            <dt class="font-medium text-gray-500">Trailer Number</dt>
                            <dd class="sm:col-span-2">{{ $trip->trailer->number ?? 'Not Assigned' }}</dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                            <dt class="font-medium text-gray-500">Total Trip Miles</dt>
                            <dd class="sm:col-span-2">{{ $trip->total_trip_miles ?? '-' }}</dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                            <dt class="font-medium text-gray-500">Total Quantity</dt>
                            <dd class="sm:col-span-2">{{ $trip->total_quantity ?? '-' }}</dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                            <dt class="font-medium text-gray-500">Status</dt>
                            <dd class="sm:col-span-2">
                                @if ($trip->status == 0)
                                    In Progress
                                @elseif($trip->status == 1)
                                    Completed
                                @else
                                    Pending
                                @endif
                            </dd>
                        </div>
                    </dl>
                </div>
            </div>

            <!-- Stops Details with Pick Location button -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-medium text-gray-900">Stops Details</h3>
                        <p class="text-sm text-gray-500">Pick location on map for each stop.</p>
                    </div>

                    <div class="mt-4 space-y-6">
                        @forelse($trip->stops as $stop)
                            <div class="p-4 border rounded-lg stop-row" data-id="{{ $stop->id }}">
                                <div class="flex justify-between items-baseline">
                                    <h4 class="font-semibold text-gray-800">{{ $stop->sequence_number }}. {{ $stop->name }}</h4>
                                    <div class="flex items-center space-x-2">
                                        <button type="button"
                                            class="open-map-existing inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded bg-gray-100 hover:bg-gray-200"
                                            data-stop-id="{{ $stop->id }}"
                                            data-address="{{ $stop->address ?? '' }}"
                                            data-lat="{{ $stop->latitude ?? '' }}"
                                            data-lng="{{ $stop->longitude ?? '' }}"
                                        >
                                            Pick Location
                                        </button>

                                        <span class="text-sm font-medium text-gray-500">
                                            @if ($stop->status == 0) Pending @elseif ($stop->status == 1) In Progress @else Completed @endif
                                        </span>
                                    </div>
                                </div>

                                <dl class="mt-2 text-sm divide-y divide-gray-100">
                                    @php
                                        $fields = [
                                            'start_time',
                                            'end_time',
                                            'tank_number',
                                            'full_trycock',
                                            'attn_driver_maintain',
                                            'psi_value',
                                            'levels_value',
                                            'level_before_value',
                                            'level_after_value',
                                            'psi_before_value',
                                            'psi_after_value',
                                            'quantity_value',
                                            'odometer_value',
                                        ];
                                    @endphp

                                    @foreach ($fields as $field)
                                        <div class="py-2 sm:grid sm:grid-cols-3 sm:gap-4">
                                            <dt class="font-medium text-gray-500">{{ ucwords(str_replace('_', ' ', $field)) }}</dt>
                                            <dd class="sm:col-span-2 text-gray-900">{{ $stop->$field ?? '-' }}</dd>
                                        </div>
                                    @endforeach

                                    <div class="py-2 sm:grid sm:grid-cols-3 sm:gap-4">
                                        <dt class="font-medium text-gray-500">Address</dt>
                                        <dd class="sm:col-span-2 text-gray-900 stop-address-{{ $stop->id }}">{{ $stop->address ?? '-' }}</dd>
                                    </div>
                                    <div class="py-2 sm:grid sm:grid-cols-3 sm:gap-4">
                                        <dt class="font-medium text-gray-500">Latitude / Longitude</dt>
                                        <dd class="sm:col-span-2 text-gray-900 stop-coords-{{ $stop->id }}">{{ $stop->latitude ?? '-' }} {{ $stop->longitude ? ', ' . $stop->longitude : '' }}</dd>
                                    </div>
                                </dl>
                            </div>
                        @empty
                            <p class="text-gray-500">No stops have been recorded for this trip.</p>
                        @endforelse
                    </div>
                </div>
            </div>

            <div class="flex items-center justify-end mt-4">
                <a href="{{ route('admin.trips.index') }}" class="text-sm text-gray-600 hover:text-gray-900 underline">
                    &larr; Back to All Trips
                </a>
                @if ($trip->status == 0)
                <a href="{{ route('admin.trips.edit', $trip->id) }}"
                    class="ml-4 inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">
                    Edit
                </a>
                @endif
            </div>
        </div>
    </div>

    {{-- Map modal (same) --}}
    <div id="map-modal" class="fixed inset-0 z-50 hidden items-center justify-center bg-black bg-opacity-50">
        <div class="bg-white rounded-lg w-11/12 md:w-3/4 lg:w-2/3 max-w-5xl p-4">
            <div class="flex justify-between items-center mb-3">
                <h3 id="map-modal-title" class="text-lg font-semibold">Pick location</h3>
                <button id="close-map-modal" class="text-gray-600 hover:text-gray-900">&times;</button>
            </div>

            <div class="space-y-3">
                <input id="place-search-input" type="text" placeholder="Search address or place" class="w-full border rounded px-3 py-2" />
                <div id="map" style="height:400px; width:100%;" class="rounded"></div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Address</label>
                        <input id="selected-address" type="text" class="mt-1 block w-full border rounded px-2 py-2" />
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Latitude</label>
                        <input id="selected-lat" type="text" class="mt-1 block w-full border rounded px-2 py-2" />
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Longitude</label>
                        <input id="selected-lng" type="text" class="mt-1 block w-full border rounded px-2 py-2" />
                    </div>
                </div>

                <div class="flex justify-end space-x-2">
                    <button id="cancel-location" class="px-4 py-2 border rounded">Cancel</button>
                    <button id="save-location" class="px-4 py-2 bg-blue-600 text-white rounded">Save Location</button>
                </div>
            </div>
        </div>
    </div>

    {{-- CSRF token meta --}}
    <meta name="csrf-token" content="{{ csrf_token() }}">

    {{-- Google Maps API (Places) --}}
    <script async defer src="https://maps.googleapis.com/maps/api/js?key={{ $googleMapsApiKey }}&libraries=places"></script>

    <script>
        // Map modal logic for show page (only existing stops)
        let map, marker, autocomplete;
        let currentStopId = null;

        function openMapModalForStop(stopId, address = '', lat = '', lng = '') {
            currentStopId = stopId;
            document.getElementById('map-modal-title').innerText = 'Pick location for stop #' + stopId;
            document.getElementById('selected-address').value = address || '';
            document.getElementById('selected-lat').value = lat || '';
            document.getElementById('selected-lng').value = lng || '';

            const modal = document.getElementById('map-modal');
            modal.classList.remove('hidden'); modal.classList.add('flex');

            setTimeout(() => initMapForModal(lat, lng), 50);
        }

        function initMapForModal(lat = null, lng = null) {
    // Default center: California, USA
    const defaultPos = { lat: lat ? parseFloat(lat) : 36.7783, lng: lng ? parseFloat(lng) : -119.4179 };
    map = new google.maps.Map(document.getElementById('map'), {
        center: defaultPos,
        zoom: (lat && lng) ? 14 : 6,
    });

    marker = new google.maps.Marker({
        position: defaultPos,
        map: map,
        draggable: true,
    });

    marker.addListener('dragend', function() {
        const pos = marker.getPosition();
        updateLocationInputs(pos.lat(), pos.lng());
        reverseGeocode(pos.lat(), pos.lng());
    });

    map.addListener('click', function(e) {
        const clicked = e.latLng;
        marker.setPosition(clicked);
        updateLocationInputs(clicked.lat(), clicked.lng());
        reverseGeocode(clicked.lat(), clicked.lng());
    });

    const input = document.getElementById('place-search-input');
    autocomplete = new google.maps.places.Autocomplete(input);
    autocomplete.bindTo('bounds', map);

    autocomplete.addListener('place_changed', function() {
        const place = autocomplete.getPlace();
        if (!place.geometry) return;
        if (place.geometry.viewport) {
            map.fitBounds(place.geometry.viewport);
        } else {
            map.setCenter(place.geometry.location);
            map.setZoom(17);
        }
        marker.setPosition(place.geometry.location);
        const lat = place.geometry.location.lat();
        const lng = place.geometry.location.lng();
        updateLocationInputs(lat, lng);
        document.getElementById('selected-address').value = place.formatted_address || input.value;
    });
}

        function updateLocationInputs(lat, lng) {
            document.getElementById('selected-lat').value = lat;
            document.getElementById('selected-lng').value = lng;
        }

        function reverseGeocode(lat, lng) {
            const geocoder = new google.maps.Geocoder();
            geocoder.geocode({ location: { lat: lat, lng: lng } }, (results, status) => {
                if (status === 'OK' && results[0]) document.getElementById('selected-address').value = results[0].formatted_address;
            });
        }

        document.querySelectorAll('.open-map-existing').forEach(btn => {
            btn.addEventListener('click', function() {
                const stopId = this.dataset.stopId;
                const address = this.dataset.address || '';
                const lat = this.dataset.lat || '';
                const lng = this.dataset.lng || '';
                openMapModalForStop(stopId, address, lat, lng);
            });
        });

        document.getElementById('close-map-modal').addEventListener('click', function() {
            document.getElementById('map-modal').classList.add('hidden'); document.getElementById('map-modal').classList.remove('flex');
            currentStopId = null;
        });

        document.getElementById('cancel-location').addEventListener('click', function() {
            document.getElementById('map-modal').classList.add('hidden'); document.getElementById('map-modal').classList.remove('flex');
            currentStopId = null;
        });

        document.getElementById('save-location').addEventListener('click', function() {
            if (!currentStopId) return alert('No stop selected.');
            const address = document.getElementById('selected-address').value;
            const lat = document.getElementById('selected-lat').value;
            const lng = document.getElementById('selected-lng').value;
            if (!lat || !lng) return alert('Please select a location.');

            const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

            fetch("{{ url('/admin/stops') }}/" + currentStopId + "/location", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': token,
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ address: address, latitude: lat, longitude: lng })
            })
            .then(r => r.json())
            .then(data => {
                if (data.status === 'success') {
                    const addrEl = document.querySelector('.stop-address-' + currentStopId);
                    const coordsEl = document.querySelector('.stop-coords-' + currentStopId);
                    if (addrEl) addrEl.innerText = data.stop.address || '-';
                    if (coordsEl) coordsEl.innerText = (data.stop.latitude || '-') + (data.stop.longitude ? ', ' + data.stop.longitude : '');
                    alert('Location saved.');
                    document.getElementById('map-modal').classList.add('hidden'); document.getElementById('map-modal').classList.remove('flex');
                    currentStopId = null;
                } else {
                    alert('Failed to save location.');
                }
            })
            .catch(err => {
                console.error(err);
                alert('Error saving location.');
            });
        });
    </script>
</x-app-layout>
