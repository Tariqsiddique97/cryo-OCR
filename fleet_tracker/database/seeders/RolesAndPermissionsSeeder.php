<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // --- Define Permissions for every action ---
        $permissions = [
            'permission.view', 'permission.create', 'permission.edit', 'permission.delete',
            'role.view', 'role.create', 'role.edit', 'role.delete',
            'user.view', 'user.create', 'user.edit', 'user.delete', // <-- 'user.create' is added
        ];

        // Create Permissions
        foreach ($permissions as $permission) {
            Permission::create(['name' => $permission]);
        }

        // --- Create the main 'Admin' role ---
        $adminRole = Role::create(['name' => 'admin']);
        $adminRole->givePermissionTo(Permission::all());

        // --- Create a less privileged 'Editor' role for demonstration ---
        $editorRole = Role::create(['name' => 'editor']);
        $editorRole->givePermissionTo(['permission.view', 'role.view', 'user.view']);

        // --- Create the primary admin user ---
        $adminUser = User::factory()->create([
            'name' => 'Admin User',
            'username' => 'admin',
            'email' => 'admin@admin.com',
            'password' => Hash::make('password')
        ]);
        $adminUser->assignRole($adminRole);

         // --- Create a demo editor user ---
        $editorUser = User::factory()->create([
            'name' => 'Editor User',
            'username' => 'editor',
            'email' => 'editor@example.com',
            'password' => Hash::make('password')
        ]);
        $editorUser->assignRole($editorRole);
    }
}