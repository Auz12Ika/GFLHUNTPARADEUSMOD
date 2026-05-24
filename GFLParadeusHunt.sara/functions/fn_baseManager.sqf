/*
    Author: Modder
    File: fn_baseManager.sqf
    Description: Spawn pasukan dalam jumlah besar dengan cooldown 2 jam.
                 🔧 FIX P7: Parameter diubah menjadi posisi, faksi, tipe.
                 Digunakan untuk event dadakan (bala bantuan, serangan Cult, dll.)
                 BUKAN bagian dari sistem spawn utama (sudah ditangani fn_systemController).
*/

params [
    ["_pos", [0,0,0], [[]]],
    ["_factionID", "USA", [""]],
    ["_baseType", "BASE", [""]]
];

if (!isServer) exitWith {};

// 1. CEK COOLDOWN (2 jam = 7200 detik)
private _cooldownVar = format ["MERC_baseCooldown_%1", _factionID];
private _lastSpawn = missionNamespace getVariable [_cooldownVar, -7200];
private _currentTime = serverTime;

if (_currentTime - _lastSpawn < 7200) exitWith {
    diag_log format ["BASE MANAGER: %1 masih cooldown. Sisa %2 detik.", _factionID, 7200 - (_currentTime - _lastSpawn)];
};

// 2. JUMLAH GRUP (2-5)
private _numGroups = 2 + floor random 4;
diag_log format ["BASE MANAGER: Spawning %1 groups for %2 at %3", _numGroups, _factionID, _baseType];

for "_i" from 1 to _numGroups do {
    private _spawnPos = [_pos, 5, 80, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
    private _isPatrol = (_i == 1); // Grup pertama patroli, sisanya jaga
    [_spawnPos, _factionID, _baseType, _isPatrol] call MERC_fnc_spawnGroupUniversal;
};

// 3. SET COOLDOWN
missionNamespace setVariable [_cooldownVar, _currentTime, true];

// 4. MARKER SEMENTARA (30 menit)
private _mName = format ["MERC_base_%1", floor(random 100000)];
private _m = createMarker [_mName, _pos];
_m setMarkerType "loc_ViewPoint";
_m setMarkerColor "ColorRed";
_m setMarkerText format ["%1 REINFORCEMENTS", _factionID];

[_m] spawn {
    params ["_marker"];
    sleep 1800; // 30 menit
    deleteMarker _marker;
};

diag_log format ["BASE MANAGER: %1 groups spawned for %1. Marker %2 created.", _numGroups, _mName];