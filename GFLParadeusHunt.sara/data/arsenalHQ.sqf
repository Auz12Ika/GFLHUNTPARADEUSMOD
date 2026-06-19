/*
    File: data\arsenalHQ.sqf
    Description: Whitelist item Arsenal HQ (GFL2 + SMA + KA + Vanilla).
*/

// === SENJATA UTAMA (SMA + KA + Vanilla) ===
MERC_arsenal_weapons = [
    // SMA
    "SMA_AUG_A3_CQC_F", "SMA_HK416_F", "SMA_HK416_GL_F", "SMA_HK417_F",
    "SMA_MSAR_E4_F", "SMA_SAR21_F", "SMA_SCAR_F", "SMA_SKS_Bullpup_F",
    // KA Weapons
    "KA_M4A1", "KA_SCAR_H", "KA_AN94", "KA_AN94_MTK83",
    "KA_MRC", "KA_AR15_Training", "KA_HK416", "KA_SKS",
    "KA_AMR2", "KA_M134", "KA_AA12", "KA_XM25",
    "KA_Destroyer",
    // Vanilla
    "arifle_MX_F", "arifle_MX_GL_F", "arifle_Katiba_F", "arifle_Katiba_GL_F",
    "arifle_Mk20_F", "arifle_Mk20_GL_F", "arifle_TRG21_F", "arifle_TRG21_GL_F",
    "arifle_SDAR_F", "arifle_SPAR_01_blk_F", "arifle_SPAR_01_GL_blk_F",
    "LMG_Mk200_F", "LMG_Zafir_F", "srifle_EBR_F", "srifle_DMR_01_F"
];

// === PISTOL ===
MERC_arsenal_weapons append [
    "hgun_P07_F", "hgun_Rook40_F", "hgun_ACPC2_F",
    "hgun_Pistol_heavy_01_F", "hgun_Pistol_heavy_02_F",
    "KA_Glock17", "KA_DesertEagle", "KA_CalicoM950"
];

// === LAUNCHER ===
MERC_arsenal_weapons append [
    "launch_RPG32_F", "launch_NLAW_F", "launch_Titan_short_F"
];

// === MAGASIN & GRANAT ===
MERC_arsenal_magazines = [
    "30Rnd_65x39_caseless_mag", "30Rnd_65x39_caseless_mag_Tracer",
    "100Rnd_65x39_caseless_mag", "100Rnd_65x39_caseless_mag_Tracer",
    "30Rnd_556x45_Stanag", "30Rnd_556x45_Stanag_Tracer_Red",
    "150Rnd_556x45_Drum_Mag_F", "20Rnd_762x51_Mag",
    "200Rnd_65x39_cased_Box", "200Rnd_65x39_cased_Box_Tracer",
    "150Rnd_762x54_Box", "150Rnd_762x54_Box_Tracer",
    "16Rnd_9x21_Mag", "30Rnd_9x21_Mag", "9Rnd_45ACP_Mag",
    "11Rnd_45ACP_Mag", "6Rnd_45ACP_Cylinder",
    "RPG32_F", "RPG32_HE_F", "NLAW_F", "Titan_AT", "Titan_AP",
    "HandGrenade", "MiniGrenade", "1Rnd_HE_Grenade_shell", "3Rnd_HE_Grenade_shell",
    "SmokeShell", "SmokeShellBlue", "SmokeShellRed", "SmokeShellGreen",
    "Chemlight_green", "Chemlight_blue", "Chemlight_red","rhsusf_100Rnd_762x51_m80a1epr"
];

// === ATTACHMENT & ITEM ===
MERC_arsenal_items = [
    "optic_ACO_grn", "optic_Holosight", "optic_Holosight_smg", "optic_MRCO",
    "optic_SOS", "optic_AMS", "optic_NVS", "optic_DMS", "optic_Arco", "optic_ERCO_blk_F",
    "muzzle_snds_H", "muzzle_snds_B", "muzzle_snds_M", "muzzle_snds_L",
    "acc_flashlight", "acc_pointer_IR",
    "bipod_01_F_snd", "bipod_02_F_blk", "bipod_03_F_blk",
    "FirstAidKit", "Medikit", "ToolKit", "MineDetector",
    "Binocular", "Rangefinder",
    "ItemMap", "ItemCompass", "ItemWatch"
];

// === BACKPACK ===
MERC_arsenal_backpacks = [
    "B_AssaultPack_blk", "B_AssaultPack_khk", "B_AssaultPack_mcamo",
    "B_Kitbag_mcamo", "B_Kitbag_sgg",
    "B_Carryall_oli", "B_Carryall_khk",
    "B_FieldPack_oli", "B_FieldPack_khk",
    "B_TacticalPack_blk", "B_TacticalPack_mcamo"
];

// === UNIFORM GFL2 ===
MERC_arsenal_uniforms = [
    "klukai_uniform", "sakura_uniform", "lainiealt_uniform", "balthilde_uniform",
    "cheyanne_uniform", "peritya_uniform", "helen_uniform", "nikketa_uniform",
    "voymastina_uniform", "groza_uniform", "colphne_uniform", "sharkry_uniform",
    "tololo_uniform", "qiongjiu_uniform", "cheeta_uniform", "nagant_uniform",
    "littara_uniform", "ksenia_uniform", "makiatto_uniform", "papasha_uniform",
    "ullrid_uniform", "mosin_uniform", "faye_uniform", "suomi_uniform",
    "zhaohui_uniform", "dushevnaya_uniform", "alva_uniform", "jiangyu_uniform",
    "andoris_uniform", "sabrina_uniform", "springfield_uniform", "harpsy_uniform",
    "nemesis_uniform", "mechty_uniform", "lind_uniform", "soppo_uniform",
    "phaetusa_uniform", "mityl_uniform", "peri_uniform", "vector_uniform",
    "yoohee_uniform", "robella_uniform", "basti_uniform", "commanderfemale_uniform",
    "strikecaptain_uniform", "ump9_uniform", "liushih_uniform", "ak12_uniform"
];

// === VEST GFL2 + Vanilla ===
MERC_arsenal_vests = [
    "KlukaiVest",
    "V_PlateCarrier1_rgr", "V_PlateCarrier2_rgr", "V_Chestrig_khk", "V_TacVest_khk"
];

// === HELM (Vanilla) ===
MERC_arsenal_headgear = [
    "H_HelmetB", "H_HelmetB_light", "H_Booniehat_khk", "H_Cap_blk",
    "H_Watchcap_blk", "H_Beret_Colonel", "H_MilCap_blue"
];

diag_log "DATA: arsenalHQ.sqf loaded.";