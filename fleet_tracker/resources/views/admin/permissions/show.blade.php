<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Permission Details') }}</h2>
    </x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <dl class="divide-y divide-gray-200">
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Name</dt><dd class="sm:col-span-2">{{ $permission->name }}</dd></div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4"><dt class="font-medium text-gray-500">Created</dt><dd class="sm:col-span-2">{{ $permission->created_at->format('M d, Y') }}</dd></div>
                    </dl>
                    <div class="flex items-center justify-end mt-6 border-t pt-6">
                        <a href="{{ route('admin.permissions.index') }}" class="underline text-gray-600">&larr; Back to Permissions</a>
                        @can('permission.edit')
                        <a href="{{ route('admin.permissions.edit', $permission->id) }}" class="ml-4 inline-flex items-center px-4 py-2 bg-gray-800 rounded-md font-semibold text-xs text-white uppercase hover:bg-gray-700">Edit</a>
                        @endcan
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>