<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Create New Trip') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b">
                    <form method="POST" action="{{ route('admin.trips.store') }}">
                        @csrf

                        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div>
                                <x-input-label for="tractor_id" value="Assign Tractor" />
                                <select name="tractor_id" class="block mt-1 w-full border-gray-300 rounded-md">
                                    <option value="">Select a tractor...</option>
                                    @foreach($tractors as $tractor)
                                        <option value="{{ $tractor->id }}" @if(in_array($tractor->id, $unavailableTractorIds)) disabled @endif>
                                            {{ $tractor->number }} @if(in_array($tractor->id, $unavailableTractorIds)) (On Trip) @endif
                                        </option>
                                    @endforeach
                                </select>
                            </div>

                            <div>
                                <x-input-label for="trailor_id" value="Assign Trailer" />
                                <select name="trailor_id" class="block mt-1 w-full border-gray-300 rounded-md">
                                    <option value="">Select a trailer...</option>
                                    @foreach($trailers as $trailer)
                                        <option value="{{ $trailer->id }}" @if(in_array($trailer->id, $unavailableTrailerIds)) disabled @endif>
                                            {{ $trailer->number }} @if(in_array($trailer->id, $unavailableTrailerIds)) (On Trip) @endif
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <div class="mt-6 pt-6 border-t">
                            <div class="flex justify-between items-center">
                                <h3 class="font-medium text-gray-900">Stops</h3>
                                <button type="button" id="add-stop" class="bg-gray-200 text-sm font-bold py-1 px-3 rounded">Add Stop</button>
                            </div>

                            <div id="stops-container" class="mt-4 space-y-4">
                                {{-- initially empty; new stops added dynamically --}}
                            </div>
                        </div>

                        <div class="flex items-center justify-end mt-6">
                            <a href="{{ route('admin.trips.index') }}" class="underline mr-4">Cancel</a>
                            <x-primary-button>Create Trip</x-primary-button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    {{-- Map Modal (shared for create/edit/show) --}}
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
        // For create: stops are only new items. We'll use uid for each added stop element.
        let createStopUid = 0;
        const stopsContainer = document.getElementById('stops-container');

        function createStopElement(uid) {
            const div = document.createElement('div');
            div.className = 'flex items-center space-x-2 stop-row';
            div.setAttribute('data-uid', uid);

            div.innerHTML = `
                <div class="flex-grow">
                    <input type="text" name="stops[${uid}][name]" placeholder="Enter stop name" required class="block w-full border rounded px-2 py-2" />
                    <input type="hidden" name="stops[${uid}][address]" class="stop-address-input" />
                    <input type="hidden" name="stops[${uid}][latitude]" class="stop-lat-input" />
                    <input type="hidden" name="stops[${uid}][longitude]" class="stop-lng-input" />
                </div>
                <button type="button" class="open-map-for-new bg-gray-100 hover:bg-gray-200 border rounded px-3 py-1 text-sm" data-uid="${uid}">Pick Location</button>
                <button type="button" class="remove-stop bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-3 rounded">&times;</button>
            `;
            return div;
        }

        document.getElementById('add-stop').addEventListener('click', function() {
            const uid = createStopUid++;
            const el = createStopElement(uid);
            stopsContainer.appendChild(el);
        });

        stopsContainer.addEventListener('click', function(e) {
            if (e.target.classList.contains('remove-stop')) {
                e.target.closest('.stop-row').remove();
            }
            if (e.target.classList.contains('open-map-for-new')) {
                const uid = e.target.dataset.uid;
                openMapModalForNew(uid);
            }
        });

        // ----- Shared Map Modal logic (create/edit/show all use same modal) -----
        let map, marker, autocomplete;
        let currentTarget = null; // { type: 'new'|'existing', uid: ..., stopId: ... }

        function openMapModalForNew(uid) {
            currentTarget = { type: 'new', uid: uid };
            document.getElementById('map-modal-title').innerText = 'Pick location for new stop';
            document.getElementById('selected-address').value = '';
            document.getElementById('selected-lat').value = '';
            document.getElementById('selected-lng').value = '';

            const modal = document.getElementById('map-modal');
            modal.classList.remove('hidden'); modal.classList.add('flex');
            setTimeout(() => {
                initMapForModal(); // no lat/lng specified
            }, 60);
        }

        function closeMapModal() {
            currentTarget = null;
            const modal = document.getElementById('map-modal');
            modal.classList.add('hidden'); modal.classList.remove('flex');
            // cleanup
            map = null; marker = null;
            document.getElementById('place-search-input').value = '';
        }

        function initMapForModal(lat = null, lng = null) {
    // Center on California by default
    const defaultPos = { lat: lat ? parseFloat(lat) : 36.7783, lng: lng ? parseFloat(lng) : -119.4179 };
    map = new google.maps.Map(document.getElementById('map'), {
        center: defaultPos,
        zoom: (lat && lng) ? 14 : 6, // closer zoom if coords provided, otherwise show CA region
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
                if (status === 'OK' && results[0]) {
                    document.getElementById('selected-address').value = results[0].formatted_address;
                }
            });
        }

        document.getElementById('close-map-modal').addEventListener('click', closeMapModal);
        document.getElementById('cancel-location').addEventListener('click', closeMapModal);

        document.getElementById('save-location').addEventListener('click', function() {
            const address = document.getElementById('selected-address').value;
            const lat = document.getElementById('selected-lat').value;
            const lng = document.getElementById('selected-lng').value;

            if (!lat || !lng) return alert('Please select a location.');

            if (!currentTarget) return alert('No target selected.');

            if (currentTarget.type === 'new') {
                // write into hidden inputs inside the new stop row
                const uid = currentTarget.uid;
                const row = document.querySelector(`.stop-row[data-uid="${uid}"]`);
                if (!row) {
                    closeMapModal(); return alert('Stop row not found.');
                }
                row.querySelector('.stop-address-input').value = address;
                row.querySelector('.stop-lat-input').value = lat;
                row.querySelector('.stop-lng-input').value = lng;
                closeMapModal();
            } else {
                // Should not happen on create page; handled in edit/show (below)
                closeMapModal();
            }
        });
    </script>
</x-app-layout>
