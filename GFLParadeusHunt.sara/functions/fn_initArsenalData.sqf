/*
    File: fn_initArsenalData.sqf
    Description: Muat data arsenal dari data\arsenalHQ.sqf HANYA jika new game.
*/

if (!isServer) exitWith {};

// Jika data arsenal sudah ada (dari load game), jangan timpa.
if (!isNil "MERC_arsenal_weapons" && {count MERC_arsenal_weapons > 0}) exitWith {
    diag_log "[ARSENAL] Data already loaded from save. Skipping init.";
};

// Muat data dasar (GFL2 + vanilla + SMA)
call compile preprocessFileLineNumbers "data\arsenalHQ.sqf";

publicVariable "MERC_arsenal_weapons";
publicVariable "MERC_arsenal_magazines";
publicVariable "MERC_arsenal_items";
publicVariable "MERC_arsenal_backpacks";
publicVariable "MERC_arsenal_uniforms";
publicVariable "MERC_arsenal_vests";
publicVariable "MERC_arsenal_headgear";

diag_log format ["[ARSENAL] Initialized with %1 weapons, %2 uniforms, %3 vests, %4 headgear, %5 backpacks, %6 items",
    count MERC_arsenal_weapons,
    count MERC_arsenal_uniforms,
    count MERC_arsenal_vests,
    count MERC_arsenal_headgear,
    count MERC_arsenal_backpacks,
    count MERC_arsenal_items
];