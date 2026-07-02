/*
    File: fn_spawnMainFaction.sqf
    Description: Spawner Utama untuk faksi RU, US, dan CIV berdasarkan tiang bendera di Eden Editor.
*/

params [
    ["_spawnTarget", objNull, [objNull]],
    ["_factionType", "RU", [""]]
];

if (isNull _spawnTarget) exitWith {};
private _pos = getPosATL _spawnTarget;
private _side = east; private _pool = [];

switch (_factionType) do {
    case "RU": { _side = east; _pool = missionNamespace getVariable ["TAG_RU_InfantryPool", ["O_Soldier_F", "O_Soldier_AR_F", "O_Soldier_GL_F"]]; };
    case "US": { _side = west; _pool = missionNamespace getVariable ["TAG_US_InfantryPool", ["B_Soldier_F", "B_Soldier_AR_F", "B_Soldier_GL_F"]]; };
    case "CIV": { _side = civilian; _pool = missionNamespace getVariable ["TAG_CIV_InfantryPool", ["C_man_1", "C_man_polo_2_F", "C_man_shorts_2_F"]]; };
};

if (count _pool == 0) exitWith {};

private _groupSize = 4 + (round (random 2));
private _squadUnits = [];
for "_i" from 1 to _groupSize do { _squadUnits pushBack (selectRandom _pool); };

private _grp = [_pos, _side, _squadUnits] call BIS_fnc_spawnGroup;

if (!isNull _grp) then {
    if (!isNil "TAG_fnc_randomizeKroco") then { { [_x] call TAG_fnc_randomizeKroco; } forEach (units _grp); };
    [_grp, _pos] call BIS_fnc_taskDefend;

    // 🔥 RULE 3a.3: Deteksi Kematian - Mayat Despawn Otomatis Setelah 4 Menit (240 Detik)
    {
        _x addEventHandler ["Killed", {
            params ["_unit"];
            _unit spawn {
                sleep 240; // Tunggu 4 menit tepat
                deleteVehicle _this; // Lenyapkan dari map
            };
        }];
    } forEach (units _grp);

    // Daftarkan grup ini ke dalam database tiang bendera kota pengurusnya
    private _currentGroups = _spawnTarget getVariable ["TAG_townGroups", []];
    _currentGroups pushBack _grp;
    _spawnTarget setVariable ["TAG_townGroups", _currentGroups, true];
};