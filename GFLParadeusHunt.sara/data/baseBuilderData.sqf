/*
    File: data\baseBuilderData.sqf
    Description: Data objek Base Builder dan biayanya.
*/

MERC_baseBuilder_categories = [
    "Bunker",
    "Tower",
    "Base Building",
    "H-Wall",
    "Sandbags",
    "Turret",
    "Mortar"
];

MERC_baseBuilder_objects = [
    // Bunker
    [
        ["Land_BagBunker_Small_F", "Small Bunker", 500],
        ["Land_BagBunker_Tower_F", "Bunker Tower", 700],
        ["Land_PillboxBunker_01_hex_F", "Pillbox Bunker", 800],
        ["Land_Bunker_01_small_F", "Small Bunker (Concrete)", 1000]
    ],
    // Tower
    [
        ["Land_Tower_01_F", "Watchtower", 800],
        ["Land_GuardTower_01_F", "Guard Tower", 1000],
        ["Land_Cargo_Patrol_V1_F", "Patrol Tower", 1200]
    ],
    // Base Building
    [
        ["Land_Cargo_HQ_V1_F", "Cargo HQ", 1500],
        ["Land_Medevac_house_V1_F", "Medical House", 1500],
        ["Land_StoneHouseBig_V1_F", "Stone House", 2000]
    ],
    // H-Wall
    [
        ["Land_HBarrier_01_wall_6_F", "H-Barrier 6m", 200],
        ["Land_HBarrier_01_wall_4_F", "H-Barrier 4m", 150],
        ["Land_HBarrier_01_wall_corner_F", "H-Barrier Corner", 250]
    ],
    // Sandbags
    [
        ["Land_BagFence_Round_F", "Sandbag Round", 100],
        ["Land_BagFence_Long_F", "Sandbag Long", 150],
        ["Land_BagFence_Corner_F", "Sandbag Corner", 120]
    ],
    // Turret
    [
        ["B_GMG_01_high_F", "GMG Turret", 2000],
        ["B_HMG_01_high_F", "HMG Turret", 1800],
        ["B_static_AA_F", "AA Turret", 3000]
    ],
    // Mortar
    [
        ["B_Mortar_01_F", "Mortar", 3000]
    ]
];

if (isNil "MERC_base_objects") then {
    MERC_base_objects = [];
};

diag_log "[BASE BUILDER] Data loaded.";