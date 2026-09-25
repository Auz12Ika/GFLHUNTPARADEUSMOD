/*
    File: InsurgencyFunction\Missions\Barrack.sqf
    Description: Misi Barrack – Bunuh semua musuh (dengan boss untuk CULT).
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. SISI MUSUH
// ========================================================================
private _missionSide = east;
switch (_target) do {
    case "RUSSIA":     { _missionSide = east; };
    case "USA":        { _missionSide = west; };
    case "CULT": {
        if (_giver in ["RU", "RUSSIA"]) then { _missionSide = west; }
        else { if (_giver in ["US", "USA"]) then { _missionSide = west; }; };
    };
};
private _missionGroup = createGroup [_missionSide, true];

// ========================================================================
// 2. KOMPOSISI BARACK (dari allcompositions.sqf)
// ========================================================================
private _compArray = [];
switch (_target) do {
    case "USA":    { _compArray = missionNamespace getVariable ["MERC_comp_barrack1", []]; };
    case "RUSSIA": { _compArray = missionNamespace getVariable ["MERC_comp_barrack2", []]; };
    case "CULT":   { _compArray = missionNamespace getVariable ["MERC_comp_cult_barrack", []]; };
    default        { _compArray = missionNamespace getVariable ["MERC_comp_barrack1", []]; };
};

private _spawned = [];
private _globalDir = random 360;

if (count _compArray > 0) then {
    _spawned = [_spawnPos, _globalDir, _compArray] call BIS_fnc_objectsMapper;
    diag_log format ["[MERC] Spawned %1 structures", count _spawned];
} else {
    diag_log "[MERC] Composition array empty!";
};
missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _spawned, true];

// ========================================================================
// 3. POOL GRUNT (TANPA BOSS – boss diurus di bagian 4)
// ========================================================================
private _gruntPool = [];

switch (_target) do {
    case "CULT": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
    };
    case "USA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
    };
    case "RUSSIA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
    };
    case "MERC_ENEMY": {
        _gruntPool = (missionNamespace getVariable ["MERC_factions_Vanjager", []]) +
                     (missionNamespace getVariable ["MERC_factions_Mangi", []]);
    };
};

// Fallback jika gruntPool kosong
if (count _gruntPool == 0) then {
    _gruntPool = ["B_Soldier_F"];
    diag_log "[MERC] WARNING: gruntPool empty, using fallback";
};

// ========================================================================
// 4. SPAWN BOSS (KHUSUS CULT) & GRUNTS (SEMUA SATU GROUP) - BIS SPAWNGROUP
// ========================================================================

private _allTargets = [];
private _unitsArray = [];

// ========================================================================
// BUILD UNIT ARRAY
// ========================================================================

private _unitsArray = [];

for "_i" from 1 to _aiCount do {
    _unitsArray pushBack (selectRandom _gruntPool);
};

// ========================================================================
// SPAWN GROUP
// ========================================================================
private _groupPos = _spawnPos getPos [random 120, random 360];
_groupPos = [_groupPos, 0, 20, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;

private _spawnGroup = [
    _spawnPos,
    _missionSide,
    _unitsArray
] call BIS_fnc_spawnGroup;

{
    private _pos = getPosASL _x;
    private _ground = getTerrainHeightASL [_pos select 0, _pos select 1];
    _x setPosASL [_pos select 0, _pos select 1, _ground + 0.3];
} forEach units _spawnGroup;

// ========================================================================
// SETUP UNIT
// ========================================================================

{
    _x setBehaviour "AWARE";
    _x setCombatMode "RED";

    _x allowFleeing 0;
    _x addRating 10000;

    _x setVariable ["MERC_is_barrack_unit", true, true];

    _allTargets pushBack _x;

} forEach units _spawnGroup;

// ========================================================================
// 4. ROLE, POSITION, PATROL & ALERT SYSTEM
// ========================================================================

// Barrack: 1 Commando, 2 Guard, 2 Assault, sisanya Recon.
// Randomness hanya menentukan unit mana yang mendapat role.
private _infantryTargets = units _spawnGroup;

// Buat group role terpisah.
private _commandoGroup = createGroup [_missionSide, true];
private _guardGroup = createGroup [_missionSide, true];
private _assaultGroup = createGroup [_missionSide, true];
private _reconGroup = createGroup [_missionSide, true];

// Unit diacak sebelum dibagi ke role.
private _rolePool = +_infantryTargets;
_rolePool = _rolePool call BIS_fnc_arrayShuffle;

// Commando: maksimal 1.
if (count _rolePool > 0) then {
    private _unit = _rolePool deleteAt 0;
    [_unit] joinSilent _commandoGroup;
    _commandoGroup selectLeader _unit;
    _unit setVariable ["MERC_is_barrack_commando", true, true];
};

// Guard: maksimal 2.
for "_i" from 1 to 2 do {
    if (count _rolePool > 0) then {
        private _unit = _rolePool deleteAt 0;
        [_unit] joinSilent _guardGroup;
    };
};

// Assault: maksimal 2.
for "_i" from 1 to 2 do {
    if (count _rolePool > 0) then {
        private _unit = _rolePool deleteAt 0;
        [_unit] joinSilent _assaultGroup;
    };
};

// Sisanya Recon.
{
    [_x] joinSilent _reconGroup;
} forEach _rolePool;

// Cari building/tower yang punya posisi AI yang bisa dimasuki.
private _enterableBuildings = nearestObjects [_spawnPos, ["House", "Building"], 150];
_enterableBuildings = _enterableBuildings select {
    count (_x buildingPos -1) > 0
};

// Tempatkan unit dalam building/tower.
private _placeInsideBuilding = {
    params ["_unit", "_building"];

    if (isNull _building) then {
        if (count _enterableBuildings > 0) then {
            _building = selectRandom _enterableBuildings;
        };
    };

    if (!isNull _building) then {
        private _positions = _building buildingPos -1;

        if (count _positions > 0) then {
            _unit setPosASL (selectRandom _positions);
        };
    };
};

// Commando berada di titik tengah bangunan, bukan di buildingPos/interior.
private _commando = objNull;
private _commandoBuilding = objNull;

if (count units _commandoGroup > 0) then {
    _commando = leader _commandoGroup;
    if (count _enterableBuildings > 0) then {
        _commandoBuilding = selectRandom _enterableBuildings;
        _commando setPosATL (getPosATL _commandoBuilding);
    };
};

// Helper posisi acak di radius tertentu dari tengah AO.
private _randomRadiusPos = {
    params ["_center", "_radius"];
    private _pos = _center getPos [random _radius, random 360];
    private _safePos = [_pos, 0, 20, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
    if (count _safePos > 0) then { _safePos } else { _pos };
};

// Guard tersebar dekat Commando. PATH tetap aktif.
{
    private _pos = [_commando, 15] call _randomRadiusPos;
    _x setPosATL [_pos select 0, _pos select 1, 0];
} forEach units _guardGroup;

// Assault tersebar langsung di AO, lalu tetap mendapat patrol waypoint.
{
    private _pos = [_spawnPos, 255] call _randomRadiusPos;
    _x setPosATL [_pos select 0, _pos select 1, 0];
} forEach units _assaultGroup;

// Recon tersebar langsung di perimeter AO, lalu mendapat patrol waypoint.
{
    private _pos = [_spawnPos, 350] call _randomRadiusPos;
    _x setPosATL [_pos select 0, _pos select 1, 0];
} forEach units _reconGroup;

// ========================================================================
// GUARD PROTECTION
// Guard bergerak mengelilingi Commando.
// ========================================================================
if (!isNull _commando && {count units _guardGroup > 0}) then {

    private _guardCenter = getPosATL _commando;
    private _guardRadius = 15;
    private _guardAngles = [0, 90, 180, 270];

    {
        private _angle = _x;
        private _pos = [
            (_guardCenter select 0) + (sin _angle * _guardRadius),
            (_guardCenter select 1) + (cos _angle * _guardRadius),
            _guardCenter select 2
        ];

        private _wp = _guardGroup addWaypoint [_pos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointCombatMode "YELLOW";
        _wp setWaypointCompletionRadius 5;
    } forEach _guardAngles;

    private _cycleWP = _guardGroup addWaypoint [_guardCenter, 0];
    _cycleWP setWaypointType "CYCLE";
};

// ========================================================================
// PATROL RADIUS
// Barrack:
// Recon   = 350m
// Assault = 255m
// ========================================================================
if (count units _assaultGroup > 0) then {
    [_assaultGroup, _spawnPos, 255] call BIS_fnc_taskPatrol;
};

if (count units _reconGroup > 0) then {
    [_reconGroup, _spawnPos, 350] call BIS_fnc_taskPatrol;
};

{
    _x setBehaviour "AWARE";
    _x setCombatMode "YELLOW";
    _x setSkill ["spotDistance",1];
    _x setSkill ["spotTime",1];
} forEach _infantryTargets;

// ========================================================================
// ALERT SYSTEM
//
// Recon / Guard melihat musuh:
//     -> Assault diberi target dan path menuju player.
//
// Guard tetap menjaga Commando dan tidak diberi patrol radius.
// ========================================================================
private _alertGroups = [_reconGroup, _guardGroup];

{
    private _grp = _x;

    [_grp, _assaultGroup] spawn {
        params ["_grp", "_assaultGroup"];

        while {{alive _x} count units _grp > 0} do {

            {
                if (alive _x) then {

                    private _enemy = _x findNearestEnemy _x;

                    if (!isNull _enemy && {alive _enemy}) then {

                        _grp setVariable ["MERC_alert", true, true];
                        _grp setVariable ["MERC_alertTarget", _enemy, true];

                        // Assault menjadi reaction force.
                        if (count units _assaultGroup > 0) then {

                            _assaultGroup setVariable [
                                "MERC_assaultTarget",
                                _enemy,
                                true
                            ];

                            while {count waypoints _assaultGroup > 0} do {
                                deleteWaypoint [_assaultGroup, 0];
                            };

                            private _wp = _assaultGroup addWaypoint [
                                getPosATL _enemy,
                                0
                            ];

                            _wp setWaypointType "SAD";
                            _wp setWaypointBehaviour "COMBAT";
                            _wp setWaypointCombatMode "RED";
                            _wp setWaypointCompletionRadius 7.5;
                        };
                    };
                };

            } forEach units _grp;

            sleep 2;
        };
    };

} forEach _alertGroups;

// ========================================================================
// ASSAULT RETURN TO PATROL
// ========================================================================
if (count units _assaultGroup > 0) then {

    [_assaultGroup, _spawnPos] spawn {
        params ["_assaultGroup", "_spawnPos"];

        while {{alive _x} count units _assaultGroup > 0} do {

            private _target = _assaultGroup getVariable [
                "MERC_assaultTarget",
                objNull
            ];

            if (!isNull _target && {!alive _target}) then {

                _assaultGroup setVariable [
                    "MERC_assaultTarget",
                    objNull,
                    true
                ];

                while {count waypoints _assaultGroup > 0} do {
                    deleteWaypoint [_assaultGroup, 0];
                };

                [_assaultGroup, _spawnPos, 255] call BIS_fnc_taskPatrol;
            };

            sleep 5;
        };
    };
};

// ========================================================================
// 5. KENDARAAN STATIS (PARKIR) + PESAWAT PATROLI
// ========================================================================
private _vehPool = [];
private _vehCount = 0;
private _isMajor = false;

switch (_target) do {
    case "CULT":       { _vehPool = missionNamespace getVariable ["MERC_vehicles_CULT", []]; };
    case "USA":        { _vehPool = missionNamespace getVariable ["MERC_vehicles_USA", []]; _isMajor = true; };
    case "RUSSIA":     { _vehPool = missionNamespace getVariable ["MERC_vehicles_RUS", []]; _isMajor = true; };
};

if (count _vehPool > 0) then {
    _vehCount = if (_isMajor) then { 2 } else { if (random 100 <= 20) then { 1 } else { 0 } };
    for "_v" from 1 to _vehCount do {
        private _vPos = _spawnPos getPos [30 + (_v*10), random 360];
        private _chosenVic = selectRandom _vehPool;
        private _vic = objNull;
        
        // ---- SAMA PERSIS DENGAN TRIGGER ----
        if (_chosenVic isKindOf "Air") then {
            _vic = createVehicle [_chosenVic, [_vPos select 0, _vPos select 1, 200], [], 0, "FLY"];
            _vic flyInHeight 150;
        } else {
            _vic = createVehicle [_chosenVic, _vPos, [], 0, "NONE"];
            _vic setDir random 360;
            _vic setPosATL _vPos;
            _vic setVectorUp (surfaceNormal _vPos);
            _vic setVehicleLock "LOCKED";
        };
        // -------------------------------------
        
        // Buat awak untuk kendaraan (jika belum ada)
        if (count (crew _vic) == 0) then {
            createVehicleCrew _vic;
        };
        (crew _vic) joinSilent _missionGroup;
        
        // Tambahkan semua awak ke _allTargets
        {
            _x setVariable ["MERC_is_barrack_unit", true, true];
            _x setCombatMode "RED";
            _x allowFleeing 0;
            _x addRating 10000;
            _allTargets pushBack _x;
        } forEach (crew _vic);
        
        // ---- PATROLI KHUSUS UNTUK PESAWAT ----
        if (_vic isKindOf "Air") then {
            // Buat group terpisah untuk pesawat
            private _airGroup = createGroup [_missionSide, true];
            (crew _vic) joinSilent _airGroup;
            while {count waypoints _airGroup > 0} do { deleteWaypoint [_airGroup, 0]; };
            // Patroli di udara mengcover area Barrack
            [_airGroup, _spawnPos, 300] call BIS_fnc_taskPatrol;
            _airGroup setBehaviour "AWARE";
            _airGroup setCombatMode "RED";
            missionNamespace setVariable [format ["MERC_air_group_%1", _id], _airGroup, true];
        };
    };
};


// ========================================================================
// SIMPAN SEMUA UNIT BARACK (untuk cleanup)
// ========================================================================
missionNamespace setVariable [format ["MERC_barrack_units_%1", _id], _allTargets, true];
diag_log format ["[MERC] Barrack spawned with %1 units (including boss)", count _allTargets];

// ========================================================================
// 6. MARKER AREA (ukuran dinamis)
// ========================================================================
private _centerPos = _spawnPos;
private _markerSizeX = 200;
private _markerSizeY = 200;

if (count _spawned > 0) then {
    private _minX = 1e10;
    private _maxX = -1e10;
    private _minY = 1e10;
    private _maxY = -1e10;

    {
        private _pos = getPos _x;
        private _xPos = _pos select 0;
        private _yPos = _pos select 1;
        if (_xPos < _minX) then { _minX = _xPos; };
        if (_xPos > _maxX) then { _maxX = _xPos; };
        if (_yPos < _minY) then { _minY = _yPos; };
        if (_yPos > _maxY) then { _maxY = _yPos; };
    } forEach _spawned;

    private _width = abs (_maxX - _minX);
    private _length = abs (_maxY - _minY);
    _markerSizeX = _width + 80;
    _markerSizeY = _length + 80;
    private _centerX = (_minX + _maxX) / 2;
    private _centerY = (_minY + _maxY) / 2;
    _centerPos = [_centerX, _centerY, 0];
};

private _barrackMarker = createMarker [format ["MERC_Barrack_%1", time], _centerPos];
_barrackMarker setMarkerShape "ELLIPSE";
_barrackMarker setMarkerSize [_markerSizeX, _markerSizeY];
_barrackMarker setMarkerColor "ColorRED";
_barrackMarker setMarkerAlpha 0.4;
_barrackMarker setMarkerBrush "Border";
_barrackMarker setMarkerText "Barrack AO";

// ========================================================================
// 7. MONITOR – SEMUA TARGET MATI → SUKSES
// ========================================================================
[_allTargets, _id, _barrackMarker] spawn {
    params ["_targets", "_id", "_marker"];
    waitUntil { sleep 5; { alive _x } count _targets == 0 };
    
    private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];
    if (count _contract > 0) then {
        _contract params ["", "", "", "", "_rewardRange", "_repReward", "_giver", "_target"];
        private _reward = (_rewardRange select 0) + round random ((_rewardRange select 1) - (_rewardRange select 0));
        ["barrack", _targets select 0, _giver, _reward, _repReward] call MERC_fnc_missionSuccess;
    } else {
        ["barrack", _targets select 0] call MERC_fnc_missionSuccess;
    };
    [format ["MERC_%1", _id], true] call BIS_fnc_deleteTask;
    deleteMarker _marker;
};

_missionGroup;