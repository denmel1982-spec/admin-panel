# 🚀 Laravel 11 Admin Panel with JWT & FilamentPHP

Полное руководство по развёртыванию production-ready админ-панели.

## 📋 Обзор архитектуры

### Выбранный стек:
- **Backend**: Laravel 11 (PHP 8.2+)
- **Database**: PostgreSQL 15
- **API Authentication**: JWT (tymon/jwt-auth)
- **Admin UI**: **FilamentPHP v3** (выбран как лучший вариант)

### Почему FilamentPHP?

| Критерий | FilamentPHP | Laravel Nova | Backpack |
|----------|-------------|--------------|----------|
| Стоимость | Бесплатно (Open Source) | $199/сайт | Бесплатно + платные аддоны |
| Интеграция с Laravel 11 | Нативная | Требует лицензии | Хорошая |
| Кастомизация | Полная через Blade/Twig | Ограничена | Хорошая |
| Сообщество | Активное, растёт | Официальное Laravel | Большое |
| TALL Stack | Да (Tailwind, Alpine, Laravel, Livewire) | Нет | Нет |

**FilamentPHP** использует Laravel Livewire для server-side rendering, что идеально сочетается с нашей архитектурой:
- Админка работает через session-based auth (web guard)
- API использует JWT auth (api guard)
- Чёткое разделение ответственности

## 🏗️ Архитектура приложения

```
┌─────────────────────────────────────────────────────────────┐
│                      Nginx (Port 8080)                       │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
    ┌─────────────────┐            ┌─────────────────┐
    │   Web Routes    │            │   API Routes    │
    │  (Session Auth) │            │   (JWT Auth)    │
    │                 │            │                 │
    │  /admin/*       │            │  /api/auth/*    │
    │  FilamentPHP    │            │  /api/users/*   │
    └────────┬────────┘            └────────┬────────┘
             │                               │
             ▼                               ▼
    ┌─────────────────┐            ┌─────────────────┐
    │   web Guard     │            │   api Guard     │
    │   (session)     │            │   (jwt)         │
    └────────┬────────┘            └────────┬────────┘
             │                               │
             └───────────────┬───────────────┘
                             ▼
                   ┌─────────────────┐
                   │   PostgreSQL    │
                   │   (users table) │
                   └─────────────────┘
```

## 📦 Шаг 1: Установка зависимостей

```bash
# Создаём проект Laravel 11
composer create-project laravel/laravel:^11.0 admin-panel
cd admin-panel

# Устанавливаем JWT пакет
composer require tymon/jwt-auth

# Устанавливаем FilamentPHP v3
composer require filament/filament:"^3.2" -W

# Публикуем конфиги
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret

# Создаём админа Filament
php artisan make:filament-user
```

## 🔧 Шаг 2: Конфигурация базы данных (.env)

```env
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=admin_panel
DB_USERNAME=admin
DB_PASSWORD=secret

JWT_SECRET=your_generated_secret_here
JWT_TTL=60
JWT_REFRESH_TTL=20160
JWT_BLACKLIST_ENABLED=true
JWT_BLACKLIST_GRACE_PERIOD=0
```

## 📝 Шаг 3: Миграции

### Создание миграции пользователей

```bash
php artisan make:migration create_users_table
```

Файл: `database/migrations/2024_01_01_000000_create_users_table.php`

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            
            // ENUM для ролей (PostgreSQL specific)
            $table->enum('role', ['user', 'admin'])->default('user');
            
            $table->rememberToken();
            $table->softDeletes(); // Soft deletes
            $table->timestamps();
            
            // Индексы для оптимизации поиска
            $table->index('email');
            $table->index('role');
            $table->index(['deleted_at', 'role']);
        });

        // Создаём ENUM тип в PostgreSQL
        DB::statement("CREATE TYPE user_role AS ENUM ('user', 'admin')");
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
        DB::statement("DROP TYPE IF EXISTS user_role");
    }
};
```

### Таблица для JWT blacklist

```bash
php artisan make:migration create_jwt_blacklist_table
```

Файл: `database/migrations/2024_01_01_000001_create_jwt_blacklist_table.php`

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('jwt_blacklist', function (Blueprint $table): void {
            $table->id();
            $table->string('token')->unique();
            $table->timestamp('expires_at');
            $table->timestamps();
            
            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jwt_blacklist');
    }
};
```

