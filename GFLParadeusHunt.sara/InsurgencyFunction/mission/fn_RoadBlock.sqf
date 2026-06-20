/*
    File: InsurgencyFunction\Missions\Roadblock.sqf
    Description: Misi Hancurkan Pos Pemeriksaan – Semua musuh di area harus mati.
    Target: MERC_ENEMY
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. SISI MUSUH – MERC_ENEMY pasti EAST
// ========================================================================
private _missionSide = east;
private _missionGroup = createGroup [_missionSide, true];

// ========================================================================
// 2. CARI JALAN TERDEKAT UNTUK ORIENTASI PENGHALANG
// ========================================================================
private _roadDir = random 360;  // fallback arah acak
private _roads = _spawnPos nearRoads 80;
if (count _roads > 0) then {
    private _road = _roads select 0;
    private _connectedRoads = roadsConnectedTo _road;
    if (count _connectedRoads > 0) then {
        _roadDir = _road getDir (_connectedRoads select 0);
    };
};

private _perpendicularDir = _roadDir + 90;

// ========================================================================
// 3. TARUH RINTANGAN JALAN SECARA MANUAL (KOMPOSISI AMAN)
// ========================================================================
private _barrierTypes = [
    "Land_HBarrier_Big_F",
    "Land_HBarrier_5_F",
    "Land_CzechHedgehog_01_F",
    "Land_Razorwire_F"
];
private _barrierObjects = [];

// Buat garis rintangan melintang jalan, 5 objek dengan jarak 4m
for "_i" from -2 to 2 do {
    private _pos = _spawnPos getPos [4 * _i, _perpendicularDir];
    private _barrier = createVehicle [selectRandom _barrierTypes, _pos, [], 0, "CAN_COLLIDE"];
    _barrier setDir _roadDir;
    _barrier setPosWorld (getPosWorld _barrier);
    _barrier setVectorUp (surfaceNormal _pos);
    _barrierObjects pushBack _barrier;
};

// Tambahkan beberapa objek suplementer (tenda, generator, kawat)
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
    private _objPos = _spawnPos getPos [_offset select 0, _perpendicularDir + (_offset select 1)];
    private _obj = createVehicle [_type, _objPos, [], 0, "CAN_COLLIDE"];
    _obj setDir (_roadDir + _dirOffset);
    _obj setPosWorld (getPosWorld _obj);
    _obj setVectorUp (surfaceNormal _objPos);
} forEach _extraObjects;

missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _allRoadblockObjects, true];

// ========================================================================
// 4. POOL MUSUH MERC_ENEMY
// ========================================================================
private _gruntPool = (missionNamespace getVariable ["MERC_factions_Vanjager", []]) +
                     (missionNamespace getVariable ["MERC_factions_SF", []]) +
                     (missionNamespace getVariable ["MERC_factions_Mangi", []]);

if (count _gruntPool == 0) exitWith {
    diag_log "MERC ROADBLOCK ERROR: Grunt pool MERC_ENEMY kosong!";
    deleteGroup _missionGroup;
};

// Spawn musuh
private _allUnits = [];
for "_i" from 1 to _aiCount do {
    private _unitPos = _spawnPos getPos [random 40, random 360];
    _unitPos = _unitPos findEmptyPosition [0, 10, selectRandom _gruntPool];
    if (count _unitPos == 0) then { _unitPos = _spawnPos; };
    private _unit = _missionGroup createUnit [selectRandom _gruntPool, _unitPos, [], 0, "NONE"];
    _unit setCombatMode "RED";
    _unit allowFleeing 0;
    _allUnits pushBack _unit;
};

// Patroli kecil di sekitar pos
[_missionGroup, _spawnPos, 50] call BIS_fnc_taskPatrol;

// ========================================================================
// 5. KENDARAAN (PELUANG 15%, TIDAK PAKAI MAJOR KARENA BUKAN USA/RUS)
// ========================================================================
private _vehPool = missionNamespace getVariable ["MERC_vehicles_SF", []];
if (count _vehPool > 0 && random 100 <= 15) then {
    private _vPos = _spawnPos getPos [25, random 360];
    private _vic = createVehicle [selectRandom _vehPool, _vPos, [], 0, "NONE"];
    _vic setDir random 360;
    private _vGrp = createGroup [_missionSide, true];
    private _drv = _vGrp createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
    _drv moveInDriver _vic;
    if (_vic emptyPositions "gunner" > 0) then {
        private _gnr = _vGrp createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
        _gnr moveInGunner _vic;
    };
    [_vGrp, _spawnPos, 50] call BIS_fnc_taskPatrol;
};

// ========================================================================
// 6. MARKER AREA PENCARIAN (150x150m, DIGESER ACAK)
// ========================================================================
private _markerOffset = [30 + random 50, 0, random 360] call BIS_fnc_relPos;
private _markerCenter = _spawnPos vectorAdd _markerOffset;
if (surfaceIsWater _markerCenter) then { _markerCenter = _spawnPos; };

private _rbMarker = createMarker [format ["MERC_RB_%1", time], _markerCenter];
_rbMarker setMarkerShape "ELLIPSE";
_rbMarker setMarkerSize [75, 75];  // diameter 150m
_rbMarker setMarkerColor "ColorRed";
_rbMarker setMarkerAlpha 0.4;
_rbMarker setMarkerBrush "Border";
_rbMarker setMarkerText "Roadblock Area";

// ========================================================================
// 7. PEMANTAUAN: MISI SUKSES JIKA SEMUA MUSUH MATI
// ========================================================================
private _monitorHandle = [_allUnits, _rbMarker] spawn {
    params ["_units", "_marker"];
    private _total = count _units;
    while { {alive _x} count _units > 0 } do {
        sleep 5;
    };
    // Semua mati
    ["MERC_fnc_missionSuccess", ["roadblock", _units select 0]] remoteExec ["call", 2];
    ["<t color='#00FF00' size='1.5'>ROADBLOCK DESTROYED</t>"] remoteExec ["hintSilent", 0];
    { if (markerText _x == "Roadblock Area") then { deleteMarker _x; }; } forEach allMapMarkers;
};

_missionGroup