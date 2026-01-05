<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Tractor;
use Illuminate\Http\Request;

class TractorController extends Controller
{
    public function index()
    {
        $tractors = Tractor::orderBy('number')->get();
        return view('admin.tractors.index', compact('tractors'));
    }
    public function create()
    {
        return view('admin.tractors.create');
    }
    public function store(Request $request)
    {
        $validated = $request->validate(['number' => 'required|string|unique:tractors,number']);
        Tractor::create($validated);
        return redirect()->route('admin.tractors.index')->with('success', 'Tractor created.');
    }
    public function show(Tractor $tractor)
    {
        return view('admin.tractors.show', compact('tractor'));
    }
    public function edit(Tractor $tractor)
    {
        return view('admin.tractors.edit', compact('tractor'));
    }
    public function update(Request $request, Tractor $tractor)
    {
        $validated = $request->validate(['number' => 'required|string|unique:tractors,number,' . $tractor->id]);
        $tractor->update($validated);
        return redirect()->route('admin.tractors.index')->with('success', 'Tractor updated.');
    }
    public function destroy(Tractor $tractor)
    {
        $tractor->delete();
        return redirect()->route('admin.tractors.index')->with('success', 'Tractor deleted.');
    }
}
