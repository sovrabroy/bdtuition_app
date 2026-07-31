<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Guardian;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

/**
 * Guardian authentication for the mobile app (register / login / logout /
 * profile). Mirrors the teacher API: on success returns a Sanctum bearer
 * token plus the guardian record. All NEW — no existing controller touched.
 */
class GuardianAuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'phone'    => 'required|string|max:20|unique:guardians,phone',
            'password' => 'required|string|min:4',
            'email'    => 'nullable|email|max:255',
            'city'     => 'nullable|string|max:255',
            'area'     => 'nullable|string|max:255',
            'address'  => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 422);
        }

        $guardian = Guardian::create([
            'name'     => $request->name,
            'phone'    => $request->phone,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'city'     => $request->city,
            'area'     => $request->area,
            'address'  => $request->address,
        ]);

        $token = $guardian->createToken('guardian-app')->plainTextToken;

        return response()->json([
            'success'  => true,
            'message'  => 'Account created successfully',
            'token'    => $token,
            'guardian' => $this->present($guardian),
        ], 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login'    => 'required|string',   // phone or email
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $guardian = Guardian::where('phone', $request->login)
            ->orWhere('email', $request->login)
            ->first();

        if (! $guardian || ! Hash::check($request->password, $guardian->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid phone/email or password',
            ], 401);
        }

        $token = $guardian->createToken('guardian-app')->plainTextToken;

        return response()->json([
            'success'  => true,
            'message'  => 'Login successful',
            'token'    => $token,
            'guardian' => $this->present($guardian),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out',
        ]);
    }

    public function profile(Request $request)
    {
        return response()->json([
            'success'  => true,
            'guardian' => $this->present($request->user()),
        ]);
    }

    private function present(Guardian $g): array
    {
        return [
            'id'      => $g->id,
            'name'    => $g->name,
            'phone'   => $g->phone,
            'email'   => $g->email,
            'city'    => $g->city,
            'area'    => $g->area,
            'address' => $g->address,
        ];
    }
}
