/*
    File: fn_hireMercenary.sqf
    Description: Rekrut personel dari pool MERC_factions_HIRE_POOL dengan biaya.
*/

if (!hasInterface) exitWith {};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "HQ tidak ditemukan."; };

private _pool = missionNamespace getVariable ["MERC_factions_HIRE_POOL", []];
if (count _pool == 0) then {
    _pool = ["B_Soldier_F"]; // fallback
};

// Biaya rekrut
private _cost = 500;

// Cek uang pemain
private _money = player getVariable ["merc_money", 0];
if (_money < _cost) exitWith {
    hint format ["Uang tidak cukup! Butuh $%1. Uang kamu: $%2.", _cost, _money];
};

// Konfirmasi (pakai hint sebagai pengganti dialog)
private _unitClass = selectRandom _pool;
private _displayName = getText (configFile >> "CfgVehicles" >> _unitClass >> "displayName");

// Potong uang
player setVariable ["merc_money", _money - _cost, true];

// Spawn unit
private _spawnPos = _hq getRelPos [5, random 360];
private _unit = (group player) createUnit [_unitClass, _spawnPos, [], 0, "NONE"];
[_unit] joinSilent (group player);

hint format ["%1 telah direkrut. Sisa uang: $%2.", _displayName, _money - _cost];
systemChat format ["HIRE: %1 bergabung dengan squad.", _displayName];