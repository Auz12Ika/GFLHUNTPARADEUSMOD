/*
    Author: Modder
    File: fn_usaHunterTeam.sqf
    Description: Helikopter USA + Hunter-Killer Team. Memburu pemain.
    🔧 FINAL: Data-driven dari MERC_vehicles_USA & MERC_factions_USA.
*/

if (!isServer) exitWith {};

if (random 100 > 15) exitWith { diag_log "USA Hunter: Tim pencari tidak menemukan lokasi pemain hari ini."; };

private _player = selectRandom (allPlayers select {alive _x});
if (isNil "_player") exitWith {};

private _playerPos = getPos _player;
private _spawnPos = [_playerPos, 2000, 3000, 0, 0, 20, 0] call BIS_fnc_findSafePos;
_spawnPos set [2, 100];

// 1. SPAWN TRANSPORT HELI (dari MERC_vehicles_USA indeks 3 = Blackhawk, fallback vanilla)
private _heliClass = if (!isNil "MERC_vehicles_USA" && {count MERC_vehicles_USA > 3}) then {
    MERC_vehicles_USA select 3
} else {
    "B_Heli_Transport_01_F"
};

private _heliVeh = createVehicle [_heliClass, _spawnPos, [], 0, "FLY"];
createVehicleCrew _heliVeh;
private _heliGrp = group driver _heliVeh;
_heliGrp setGroupIdGlobal ["HUNTER_LEAD"];

// 2. SPAWN ELITE HUNTER TEAM (dari MERC_factions_USA, fallback vanilla)
private _hunterGrp = createGroup west;
private _unitPool = if (!isNil "MERC_factions_USA") then { MERC_factions_USA } else { ["B_Soldier_F", "B_Soldier_AR_F", "B_Medic_F"] };
private _groupSize = (4 + round random 6) min 10;

for "_i" from 1 to _groupSize do {
    private _u = _hunterGrp createUnit [selectRandom _unitPool, _spawnPos, [], 0, "NONE"];
    _u moveInCargo _heliVeh;
    _u setSkill 0.8;
};

// 3. LOGIKA PENYERGAPAN
private _wp1 = _heliGrp addWaypoint [_playerPos, 0];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointStatements ["true", "(vehicle this) setVariable ['canDrop', true];"];

[_heliVeh, _hunterGrp, _playerPos] spawn {
    params ["_heli", "_grp", "_pPos"];
    
    waitUntil { (_heli distance _pPos < 150) || !alive _heli };
    
    if (alive _heli) then {
        _heli flyInHeight 25;
        sleep 2;
        
        {
            unassignVehicle _x;
            moveOut _x;
            private _pos = getPos _heli;
            _x setPos [_pos select 0, _pos select 1, (_pos select 2) - 3];
            sleep 0.5;
        } forEach (units _grp);
        
        private _wpHunt = _grp addWaypoint [_pPos, 0];
        _wpHunt setWaypointType "SAD";
        _grp setBehaviour "COMBAT";
        
        systemChat "WARNING: USA Recon Team has been deployed to your location!";
    };
    
    private _homePos = missionNamespace getVariable ["merc_usa_mainbase_pos", [0,0,0]];
    private _wpRet = (group driver _heli) addWaypoint [_homePos, 0];
    _wpRet setWaypointType "MOVE";
    waitUntil { (_heli distance _homePos < 500) };
    { deleteVehicle _x } forEach (crew _heli) + [_heli];
};