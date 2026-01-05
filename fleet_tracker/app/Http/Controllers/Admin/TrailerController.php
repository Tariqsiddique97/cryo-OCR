<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trailer;
use Illuminate\Http\Request;

class TrailerController extends Controller
{
    public function index()
    {
        $trailers = Trailer::orderBy('number')->get();
        return view('admin.trailers.index', compact('trailers'));
    }
    public function create()
    {
        return view('admin.trailers.create');
    }
    public function store(Request $request)
    {
        $validated = $request->validate(['number' => 'required|string|unique:trailers,number']);
        Trailer::create($validated);
        return redirect()->route('admin.trailers.index')->with('success', 'Trailer created.');
    }
    public function show(Trailer $trailer)
    {
        return view('admin.trailers.show', compact('trailer'));
    }
    public function edit(Trailer $trailer)
    {
        return view('admin.trailers.edit', compact('trailer'));
    }
    public function update(Request $request, Trailer $trailer)
    {
        $validated = $request->validate(['number' => 'required|string|unique:trailers,number,' . $trailer->id]);
        $trailer->update($validated);
        return redirect()->route('admin.trailers.index')->with('success', 'Trailer updated.');
    }
    public function destroy(Trailer $trailer)
    {
        $trailer->delete();
        return redirect()->route('admin.trailers.index')->with('success', 'Trailer deleted.');
    }
}
