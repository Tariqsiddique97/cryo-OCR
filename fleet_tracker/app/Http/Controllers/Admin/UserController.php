<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class UserController extends Controller
{
    // ... index() method ...
    public function index()
    {
        $users = User::with('roles')->orderBy('name')->get();
        return view('admin.users.index', compact('users'));
    }


    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $roles = Role::orderBy('name')->get();
        return view('admin.users.create', compact('roles'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users,username',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'roles' => 'sometimes|array'
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'username' => $validated['username'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $user->syncRoles($request->roles ?? []);

        return redirect()->route('admin.users.index')->with('success', 'User created successfully.');
    }

    // ... show(), edit(), update(), destroy() methods ...
    public function show(User $user)
    {
        $user->load('roles.permissions');
        return view('admin.users.show', compact('user'));
    }

    public function edit(User $user)
    {
        $roles = Role::orderBy('name')->get();
        $userRoles = $user->roles->pluck('name')->toArray();
        return view('admin.users.edit', compact('user', 'roles', 'userRoles'));
    }

    public function update(Request $request, User $user)
    {
        $request->validate(['roles' => 'sometimes|array']);
        if ($user->id === auth()->id() && !in_array('admin', $request->roles ?? [])) {
            return back()->with('error', 'You cannot remove your own admin role.');
        }
        $user->syncRoles($request->roles ?? []);
        return redirect()->route('admin.users.index')->with('success', 'User roles updated successfully.');
    }

    public function destroy(User $user)
    {
        if ($user->id === auth()->id() || $user->hasRole('admin')) {
            return back()->with('error', 'You cannot delete this user.');
        }
        $user->delete();
        return back()->with('success', 'User deleted successfully.');
    }
}