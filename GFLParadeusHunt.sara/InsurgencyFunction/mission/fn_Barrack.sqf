/*
    File: InsurgencyFunction\Missions\Barrack.sqf
    Description: Misi Barrack – Bunuh semua musuh. USA→barrack_1, RUS→barrack_2, CULT→cult_barrack_1.
    Setelah sukses, server akan menghapus base setelah 1 menit (self‑destruct terpusat).
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
    case "MERC_ENEMY": { _missionSide = east; };
    case "CULT": {
        if (_giver in ["RU", "RUSSIA"]) then { _missionSide = west; }
        else { if (_giver in ["US", "USA"]) then { _missionSide = east; }; };
    };
};
private _missionGroup = createGroup [_missionSide, true];

// ========================================================================
// 2. KOMPOSISI BARACK (sesuai faksi)
// ========================================================================
private _sqeFile = "";
switch (_target) do {
    case "USA":    { _sqeFile = "data\compositions\barrack_1.sqf"; };
    case "RUSSIA": { _sqeFile = "data\compositions\barrack_2.sqf"; };
    case "CULT":   { _sqeFile = "data\compositions\cult_barrack_1.sqf"; };
    default        { _sqeFile = "data\compositions\barrack_1.sqf"; }; // MERC_ENEMY fallback
};

private _objs = call compile preprocessFileLineNumbers _sqeFile;
private _spawnedStructures = [_spawnPos, random 360, _objs] call BIS_fnc_objectsMapper;

// Pastikan semua bangunan tepat di permukaan tanah
{
    if (!isNull _x) then {
        _x setPosWorld (getPosWorld _x);
        _x setVectorUp (surfaceNormal getPosWorld _x);
    };
} forEach _spawnedStructures;

// 💾 Simpan referensi objek untuk self‑destruct 1 menit setelah misi sukses
missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _spawnedStructures, true];

// ========================================================================
// 3. POOL GRUNT & BOSS
// ========================================================================
private _gruntPool = [];
private _bossArray = [];

switch (_target) do {
    case "CULT": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
        private _sextans = missionNamespace getVariable ["Sextans_boss", objNull];
        private _niter   = missionNamespace getVariable ["Niter_boss", objNull];
        if (!isNull _sextans) then { _bossArray pushBack _sextans; };
        if (!isNull _niter)   then { _bossArray pushBack _niter; };
    };
    case "USA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
    };
    case "RUSSIA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
    };
    case "MERC_ENEMY": {
        _gruntPool = (missionNamespace getVariable ["MERC_factions_Vanjager", []]) +
                     (missionNamespace getVariable ["MERC_factions_SF", []]) +
                     (missionNamespace getVariable ["MERC_factions_Mangi", []]);
    };
};

// ========================================================================
// 4. SPAWN BOSS & GRUNT (semua bertanda wajib bunuh)
// ========================================================================
private _allTargets = [];

// Boss (Cult: dua boss dari editor, lainnya: 1 random dari grunt pool)
if (count _bossArray > 0) then {
    {
        private _boss = _missionGroup createUnit [typeOf _x, _spawnPos getPos [random 15, random 360], [], 0, "NONE"];
        _boss setUnitLoadout (getUnitLoadout _x);
        _boss setVariable ["MERC_is_mission_target", true, true];
        _boss setCombatMode "RED";
        _boss allowFleeing 0;
        _allTargets pushBack _boss;
    } forEach _bossArray;
} else {
    if (count _gruntPool > 0) then {
        private _boss = _missionGroup createUnit [selectRandom _gruntPool, _spawnPos getPos [random 15, random 360], [], 0, "NONE"];
        _boss setVariable ["MERC_is_mission_target", true, true];
        _boss setCombatMode "RED";
        _boss allowFleeing 0;
        _allTargets pushBack _boss;
    };
};

// Grunt
if (isNil "_aiCount" || {_aiCount <= 0}) then { _aiCount = 15; };
if (count _gruntPool > 0) then {
    for "_i" from 1 to _aiCount do {
        private _pos = _spawnPos getPos [random 60, random 360];
        _pos = _pos findEmptyPosition [0, 10, selectRandom _gruntPool];
        if (count _pos == 0) then { _pos = _spawnPos; };
        private _unit = _missionGroup createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
        _unit setVariable ["MERC_is_mission_target", true, true];
        _unit setCombatMode "RED";
        _unit allowFleeing 0;
        _allTargets pushBack _unit;
    };
};

[_missionGroup, _spawnPos, 120] call BIS_fnc_taskPatrol;

// ========================================================================
// 5. KENDARAAN PATROLI
// ========================================================================
private _vehPool = [];
private _vehCount = 0;
private _isMajor = false;
switch (_target) do {
    case "CULT":       { _vehPool = missionNamespace getVariable ["MERC_vehicles_CULT", []]; };
    case "MERC_ENEMY": { _vehPool = missionNamespace getVariable ["MERC_vehicles_SF", []]; };
    case "USA":        { _vehPool = missionNamespace getVariable ["MERC_vehicles_USA", []]; _isMajor = true; };
    case "RUSSIA":     { _vehPool = missionNamespace getVariable ["MERC_vehicles_RUS", []]; _isMajor = true; };
};

if (count _vehPool > 0) then {
    _vehCount = if (_isMajor) then { 2 } else { if (random 100 <= 15) then { 1 } else { 0 } };
    for "_v" from 1 to _vehCount do {
        private _vPos = _spawnPos getPos [45 + (_v*5), random 360];
        private _vic = createVehicle [selectRandom _vehPool, _vPos, [], 0, "NONE"];
        _vic setDir random 360;
        private _vGrp = createGroup [_missionSide, true];
        private _drv = _vGrp createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
        _drv moveInDriver _vic;
        _drv setVariable ["MERC_is_mission_target", true, true];
        _allTargets pushBack _drv;
        if (_vic emptyPositions "gunner" > 0) then {
            private _gnr = _vGrp createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
            _gnr moveInGunner _vic;
            _gnr setVariable ["MERC_is_mission_target", true, true];
            _allTargets pushBack _gnr;
        };
        [_vGrp, _spawnPos, 60] call BIS_fnc_taskPatrol;
    };
};

// ========================================================================
// 6. MARKER AREA
// ========================================================================
private _markerSize = 100;
switch (toUpper _difficulty) do {
    case "EASY":   { _markerSize = 75; };
    case "MEDIUM": { _markerSize = 100; };
    case "HARD":   { _markerSize = 125; };
};

private _mrkOffset = [20 + random 40, 0, random 360] call BIS_fnc_relPos;
private _mrkCenter = _spawnPos vectorAdd _mrkOffset;
if (surfaceIsWater _mrkCenter) then { _mrkCenter = _spawnPos; };

private _barrackMarker = createMarker [format ["MERC_Barrack_%1", time], _mrkCenter];
_barrackMarker setMarkerShape "ELLIPSE";
_barrackMarker setMarkerSize [_markerSize, _markerSize];
_barrackMarker setMarkerColor "ColorRed";
_barrackMarker setMarkerAlpha 0.4;
_barrackMarker setMarkerBrush "Border";
_barrackMarker setMarkerText "Barrack AO";

// ========================================================================
// 7. MONITOR – SEMUA TARGET MATI → SUKSES
// ========================================================================
[_allTargets, _id, _barrackMarker] spawn {
    params ["_targets", "_id", "_marker"];
    waitUntil { sleep 5; { alive _x } count _targets == 0 };

    // Kirim event sukses ke server (fungsi yang sudah ada)
    ["MERC_fnc_missionSuccess", ["barrack", _targets select 0]] remoteExec ["call", 2];

    // Hapus marker area
    { if (markerText _x == "Barrack AO") then { deleteMarker _x; }; } forEach allMapMarkers;
};

_missionGroup