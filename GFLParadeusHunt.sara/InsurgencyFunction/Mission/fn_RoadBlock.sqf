/*
    File: InsurgencyFunction\Missions\Roadblock.sqf
    Description: Misi Hancurkan Pos Pemeriksaan – PASTI di JALAN BESAR.
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. SISI MUSUH
// ========================================================================
if (isServer) then {
    independent setFriend [independent, 1];
	west setFriend [west, 1];
	east setFriend [east, 1];
};

private _missionSide = east;
switch (_target) do {
    case "RUSSIA":     { _missionSide = east; };
    case "USA":        { _missionSide = west; };
    case "MERC_ENEMY": { _missionSide = independent; };
    case "CULT": {
        if (_giver in ["RU", "RUSSIA"]) then { _missionSide = west; }
        else { if (_giver in ["US", "USA"]) then { _missionSide = east; }; };
    };
};
private _missionGroup = createGroup [_missionSide, true];

// ========================================================================
// 2. CARI JALAN BESAR TERDEKAT
// ========================================================================
private _roadDir = random 360;
private _roadPos = _spawnPos;

private _roads = _spawnPos nearRoads 200;
if (count _roads > 0) then {
    private _bestRoad = objNull;
    private _bestLength = 0;
    {
        private _connected = roadsConnectedTo _x;
        private _len = count _connected;
        if (_len > _bestLength) then {
            _bestLength = _len;
            _bestRoad = _x;
        };
    } forEach _roads;

    if (!isNull _bestRoad) then {
        _roadPos = getPos _bestRoad;
        private _connectedRoads = roadsConnectedTo _bestRoad;
        if (count _connectedRoads > 0) then {
            _roadDir = _bestRoad getDir (_connectedRoads select 0);
        } else {
            _roadDir = random 360;
        };
    };
} else {
    _roads = _spawnPos nearRoads 500;
    if (count _roads > 0) then {
        private _bestRoad = _roads select 0;
        _roadPos = getPos _bestRoad;
        private _connectedRoads = roadsConnectedTo _bestRoad;
        if (count _connectedRoads > 0) then {
            _roadDir = _bestRoad getDir (_connectedRoads select 0);
        };
    };
};

private _perpendicularDir = _roadDir + 90;

// ========================================================================
// 3. TARUH RINTANGAN JALAN DI TENGAH JALAN
// ========================================================================
private _barrierTypes = [
    "Land_HBarrier_Big_F",
    "Land_HBarrier_5_F",
    "Land_CzechHedgehog_01_F",
    "Land_Razorwire_F"
];
private _barrierObjects = [];

for "_i" from -2 to 2 do {
    private _pos = _roadPos getPos [4 * _i, _perpendicularDir];
    private _barrier = createVehicle [selectRandom _barrierTypes, _pos, [], 0, "NONE"];
    _barrier setDir _roadDir;
    _barrier setPosWorld (getPosWorld _barrier);
    _barrier setVectorUp (surfaceNormal _pos);
    _barrierObjects pushBack _barrier;
};

private _extraSpawnedObjects = [];
private _extraObjects = [
    ["Land_TentA_F", [8, 0], 0],
    ["Land_CratesShabby_F", [-6, 3], random 360],
    ["Land_WoodenBox_F", [-6, -4], random 360],
    ["Land_PortableLight_double_F", [10, -2], 0]
];
{
    private _type = _x select 0;
    private _offset = _x select 1;
    private _dirOffset = _x select 2;
    private _objPos = _roadPos getPos [_offset select 0, _perpendicularDir + (_offset select 1)];
    private _obj = createVehicle [_type, _objPos, [], 0, "NONE"];
    _obj setDir (_roadDir + _dirOffset);
    _obj setPosWorld (getPosWorld _obj);
    _obj setVectorUp (surfaceNormal _objPos);
    _extraSpawnedObjects pushBack _obj;
} forEach _extraObjects;

private _allRoadblockObjects = _barrierObjects + _extraSpawnedObjects;
missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _allRoadblockObjects, true];

// ========================================================================
// 4. POOL MUSUH & SPAWN INFANTERI (semua satu group)
// ========================================================================
private _gruntPool = [];
private _allTargets = [];   // <-- DEKLARASI UNTUK CLEANUP

switch (_target) do {
    case "CULT": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
        // (tidak ada boss di roadblock, hanya grunts)
    };
    case "MERC_ENEMY_Vanjager": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_Vanjager", []];
    };
    case "MERC_ENEMY_SF": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_SF", []];
    };
    case "MERC_ENEMY_Mangi": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_Mangi", []];
    };
    case "USA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
    };
    case "RUSSIA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
    };
    default {
        _gruntPool = (missionNamespace getVariable ["MERC_factions_Vanjager", []]) +
                     (missionNamespace getVariable ["MERC_factions_SF", []]) +
                     (missionNamespace getVariable ["MERC_factions_Mangi", []]);
    };
};

if (count _gruntPool == 0) exitWith {
    diag_log "MERC ROADBLOCK ERROR: Grunt pool kosong!";
    deleteGroup _missionGroup;
};

// --- SPAWN INFANTERI ---
for "_i" from 1 to _aiCount do {
    private _unitPos = _roadPos getPos [random 40, random 360];
    _unitPos = _unitPos findEmptyPosition [0, 10, selectRandom _gruntPool];
    if (count _unitPos == 0) then { _unitPos = _roadPos; };
    private _unit = _missionGroup createUnit [selectRandom _gruntPool, _unitPos, [], 0, "NONE"];
    _unit setCombatMode "YELLOW";   // 🔥 Ubah dari RED ke YELLOW
    _unit allowFleeing 0;
    _unit addRating 10000;
    _allTargets pushBack _unit;
};

// ========================================================================
// 5. KENDARAAN (masuk ke group utama)
// ========================================================================
private _vehPool = [];
private _vehCount = 0;
private _isMajor = false;

switch (_target) do {
    case "CULT":                 { _vehPool = missionNamespace getVariable ["MERC_vehicles_CULT", []]; };
    case "MERC_ENEMY_Vanjager":  { _vehPool = missionNamespace getVariable ["MERC_vehicles_Vanjager", []]; };
    case "MERC_ENEMY_SF":        { _vehPool = missionNamespace getVariable ["MERC_vehicles_SF", []]; };
    case "MERC_ENEMY_Mangi":     { _vehPool = missionNamespace getVariable ["MERC_vehicles_Mangi", []]; };
    case "USA":                  { _vehPool = missionNamespace getVariable ["MERC_vehicles_USA", []]; _isMajor = true; };
    case "RUSSIA":               { _vehPool = missionNamespace getVariable ["MERC_vehicles_RUS", []]; _isMajor = true; };
    default                      { _vehPool = missionNamespace getVariable ["MERC_vehicles_SF", []]; };
};

if (count _vehPool > 0 && random 100 <= 15) then {
    private _vPos = _roadPos getPos [25, random 360];
    private _vic = createVehicle [selectRandom _vehPool, _vPos, [], 0, "NONE"];
    _vic setDir random 360;
    
    private _drv = _missionGroup createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
    _drv moveInDriver _vic;
    _drv setCombatMode "YELLOW";
    _drv allowFleeing 0;
    _drv addRating 10000;
    _allTargets pushBack _drv;
    
    if (_vic emptyPositions "gunner" > 0) then {
        private _gnr = _missionGroup createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
        _gnr moveInGunner _vic;
        _gnr setCombatMode "YELLOW";
        _gnr allowFleeing 0;
        _gnr addRating 10000;
        _allTargets pushBack _gnr;
    };
    
    if (_vic emptyPositions "commander" > 0) then {
        private _cmd = _missionGroup createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
        _cmd moveInCommander _vic;
        _cmd setCombatMode "YELLOW";
        _cmd allowFleeing 0;
        _cmd addRating 10000;
        _allTargets pushBack _cmd;
    };
};

// --- PATROL ---
[_missionGroup, _roadPos, 50] call BIS_fnc_taskPatrol;
_missionGroup setBehaviour "AWARE";
_missionGroup setCombatMode "YELLOW";

// ========================================================================
// SIMPAN SEMUA TARGET UNTUK CLEANUP
// ========================================================================
missionNamespace setVariable [format ["MERC_targets_%1", _id], _allTargets, true];

// ========================================================================
// 6. MARKER AREA (ukuran dinamis)
// ========================================================================
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
} forEach _allRoadblockObjects;

private _width = abs (_maxX - _minX);
private _length = abs (_maxY - _minY);
private _markerSizeX = _width + 80;
private _markerSizeY = _length + 80;
private _centerX = (_minX + _maxX) / 2;
private _centerY = (_minY + _maxY) / 2;
private _centerPos = [_centerX, _centerY, 0];

private _rbMarker = createMarker [format ["MERC_RB_%1", time], _centerPos];
_rbMarker setMarkerShape "ELLIPSE";
_rbMarker setMarkerSize [_markerSizeX, _markerSizeY];
_rbMarker setMarkerColor "ColorRed";
_rbMarker setMarkerAlpha 0.4;
_rbMarker setMarkerBrush "Border";
_rbMarker setMarkerText "Roadblock Area";

// ========================================================================
// 7. MONITOR SUKSES
// ========================================================================
[_allTargets, _rbMarker, _id] spawn {
    params ["_targets", "_marker", "_id"];
    waitUntil { sleep 5; { alive _x } count _targets == 0 };
    private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];
    if (count _contract > 0) then {
        _contract params ["", "", "", "", "_rewardRange", "_repReward", "_giver", "_target"];
        private _reward = (_rewardRange select 0) + round random ((_rewardRange select 1) - (_rewardRange select 0));
        ["roadblock", _targets select 0, _giver, _reward, _repReward] call MERC_fnc_missionSuccess;
    } else {
        ["roadblock", _targets select 0] call MERC_fnc_missionSuccess;
    };
    hint parseText "<t color='#00FF00' size='1.5'>ROADBLOCK DESTROYED</t>";
    deleteMarker _marker;
};

_missionGroup;