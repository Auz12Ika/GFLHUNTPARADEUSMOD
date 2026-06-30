/*
    File: InsurgencyFunction\Missions\Convoy.sqf
    Description: Misi Konvoi – Spawn manual dari pad di Eden.
                 RU: Merc_convoy_truckRU, Merc_Convoy_guardRU, Merc_Convoy_guardRU1
                 US: Merc_convoy_truckUS, Merc_Convoy_guardUS, Merc_Convoy_guardUS1
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. VALIDASI TARGET
// ========================================================================
if (_target != "USA" && _target != "RUSSIA") exitWith {
    diag_log format ["MERC CONVOY ERROR: Target %1 tidak didukung (hanya USA/RUSSIA)", _target];
};

// ========================================================================
// 2. SISI MUSUH
// ========================================================================
if (isServer) then {
    independent setFriend [independent, 1];
    west setFriend [west, 1];
    east setFriend [east, 1];
};

private _missionSide = if (_target == "USA") then { west } else { east };
private _missionGroup = createGroup [_missionSide, true];

// ========================================================================
// 3. POOL KENDARAAN & GRUNT
// ========================================================================
private _cargoTruckClass = "";
private _escortVehPool = [];
private _gruntPool = [];

switch (_target) do {
    case "USA": {
        _cargoTruckClass = "rhsusf_M1078A1R_A_fmtv_wd";
        _escortVehPool = missionNamespace getVariable ["MERC_vehicles_USA", []];
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
    };
    case "RUSSIA": {
        _cargoTruckClass = "rhs_typhoon_vdv";
        _escortVehPool = missionNamespace getVariable ["MERC_vehicles_RUS", []];
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
    };
};

if (count _gruntPool == 0) exitWith {
    diag_log "MERC CONVOY ERROR: Grunt pool kosong!";
    deleteGroup _missionGroup;
};

// ========================================================================
// 4. CARI PAD DI EDEN (MANUAL)
// ========================================================================
private _truckPadName = if (_target == "USA") then { "Merc_convoy_truckUS" } else { "Merc_convoy_truckRU" };
private _guardPadNames = if (_target == "USA") then {
    ["Merc_Convoy_guardUS", "Merc_Convoy_guardUS1"]
} else {
    ["Merc_Convoy_guardRU", "Merc_Convoy_guardRU1"]
};

// Cari semua objek (termasuk EmptyDetector, Logic)
private _allObjects = allMissionObjects "All";
private _truckPad = objNull;
private _guardPads = [];

{
    private _name = vehicleVarName _x;
    if (_name == _truckPadName) then { _truckPad = _x; };
    if (_name in _guardPadNames) then { _guardPads pushBack _x; };
} forEach _allObjects;

// Urutkan guard pads sesuai urutan nama
private _sortedGuardPads = [];
{
    private _idx = _guardPadNames find (vehicleVarName _x);
    if (_idx != -1) then { _sortedGuardPads set [_idx, _x]; };
} forEach _guardPads;
_guardPads = _sortedGuardPads - [objNull];

diag_log format ["MERC CONVOY: Truck pad: %1, Guard pads found: %2 (expected 2)", !isNull _truckPad, count _guardPads];

// ========================================================================
// 5. FUNGSI SPAWN KENDARAAN (MANUAL)
// ========================================================================
private _fnc_spawnVehicle = {
    params ["_pad", "_vehicleClass", "_group", "_gruntPool", "_allTargets", "_allVehicles", "_isTruck"];
    if (isNull _pad) exitWith { objNull };
    private _pos = getPos _pad;
    
    private _vic = createVehicle [_vehicleClass, _pos, [], 0, "NONE"];
    _vic setDir (getDir _pad);
    _vic setPos _pos; // setPos lebih presisi dari setPosATL
    _vic setVectorUp (surfaceNormal _pos);
    _allVehicles pushBack _vic;
    
    if (_isTruck) then {
        _vic setVariable ["MERC_is_mission_target", true, true];
        _vic setVariable ["MERC_vehicle_claimable", true, true];
        _vic setVariable ["MERC_vehicle_origin", _id, true];
    };
    
    // Isi awak (driver, gunner, commander, cargo)
    if (_vic emptyPositions "driver" > 0) then {
        private _driver = _group createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
        _driver moveInDriver _vic;
        _driver setCombatMode "YELLOW";
        _driver allowFleeing 0;
        _driver addRating 10000;
        _allTargets pushBack _driver;
    };
    if (_vic emptyPositions "gunner" > 0) then {
        private _gunner = _group createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
        _gunner moveInGunner _vic;
        _gunner setCombatMode "YELLOW";
        _gunner allowFleeing 0;
        _gunner addRating 10000;
        _allTargets pushBack _gunner;
    };
    if (_vic emptyPositions "commander" > 0) then {
        private _commander = _group createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
        _commander moveInCommander _vic;
        _commander setCombatMode "YELLOW";
        _commander allowFleeing 0;
        _commander addRating 10000;
        _allTargets pushBack _commander;
    };
    private _cargoSeats = _vic emptyPositions "cargo";
    for "_i" from 1 to _cargoSeats do {
        private _passenger = _group createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
        _passenger moveInCargo [_vic, _i - 1];
        _passenger setCombatMode "YELLOW";
        _passenger allowFleeing 0;
        _passenger addRating 10000;
        _allTargets pushBack _passenger;
    };
    
    diag_log format ["MERC CONVOY: Spawn %1 di %2", typeOf _vic, _pos];
    _vic
};

// ========================================================================
// 6. SPAWN KENDARAAN (MANUAL)
// ========================================================================
private _allTargets = [];
private _allVehicles = [];
private _truck = objNull;

// --- SPAWN TRUK ---
if (!isNull _truckPad) then {
    _truck = [_truckPad, _cargoTruckClass, _missionGroup, _gruntPool, _allTargets, _allVehicles, true] call _fnc_spawnVehicle;
} else {
    // FALLBACK: hardcoded posisi (tidak ada pencarian otomatis)
    private _fallbackPos = if (_target == "USA") then { [13243, 3254, 0] } else { [6803, 10767, 0] };
    diag_log format ["MERC CONVOY: Truck pad not found, using hardcoded pos %1", _fallbackPos];
    _truck = createVehicle [_cargoTruckClass, _fallbackPos, [], 0, "NONE"];
    _truck setDir random 360;
    _truck setPos _fallbackPos;
    _truck setVectorUp (surfaceNormal _fallbackPos);
    _truck setVariable ["MERC_is_mission_target", true, true];
    _truck setVariable ["MERC_vehicle_claimable", true, true];
    _truck setVariable ["MERC_vehicle_origin", _id, true];
    _allVehicles pushBack _truck;
    
    // Isi awak truk manual
    private _driver = _missionGroup createUnit [selectRandom _gruntPool, _fallbackPos, [], 0, "NONE"];
    _driver moveInDriver _truck;
    _driver setCombatMode "YELLOW";
    _driver allowFleeing 0;
    _driver addRating 10000;
    _allTargets pushBack _driver;
    private _cargoSeats = _truck emptyPositions "cargo";
    for "_i" from 1 to _cargoSeats do {
        private _passenger = _missionGroup createUnit [selectRandom _gruntPool, _fallbackPos, [], 0, "NONE"];
        _passenger moveInCargo _truck;
        _passenger setCombatMode "YELLOW";
        _passenger allowFleeing 0;
        _passenger addRating 10000;
        _allTargets pushBack _passenger;
    };
};

// --- SPAWN GUARD (dari pad) ---
private _guardCount = 0;
{
    if (!isNull _x && count _escortVehPool > 0) then {
        private _guardVehClass = selectRandom _escortVehPool;
        private _guard = [_x, _guardVehClass, _missionGroup, _gruntPool, _allTargets, _allVehicles, false] call _fnc_spawnVehicle;
        if (!isNull _guard) then { _guardCount = _guardCount + 1; };
    };
} forEach _guardPads;

// Jika guard pad tidak mencukupi (kurang dari 2), spawn manual sisanya
private _neededGuards = 2 - _guardCount;
if (_neededGuards > 0 && !isNull _truck) then {
    for "_i" from 1 to _neededGuards do {
        private _truckPos = getPos _truck;
        private _guardPos = _truckPos getPos [20 + (_i * 10), _i * 60]; // posisi berbeda
        private _guardVehClass = selectRandom _escortVehPool;
        private _guard = createVehicle [_guardVehClass, _guardPos, [], 0, "NONE"];
        _guard setDir (getDir _truck);
        _guard setPos _guardPos;
        _guard setVectorUp (surfaceNormal _guardPos);
        _guard setVariable ["MERC_vehicle_claimable", true, true];
        _guard setVariable ["MERC_vehicle_origin", _id, true];
        _allVehicles pushBack _guard;
        createVehicleCrew _guard;
        (crew _guard) joinSilent _missionGroup;
        {
            _x setCombatMode "YELLOW";
            _x allowFleeing 0;
            _x addRating 10000;
            _allTargets pushBack _x;
        } forEach (crew _guard);
        diag_log format ["MERC CONVOY: Guard %1 spawned manual di sekitar truk", _i];
    };
};

// ========================================================================
// 7. WAYPOINT (MANUAL)
// ========================================================================
if (!isNull _truck) then {
    while {count waypoints _missionGroup > 0} do { deleteWaypoint [_missionGroup, 0]; };
    
    private _targetPos = if (_target == "USA") then { [6803, 10767, 0] } else { [13243, 3254, 0] };
    private _wp0 = _missionGroup addWaypoint [getPos _truck, 0];
    _wp0 setWaypointType "MOVE";
    _wp0 setWaypointSpeed "LIMITED";
    _wp0 setWaypointBehaviour "AWARE";
    _wp0 setWaypointFormation "COLUMN";
    _wp0 setWaypointCompletionRadius 30;
    
    private _wp1 = _missionGroup addWaypoint [_targetPos, 0];
    _wp1 setWaypointType "SAD";
    _wp1 setWaypointSpeed "LIMITED";
    _wp1 setWaypointBehaviour "AWARE";
    _wp1 setWaypointCombatMode "YELLOW";
    _wp1 setWaypointCompletionRadius 100;
    
    private _wpLoop = _missionGroup addWaypoint [getPos _truck, 0];
    _wpLoop setWaypointType "CYCLE";
};

_missionGroup setBehaviour "AWARE";
_missionGroup setCombatMode "YELLOW";

// ========================================================================
// 8. PASTIKAN PESAWAT TERBANG (jika ada)
// ========================================================================
{
    if (_x isKindOf "Air") then {
        _x flyInHeight 150;
        _x setPos [getPos _x select 0, getPos _x select 1, 150];
        [_x, getPos _truck, 300] call BIS_fnc_taskPatrol;
    };
} forEach _allVehicles;

// ========================================================================
// 9. SIMPAN UNTUK CLEANUP
// ========================================================================
missionNamespace setVariable [format ["MERC_targets_%1", _id], _allTargets, true];
missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _allTargets, true];

if (!isNull _truck) then {
    [format ["<t color='#FFA500'>CONVOY VEHICLES</t><br/>Destroyed convoy vehicles can be claimed for your use!"]] remoteExec ["hintSilent", 0];
};

// ========================================================================
// 10. MONITOR SUKSES/GAGAL
// ========================================================================
if (!isNull _truck) then {
    private _timeLimit = _missionData select 3;
    [_truck, _timeLimit, _id] spawn {
        params ["_truck", "_timeLimit", "_id"];
        private _timeOut = time + (_timeLimit * 3600);
        waitUntil { sleep 5; (!alive _truck) || (time >= _timeOut) };
        if (!alive _truck) then {
            ["MERC_fnc_missionSuccess", ["convoy", _truck]] remoteExec ["call", 2];
            [format ["<t color='#00FF00' size='1.5'>CONVOY DESTROYED</t><br/>%1 eliminated!", typeOf _truck]] remoteExec ["hintSilent", 0];
        } else {
            ["<t color='#FF0000' size='1.5'>TIME'S UP</t><br/>Convoy escaped!"] remoteExec ["hintSilent", 0];
        };
        { if (markerText _x find "Convoy" >= 0) then { deleteMarker _x; }; } forEach allMapMarkers;
    };
};

_missionGroup;