/*
    File: fn_HQ_ArsenalHQ.sqf
    Description: Script Membuka BIS Arsenal
*/
systemChat "Membuka Arsenal...";

if (!hasInterface) exitWith {};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "Kotak Arsenal tidak ditemukan!"; };

// Buka Vanilla BIS Arsenal (dengan parameter FALSE agar hanya menampilkan senjata Unlimited kita)
["Open", [false, _hq]] call BIS_fnc_arsenal;