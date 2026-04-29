<?php

namespace App\Http\Controllers\Platform;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Inertia\Inertia;
use Inertia\Response;

class PlatformProfileController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();
        if (! $user || ! $user->canAccessPlatformPanel()) {
            abort(403);
        }

        return Inertia::render('Platform/Profile/Index', [
            'pageTitle' => 'Minha conta',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    public function updateEmail(Request $request): RedirectResponse
    {
        $user = $request->user();
        if (! $user || ! $user->canAccessPlatformPanel()) {
            abort(403);
        }

        $validated = $request->validate([
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user)],
        ], [
            'email.unique' => 'Este e-mail já está em uso por outra conta.',
        ]);

        if ($user->email !== $validated['email']) {
            $user->email = $validated['email'];
            $user->email_verified_at = null;
            $user->save();
        }

        return redirect()->route('plataforma.account.index')->with('success', 'E-mail atualizado.');
    }

    public function updatePassword(Request $request): RedirectResponse
    {
        $user = $request->user();
        if (! $user || ! $user->canAccessPlatformPanel()) {
            abort(403);
        }

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'confirmed', Password::defaults()],
        ], [
            'current_password.required' => 'Informe a senha atual.',
            'password.required' => 'O campo nova senha é obrigatório.',
            'password.confirmed' => 'A confirmação da senha não confere.',
            'password.min' => 'A senha deve ter no mínimo 8 caracteres.',
        ]);

        if (! Hash::check($validated['current_password'], $user->password)) {
            return redirect()->back()->withErrors(['current_password' => 'A senha atual está incorreta.']);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        return redirect()->route('plataforma.account.index')->with('success', 'Senha alterada.');
    }
}
