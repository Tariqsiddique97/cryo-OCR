<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Manage Trips') }}</h2>
    </x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b">
                    <div class="flex justify-end mb-4">
                        <a href="{{ route('admin.trips.create') }}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Create New Trip</a>
                    </div>
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Trip ID</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tractor</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Trailer</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                                <th class="relative px-6 py-3"></th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y">
                            @forelse ($trips as $trip)
                            <tr>
                                <td class="px-6 py-4 font-medium">{{ $trip->id }}</td>
                                <td class="px-6 py-4">{{ $trip->tractor->number ?? 'N/A' }}</td>
                                <td class="px-6 py-4">{{ $trip->trailer->number ?? 'N/A' }}</td>
                                <td class="px-6 py-4">
                                    @if($trip->status == 0)
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">In Progress</span>
                                    @elseif($trip->status == 1)
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Completed</span>
                                        
                                    @else
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">In Progress</span>
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Completed</span>
                                         <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">Pending</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-right text-sm font-medium">
                                <a href="{{ route('admin.trips.show', $trip->id) }}" class="text-gray-600">View</a>
                                @if($trip->status == 0)
                                    
                                    <a href="{{ route('admin.trips.edit', $trip->id) }}" class="text-indigo-600 ml-4">Edit</a>
                                    <form class="inline-block" action="{{ route('admin.trips.destroy', $trip->id) }}" method="POST" onsubmit="return confirm('Are you sure?');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="text-red-600 ml-4">Delete</button>
                                    </form>

                                @endif
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td class="px-6 py-4 text-center" colspan="5">No trips found.</td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>