<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    /**
     * Определить, может ли пользователь просматривать список.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Определить, может ли пользователь просматривать запись.
     */
    public function view(User $user, User $model): bool
    {
        return $user->isAdmin() || $user->id === $model->id;
    }

    /**
     * Определить, может ли пользователь создавать записи.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Определить, может ли пользователь обновлять запись.
     */
    public function update(User $user, User $model): bool
    {
        return $user->isAdmin() || $user->id === $model->id;
    }

    /**
     * Определить, может ли пользователь удалять запись.
     */
    public function delete(User $user, User $model): bool
    {
        return $user->isAdmin() && $user->id !== $model->id;
    }

    /**
     * Определить, может ли пользователь восстанавливать запись.
     */
    public function restore(User $user, User $model): bool
    {
        return $user->isAdmin();
    }

    /**
     * Определить, может ли пользователь навсегда удалять запись.
     */
    public function forceDelete(User $user, User $model): bool
    {
        return $user->isAdmin();
    }
}