### Таблица для сессий (для Filament)

```bash
php artisan session:table
```

## 🔐 Шаг 4: Модель User

Файл: `app/Models/User.php`

```php
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
```

## 🎯 Шаг 5: Конфигурация аутентификации

Файл: `config/auth.php`

```php
<?php

declare(strict_types=1);

return [

    /*
    |--------------------------------------------------------------------------
    | Authentication Defaults
    |--------------------------------------------------------------------------
    */

    'defaults' => [
        'guard' => 'web',
        'passwords' => 'users',
    ],

    /*
    |--------------------------------------------------------------------------
    | Authentication Guards
    |--------------------------------------------------------------------------
    */

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'jwt',
            'provider' => 'users',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | User Providers
    |--------------------------------------------------------------------------
    */

    'providers' => [
        'users' => [
            'driver' => 'eloquent',
            'model' => App\Models\User::class,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Resetting Passwords
    |--------------------------------------------------------------------------
    */

    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table' => 'password_reset_tokens',
            'expire' => 60,
            'throttle' => 60,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Password Confirmation Timeout
    |--------------------------------------------------------------------------
    */

    'password_timeout' => 10800,

];
```

Файл: `config/jwt.php` (после публикации)

```php
<?php

declare(strict_types=1);

return [

    /*
    |--------------------------------------------------------------------------
    | JWT Secret
    |--------------------------------------------------------------------------
    */

    'secret' => env('JWT_SECRET'),

    /*
    |--------------------------------------------------------------------------
    | JWT Keys
    |--------------------------------------------------------------------------
    */

    'keys' => [
        'public' => env('JWT_PUBLIC_KEY'),
        'private' => env('JWT_PRIVATE_KEY'),
        'passphrase' => env('JWT_PASSPHRASE'),
    ],

    /*
    |--------------------------------------------------------------------------
    | JWT Time To Live
    |--------------------------------------------------------------------------
    */

    'ttl' => env('JWT_TTL', 60), // минут

    /*
    |--------------------------------------------------------------------------
    | Refresh Token Time To Live
    |--------------------------------------------------------------------------
    */

    'refresh_ttl' => env('JWT_REFRESH_TTL', 20160), // минут (14 дней)

    /*
    |--------------------------------------------------------------------------
    | JWT Blacklist
    |--------------------------------------------------------------------------
    */

    'blacklist_enabled' => env('JWT_BLACKLIST_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Blacklist Grace Period
    |--------------------------------------------------------------------------
    */

    'blacklist_grace_period' => env('JWT_BLACKLIST_GRACE_PERIOD', 0),

    /*
    |--------------------------------------------------------------------------
    | Required Claims
    |--------------------------------------------------------------------------
    */

    'required_claims' => [
        'iss',
        'iat',
        'exp',
        'nbf',
        'sub',
        'jti',
    ],

    /*
    |--------------------------------------------------------------------------
    | Persistent Claims
    |--------------------------------------------------------------------------
    */

    'persistent_claims' => [
        'role',
        'email',
    ],

    /*
    |--------------------------------------------------------------------------
    | Lock Subject
    |--------------------------------------------------------------------------
    */

    'lock_subject' => true,

    /*
    |--------------------------------------------------------------------------
    | Leeway
    |--------------------------------------------------------------------------
    */

    'leeway' => env('JWT_LEEWAY', 0),

    /*
    |--------------------------------------------------------------------------
    | Show Token in Response
    |--------------------------------------------------------------------------
    */

    'show' => true,

];
```

## 🛣️ Шаг 6: Маршруты

Файл: `routes/api.php`

```php
<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::prefix('auth')->group(function (): void {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('register', [AuthController::class, 'register']);
});

// Protected routes
Route::middleware('jwt.auth')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('refresh', [AuthController::class, 'refresh']);
        Route::get('me', [AuthController::class, 'me']);
    });

    // Admin only routes
    Route::middleware('role:admin')->group(function (): void {
        Route::apiResource('users', UserController::class);
    });
});
```

