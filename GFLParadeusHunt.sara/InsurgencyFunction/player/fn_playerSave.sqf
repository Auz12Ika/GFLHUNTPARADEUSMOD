/*
    Author: Gemini / Modder
    File: fn_playerSave.sqf
    Description: Menyimpan data ke profileNamespace berdasarkan nomor slot & membatasi pangkalan radius 100m dari HQ.
*/
if (!hasInterface) exitWith {};

params [["_slot", 1]]; // Menerima nomor slot dari addAction, default jika kosong = 1

// 1. Ambil Variabel Ekonomi & Reputasi Saat Ini
private _money = missionNamespace getVariable ["merc_money", 0];
private _repUSA = missionNamespace getVariable ["rep_USA", 0];
private _repRUS = missionNamespace getVariable ["rep_RUSSIA", 0];
private _repCULT = missionNamespace getVariable ["rep_CULT", 0];
private _repMERC = missionNamespace getVariable ["rep_MERC", 0];
private _repCIV = missionNamespace getVariable ["rep_CIV", 0];

// 2. Filter & Ambil Data Koordinat Bangunan Pangkalan (Radius 100m dari HQ)
private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
private _savedObjectsData = []; // Wadah penampung data koordinat ter-enkripsi
private _baseObjects = missionNamespace getVariable ["MERC_base_objects", []];

if (!isNull _hq) then {
    // Simpan Posisi & Arah Hadap Mobil HQ fisik ke slot terpilih
    profileNamespace setVariable [format ["MERC_save_hq_position_slot_%1", _slot], getPosATL _hq];
    profileNamespace setVariable [format ["MERC_save_hq_direction_slot_%1", _slot], getDir _hq];
    
    // Scan seluruh objek pangkalan yang hidup di dalam misi saat ini
    {
        if (!isNull _x && {alive _x}) then {
            // CRITICAL CHECK: Hanya simpan jika jarak struktur ke HQ kurang dari atau sama dengan 100 Meter
            if ((_x distance _hq) <= 100) then {
                // Konversi objek fisik menjadi tipe data array [Classname, Posisi, Arah] agar aman saat di-load
                _savedObjectsData pushBack [typeOf _x, getPosATL _x, getDir _x];
            };
        };
    } forEach _baseObjects;
};

// Kunci data pangkalan hasil filter radius ke dalam profil slot terkait
profileNamespace setVariable [format ["MERC_save_base_objects_slot_%1", _slot], _savedObjectsData];

// 3. Simpan Variabel Utama ke Profil Slot Terpilih
profileNamespace setVariable [format ["merc_save_money_slot_%1", _slot], _money];
profileNamespace setVariable [format ["merc_save_repUSA_slot_%1", _slot], _repUSA];
profileNamespace setVariable [format ["merc_save_repRUS_slot_%1", _slot], _repRUS];
profileNamespace setVariable [format ["merc_save_repCULT_slot_%1", _slot], _repCULT];
profileNamespace setVariable [format ["merc_save_repMERC_slot_%1", _slot], _repMERC];
profileNamespace setVariable [format ["merc_save_repCIV_slot_%1", _slot], _repCIV];

// 4. Simpan Stok Virtual Arsenal HQ Ke Slot Terpilih
profileNamespace setVariable [format ["MERC_save_arsenal_weapons_slot_%1", _slot], MERC_arsenal_weapons];
profileNamespace setVariable [format ["MERC_save_arsenal_magazines_slot_%1", _slot], MERC_arsenal_magazines];
profileNamespace setVariable [format ["MERC_save_arsenal_items_slot_%1", _slot], MERC_arsenal_items];
profileNamespace setVariable [format ["MERC_save_arsenal_backpacks_slot_%1", _slot], MERC_arsenal_backpacks];
profileNamespace setVariable [format ["MERC_save_arsenal_uniforms_slot_%1", _slot], MERC_arsenal_uniforms];
profileNamespace setVariable [format ["MERC_save_arsenal_vests_slot_%1", _slot], MERC_arsenal_vests];
profileNamespace setVariable [format ["MERC_save_arsenal_headgear_slot_%1", _slot], MERC_arsenal_headgear];

// Simpan data counter misi/quest progress
private _allCounters = [];
{
    if (_x select [0,13] == "MERC_counter_") then {
        _allCounters pushBack [_x, missionNamespace getVariable [_x, 0]];
    };
} forEach (allVariables missionNamespace);
profileNamespace setVariable [format ["MERC_save_counters_slot_%1", _slot], _allCounters];

// Tandai nomor slot ini sebagai aktivitas penyimpanan terakhir
profileNamespace setVariable ["MERC_last_used_slot", _slot];

// 5. Perintahkan sistem operasi Arma untuk langsung menulis data ke harddisk
saveProfileNamespace;

[format ["PROGRESS SAVED\nSeluruh data pangkalan radius 100m, uang, dan arsenal berhasil dikunci pada SLOT %1.", _slot], "BERHASIL"] spawn BIS_fnc_guiMessage;