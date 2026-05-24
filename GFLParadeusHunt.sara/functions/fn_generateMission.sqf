/*
    Author: Modder
    File: fn_generateMission.sqf
    Description: Generate daftar kontrak berdasarkan reputasi.
    🔧 FIX P9: Threshold reputasi dari merc_factions (fallback -600).
               Deteksi Cult night mission lebih aman.
*/

params [["_player", objNull]];

private _availableContracts = [];
private _hour = daytime;

// --- Baca threshold dari config (fallback -600) ---
private _thresholdMin = -600;
if (!isNil "merc_factions") then {
    {
        if ((_x select 0) == "USA") exitWith {
            _thresholdMin = (_x select 2) select 2; // indeks 2 = hostile threshold
        };
    } forEach merc_factions;
};

// --- USA CONTRACT ---
private _repUSA = missionNamespace getVariable ["rep_USA", 0];
if (_repUSA > _thresholdMin) then {
    {
        if ((_x select 3) == "USA") then {
            _availableContracts pushBack _x;
        };
    } forEach merc_missions;
};

// --- RUSSIA CONTRACT ---
private _repRUS = missionNamespace getVariable ["rep_RUSSIA", 0];
if (_repRUS > _thresholdMin) then {
    {
        if ((_x select 3) == "RUSSIA") then {
            _availableContracts pushBack _x;
        };
    } forEach merc_missions;
};

// --- CIV CONTRACT (selalu tersedia) ---
{
    if ((_x select 3) == "CIV") then {
        _availableContracts pushBack _x;
    };
} forEach merc_missions;

// --- HQ CONTRACT (selalu tersedia) ---
{
    if ((_x select 3) == "HQ") then {
        _availableContracts pushBack _x;
    };
} forEach merc_missions;

// --- CULT NIGHT CONTRACT ---
if (_hour >= 19 || _hour <= 5) then {
    {
        private _enemyFaction = _x select 4;
        // 🔧 FIX: Deteksi lebih aman, baik string maupun array
        private _isCultMission = if (_enemyFaction isEqualType []) then {
            "CULT" in _enemyFaction
        } else {
            _enemyFaction == "CULT"
        };
        
        if (_isCultMission) then {
            _availableContracts pushBack _x;
        };
    } forEach merc_missions;
};

// --- RETURN ---
_availableContracts