<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('User Details') }}</h2>
    </x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-medium text-gray-900">{{ $user->name }} ({{ $user->email }})</h3>
                    <div class="mt-4 pt-4 border-t"><h4 class="font-medium text-gray-700">Assigned Roles</h4><div class="flex flex-wrap gap-2 mt-2">@forelse($user->roles as $role)<span class="px-3 py-1 text-sm font-semibold rounded-full bg-green-100 text-green-800">{{ $role->name }}</span>@empty<p class="text-sm text-gray-500">None.</p>@endforelse</div></div>
                    <div class="mt-4 pt-4 border-t"><h4 class="font-medium text-gray-700">All Permissions (from Roles)</h4><div class="flex flex-wrap gap-2 mt-2">@forelse($user->getAllPermissions() as $p)<span class="px-3 py-1 text-sm font-semibold rounded-full bg-blue-100 text-blue-800">{{ $p->name }}</span>@empty<p class="text-sm text-gray-500">None.</p>@endforelse</div></div>
                    <div class="flex items-center justify-end mt-6 pt-6 border-t">
                        <a href="{{ route('admin.users.index') }}" class="underline text-gray-600">&larr; Back to Users</a>
                        @can('user.edit')
                        <a href="{{ route('admin.users.edit', $user->id) }}" class="ml-4 inline-flex items-center px-4 py-2 bg-gray-800 rounded-md font-semibold text-xs text-white uppercase hover:bg-gray-700">Edit Roles</a>
                        @endcan
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>