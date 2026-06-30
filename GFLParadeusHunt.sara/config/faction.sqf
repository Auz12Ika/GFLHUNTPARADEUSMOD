/*
Nama : faction.sqf
    ====================================================
    MERC FACTION CONFIGURATION (merc_factions)
    ====================================================
    Setiap faksi memiliki 7 elemen array utama:
    0: Faction ID (STRING)         - "USA", "RUSSIA", dll.
    1: Arma Side (SIDE)           - west, east, dll.
    2: Reputation Thresholds (ARRAY of 4 SCALARS)
       [ally, neutral, hostile, reconHunt]
    3: Hostile Factions (ARRAY of STRINGs) - Faksi musuh
    4: Territory Behavior (ARRAY)
       [radius (SCALAR), protectTerritory (BOOL)]
    5: Recon System (ARRAY)
       [useReconHunt (BOOL), squadSize (SCALAR), canUseVehicle (BOOL)]
    6: Special Behavior (ARRAY)
       Format: [Behavior1 (BOOL/SCALAR), Behavior2 (BOOL/SCALAR)]
       Penggunaan berbeda per faksi, lihat catatan di bawah.
    ====================================================
*/

merc_factions = [

    // ====================================================
    // USA — Air Power, Tanah Ringan (No Heavy Tank)
    // ====================================================
    [
        "USA",                         // 0: Faction ID
        west,                          // 1: Arma Side

        // 2: Reputation Thresholds
        [70, 0, -40, -100],            // ally, neutral, hostile, reconHunt

        // 3: Hostile Factions
        ["RUSSIA", "CULT"],

        // 4: Territory Behavior
        [1580, true],                  // radius 2.5km², protektif

        // 5: Recon System
        [true, 10, true],              // recon hunt ON, 10 orang, bisa pakai kendaraan

        // 6: Special Behavior
        // [NightAggressionReduce (BOOL), AggroMultiplier (SCALAR)]
        [true, 0.5]                    // Agresi berkurang 50% di malam hari
    ],

    // ====================================================
    // RUSSIA — Tank Superpower, Heli Ka-52
    // ====================================================
    [
        "RUSSIA",
        east,

        [70, 0, -40, -100],

        ["USA", "CULT"],

        [1580, true],

        [true, 10, true],

        // [NightAggressionReduce (BOOL), AggroMultiplier (SCALAR)]
        [true, 0.5]
    ],

    // ====================================================
    // CULT — Paradeus, Bunuh Diri, Infiltrasi
    // ====================================================
    [
        "CULT",
        independent,

        // Reputasi tidak digunakan untuk Cult
        [0, 0, 0, 0],

        // Hostile ke SEMUA faksi
        ["USA", "RUSSIA", "MERC", "CIV"],

        // Territory: lebih kecil, tidak protektif (lebih suka menyebar)
        [800, false],

        // Recon: tidak digunakan (digantikan infiltrasi)
        [false, 0, false],

        // Special Behavior:
        // [Disguise (BOOL), SuicideAttack (BOOL)]
        [true, true]                   // Bisa menyamar dan menyerang bunuh diri
    ],

    // ====================================================
    // MERC — Sangvis/Mange, Netral/Bisa Disewa
    // ====================================================
    [
        "MERC",
        resistance,

        [0, 0, 0, 0],

        [],                            // Tidak ada musuh permanen

        [500, false],

        [false, 0, false],

        // Special Behavior:
        // [NeutralPossible (BOOL), Hireable (BOOL), MissionHostile (BOOL)]
        [true, true, true]             // Bisa netral, bisa disewa, misi hostile
    ],

    // ====================================================
    // CIV — Warga Sipil
    // ====================================================
    [
        "CIV",
        civilian,

        [0, 0, 0, 0],

        [],

        [300, false],

        [false, 0, false],

        // Special Behavior: tidak ada
        [false, false]
    ]

];