<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
            'email_verified_at' => $this->whenNotNull($this->email_verified_at?->toIso8601String()),
            'created_at' => $this->whenNotNull($this->created_at?->toIso8601String()),
            'updated_at' => $this->whenNotNull($this->updated_at?->toIso8601String()),
            'deleted_at' => $this->whenNotNull($this->deleted_at?->toIso8601String()),
        ];
    }
}
