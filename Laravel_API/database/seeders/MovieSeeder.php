<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Movie;

class MovieSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Movie::create([
            'title' => 'The Last Horizon',
            'synopsis' => 'A group of explorers travels beyond the known world in search of a new home.',
            'year' => 2024,
            'cover' => 'the_last_horizon.jpg',
        ]);

        Movie::create([
            'title' => 'Midnight Echo',
            'synopsis' => 'A journalist investigates a mysterious signal that only appears after midnight.',
            'year' => 2021,
            'cover' => 'midnight_echo.jpg',
        ]);

        Movie::create([
            'title' => 'Broken Stars',
            'synopsis' => 'Two childhood friends reunite after years apart and uncover an old family secret.',
            'year' => 2019,
            'cover' => 'broken_stars.jpg',
        ]);

        Movie::create([
            'title' => 'City of Rain',
            'synopsis' => 'A detective follows a series of strange events during the longest storm in the city.',
            'year' => 2020,
            'cover' => 'city_of_rain.jpg',
        ]);

        Movie::create([
            'title' => 'Silent Forest',
            'synopsis' => 'A group of hikers discovers an abandoned village hidden deep inside a forest.',
            'year' => 2018,
            'cover' => 'silent_forest.jpg',
        ]);

        Movie::create([
            'title' => 'Neon Dreams',
            'synopsis' => 'A young musician tries to achieve success in a futuristic city full of secrets.',
            'year' => 2023,
            'cover' => 'neon_dreams.jpg',
        ]);

        Movie::create([
            'title' => 'The Forgotten Room',
            'synopsis' => 'A woman moves into an old house and discovers a room that does not appear on the plans.',
            'year' => 2017,
            'cover' => 'forgotten_room.jpg',
        ]);

        Movie::create([
            'title' => 'Ocean Beyond',
            'synopsis' => 'A marine scientist begins an expedition to investigate an unexplored part of the ocean.',
            'year' => 2022,
            'cover' => 'ocean_beyond.jpg',
        ]);

        Movie::create([
            'title' => 'Paper Wings',
            'synopsis' => 'A student dreams of becoming a pilot while facing challenges in her small hometown.',
            'year' => 2016,
            'cover' => 'paper_wings.jpg',
        ]);

        Movie::create([
            'title' => 'Last Train Home',
            'synopsis' => 'Several strangers meet on the final train of the night and discover their lives are connected.',
            'year' => 2025,
            'cover' => 'last_train_home.jpg',
        ]);
    }
}