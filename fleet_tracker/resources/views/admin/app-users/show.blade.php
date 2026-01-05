<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('App User Details') }}</h2></x-slot>
    <div class="py-12"><div class="max-w-7xl mx-auto sm:px-6 lg:px-8"><div class="bg-white overflow-hidden shadow-sm sm:rounded-lg"><div class="p-6 bg-white border-b">
        <dl class="divide-y divide-gray-200">
            <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Name</dt><dd class="sm:col-span-2">{{ $user->name }}</dd></div>
            <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Username</dt><dd class="sm:col-span-2">{{ $user->username }}</dd></div>
            <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Email</dt><dd class="sm:col-span-2">{{ $user->email }}</dd></div>
            <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Phone</dt><dd class="sm:col-span-2">{{ $user->country_code }} {{ $user->phone_number }}</dd></div>
            <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Assigned Role</dt><dd class="sm:col-span-2">{{ $user->appRole->name ?? 'N/A' }}</dd></div>
        </dl>
        <div class="flex items-center justify-end mt-6 pt-6 border-t"><a href="{{ route('admin.app-users.index') }}" class="underline">&larr; Back to Users</a><a href="{{ route('admin.app-users.edit', $user->id) }}" class="ml-4 inline-flex items-center px-4 py-2 bg-gray-800 rounded-md font-semibold text-xs text-white uppercase hover:bg-gray-700">Edit</a></div>
    </div></div></div></div>
</x-app-layout>