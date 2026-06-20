/*
    Author: Gemini / Modder
    File: fn_playerLoad.sqf
    Description: Memuat progres dari profileNamespace berdasarkan nomor slot secara aman.
*/
if (!hasInterface) exitWith {};

params [["_slot", 1]]; // Menerima nomor slot dari addAction, default jika kosong = 1

// 1. SISTEM ANTI-DUPLIKASI: Hapus paksa semua bangunan fisik pangkalan yang saat ini berdiri di map
private _oldObjects = missionNamespace getVariable ["MERC_base_objects", []];
{
    if (!isNull _x) then { deleteVehicle _x; };
} forEach _oldObjects;
missionNamespace setVariable ["MERC_base_objects", [], true];

// 2. Muat Variabel Database Gudang Senjata / Virtual Arsenal HQ
MERC_arsenal_weapons = profileNamespace getVariable [format ["MERC_save_arsenal_weapons_slot_%1", _slot], []];
MERC_arsenal_magazines = profileNamespace getVariable [format ["MERC_save_arsenal_magazines_slot_%1", _slot], []];
MERC_arsenal_items = profileNamespace getVariable [format ["MERC_save_arsenal_items_slot_%1", _slot], []];
MERC_arsenal_backpacks = profileNamespace getVariable [format ["MERC_save_arsenal_backpacks_slot_%1", _slot], []];
MERC_arsenal_uniforms = profileNamespace getVariable [format ["MERC_save_arsenal_uniforms_slot_%1", _slot], []];
MERC_arsenal_vests = profileNamespace getVariable [format ["MERC_save_arsenal_vests_slot_%1", _slot], []];
MERC_arsenal_headgear = profileNamespace getVariable [format ["MERC_save_arsenal_headgear_slot_%1", _slot], []];

// Muat data counter quest progress
private _allCounters = profileNamespace getVariable [format ["MERC_save_counters_slot_%1", _slot], []];
{
    _x params ["_var", "_val"];
    missionNamespace setVariable [_var, _val];
} forEach _allCounters;

// 3. Muat Koordinat Posisi Terakhir Kendaraan Mobil HQ
private _hqVeh = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (!isNull _hqVeh) then {
    private _defaultPos = getPosATL _hqVeh;
    private _hqPos = profileNamespace getVariable [format ["MERC_save_hq_position_slot_%1", _slot], _defaultPos];
    private _hqDir = profileNamespace getVariable [format ["MERC_save_hq_direction_slot_%1", _slot], 0];
    
    _hqVeh setDir _hqDir;
    _hqVeh setPosATL _hqPos;
    
    // Geser marker respawn global ke posisi HQ yang baru di-load
    if (markerType "respawn_guerrila" == "") then {
        createMarker ["respawn_guerrila", _hqPos];
    } else {
        "respawn_guerrila" setMarkerPos _hqPos;
    };
    missionNamespace setVariable ["merc_hq_position", _hqPos, true];
};

// 4. SPAWN ULANG SELURUH BANGUNAN PANGKALAN DARI DATA SLOT
private _savedObjectsData = profileNamespace getVariable [format ["MERC_save_base_objects_slot_%1", _slot], []];
private _newObjectsArray = [];

{
    _x params ["_classname", "_pos", "_dir"];
    // Bangun kembali struktur fisik di koordinat aslinya secara global
    private _obj = createVehicle [_classname, _pos, [], 0, "CAN_COLLIDE"];
    _obj setDir _dir;
    _obj setPosATL _pos;
    _newObjectsArray pushBack _obj;
} forEach _savedObjectsData;

// Masukkan kembali objek-objek baru ke database pangkalan aktif misi
missionNamespace setVariable ["MERC_base_objects", _newObjectsArray, true];

// 5. Muat Uang & Reputasi Factions
private _money = profileNamespace getVariable [format ["merc_save_money_slot_%1", _slot], 5000]; // Default awal game $5.000 jika slot kosong
private _repUSA = profileNamespace getVariable [format ["merc_save_repUSA_slot_%1", _slot], 0];
private _repRUS = profileNamespace getVariable [format ["merc_save_repRUS_slot_%1", _slot], 0];
private _repCULT = profileNamespace getVariable [format ["merc_save_repCULT_slot_%1", _slot], 0];
private _repMERC = profileNamespace getVariable [format ["merc_save_repMERC_slot_%1", _slot], 0];
private _repCIV = profileNamespace getVariable [format ["merc_save_repCIV_slot_%1", _slot], 0];

missionNamespace setVariable ["merc_money", _money, true];
missionNamespace setVariable ["rep_USA", _repUSA, true];
missionNamespace setVariable ["rep_RUSSIA", _repRUS, true];
missionNamespace setVariable ["rep_CULT", _repCULT, true];
missionNamespace setVariable ["rep_MERC", _repMERC, true];
missionNamespace setVariable ["rep_CIV", _repCIV, true];

hint format ["PROGRESS LOADED!\nSlot Aktif: Slot %1\nSaldo Kontrak Anda: $%2\nSeluruh struktur pangkalan berhasil didirikan kembali.", _slot, _money];