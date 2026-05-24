/*
    Author: Modder
    File: data\factions.sqf
    Description: Database Classname untuk semua faksi Sahrani.
    🔧 FINAL v3: Data-driven. Semua spawner membaca dari sini.
                 Validasi mod RHS, TacGirls, Exo.
                 Fallback vanilla untuk setiap pool.
                 Pool kendaraan terpusat (MERC_vehicles_*).
*/

// =====================================================
// VALIDASI MOD DEPENDENCY
// =====================================================
private _hasRHS = isClass (configFile >> "CfgVehicles" >> "rhsusf_army_ocp_rifleman");
private _hasTacGirls = isClass (configFile >> "CfgVehicles" >> "tacgirls_paradeus_strelet");
private _hasExo = isClass (configFile >> "CfgVehicles" >> "Exo_Unit_Standard");

diag_log format ["MERC VALIDASI MOD: RHS=%1 | TacGirls=%2 | Exo=%3", _hasRHS, _hasTacGirls, _hasExo];


// =====================================================
// USA: RHSUSAF (Air Power) — TANPA TANK BERAT
// =====================================================
MERC_factions_USA = if (_hasRHS) then {
    [
        "rhsusf_army_ocp_rifleman",
        "rhsusf_army_ocp_grenadier",
        "rhsusf_army_ocp_maaf",
        "rhsusf_army_ocp_aa",
        "rhsusf_army_ocp_medic",
        "rhsusf_army_ocp_machinegunner",
        "rhsusf_army_ocp_javelin"
    ]
} else {
    ["B_Soldier_F", "B_Soldier_GL_F", "B_Soldier_LAT_F", "B_Soldier_AA_F", "B_Medic_F", "B_Soldier_AR_F", "B_Soldier_AT_F"]
};

MERC_vehicles_USA = if (_hasRHS) then {
    [
        "rhsusf_m1151_m2_v2_wd",         // Humvee HMG
        "rhsusf_m1025_w_m2",             // Humvee M2
        "rhsusf_m1126_mk19_wd",          // Stryker MK19
        "RHS_UH60M_d",                   // Blackhawk (Transport)
        "RHS_MELB_AH6M",                 // Little Bird (Attack)
        "RHS_AH64D_wd"                   // Apache (Attack Heavy, MAIN_BASE)
    ]
} else {
    ["B_MRAP_01_hmg_F", "B_MRAP_01_F", "B_MRAP_01_gmg_F", "B_Heli_Transport_01_F", "B_Heli_Light_01_armed_F", "B_Heli_Attack_01_F"]
};


// =====================================================
// RUSSIA: RHSAFRF (Tank Power) — Tank MBT + AA + Heli Ka-52
// =====================================================
MERC_factions_RUS = if (_hasRHS) then {
    [
        "rhs_msv_emr_rifleman",
        "rhs_msv_emr_rpg7",
        "rhs_msv_emr_aa",
        "rhs_msv_emr_machinegunner",
        "rhs_msv_emr_medic",
        "rhs_msv_emr_at",
        "rhs_msv_emr_grenadier"
    ]
} else {
    ["O_Soldier_F", "O_Soldier_LAT_F", "O_Soldier_AA_F", "O_Soldier_AR_F", "O_Medic_F", "O_Soldier_AT_F", "O_Soldier_GL_F"]
};

MERC_vehicles_RUS = if (_hasRHS) then {
    [
        "rhs_tigr_sts_3camo",             // Tigr (Ringan)
        "rhs_uaz_open_MSV_01",            // UAZ (Ringan)
        "rhs_btr80a_msv",                 // BTR-80A (APC)
        "rhs_t72ba_tv",                   // T-72B (MBT)
        "rhs_t90a_tv",                    // T-90A (MBT, MAIN_BASE)
        "rhs_t80uk",                      // T-80UK (MBT, MAIN_BASE)
        "rhs_mi8mt_vvs"                   // Mi-8 (Transport)
    ]
} else {
    ["O_MRAP_02_F", "O_MRAP_02_hmg_F", "O_APC_Wheeled_02_rcws_F", "O_MBT_02_cannon_F", "O_MBT_02_cannon_F", "O_MBT_02_cannon_F", "O_Heli_Light_02_unarmed_F"]
};


