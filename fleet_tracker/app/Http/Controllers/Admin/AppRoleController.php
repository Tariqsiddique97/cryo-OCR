<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\AppRole;
use Illuminate\Http\Request;
class AppRoleController extends Controller
{
    public function index() { $roles = AppRole::orderBy('name')->get(); return view('admin.app-roles.index', compact('roles')); }
    public function create() { return view('admin.app-roles.create'); }
    public function store(Request $request) { $validated = $request->validate(['name' => 'required|string|unique:app_roles,name']); AppRole::create($validated); return redirect()->route('admin.app-roles.index')->with('success', 'Role created.'); }
    public function show(AppRole $appRole) { $appRole->load('appUsers'); return view('admin.app-roles.show', ['role' => $appRole]); }
    public function edit(AppRole $appRole) { return view('admin.app-roles.edit', ['role' => $appRole]); }
    public function update(Request $request, AppRole $appRole) { $validated = $request->validate(['name' => 'required|string|unique:app_roles,name,' . $appRole->id]); $appRole->update($validated); return redirect()->route('admin.app-roles.index')->with('success', 'Role updated.'); }
    public function destroy(AppRole $appRole) { $appRole->delete(); return redirect()->route('admin.app-roles.index')->with('success', 'Role deleted.'); }
}