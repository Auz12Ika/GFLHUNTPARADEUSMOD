/*
    Name: TAG_fnc_setupFactions
    Description: Menginisialisasi seluruh variabel data faksi dan pool item untuk Sahrani Sandbox.
*/
if (!isServer) exitWith {};

// ============================================================================
// 1. DATA POOL ITEM ACAK UNTUK KROCO MERC (CUP, RHS, VANILLA MIKSED)
// ============================================================================
TAG_pool_vests = [
    "V_PlateCarrier1_rgr", "V_Chestrig_khk", "V_TacVest_blk",
    "rhs_6b23_6sh116", "rhs_6b45_rifleman", "rhsusf_iotv_ocp_Rifleman",
    "CUP_V_B_BAF_DDPM_Osprey_Mk3_Rifleman", "CUP_V_I_GUE_ArmoredVest_01"
];

TAG_pool_weapons = [
    // [Classname Senjata, Classname Magazine]
    ["arifle_MX_F", "30Rnd_65x39_caseless_mag"],
    ["rhs_weap_ak74m", "rhs_30Rnd_545x39_7N10_AK"],
    ["rhs_weap_m4a1_carryhandle", "rhs_mag_30Rnd_556x45_M855A1_Stanag"],
    ["CUP_arifle_AK74M", "CUP_30Rnd_545x39_AK74_plum_M"],
    ["CUP_arifle_M4A1_black", "CUP_30Rnd_556x45_Stanag"],
    ["CUP_arifle_FNFAL", "CUP_20Rnd_762x51_FNFAL_M"]
];

// ============================================================================
// 2. DATA FACTION MAJOR (US & RU)
// ============================================================================
TAG_US_Infanteri = [
    "rhsusf_socom_marsoc_teamleader", "rhsusf_socom_marsoc_operator", 
    "rhsusf_socom_marsoc_grenadier", "rhsusf_socom_marsoc_marksman", 
    "rhsusf_socom_marsoc_medic", "rhsusf_socom_marsoc_breacher",
    "B_soldier_LAT_F", "B_soldier_AT_F", "B_soldier_AA_F"
];
TAG_US_Vehicles   = ["CUP_B_nM1151_ogpk_m2_USA_DES"];
TAG_US_Armor      = ["CUP_B_M6LineBacker_USA_D"];
TAG_US_Air_Attack = ["CUP_B_AH64_DL_USA", "CUP_B_A10_DYN_USA", "B_T_VTOL_01_armed_F"];
TAG_US_Air_Helis  = ["CUP_B_AH6M_USA", "CUP_B_MH6M_USA", "CUP_B_UH60M_USMC", "CUP_B_CH47F_USA"];

TAG_RU_Infanteri = [
    "rhs_msv_emr_sergeant", "rhs_msv_emr_junior_sergeant", "rhs_msv_emr_efreitor", 
    "rhs_msv_emr_rifleman", "rhs_msv_emr_grenadier", "rhs_msv_emr_machinegunner", 
    "rhs_msv_emr_marksman", "rhs_msv_emr_medic", "rhs_msv_emr_at", "rhs_msv_emr_aa"
];
TAG_RU_Vehicles   = ["CUP_O_BTR80A_CSAT", "CUP_O_BMP_HQ_CSAT"];
TAG_RU_Armor      = ["CUP_O_T90MS_CSAT", "O_APC_Tracked_02_AA_F"];
TAG_RU_Air_Attack = ["CUP_O_Ka52_RU"];

// ============================================================================
// 3. DATA MERCENARIES FACTIONS (INDEPENDENT SIDE)
// ============================================================================
TAG_Sangvis_Infanteri  = ["classname_SF_Guard", "classname_SF_Jaeger", "classname_SF_Ripper", "classname_SF_Vespid"];
TAG_Sangvis_Vehicles   = ["CUP_B_nM1151_ogpk_m2_USA_DES", "O_APC_Tracked_02_AA_F"];

TAG_Mangi_Infanteri    = ["classname_Mangi_Blaster", "classname_Mangi_Mechanist", "classname_Mangi_Spotter", "classname_Mangi_Strike_Captain"];
TAG_Mangi_Vehicles     = ["CUP_O_BTR80A_CSAT", "CUP_O_BMP_HQ_CSAT"];

TAG_Vanjager_Infanteri = ["classname_Unitas_015", "classname_Unitas_089", "classname_Exo_Soldier_Suit", "classname_Miler"];
TAG_Vanjager_Armor     = ["CUP_O_T90MS_CSAT"];

TAG_Cult_Infanteri     = ["classname_Ballator_187", "classname_Gustav_08E"]; // Ditambah unit sisa Paradeus
TAG_Cult_Vehicles      = ["C_Offroad_01_armed_F"];
TAG_Cult_HQ_Count      = 1; 

publicVariable "TAG_pool_vests";
publicVariable "TAG_pool_weapons";
diag_log "SERVER LOG: Faction Setup successfully initialized.";