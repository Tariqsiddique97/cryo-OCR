<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Role Details') }}</h2></x-slot>
    <div class="py-12"><div class="max-w-7xl mx-auto sm:px-6 lg:px-8"><div class="bg-white overflow-hidden shadow-sm sm:rounded-lg"><div class="p-6 bg-white border-b">
        <h3 class="text-lg font-medium text-gray-900">{{ $role->name }}</h3>
        <div class="mt-4 pt-4 border-t"><h4 class="font-medium text-gray-700">Users with this Role ({{ $role->appUsers->count() }})</h4>
            <ul class="mt-2 list-disc list-inside">@forelse($role->appUsers as $user)<li>{{ $user->name }} ({{ $user->email }})</li>@empty<li>No users assigned to this role.</li>@endforelse</ul>
        </div>
        <div class="flex items-center justify-end mt-6 pt-6 border-t"><a href="{{ route('admin.app-roles.index') }}" class="underline">&larr; Back to Roles</a><a href="{{ route('admin.app-roles.edit', $role->id) }}" class="ml-4 inline-flex items-center px-4 py-2 bg-gray-800 rounded-md font-semibold text-xs text-white uppercase hover:bg-gray-700">Edit</a></div>
    </div></div></div></div>
</x-app-layout>