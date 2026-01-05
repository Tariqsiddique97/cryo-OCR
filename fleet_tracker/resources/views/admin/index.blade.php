<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Admin Dashboard') }}
        </h2>
    </x-slot>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        @can('permission.view')
        <div class="p-6 bg-white rounded-lg shadow">
            <h3 class="text-lg font-semibold text-gray-700">Manage Permissions</h3>
            <p class="mt-2 text-gray-600">Define the granular actions users can perform.</p>
            <a href="{{ route('admin.permissions.index') }}" class="mt-4 inline-block text-blue-500 hover:text-blue-700 font-semibold">Go to Permissions &rarr;</a>
        </div>
        @endcan
        @can('role.view')
         <div class="p-6 bg-white rounded-lg shadow">
            <h3 class="text-lg font-semibold text-gray-700">Manage Roles</h3>
            <p class="mt-2 text-gray-600">Group permissions into roles like 'Editor' or 'Moderator'.</p>
            <a href="{{ route('admin.roles.index') }}" class="mt-4 inline-block text-blue-500 hover:text-blue-700 font-semibold">Go to Roles &rarr;</a>
        </div>
        @endcan
        @can('user.view')
         <div class="p-6 bg-white rounded-lg shadow">
            <h3 class="text-lg font-semibold text-gray-700">Manage Users</h3>
            <p class="mt-2 text-gray-600">Assign roles to your application's users.</p>
            <a href="{{ route('admin.users.index') }}" class="mt-4 inline-block text-blue-500 hover:text-blue-700 font-semibold">Go to Users &rarr;</a>
        </div>
        @endcan
    </div>
</x-app-layout>