/*
    Author: Modder
    File: fn_civTraffic.sqf
    Description: Mengatur spawn warga sipil dan lalu lintas kendaraan antar kota.
*/

if (!isServer) exitWith {};

private _locationData = missionNamespace getVariable ["merc_location_data", []];
private _cities = _locationData select { _x select 1 == "CITY" };

// 1. SPAWN WARGA JALAN KAKI (Garrison di rumah-rumah)
{
    _x params ["_cityPos", "_type", "_cityName"];
    
    // Hanya spawn jika pemain mendekat (Optimization)
    [_cityPos, _cityName] spawn {
        params ["_pos", "_name"];
        while {true} do {
            private _nearbyPlayers = { _x distance _pos < 1000 } count allPlayers;
            
            if (_nearbyPlayers > 0) then {
                // Spawn 3-6 warga sipil di kota tersebut jika belum ada
                if (missionNamespace getVariable [format["civ_spawned_%1", _name], 0] < 3) then {
                    private _civGrp = createGroup civilian;
                    for "_i" from 1 to (3 + round random 3) do {
                        private _u = _civGrp createUnit [selectRandom ["C_man_1", "C_man_polo_1_F", "C_man_shorts_1_F"], _pos, [], 50, "NONE"];
                        [_u] spawn { params ["_u"]; [_u, getPos _u, 100] call BIS_fnc_taskPatrol; };
                    };
                    missionNamespace setVariable [format["civ_spawned_%1", _name], 5];
                };
            };
            sleep 60;
        };
    };
} forEach _cities;

// 2. LOGIKA LALU LINTAS KENDARAAN (Antar Kota)
[] spawn {
    while {true} do {
        // Cari dua kota acak untuk rute perjalanan
        private _locData = missionNamespace getVariable ["merc_location_data", []];
        private _cities = _locData select { _x select 1 == "CITY" };
        
        if (count _cities >= 2) then {
            private _startCity = selectRandom _cities;
            private _endCity = selectRandom (_cities - [_startCity]);
            
            _startCity params ["_sPos"];
            _endCity params ["_ePos"];

            // Cek peluang spawn kendaraan (Lore: Aktivitas harian)
            if (random 100 < 40) then {
                private _road = [_sPos, 200] call BIS_fnc_nearestRoad;
                if (!isNull _road) then {
                    private _vehClass = selectRandom ["C_Offroad_01_F", "C_Hatchback_01_F", "C_SUV_01_F", "C_Van_01_transport_F"];
                    private _veh = createVehicle [_vehClass, getPos _road, [], 0, "NONE"];
                    createVehicleCrew _veh;
                    private _grp = group (driver _veh);
                    
                    // Beri perintah mengemudi ke kota tujuan
                    private _wp = _grp addWaypoint [_ePos, 50];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointBehaviour "SAFE";
                    _wp setWaypointSpeed "LIMITED";
                    _wp setWaypointCompletionRadius 100;
                    
                    // Cleanup saat sampai atau kendaraan rusak
                    [_veh, _ePos] spawn {
                        params ["_v", "_dest"];
                        waitUntil { sleep 10; (_v distance _dest < 150) || !alive _v || !alive (driver _v) };
                        if (alive _v) then {
                            sleep 30; // Parkir sebentar
                            { deleteVehicle _x } forEach (crew _v) + [_v];
                        };
                    };
                };
            };
        };
        sleep (300 + random 300); // Spawn kendaraan baru setiap 5-10 menit
    };
};