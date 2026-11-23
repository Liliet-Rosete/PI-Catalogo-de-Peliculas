<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
Route::middleware('auth:sanctum')->group(function () {
Route::get('/movies', function () {
    return \App\Models\Movie::all();
});
Route::get('/movies/{id}', function ($id) {
    return \App\Models\Movie::find($id);
});
Route::post('/movies', function (Request $request) {
    return \App\Models\Movie::create([
        'title' => $request->title,
        'synopsis' => $request->synopsis,
        'year' => $request->year,
            'director' => $request->director,
            'genre' => $request->genre,
        'cover' => $request->cover,
    ]);
});
Route::put('/movies/{id}', function (Request $request, $id) {
    $movie = \App\Models\Movie::find($id);

    $movie->update([
        'title' => $request->title,
        'synopsis' => $request->synopsis,
        'year' => $request->year,
            'director' => $request->director,
            'genre' => $request->genre,
        'cover' => $request->cover,
    ]);

    return $movie;
});
Route::delete('/movies/{id}', function ($id) {
    $movie = \App\Models\Movie::find($id);

    $movie->delete();

    return response()->json([
        'message' => 'Movie deleted successfully'
    ]);
});
});

Route::post('/register', [\App\Http\Controllers\Api\AuthController::class, 'register']);
Route::post('/login', [\App\Http\Controllers\Api\AuthController::class, 'login']);
Route::middleware('auth:sanctum')->post('/logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);