Файл: `routes/web.php`

```php
<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Filament routes are auto-registered at /admin
```

## 🎭 Шаг 7: Middleware

### Role Middleware

```bash
php artisan make:middleware RoleMiddleware
```

Файл: `app/Http/Middleware/RoleMiddleware.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string $role): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        if ($user->role !== $role) {
            return response()->json([
                'success' => false,
                'message' => 'Insufficient permissions',
            ], 403);
        }

        return $next($request);
    }
}
```

Регистрация middleware в `bootstrap/app.php`:

```php
<?php

use App\Http\Middleware\RoleMiddleware;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => RoleMiddleware::class,
        ]);
        
        $middleware->statefulApi();
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
```

## 🎮 Шаг 8: Контроллеры API

### AuthController

```bash
php artisan make:controller Api/AuthController
```

Файл: `app/Http/Controllers/Api/AuthController.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
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
```

### UserController

```bash
php artisan make:controller Api/UserController --resource
```

Файл: `app/Http/Controllers/Api/UserController.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreUserRequest;
use App\Http\Requests\Api\UpdateUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class UserController extends Controller
{
    /**
     * Список пользователей.
     */
    public function index(): AnonymousResourceCollection
    {
        $users = User::query()
            ->withTrashed()
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return UserResource::collection($users);
    }

    /**
     * Создать пользователя.
     */
    public function store(StoreUserRequest $request): JsonResponse
    {
        $user = User::create($request->validated());

        return response()->json([
            'success' => true,
            'data' => new UserResource($user),
        ], 201);
    }

    /**
     * Показать пользователя.
     */
    public function show(User $user): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => new UserResource($user),
        ]);
    }

    /**
     * Обновить пользователя.
     */
    public function update(UpdateUserRequest $request, User $user): JsonResponse
    {
        $user->update($request->validated());

        return response()->json([
            'success' => true,
            'data' => new UserResource($user),
        ]);
    }

    /**
     * Удалить пользователя (мягкое удаление).
     */
    public function destroy(User $user): JsonResponse
    {
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully',
        ]);
    }

    /**
     * Восстановить удалённого пользователя.
     */
    public function restore(int $id): JsonResponse
    {
        $user = User::withTrashed()->findOrFail($id);
        $user->restore();

        return response()->json([
            'success' => true,
            'message' => 'User restored successfully',
            'data' => new UserResource($user),
        ]);
    }

    /**
     * Полностью удалить пользователя.
     */
    public function forceDelete(int $id): JsonResponse
    {
        $user = User::withTrashed()->findOrFail($id);
        $user->forceDelete();

        return response()->json([
            'success' => true,
            'message' => 'User permanently deleted',
        ]);
    }
}
```

## 📝 Шаг 9: Form Requests

```bash
php artisan make:request Api/LoginRequest
php artisan make:request Api/RegisterRequest
php artisan make:request Api/StoreUserRequest
php artisan make:request Api/UpdateUserRequest
```

Файл: `app/Http/Requests/Api/LoginRequest.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:255'],
            'password' => ['required', 'string', 'min:8'],
        ];
    }
}
```

Файл: `app/Http/Requests/Api/RegisterRequest.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ];
    }
}
```

Файл: `app/Http/Requests/Api/StoreUserRequest.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth('api')->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'confirmed', Password::defaults()],
            'role' => ['sometimes', 'in:user,admin'],
        ];
    }
}
```

Файл: `app/Http/Requests/Api/UpdateUserRequest.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth('api')->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'string', 'email', 'max:255', Rule::unique('users')->ignore($this->route('user'))],
            'password' => ['sometimes', 'confirmed', Password::defaults()],
            'role' => ['sometimes', 'in:user,admin'],
        ];
    }
}
```

## 🎁 Шаг 10: API Resources

```bash
php artisan make:resource UserResource
```

Файл: `app/Http/Resources/UserResource.php`

```php
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
            'email_verified_at' => $this->email_verified_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'deleted_at' => $this->deleted_at?->toIso8601String(),
        ];
    }
}
```

## 🎨 Шаг 11: FilamentPHP Ресурсы

