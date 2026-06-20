/*
    File: InsurgencyFunction\Missions\fn_HVT.sqf
    Description: Misi HVT – Musuh patroli area 100m, HVT di tengah (aman), bangunan tepat tanah.
    Kompatibel dengan GFLHUNTPARADEUSMOD (tanpa CBA).
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. LOGIKA PENENTUAN SIDE MUSUH SECARA SITUASIONAL
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
// 2. SPAWN STRUKTUR BASE (random)
// ========================================================================
private _baseFile = selectRandom [
    "data\compositions\hvt_loc_1.sqf",
    "data\compositions\hvt_loc_2.sqf",
    "data\compositions\hvt_loc_3.sqf"
];
private _objs = call compile preprocessFileLineNumbers _baseFile;
private _spawned = [_spawnPos, random 360, _objs] call BIS_fnc_objectsMapper;

// Pastikan bangunan tepat di permukaan tanah (tidak mengambang/tenggelam)
{
    if (!isNull _x) then {
        _x setPosWorld (getPosWorld _x);
        _x setVectorUp (surfaceNormal getPosWorld _x);
    };
} forEach _spawned;

missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _spawned, true];
// ========================================================================
// 3. ATURAN BOSS & POOL AI
// ========================================================================
private _gruntPool = [];
private _hvt = objNull;

switch (_target) do {
    case "CULT": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
        private _sextans = missionNamespace getVariable ["Sextans_boss", objNull];
        private _niter   = missionNamespace getVariable ["Niter_boss", objNull];

        if (random 100 <= 25 && !isNull _sextans) then {
            _hvt = _missionGroup createUnit [typeOf _sextans, _spawnPos, [], 0, "NONE"];
            _hvt setUnitLoadout (getUnitLoadout _sextans);
        } else {
            if (!isNull _niter) then {
                _hvt = _missionGroup createUnit [typeOf _niter, _spawnPos, [], 0, "NONE"];
                _hvt setUnitLoadout (getUnitLoadout _niter);
            } else {
                private _bossPool = missionNamespace getVariable ["MERC_factions_CULTBOSS", []];
                if (count _bossPool > 0) then {
                    _hvt = _missionGroup createUnit [selectRandom _bossPool, _spawnPos, [], 0, "NONE"];
                };
            };
        };
    };
    case "MERC_ENEMY": {
        _gruntPool = (missionNamespace getVariable ["MERC_factions_Vanjager", []]) +
                     (missionNamespace getVariable ["MERC_factions_SF", []]) +
                     (missionNamespace getVariable ["MERC_factions_Mangi", []]);
    };
    case "USA":    { _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []]; };
    case "RUSSIA": { _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []]; };
};

if (isNull _hvt && count _gruntPool > 0) then {
    _hvt = _missionGroup createUnit [selectRandom _gruntPool, _spawnPos, [], 0, "NONE"];
};

if (isNull _hvt) exitWith {
    diag_log "MERC HVT ERROR: Tidak dapat membuat unit target!";
    deleteGroup _missionGroup;
};

private _safePos = _spawnPos findEmptyPosition [0, 15, typeOf _hvt];
if (count _safePos > 0) then {
    _hvt setPos _safePos;
};

_hvt setVariable ["MERC_is_mission_target", true, true];
_hvt setCombatMode "RED";
_hvt allowFleeing 0;

// ========================================================================
// 4. SPAWN GRUNT (radius 80m dari HQ)
// ========================================================================
if (count _gruntPool > 0) then {
    for "_i" from 1 to (_aiCount - 1) do {
        private _gruntPos = _spawnPos getPos [random 80, random 360];
        _gruntPos = _gruntPos findEmptyPosition [0, 10, selectRandom _gruntPool];
        if (count _gruntPos == 0) then { _gruntPos = _spawnPos; };
        private _grunt = _missionGroup createUnit [selectRandom _gruntPool, _gruntPos, [], 0, "NONE"];
        _grunt setCombatMode "RED";
        _grunt allowFleeing 0;
    };
};

// ========================================================================
// 5. PATROLI SEMUA MUSUH DALAM RADIUS 100M
// ========================================================================
[_missionGroup, _spawnPos, 100] call BIS_fnc_taskPatrol;

// ========================================================================
// 6. ATURAN KENDARAAN PATROLI
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
        if (_vic emptyPositions "gunner" > 0) then {
            private _gnr = _vGrp createUnit [selectRandom _gruntPool, _vPos, [], 0, "NONE"];
            _gnr moveInGunner _vic;
        };
        [_vGrp, _spawnPos, 60] call BIS_fnc_taskPatrol;
    };
};

// ========================================================================
// 7. MARKER AREA PENCARIAN (200x200m, digeser acak)
// ========================================================================
private _markerOffset = [50 + random 60, 0, random 360] call BIS_fnc_relPos;
private _markerCenter = (getPos _hvt) vectorAdd _markerOffset;
if (surfaceIsWater _markerCenter) then { _markerCenter = getPos _hvt; };

private _hvtMarker = createMarker [format ["MERC_HVT_%1", time], _markerCenter];
_hvtMarker setMarkerShape "ELLIPSE";
_hvtMarker setMarkerSize [100, 100];
_hvtMarker setMarkerColor "ColorRed";
_hvtMarker setMarkerAlpha 0.4;
_hvtMarker setMarkerBrush "Border";
_hvtMarker setMarkerText "Search Area";

// ========================================================================
// 8. EVENT HANDLER: HVT MATI = MISI SUKSES
// ========================================================================
_hvt addEventHandler ["Killed", {
    params ["_unit"];
    // Gunakan fungsi misi sukses yang sudah ada di mod Anda
    ["MERC_fnc_missionSuccess", ["hvt", _unit, _this select 1]] remoteExec ["call", 2];

    [format ["<t color='#00FF00' size='1.5'>HVT ELIMINATED</t><br/>%1 has been neutralized.", name _unit]] remoteExec ["hintSilent", 0];
    { if (markerText _x == "Search Area") then { deleteMarker _x; }; } forEach allMapMarkers;
}];

_missionGroup