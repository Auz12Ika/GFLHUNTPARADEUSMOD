/*
    File: fn_triggerDeactivated.sqf
    Description: Membersihkan unit yang di-spawn saat pemain keluar trigger (dengan cooldown 120 detik).
*/
params ["_trigger"];

private _modules = synchronizedObjects _trigger;
{
    _x setVariable ["playerLeft", true, true];
    [_x] spawn {
        params ["_mod"];
        sleep 60;
        // Cek apakah pemain benar-benar sudah tidak ada
        private _trig = (_mod getVariable ["syncedTrigger", objNull]);
        if (count (allPlayers select {alive _x && _x distance (_mod getVariable ["syncedTrigger", objNull]) < 1000}) == 0) then {
            _mod setVariable ["spawned", false, true];
            private _grp = _mod getVariable ["spawnedGroup", grpNull];
            if (!isNull _grp) then {
                { deleteVehicle (vehicle _x); deleteVehicle _x; } forEach (units _grp);
                deleteGroup _grp;
            };
            private _vic = _mod getVariable ["spawnedVic", objNull];
            if (!isNull _vic) then { deleteVehicle _vic; };
        } else {
            _mod setVariable ["playerLeft", false, true];
        };
    };
} forEach _modules;