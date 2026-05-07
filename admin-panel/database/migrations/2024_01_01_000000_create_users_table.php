<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            
            // ENUM для ролей
            $table->enum('role', ['user', 'admin'])->default('user');
            
            $table->rememberToken();
            $table->softDeletes();
            $table->timestamps();
            
            // Индексы для оптимизации поиска
            $table->index('email');
            $table->index('role');
            $table->index(['deleted_at', 'role']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
