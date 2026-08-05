/*
    File: fn_spawnMercFaction.sqf
    Description: Sistem Spawner Otomatis Skuad Mercenary dengan Fitur Safe-Delay CBA
*/

params [
    ["_spawnTarget", objNull, [objNull, []]],
    ["_factionSide", east, [east]]
];

[_spawnTarget, _factionSide] spawn {
    params ["_spawnTarget", "_factionSide"];
    waitUntil { time > 1 }; 

    private _pos = [0,0,0];
    if (typeName _spawnTarget == "OBJECT") then { if (!isNull _spawnTarget) then { _pos = getPosATL _spawnTarget; }; } else { _pos = _spawnTarget; };
    if (_pos isEqualTo [0,0,0]) exitWith {};

    private _infPool = missionNamespace getVariable ["TAG_Merc_InfantryPool", ["O_G_Soldier_F", "O_G_Soldier_AR_F", "O_G_Soldier_M_F"]];
    private _groupSize = 4 + (round (random 2));
    private _squadUnits = [];
    for "_i" from 1 to _groupSize do { _squadUnits pushBack (selectRandom _infPool); };

    private _grpInf = [_pos, _factionSide, _squadUnits] call BIS_fnc_spawnGroup;

    if (!isNull _grpInf) then {
        if (!isNil "TAG_fnc_randomizeKroco") then { { [_x] call TAG_fnc_randomizeKroco; } forEach (units _grpInf); };
        [_grpInf, _pos] call BIS_fnc_taskDefend;

        // 🔥 RULE 3a.3: Deteksi Kematian - Mayat Despawn Otomatis Setelah 4 Menit (240 Detik)
        {
            _x addEventHandler ["Killed", {
                params ["_unit"];
                _unit spawn {
                    sleep 240;
                    deleteVehicle _this;
                };
            }];
        } forEach (units _grpInf);

        // Daftarkan grup ke tiang bendera MERC
        if (typeName _spawnTarget == "OBJECT") then {
            private _currentGroups = _spawnTarget getVariable ["TAG_townGroups", []];
            _currentGroups pushBack _grpInf;
            _spawnTarget setVariable ["TAG_townGroups", _currentGroups, true];
        };
    };
};