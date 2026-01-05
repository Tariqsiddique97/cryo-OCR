<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Edit Trip') }}: #{{$trip->id}}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b">
                    <form method="POST" action="{{ route('admin.trips.update', $trip->id) }}">
                        @csrf
                        @method('PUT')

                        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div>
                                <x-input-label for="tractor_id" value="Assign Tractor" />
                                <select name="tractor_id" class="block mt-1 w-full border-gray-300 rounded-md">
                                    <option value="">Select a tractor...</option>
                                    @foreach($tractors as $tractor)
                                        <option value="{{ $tractor->id }}" 
                                                @selected($trip->tractor_id == $tractor->id) 
                                                @if(in_array($tractor->id, $unavailableTractorIds)) disabled @endif>
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
                                        <option value="{{ $trailer->id }}" 
                                                @selected($trip->trailor_id == $trailer->id) 
                                                @if(in_array($trailer->id, $unavailableTrailerIds)) disabled @endif>
                                            {{ $trailer->number }} @if(in_array($trailer->id, $unavailableTrailerIds)) (On Trip) @endif
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <div class="mt-6 pt-6 border-t">
                            <div class="flex justify-between items-center">
                                <h3 class="font-medium text-gray-900">Stops (Drag to re-order)</h3>
                                <button type="button" id="add-stop" class="bg-gray-200 hover:bg-gray-300 text-gray-700 font-bold py-1 px-3 rounded text-sm">Add Stop</button>
                            </div>

                            <div id="stops-container" class="mt-4 space-y-4">
                                @foreach($trip->stops as $index => $stop)
                                    <div class="flex items-center space-x-2 group stop-row" data-id="{{ $stop->id }}" data-uid="" data-index="{{ $index }}">
                                        <input type="hidden" name="stops[{{$index}}][id]" value="{{ $stop->id }}">
                                        <span class="cursor-move text-gray-400 group-hover:text-gray-700">☰</span>
                                        <div class="flex-grow">
                                            <input name="stops[{{$index}}][name]" class="block w-full border rounded px-2 py-2" type="text" value="{{ $stop->name }}" required />
                                            <input type="hidden" name="stops[{{$index}}][address]" class="stop-address-input" value="{{ $stop->address ?? '' }}" />
                                            <input type="hidden" name="stops[{{$index}}][latitude]" class="stop-lat-input" value="{{ $stop->latitude ?? '' }}" />
                                            <input type="hidden" name="stops[{{$index}}][longitude]" class="stop-lng-input" value="{{ $stop->longitude ?? '' }}" />
                                        </div>

                                        <button type="button" class="open-map-existing inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded bg-gray-100 hover:bg-gray-200" 
                                            data-stop-id="{{ $stop->id }}" 
                                            data-address="{{ $stop->address ?? '' }}" 
                                            data-lat="{{ $stop->latitude ?? '' }}" 
                                            data-lng="{{ $stop->longitude ?? '' }}" 
                                            data-stop-index="{{ $index }}">
                                            Pick Location
                                        </button>

                                        <button type="button" class="remove-stop bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-3 rounded">&times;</button>
                                    </div>
                                @endforeach
                            </div>
                        </div>

                        <div class="flex items-center justify-end mt-6">
                            <a href="{{ route('admin.trips.index') }}" class="underline mr-4">Cancel</a>
                            <x-primary-button>Update Trip</x-primary-button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    {{-- Map Modal (shared) --}}
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

    {{-- SortableJS for drag reorder (you already used) --}}
    <script src="https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.min.js"></script>

    <script>
        // Manage adding new stops in edit page (new stops will have uid)
        let stopIndex = {{ $trip->stops->count() }};
        let newUidCounter = 0;
        const container = document.getElementById('stops-container');

        new Sortable(container, {
            animation: 150,
            handle: '.cursor-move, .cursor-move',
            onEnd: function () {
                Array.from(container.children).forEach((el, index) => {
                    // rename input names to keep sequential indices
                    el.querySelectorAll('input, select, textarea').forEach(input => {
                        if (input.name) {
                            input.name = input.name.replace(/stops\[\d+\]/, `stops[${index}]`);
                        }
                    });
                });
            }
        });

        document.getElementById('add-stop').addEventListener('click', function() {
            const idx = stopIndex++;
            const uid = 'new-' + (newUidCounter++);
            const stopDiv = document.createElement('div');
            stopDiv.className = 'flex items-center space-x-2 group stop-row';
            stopDiv.setAttribute('data-id', '');
            stopDiv.setAttribute('data-uid', uid);
            stopDiv.innerHTML = `
                <input type="hidden" name="stops[${idx}][id]" value="">
                <span class="cursor-move text-gray-400 group-hover:text-gray-700">☰</span>
                <div class="flex-grow">
                    <input name="stops[${idx}][name]" class="block w-full border rounded px-2 py-2" type="text" placeholder="Enter stop name" required />
                    <input type="hidden" name="stops[${idx}][address]" class="stop-address-input" value="" />
                    <input type="hidden" name="stops[${idx}][latitude]" class="stop-lat-input" value="" />
                    <input type="hidden" name="stops[${idx}][longitude]" class="stop-lng-input" value="" />
                </div>
                <button type="button" class="open-map-new inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded bg-gray-100 hover:bg-gray-200" data-uid="${uid}" data-index="${idx}">Pick Location</button>
                <button type="button" class="remove-stop bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-3 rounded">&times;</button>
            `;
            container.appendChild(stopDiv);
        });

        // click handlers inside stops container
        container.addEventListener('click', function(e) {
            if (e.target.classList.contains('remove-stop')) {
                e.target.closest('.stop-row').remove();
                // reindex names
                Array.from(container.children).forEach((el, index) => {
                    el.querySelectorAll('input, select, textarea').forEach(input => {
                        if (input.name) {
                            input.name = input.name.replace(/stops\[\d+\]/, `stops[${index}]`);
                        }
                    });
                });
            }

            // existing stop -> open modal, will save via AJAX
            if (e.target.classList.contains('open-map-existing')) {
                const btn = e.target;
                const stopId = btn.dataset.stopId;
                const address = btn.dataset.address || '';
                const lat = btn.dataset.lat || '';
                const lng = btn.dataset.lng || '';
                openMapModalForExisting(stopId, address, lat, lng);
            }

            // new stop -> open modal and store into hidden inputs
            if (e.target.classList.contains('open-map-new')) {
                const btn = e.target;
                const index = btn.dataset.index;
                const uid = btn.dataset.uid;
                openMapModalForNewEdit(index, uid);
            }
        });

        // ----- Shared modal logic (reused) -----
        let map, marker, autocomplete;
        let currentTarget = null; // { type: 'existing'|'new', stopId, index }

        function openMapModalForExisting(stopId, address = '', lat = '', lng = '') {
            currentTarget = { type: 'existing', stopId: stopId };
            document.getElementById('map-modal-title').innerText = 'Pick location for stop #' + stopId;
            document.getElementById('selected-address').value = address || '';
            document.getElementById('selected-lat').value = lat || '';
            document.getElementById('selected-lng').value = lng || '';
            const modal = document.getElementById('map-modal');
            modal.classList.remove('hidden'); modal.classList.add('flex');
            setTimeout(() => initMapForModal(lat, lng), 50);
        }

        function openMapModalForNewEdit(index, uid) {
            currentTarget = { type: 'new', index: index, uid: uid };
            document.getElementById('map-modal-title').innerText = 'Pick location for new stop';
            document.getElementById('selected-address').value = '';
            document.getElementById('selected-lat').value = '';
            document.getElementById('selected-lng').value = '';
            const modal = document.getElementById('map-modal');
            modal.classList.remove('hidden'); modal.classList.add('flex');
            setTimeout(() => initMapForModal(), 50);
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
                if (status === 'OK' && results[0]) {
                    document.getElementById('selected-address').value = results[0].formatted_address;
                }
            });
        }

        document.getElementById('close-map-modal').addEventListener('click', function() {
            const modal = document.getElementById('map-modal');
            modal.classList.add('hidden'); modal.classList.remove('flex');
            currentTarget = null;
        });
        document.getElementById('cancel-location').addEventListener('click', function() {
            const modal = document.getElementById('map-modal');
            modal.classList.add('hidden'); modal.classList.remove('flex');
            currentTarget = null;
        });

        document.getElementById('save-location').addEventListener('click', function() {
            const address = document.getElementById('selected-address').value;
            const lat = document.getElementById('selected-lat').value;
            const lng = document.getElementById('selected-lng').value;

            if (!lat || !lng) return alert('Please select a location on the map.');

            if (!currentTarget) return alert('No target selected.');

            if (currentTarget.type === 'existing') {
                // AJAX save to server for existing stop
                const stopId = currentTarget.stopId;
                const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
                fetch("{{ url('/admin/stops') }}/" + stopId + "/location", {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': token,
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        address: address,
                        latitude: lat,
                        longitude: lng
                    })
                })
                .then(r => r.json())
                .then(data => {
                    if (data.status === 'success') {
                        // update the row's hidden inputs & data attributes
                        const row = document.querySelector(`.stop-row[data-id="${stopId}"]`);
                        if (row) {
                            row.querySelector('.stop-address-input').value = data.stop.address || '';
                            row.querySelector('.stop-lat-input').value = data.stop.latitude || '';
                            row.querySelector('.stop-lng-input').value = data.stop.longitude || '';

                            // also update the open-map-existing button dataset for subsequent opens
                            const btn = row.querySelector('.open-map-existing');
                            if (btn) {
                                btn.dataset.address = data.stop.address || '';
                                btn.dataset.lat = data.stop.latitude || '';
                                btn.dataset.lng = data.stop.longitude || '';
                            }
                        }
                        alert('Location saved.');
                    } else {
                        alert('Failed to save location.');
                    }
                    // close
                    const modal = document.getElementById('map-modal');
                    modal.classList.add('hidden'); modal.classList.remove('flex');
                    currentTarget = null;
                })
                .catch(err => {
                    console.error(err);
                    alert('Error saving location.');
                });

            } else if (currentTarget.type === 'new') {
                // For new stop in edit page: copy to hidden inputs of that row
                const idx = currentTarget.index;
                const row = document.querySelectorAll('.stop-row')[idx];
                if (row) {
                    row.querySelector('.stop-address-input').value = address;
                    row.querySelector('.stop-lat-input').value = lat;
                    row.querySelector('.stop-lng-input').value = lng;
                    alert('Location set for new stop.');
                }
                const modal = document.getElementById('map-modal');
                modal.classList.add('hidden'); modal.classList.remove('flex');
                currentTarget = null;
            }
        });
    </script>
</x-app-layout>
