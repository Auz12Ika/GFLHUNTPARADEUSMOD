/*
    Author: Modder
    File: fn_rusHunterTeam.sqf
    Description: Tank/BTR Rusia + Infantry Support. Memburu pemain.
    🔧 FINAL: Data-driven dari MERC_vehicles_RUS & MERC_factions_RUS.
*/

if (!isServer) exitWith {};

if (random 100 > 15) exitWith { diag_log "RUS Hunter: Kavaleri Rusia gagal melacak posisi kita hari ini."; };

private _player = selectRandom (allPlayers select {alive _x});
if (isNil "_player") exitWith {};
private _playerPos = getPos _player;

private _nearRoads = _playerPos nearRoads 800;
private _spawnPos = if (count _nearRoads > 0) then { getPos (selectRandom _nearRoads) } else { [_playerPos, 500, 1000, 5, 0, 0.3, 0] call BIS_fnc_findSafePos; };

// 1. SPAWN KENDARAAN BERAT (dari MERC_vehicles_RUS, fallback vanilla)
private _vecClass = if (!isNil "MERC_vehicles_RUS" && {count MERC_vehicles_RUS >= 4}) then {
    selectRandom [MERC_vehicles_RUS select 3, MERC_vehicles_RUS select 4]
} else {
    selectRandom ["O_MBT_02_cannon_F", "O_MBT_02_cannon_F"]
};

private _vec = createVehicle [_vecClass, _spawnPos, [], 0, "NONE"];
createVehicleCrew _vec;
private _vecGrp = group driver _vec;
_vecGrp setGroupIdGlobal ["RUS_IRON_HUNT"];

// 2. SPAWN INFANTRY SUPPORT (dari MERC_factions_RUS, fallback vanilla)
private _unitPool = if (!isNil "MERC_factions_RUS") then { MERC_factions_RUS } else { ["O_Soldier_F", "O_Soldier_AT_F", "O_Soldier_AR_F", "O_Medic_F"] };
private _infGrp = createGroup east;
private _groupSize = (4 + round random 6) min 10;

for "_i" from 1 to _groupSize do {
    private _u = _infGrp createUnit [selectRandom _unitPool, _spawnPos, [], 5, "NONE"];
    _u moveInCargo _vec;
    _u setSkill 0.7;
};

// 3. LOGIKA BERBURU
private _wp = _vecGrp addWaypoint [_playerPos, 50];
_wp setWaypointType "SAD";
_vecGrp setBehaviour "COMBAT";
_vecGrp setSpeedMode "LIMITED";

systemChat "WARNING: Russian Heavy Armor detected in the area. They are searching for you!";