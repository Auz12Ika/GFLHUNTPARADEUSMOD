/*
    Author: Modder
    File: data\factions.sqf
    Description: Database Classname untuk semua faksi Sahrani.
    🔧 FORCED VERSION: Menghilangkan proteksi IF agar MOD pasti terbaca 100%.
*/

// =====================================================
// USA: RHSUSAF (Air Power) — TANPA TANK BERAT
// =====================================================
MERC_factions_USA = [
    "rhsusf_army_ocp_rifleman",
    "rhsusf_army_ocp_grenadier",
    "rhsusf_army_ocp_maaf",
    "rhsusf_army_ocp_aa",
    "rhsusf_army_ocp_medic",
    "rhsusf_army_ocp_machinegunner",
    "rhsusf_army_ocp_javelin"
];

MERC_vehicles_USA = [
    "rhsusf_m1151_m2_v2_wd",         // Humvee HMG
    "rhsusf_m1025_w_m2",             // Humvee M2
    "rhsusf_m1126_mk19_wd",          // Stryker MK19
    "RHS_UH60M_d",                   // Blackhawk (Transport)
    "RHS_MELB_AH6M",                 // Little Bird (Attack)
    "RHS_AH64D_wd",                  // Apache (Attack Heavy, MAIN_BASE)
    "RHS_A10"    					 // A-10 Warthog (CAS)
];

MERC_vehicles_USAblackfisharmed = ["B_T_VTOL_01_armed_F"];


// =====================================================
// RUSSIA: RHSAFRF (Tank Power) — Tank MBT + AA + Heli Ka-52
// =====================================================
MERC_factions_RUS = [
    "rhs_msv_emr_rifleman",
    "rhs_msv_emr_rpg7",
    "rhs_msv_emr_aa",
    "rhs_msv_emr_machinegunner",
    "rhs_msv_emr_medic",
    "rhs_msv_emr_at",
    "rhs_msv_emr_grenadier"
];

MERC_vehicles_RUS = [
    "rhs_tigr_sts_3camo",             // Tigr (Ringan)
    "rhs_uaz_open_MSV_01",            // UAZ (Ringan)
    "rhs_btr80a_msv",                 // BTR-80A (APC)
    "O_APC_Tracked_02_AA_F",                   // T-72B (MBT)
    "rhs_t90a_tv",                    // T-90A (MBT, MAIN_BASE)
    "rhs_t80uk",                      // T-80UK (MBT, MAIN_BASE)
    "O_T_VTOL_02_infantry_dynamicLoadout_F",                
    "RHS_Ka52_vvsc"                   // Ka-52 Alligator (Attack Heli)
];
// =====================================================
// CULT: Paradeus + EXO
// =====================================================
MERC_factions_CULTBOSS = [
	"Sextans_boss",  
    "Niter_boss"      // BOSS
];

MERC_factions_CULT = [
    "GFL_Unitas_015",
    "GFL_Unitas_039",
    "GFL_Custos_036",
    "CYT_V_Exo_Soldier_Suit_01",
	"GFL_Bellator137"
];

MERC_vehicles_CULT = [
	"O_T_MBT_02_railgun_ghex_F",
	"Osiris",
	"CUP_B_M1128_MGS_Desert"
];


// =====================================================
// MERC (Hostile/Neutral): Sangvis + Mange
// =====================================================
MERC_factions_SF = ["SF_Ripper", "SF_Vespid", "SF_Jaeger"];
MERC_vehicles_SF = ["CUP_I_LR_SF_HMG_AAF"];

MERC_factions_Mangi = ["GFL_Mangi_Strike_Captain", "GFL_Mangi_Blaster", "GFL_Mangi_Spotter", "GFL_Mangi_Mechanist"];
MERC_vehicles_Mangi = ["CUP_I_BTR80A_ION"];

MERC_factions_Vanjager = ["Felade_F", "Felamedisin_F", "Urokrake_F"];
MERC_vehicles_Vanjager = ["CUP_B_M1A2C_LDF"];


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

diag_log "MERC SYSTEM: Factions Data FORCED and Loaded Perfectly.";