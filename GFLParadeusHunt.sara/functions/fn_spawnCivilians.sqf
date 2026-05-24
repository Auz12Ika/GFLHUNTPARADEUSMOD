/*
    Author: Gemini
    File: fn_spawnCivilians.sqf
    Description: Menghidupkan kota dengan pejalan kaki dan kendaraan sipil.
*/
params [["_pos", [0,0,0]]];

if (!isServer) exitWith {};

// 1. Spawn Pejalan Kaki (3 - 6 orang per kota)
private _civCount = 3 + (round random 3);
private _grp = createGroup civilian;

for "_i" from 1 to _civCount do {
    private _uClass = selectRandom MERC_factions_CIV;
    private _uPos = [_pos, 5, 100, 2, 0, 0.5, 0] call BIS_fnc_findSafePos;
    
    private _unit = _grp createUnit [_uClass, _uPos, [], 0, "NONE"];
    _unit setBehaviour "SAFE";
    [_grp, _pos, 150] call BIS_fnc_taskPatrol; // Mereka akan jalan santai di kota
};

// 2. Spawn Kendaraan Parkir / Melintas
if (random 100 > 40) then {
    private _vClass = selectRandom MERC_vehicles_CIV;
    private _vPos = [_pos, 5, 100, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
    private _veh = createVehicle [_vClass, _vPos, [], 0, "NONE"];
    _veh setDir (random 360);
};