// =====================================================
// CULT: Paradeus + EXO
// =====================================================
MERC_factions_CULT = [];
if (_hasTacGirls) then {
    MERC_factions_CULT append [
        "tacgirls_paradeus_strelet",
        "tacgirls_paradeus_strelet_at",
        "tacgirls_paradeus_rodelero",
        "tacgirls_paradeus_doppel",       // Elite Cult
        "tacgirls_paradeus_bellator137",  // BOSS
        "tacgirls_paradeus_niter",        // BOSS
        "tacgirls_paradeus_goliath_elite" // BOSS HQ
    ];
};
if (_hasExo) then {
    MERC_factions_CULT append [
        "Exo_Unit_Standard",
        "Exo_Unit_Heavy",
        "Exo_Unit_AT"
    ];
};
if (count MERC_factions_CULT == 0) then {
    MERC_factions_CULT = ["I_Soldier_F", "I_Soldier_LAT_F", "I_Soldier_AR_F", "I_Soldier_AA_F", "I_Medic_F", "I_Soldier_AT_F", "I_Soldier_GL_F"];
};

MERC_vehicles_CULT = [
    "RHS_Ural_Open_Civ_01",
    "RHS_Ural_Civ_03",
    "rhs_uaz_open_MSV_01",
    "C_Offroad_01_F",
    "C_Van_01_transport_F"
];
if (!_hasRHS) then {
    MERC_vehicles_CULT = ["C_Offroad_01_F", "C_Van_01_transport_F", "C_Truck_02_transport_F", "C_SUV_01_F", "C_Hatchback_01_F"];
};


// =====================================================
// MERC (Hostile/Neutral): Sangvis + Mange
// =====================================================
MERC_factions_MERC = if (_hasTacGirls) then {
    [
        "tacgirls_sangvis_jaeger",
        "tacgirls_sangvis_striker",
        "tacgirls_sangvis_vespid",
        "tacgirls_sangvis_ripper",
        "tacgirls_mange_unit_1",
        "tacgirls_mange_unit_2",
        "tacgirls_mange_specialist"
    ]
} else {
    ["I_Soldier_F", "I_Soldier_LAT_F", "I_Soldier_AR_F", "I_Soldier_AA_F", "I_Medic_F", "I_Soldier_AT_F", "I_Soldier_GL_F"]
};

MERC_vehicles_MERC = if (_hasRHS) then {
    [
        "rhs_btr80_msv",
        "rhsusaf_m1126_mk19_wd",
        "rhsusaf_m1151_withrep_usarmy_wd",
        "I_C_Offroad_02_LMG_F",
        "RHS_Ural_Open_MSV_01"            // Truk Supply
    ]
} else {
    ["I_MRAP_03_hmg_F", "I_MRAP_03_gmg_F", "I_MRAP_03_F", "I_C_Offroad_02_LMG_F", "I_Truck_02_transport_F"]
};


// =====================================================
// HIRE (Player Allies): Elmo, Sangvis, Mange
// =====================================================
MERC_factions_HIRE_POOL = if (_hasTacGirls) then {
    [
        "tacgirls_elmo_rifleman",
        "tacgirls_elmo_medic",
        "tacgirls_elmo_specialist",
        "tacgirls_sangvis_jaeger",
        "tacgirls_mange_unit_1"
    ]
} else {
    ["B_Soldier_F", "B_Medic_F", "B_Soldier_GL_F", "I_Soldier_F", "B_Soldier_LAT_F"]
};


// =====================================================
// CIVILIAN
// =====================================================
MERC_factions_CIV = [
    "C_man_1", "C_man_p_beggar_F", "C_man_p_fugitive_F",
    "C_man_hunter_1_F", "C_man_shorts_1_F", "C_man_utility_shorts_F",
    "C_man_w_worker_F"
];

MERC_vehicles_CIV = [
    "C_Offroad_01_F", "C_SUV_01_F", "C_Hatchback_01_F", 
    "C_Van_01_transport_F", "C_Truck_02_transport_F"
];


// =====================================================
// LOG
// =====================================================
diag_log format ["MERC SYSTEM: Factions Data Loaded. RHS=%1 | TacGirls=%2 | Exo=%3", _hasRHS, _hasTacGirls, _hasExo];
diag_log format ["MERC SYSTEM: USA=%1/%2 | RUS=%3/%4 | CULT=%5/%6 | MERC=%7/%8 | HIRE=%9", 
    count MERC_factions_USA, count MERC_vehicles_USA,
    count MERC_factions_RUS, count MERC_vehicles_RUS,
    count MERC_factions_CULT, count MERC_vehicles_CULT,
    count MERC_factions_MERC, count MERC_vehicles_MERC,
    count MERC_factions_HIRE_POOL];