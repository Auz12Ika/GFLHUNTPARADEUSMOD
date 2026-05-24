/*
    GFL SYSTEM CONTROLLER (v1.1)
    Fokus: Stabilitas FPS & Manajemen Unit Skala Besar
    🔧 FIX P2: Ghost functions diganti dengan panggilan yang benar.
               Spawn berdasarkan kepemilikan lokasi (owner_*).
*/

if (!isServer) exitWith {};

// --- VARIABLE INITIALIZATION ---
private _maxAI          = 120;
private _spawnRadius    = 4500;
private _safeRadius     = 800;
private _despawnRadius  = 4000;
private _fpsCritical    = 24;

while {true} do {
    private _fps = diag_fps;
    private _allPlayers = allPlayers select {alive _x};

    // --- SEKSI 1: PENGAMAN CPU & RAM (FPS GUARD) ---
    if (_fps < _fpsCritical) then {
        missionNamespace setVariable ["GFL_LockSpawn", true, true];
        // 🔧 FIX P2: Tidak ada pembersihan GFL_temp_, karena tidak digunakan.
    } else {
        missionNamespace setVariable ["GFL_LockSpawn", false, true];
    };

    // --- SEKSI 2: ANTRIAN SPAWN (DELAYED CALL) ---
    if !(missionNamespace getVariable ["GFL_LockSpawn", false]) then {
        {
            private _pPos = getPos _x;
            
            // Cari lokasi pangkalan dalam radius spawn (tapi di luar safe zone)
            private _nearby = (missionNamespace getVariable ["merc_location_data", []]) select {
                private _dist = (_x select 0) distance _pPos;
                (_dist < _spawnRadius) && (_dist > _safeRadius)
            };

            {
                _x params ["_pos", "_type", "_name"];
                private _baseID = format["GFL_Active_%1", _name];

                // Cek apakah pangkalan sudah aktif atau belum
                if !(missionNamespace getVariable [_baseID, false]) then {
                    // Cek Quota Global 120 AI
                    if (count (allUnits select {side _x != civilian}) < _maxAI) then {
                        
                        // 🔧 FIX P2: Tentukan faksi berdasarkan kepemilikan
                        private _owner = missionNamespace getVariable [format["owner_%1", _name], "NEUTRAL"];
                        
                        if (_owner in ["USA", "RUSSIA", "CULT"]) then {
                            [_pos, _type, _name, _owner] spawn {
                                params ["_pos", "_type", "_name", "_owner"];
                                sleep 60; // DELAY 1 MENIT
                                
                                // Panggil batch spawner dengan faksi yang sesuai
                                [_pos, _owner, _type, _name] call MERC_fnc_spawnGroupUniversal;
                            };
                            missionNamespace setVariable [_baseID, true, true];
                            sleep 10; // SPAWN RATE LIMITER
                        };
                    };
                };
            } forEach _nearby;

            // --- SPAWN JALAN RAYA (KENDARAAN SIPIL) ---
            if (random 100 > 85) then {
                // 🔧 FIX P2: Spawn satu kendaraan sipil antar kota (inline)
                private _locData = missionNamespace getVariable ["merc_location_data", []];
                private _cities = _locData select { _x select 1 == "CITY" };
                
                if (count _cities >= 2) then {
                    private _startCity = selectRandom _cities;
                    private _endCity = selectRandom (_cities - [_startCity]);
                    _startCity params ["_sPos"];
                    _endCity params ["_ePos"];
                    
                    private _road = [_sPos, 200] call BIS_fnc_nearestRoad;
                    if (!isNull _road) then {
                        private _vehClass = selectRandom (if (!isNil "MERC_vehicles_CIV") then { MERC_vehicles_CIV } else { ["C_Offroad_01_F", "C_SUV_01_F", "C_Hatchback_01_F"] });
                        private _veh = createVehicle [_vehClass, getPos _road, [], 0, "NONE"];
                        createVehicleCrew _veh;
                        private _grp = group (driver _veh);
                        private _wp = _grp addWaypoint [_ePos, 50];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointBehaviour "SAFE";
                        _wp setWaypointSpeed "LIMITED";
                        
                        // Cleanup setelah sampai
                        [_veh, _ePos] spawn {
                            params ["_v", "_dest"];
                            waitUntil { sleep 10; (_v distance _dest < 150) || !alive _v || !alive (driver _v) };
                            if (alive _v) then {
                                { deleteVehicle _x } forEach (crew _v) + [_v];
                            };
                        };
                    };
                };
                sleep 15;
            };

        } forEach _allPlayers;
    };

    // --- SEKSI 3: DESPAWN & HIBERNASI AGRESIF ---
    {
        private _grp = _x;
        if (({isPlayer _x} count (units _grp)) == 0) then {
            private _leader = leader _grp;
            if (!isNull _leader) then {
                private _dist = ([_allPlayers, _leader] call BIS_fnc_distance2D);

                if (_dist > _despawnRadius) then {
                    private _persistent = _grp getVariable ["GFL_Persistent", false];
                    private _remnant    = _grp getVariable ["GFL_Remnant", false];

                    if (_persistent || _remnant) then {
                        { _x enableSimulationGlobal false; _x hideObjectGlobal true; } forEach (units _grp);
                    } else {
                        { deleteVehicle (vehicle _x); deleteVehicle _x; } forEach (units _grp);
                        deleteGroup _grp;
                    };
                } else {
                    if !(simulationEnabled (leader _grp)) then {
                        { _x enableSimulationGlobal true; _x hideObjectGlobal false; } forEach (units _grp);
                    };
                };
            };
        };
    } forEach allGroups;

    sleep 20;
};