```bash
php artisan make:filament-resource User --generate
```

Файл: `app/Filament/Resources/UserResource.php`

```php
<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('User Information')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),

                        Forms\Components\TextInput::make('email')
                            ->email()
                            ->required()
                            ->maxLength(255)
                            ->unique(ignoreRecord: true),

                        Forms\Components\Select::make('role')
                            ->options([
                                'user' => 'User',
                                'admin' => 'Admin',
                            ])
                            ->required()
                            ->default('user'),

                        Forms\Components\TextInput::make('password')
                            ->password()
                            ->required(fn (string $context): bool => $context === 'create')
                            ->dehydrateStateUsing(fn (?string $state): ?string => 
                                filled($state) ? bcrypt($state) : null
                            )
                            ->dehydrated(fn (?string $state): bool => filled($state))
                            ->maxLength(255),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->sortable(),

                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\BadgeColumn::make('role')
                    ->colors([
                        'warning' => 'user',
                        'success' => 'admin',
                    ])
                    ->sortable(),

                Tables\Columns\TextColumn::make('email_verified_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('deleted_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->options([
                        'user' => 'User',
                        'admin' => 'Admin',
                    ]),

                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
                Tables\Actions\ForceDeleteAction::make(),
                Tables\Actions\RestoreAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\ForceDeleteBulkAction::make(),
                    Tables\Actions\RestoreBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->withoutGlobalScopes([
                SoftDeletingScope::class,
            ]);
    }
}
```

Страницы Filament будут созданы автоматически в `app/Filament/Resources/UserResource/Pages/`

## 🌱 Шаг 12: Seeders

```bash
php artisan make:seeder AdminUserSeeder
```

Файл: `database/seeders/AdminUserSeeder.php`

```php
<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Admin User',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'email_verified_at' => now(),
            ]
        );

        User::firstOrCreate(
            ['email' => 'user@example.com'],
            [
                'name' => 'Regular User',
                'password' => Hash::make('user123'),
                'role' => 'user',
                'email_verified_at' => now(),
            ]
        );
    }
}
```

Файл: `database/seeders/DatabaseSeeder.php`

```php
<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            AdminUserSeeder::class,
        ]);
    }
}
```

## 🔒 Шаг 13: Policies

```bash
php artisan make:policy UserPolicy --model=User
```

Файл: `app/Policies/UserPolicy.php`

```php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\Response;

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
```

Регистрация Policy в `app/Providers/AppServiceProvider.php`:

```php
<?php

namespace App\Providers;

use App\Models\User;
use App\Policies\UserPolicy;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    protected array $policies = [
        User::class => UserPolicy::class,
    ];

    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        //
    }
}
```

## ⚙️ Шаг 14: CORS Configuration

Файл: `config/cors.php`

```php
<?php

declare(strict_types=1);

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost:8080')),

    'allowed_origins_patterns' => [],

    'allowed_headers' => explode(',', env('CORS_ALLOWED_HEADERS', '*')),

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
```

## 📊 Шаг 15: Rate Limiting

Файл: `app/Providers/AppServiceProvider.php` (дополнение)

```php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

public function boot(): void
{
    RateLimiter::for('api', function (Request $request) {
        return Limit::perMinute((int) env('RATE_LIMIT_API', 60))
            ->by($request->user()?->id ?: $request->ip());
    });
}
```

В `bootstrap/app.php` добавить:

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->alias([
        'role' => RoleMiddleware::class,
    ]);
    
    $middleware->statefulApi();
    
    $middleware->throttleApi('api');
})
```

## 🧪 Шаг 16: Тестирование API

Создайте файл `tests/API.md` с примерами запросов:

```markdown
# API Testing Examples

## 1. Регистрация пользователя

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

Ответ:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

## 2. Логин

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## 3. Получить данные текущего пользователя

```bash
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 4. Обновить токен

```bash
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 5. Logout

```bash
curl -X POST http://localhost:8080/api/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 6. CRUD Users (только для админов)

### Список пользователей
```bash
curl -X GET http://localhost:8080/api/users \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### Создать пользователя
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New User",
    "email": "new@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "user"
  }'
