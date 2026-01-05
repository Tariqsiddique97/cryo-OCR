<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Roles') }}</h2>
            @can('role.create')
                <a href="{{ route('admin.roles.create') }}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Create Role</a>
            @endcan
        </div>
    </x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Permissions</th>
                                <th class="relative px-6 py-3"><span class="sr-only">Actions</span></th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @forelse ($roles as $role)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap font-medium">{{ $role->name }}</td>
                                <td class="px-6 py-4"><div class="flex flex-wrap gap-1">@forelse($role->permissions->pluck('name') as $p)<span class="px-2 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">{{ $p }}</span>@empty - @endforelse</div></td>
                                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                    @can('role.view')<a href="{{ route('admin.roles.show', $role->id) }}" class="text-gray-600">View</a>@endcan
                                    @can('role.edit')<a href="{{ route('admin.roles.edit', $role->id) }}" class="text-indigo-600 ml-4">Edit</a>@endcan
                                    @can('role.delete')
                                    @if($role->name != 'admin')
                                    <form class="inline-block" action="{{ route('admin.roles.destroy', $role->id) }}" method="POST" onsubmit="return confirm('Are you sure?');">
                                        @csrf @method('DELETE')
                                        <button type="submit" class="text-red-600 ml-4">Delete</button>
                                    </form>
                                    @endif
                                    @endcan
                                </td>
                            </tr>
                            @empty
                            <tr><td colspan="3" class="px-6 py-4 text-center">No roles found.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>