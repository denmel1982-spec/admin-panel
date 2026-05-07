<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Войти пользователя и выдать токены.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = $request->validated();

        if (!$token = auth('api')->attempt($credentials)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        return $this->respondWithToken($token);
    }

    /**
     * Зарегистрировать нового пользователя.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();
        
        // Всегда создаём с ролью 'user'
        $data['role'] = 'user';
        $data['password'] = Hash::make($data['password']);

        $user = User::create($data);

        $token = auth('api')->login($user);

        return $this->respondWithToken($token, 201);
    }

    /**
     * Выйти из системы (инвалидировать токен).
     */
    public function logout(): JsonResponse
    {
        auth('api')->logout();

        return response()->json([
            'success' => true,
            'message' => 'Successfully logged out',
        ]);
    }

    /**
     * Обновить access токен.
     */
    public function refresh(): JsonResponse
    {
        $token = auth('api')->refresh();

        return $this->respondWithToken($token);
    }

    /**
     * Получить данные текущего пользователя.
     */
    public function me(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => auth('api')->user(),
        ]);
    }

    /**
     * Ответ с токеном.
     */
    protected function respondWithToken(string $token, int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                'access_token' => $token,
                'token_type' => 'bearer',
                'expires_in' => auth('api')->factory()->getTTL() * 60,
                'refresh_token' => auth('api')->refresh(),
            ],
        ], $status);
    }
}
