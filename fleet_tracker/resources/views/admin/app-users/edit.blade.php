<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Edit App User') }}: {{ $user->name }}</h2></x-slot>
    <div class="py-12"><div class="max-w-7xl mx-auto sm:px-6 lg:px-8"><div class="bg-white overflow-hidden shadow-sm sm:rounded-lg"><div class="p-6 bg-white border-b"><form method="POST" action="{{ route('admin.app-users.update', $user->id) }}">@csrf @method('PUT')
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div><x-input-label for="name" value="Name" /><x-text-input id="name" name="name" :value="old('name', $user->name)" class="block mt-1 w-full" type="text" required /></div>
        <div><x-input-label for="username" value="Username" /><x-text-input id="username" name="username" :value="old('username', $user->username)" class="block mt-1 w-full" type="text" required /></div>
        <div class="md:col-span-2"><x-input-label for="email" value="Email" /><x-text-input id="email" name="email" :value="old('email', $user->email)" class="block mt-1 w-full" type="email" required /></div>
        <div><x-input-label for="country_code" value="Country Code" /><select name="country_code" class="block mt-1 w-full border-gray-300 rounded-md"><option value="+91" @selected($user->country_code == '+91')>India (+91)</option><option value="+1" @selected($user->country_code == '+1')>USA (+1)</option></select></div>
        <div><x-input-label for="phone_number" value="Phone" /><x-text-input id="phone_number" name="phone_number" :value="old('phone_number', $user->phone_number)" class="block mt-1 w-full" type="text" /></div>
        <div><x-input-label for="password" value="New Password (optional)" /><x-text-input id="password" name="password" class="block mt-1 w-full" type="password" /></div>
        <div><x-input-label for="password_confirmation" value="Confirm New Password" /><x-text-input id="password_confirmation" name="password_confirmation" class="block mt-1 w-full" type="password" /></div>
        <div class="md:col-span-2"><x-input-label for="app_role_id" value="Assign Role" /><select name="app_role_id" required class="block mt-1 w-full border-gray-300 rounded-md">@foreach($roles as $role)<option value="{{ $role->id }}" @selected($user->app_role_id == $role->id)>{{ $role->name }}</option>@endforeach</select></div>
    </div>
    <div class="flex items-center justify-end mt-6"><a href="{{ route('admin.app-users.index') }}" class="underline mr-4">Cancel</a><x-primary-button>Update User</x-primary-button></div>
    </form></div></div></div></div>
</x-app-layout>