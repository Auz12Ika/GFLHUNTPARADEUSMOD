// =====================================================
// WAREVENT.SQF (FIXED - TIGRIS AA VERSION)
// =====================================================

params ["_trigger"];

private _logic = synchronizedObjects _trigger select 0;
private _faction = _logic getVariable ["faction", ""];

// Cek apakah spawn diizinkan
if (_logic getVariable ["canSpawn", true]) then {

    private _isUS = (_faction == "US");
    private _isRUS = (_faction == "RUSVTOL"); // Kita tetap pakai nama logic ini
    
    // Tentukan jarak dan posisi
    private _dist = if (_isUS) then { 1500 } else { 1000 };
    private _randDir = if (_isUS) then { random 90 } else { 180 + random 90 };
    private _targetPos = (getPos _logic) getPos [_dist, _randDir];

    // --- LOGIKA SPAWN ---
    if (_isUS) then {
        // [US: Blackfish - Tetap di Udara]
        private _spawnPos = [_targetPos select 0, _targetPos select 1, 300];
        private _veh = createVehicle ["B_T_VTOL_01_vehicle_F", _spawnPos, [], 0, "FLY"];
        createVehicleCrew _veh;
        _veh engineOn true;
        { _x setSkill 0.8; } forEach crew _veh;
        
        private _grp = group (driver _veh);
        _grp setBehaviour "COMBAT";
        _grp setCombatMode "RED";
        _grp setSpeedMode "FULL";
        
        private _wp = _grp addWaypoint [(getPos _logic), 0];
        _wp setWaypointType "SAD";
        _wp setWaypointCompletionRadius 200;
        
        diag_log "DEBUG WAREVENT: US Blackfish Spawned";

    } else {
        // [RU: 2 Tigris AA - Spawn di Darat]
        if (_isRUS) then {
            private _class = "O_APC_Tracked_02_AA_F"; // Tigris AA

            for "_i" from 1 to 2 do {
                // Spawn di permukaan tanah (z=0)
                private _pos = [_targetPos select 0, _targetPos select 1, 0];
                _pos = _pos getPos [10 * _i, random 360]; 

                if (isClass (configFile >> "CfgVehicles" >> _class)) then {
                    // Gunakan "NONE" untuk kendaraan darat agar menempel di tanah
                    private _veh = createVehicle [_class, _pos, [], 5, "NONE"]; 
                    createVehicleCrew _veh;
                    
                    private _grp = group (driver _veh);
                    _grp setBehaviour "COMBAT";
                    _grp setCombatMode "RED";
                    _grp setSpeedMode "FULL";
                    
                    private _wp = _grp addWaypoint [(getPos _logic), 0];
                    _wp setWaypointType "SAD";
                    _wp setWaypointCompletionRadius 100;
                    
                    diag_log format ["DEBUG WAREVENT: Berhasil spawn Tigris AA ke-%1", _i];
                } else {
                    diag_log format ["DEBUG WAREVENT: ERROR! Class %1 tidak ditemukan", _class];
                };
            };
        };
    };

    // Kunci agar hanya spawn sekali
    _logic setVariable ["canSpawn", false];
};