```

### Обновить пользователя
```bash
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "role": "admin"
  }'
```

### Удалить пользователя
```bash
curl -X DELETE http://localhost:8080/api/users/1 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### Восстановить пользователя
```bash
curl -X POST http://localhost:8080/api/users/1/restore \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### Полностью удалить
```bash
curl -X DELETE http://localhost:8080/api/users/1/force-delete \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```
```

## 🚀 Развёртывание

### Команды для развёртывания:

```bash
# 1. Сборка контейнеров
docker-compose build

# 2. Запуск сервисов
docker-compose up -d

# 3. Вход в PHP контейнер
docker-compose exec php bash

# 4. Установка зависимостей Composer
composer install

# 5. Генерация ключа приложения
php artisan key:generate

# 6. Публикация конфигов
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret

# 7. Миграции БД
php artisan migrate

# 8. Сидеры
php artisan db:seed

# 9. Создание админа Filament
php artisan make:filament-user

# 10. Оптимизация для продакшена
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## 🔐 Безопасность

### Checklist:

1. ✅ JWT токены с TTL 60 минут
2. ✅ Refresh tokens с TTL 14 дней
3. ✅ Blacklist для инвалидированных токенов
4. ✅ Rate limiting (60 запросов/минуту)
5. ✅ CORS настройка для конкретных доменов
6. ✅ Хеширование паролей (bcrypt, 12 rounds)
7. ✅ Защита от Mass Assignment ($fillable)
8. ✅ Form Request валидация
9. ✅ Policies для авторизации
10. ✅ Soft Deletes для восстановления
11. ✅ HTTPS в продакшене (настроить в Nginx)
12. ✅ Secure cookies для сессий
13. ✅ CSRF защита для web routes

### Рекомендации для продакшена:

```env
APP_DEBUG=false
APP_ENV=production

# JWT
JWT_TTL=30
JWT_REFRESH_TTL=10080

# Rate Limiting
RATE_LIMIT_API=30

# Session
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax
```

## 📁 Структура проекта

```
admin-panel/
├── app/
│   ├── Console/
│   ├── Exceptions/
│   ├── Filament/
│   │   └── Resources/
│   │       └── UserResource.php
│   │       └── UserResource/Pages/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Api/
│   │   │   │   ├── AuthController.php
│   │   │   │   └── UserController.php
│   │   │   └── Controller.php
│   │   ├── Middleware/
│   │   │   └── RoleMiddleware.php
│   │   ├── Requests/
│   │   │   └── Api/
│   │   │       ├── LoginRequest.php
│   │   │       ├── RegisterRequest.php
│   │   │       ├── StoreUserRequest.php
│   │   │       └── UpdateUserRequest.php
│   │   └── Resources/
│   │       └── UserResource.php
│   ├── Models/
│   │   └── User.php
│   ├── Policies/
│   │   └── UserPolicy.php
│   └── Providers/
│       └── AppServiceProvider.php
├── bootstrap/
│   └── app.php
├── config/
│   ├── auth.php
│   ├── cors.php
│   └── jwt.php
├── database/
│   ├── migrations/
│   │   ├── 2024_01_01_000000_create_users_table.php
│   │   ├── 2024_01_01_000001_create_jwt_blacklist_table.php
│   │   └── 2024_01_01_000002_create_sessions_table.php
│   └── seeders/
│       ├── AdminUserSeeder.php
│       └── DatabaseSeeder.php
├── routes/
│   ├── api.php
│   └── web.php
├── .env.example
├── docker-compose.yml
├── Dockerfile
├── Dockerfile.nginx
└── nginx.conf
```

## 🎯 Итог

Вы получили полностью рабочую админ-панель с:

- ✅ JWT аутентификацией для API
- ✅ FilamentPHP админкой для управления пользователями
- ✅ Разделением guards (web для админки, api для JWT)
- ✅ Ролевой моделью (user/admin)
- ✅ Мягким удалением
- ✅ Валидацией через Form Requests
- ✅ Policies для авторизации
- ✅ Docker конфигурацией
- ✅ Production-ready настройками безопасности

Админка доступна по `/admin`, API по `/api/*`.
