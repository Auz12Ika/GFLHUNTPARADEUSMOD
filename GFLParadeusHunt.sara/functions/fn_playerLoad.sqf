/*
    Author: Gemini / Modder
    File: fn_playerLoad.sqf
    Description: Memuat progres dari profileNamespace ke dalam misi.
*/

if (!hasInterface) exitWith {};

// Muat data Arsenal HQ (SEBELUM data lain, agar fn_initArsenalData tidak menimpa)
MERC_arsenal_weapons = profileNamespace getVariable ["MERC_save_arsenal_weapons", []];
MERC_arsenal_magazines = profileNamespace getVariable ["MERC_save_arsenal_magazines", []];
MERC_arsenal_items = profileNamespace getVariable ["MERC_save_arsenal_items", []];
MERC_arsenal_backpacks = profileNamespace getVariable ["MERC_save_arsenal_backpacks", []];
MERC_arsenal_uniforms = profileNamespace getVariable ["MERC_save_arsenal_uniforms", []];
MERC_arsenal_vests = profileNamespace getVariable ["MERC_save_arsenal_vests", []];
MERC_arsenal_headgear = profileNamespace getVariable ["MERC_save_arsenal_headgear", []];

// Muat semua counter threshold
private _allCounters = profileNamespace getVariable ["MERC_save_counters", []];
{
    _x params ["_var", "_val"];
    missionNamespace setVariable [_var, _val];
} forEach _allCounters;

// Muat data garasi
MERC_garage_data = profileNamespace getVariable ["MERC_save_garage_data", []];
publicVariable "MERC_garage_data";

// Muat posisi HQ
private _hqPos = profileNamespace getVariable ["MERC_save_hq_position", getPos player];
if (markerType "respawn_guerrila" == "") then {
    createMarker ["respawn_guerrila", _hqPos];
} else {
    "respawn_guerrila" setMarkerPos _hqPos;
};
missionNamespace setVariable ["merc_hq_position", _hqPos, true];

// Muat base objects
MERC_base_objects = profileNamespace getVariable ["MERC_save_base_objects", []];
{
    _x params ["_classname", "_pos", "_dir"];
    private _obj = createVehicle [_classname, _pos, [], 0, "NONE"];
    _obj setDir _dir;
} forEach MERC_base_objects;
publicVariable "MERC_base_objects";

// Muat uang & reputasi (data player)
private _money = profileNamespace getVariable ["merc_save_money", 0];
private _repUSA = profileNamespace getVariable ["merc_save_repUSA", 0];
private _repRUS = profileNamespace getVariable ["merc_save_repRUS", 0];
private _repCULT = profileNamespace getVariable ["merc_save_repCULT", 0];
private _repMERC = profileNamespace getVariable ["merc_save_repMERC", 0];
private _repCIV = profileNamespace getVariable ["merc_save_repCIV", 0];

missionNamespace setVariable ["merc_money", _money, true];
missionNamespace setVariable ["rep_USA", _repUSA, true];
missionNamespace setVariable ["rep_RUSSIA", _repRUS, true];
missionNamespace setVariable ["rep_CULT", _repCULT, true];
missionNamespace setVariable ["rep_MERC", _repMERC, true];
missionNamespace setVariable ["rep_CIV", _repCIV, true];

diag_log format ["[LOAD] Data loaded. Money:%1 USA:%2 RUS:%3 Arsenal weapons:%4 Garage:%5",
    _money, _repUSA, _repRUS, count MERC_arsenal_weapons, count MERC_garage_data];