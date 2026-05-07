<?php

declare(strict_types=1);

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements FilamentUser, JWTSubject
{
    use HasFactory, Notifiable, SoftDeletes;

    /**
     * Атрибуты, которые можно массово назначать.
     */
    protected array $fillable = [
        'name',
        'email',
        'password',
        'role',
    ];

    /**
     * Атрибуты, которые должны быть скрыты при сериализации.
     */
    protected array $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Приведение типов атрибутов.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Получить идентификатор для JWT токена.
     */
    public function getJWTIdentifier(): int|string
    {
        return $this->getKey();
    }

    /**
     * Вернуть кастомные claims для JWT.
     */
    public function getJWTCustomClaims(): array
    {
        return [
            'role' => $this->role,
            'email' => $this->email,
        ];
    }

    /**
     * Проверка доступа к Filament панели.
     */
    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'admin' && $this->email_verified_at !== null;
    }

    /**
     * Проверка является ли пользователь админом.
     */
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Проверка является ли пользователем.
     */
    public function isUser(): bool
    {
        return $this->role === 'user';
    }
}
