/*
    Author: Gemini / Modder
    File: fn_playerSave.sqf
    Description: Menyimpan progres pemain (Uang & Reputasi) ke profileNamespace.
*/

if (!hasInterface) exitWith {}; // Hanya simpan di sisi pemain

// 1. Ambil data saat ini
private _money = missionNamespace getVariable ["merc_money", 0];
private _repUSA = missionNamespace getVariable ["rep_USA", 0];
private _repRUS = missionNamespace getVariable ["rep_RUSSIA", 0];
private _repCULT = missionNamespace getVariable ["rep_CULT", 0];
private _repMERC = missionNamespace getVariable ["rep_MERC", 0];
private _repCIV = missionNamespace getVariable ["rep_CIV", 0];

// Simpan posisi HQ
private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (!isNull _hq) then {
    profileNamespace setVariable ["MERC_save_hq_position", getPos _hq];
};

// Simpan base objects
profileNamespace setVariable ["MERC_save_base_objects", MERC_base_objects];

// 2. Simpan ke profileNamespace (Variabel unik agar tidak bentrok dengan misi lain)
profileNamespace setVariable ["merc_save_money", _money];
profileNamespace setVariable ["merc_save_repUSA", _repUSA];
profileNamespace setVariable ["merc_save_repRUS", _repRUS];
profileNamespace setVariable ["merc_save_repCULT", _repCULT];
profileNamespace setVariable ["merc_save_repMERC", _repMERC];
profileNamespace setVariable ["merc_save_repCIV", _repCIV];

// Simpan data Arsenal HQ
profileNamespace setVariable ["MERC_save_arsenal_weapons", MERC_arsenal_weapons];
profileNamespace setVariable ["MERC_save_arsenal_magazines", MERC_arsenal_magazines];
profileNamespace setVariable ["MERC_save_arsenal_items", MERC_arsenal_items];
profileNamespace setVariable ["MERC_save_arsenal_backpacks", MERC_arsenal_backpacks];
profileNamespace setVariable ["MERC_save_arsenal_uniforms", MERC_arsenal_uniforms];
profileNamespace setVariable ["MERC_save_arsenal_vests", MERC_arsenal_vests];
profileNamespace setVariable ["MERC_save_arsenal_headgear", MERC_arsenal_headgear];

// Save garage data
profileNamespace setVariable ["MERC_save_garage_data", MERC_garage_data];
diag_log "[SAVE] Garage data saved.";

// Simpan semua counter threshold
private _allCounters = [];
{
    if (_x select [0,13] == "MERC_counter_") then {
        _allCounters pushBack [_x, missionNamespace getVariable [_x, 0]];
    };
} forEach (allVariables missionNamespace);
profileNamespace setVariable ["MERC_save_counters", _allCounters];

// 3. Force save ke disk
saveProfileNamespace;

systemChat "PROGRESS SAVED: Data berhasil disimpan ke profil karakter.";