<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\AppRole;
use App\Models\AppUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
class AppUserController extends Controller
{
    public function index() { $users = AppUser::with('appRole')->orderBy('name')->get(); return view('admin.app-users.index', compact('users')); }
    public function create() { $roles = AppRole::orderBy('name')->get(); return view('admin.app-users.create', compact('roles')); }
    public function store(Request $request) {
        $validated = $request->validate([ 'name' => 'required|string', 'username' => 'required|string|unique:app_users', 'email' => 'required|email|unique:app_users', 'country_code' => 'nullable|string', 'phone_number' => 'nullable|string', 'password' => 'required|string|min:8|confirmed', 'app_role_id' => 'required|exists:app_roles,id']);
        $validated['password'] = Hash::make($validated['password']);
        AppUser::create($validated);
        return redirect()->route('admin.app-users.index')->with('success', 'User created.');
    }
    public function show(AppUser $appUser) { $appUser->load('appRole'); return view('admin.app-users.show', ['user' => $appUser]); }
    public function edit(AppUser $appUser) { $roles = AppRole::orderBy('name')->get(); return view('admin.app-users.edit', ['user' => $appUser, 'roles' => $roles]); }
    public function update(Request $request, AppUser $appUser) {
        $validated = $request->validate([ 'name' => 'required|string', 'username' => 'required|string|unique:app_users,username,'.$appUser->id, 'email' => 'required|email|unique:app_users,email,'.$appUser->id, 'country_code' => 'nullable|string', 'phone_number' => 'nullable|string', 'password' => 'nullable|string|min:8|confirmed', 'app_role_id' => 'required|exists:app_roles,id']);
        if ($request->filled('password')) { $validated['password'] = Hash::make($validated['password']); } else { unset($validated['password']); }
        $appUser->update($validated);
        return redirect()->route('admin.app-users.index')->with('success', 'User updated.');
    }
    public function destroy(AppUser $appUser) { $appUser->delete(); return redirect()->route('admin.app-users.index')->with('success', 'User deleted.'); }
}