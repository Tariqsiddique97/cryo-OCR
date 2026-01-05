<x-app-layout><x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Add New Tractor') }}</h2>
    </x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b">
                    <form method="POST" action="{{ route('admin.tractors.store') }}">@csrf<div><x-input-label
                                for="number" value="Tractor Number" /><x-text-input id="number" name="number"
                                :value="old('number')" class="block mt-1 w-full" type="text" required autofocus /></div>
                        <div class="flex items-center justify-end mt-6"><a href="{{ route('admin.tractors.index') }}"
                                class="underline mr-4">Cancel</a><x-primary-button>Save Tractor</x-primary-button></div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
