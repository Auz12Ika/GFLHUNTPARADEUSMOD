/*
    File: InsurgencyFunction\Missions\fn_HVT.sqf
    Description: Misi HVT – Musuh patroli area 100m, HVT di tengah (aman), bangunan tepat tanah.
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. LOGIKA PENENTUAN SIDE MUSUH
// ========================================================================
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
// 2. SPAWN STRUKTUR BASE (pakai BIS_fnc_objectsMapper)
// ========================================================================
private _compArray = selectRandom [
    missionNamespace getVariable ["MERC_comp_hvt", []],
    missionNamespace getVariable ["MERC_comp_hvt2", []],
    missionNamespace getVariable ["MERC_comp_hvt3", []]
];

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
// 3. ATURAN BOSS & POOL AI
// ========================================================================
private _gruntPool = [];
private _hvt = objNull;
private _allTargets = [];

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
    case "MERC_ENEMY_Vanjager": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_Vanjager", []];
    };
    case "MERC_ENEMY_SF": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_SF", []];
    };
    case "MERC_ENEMY_Mangi": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_Mangi", []];
    };
    case "USA":    { _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []]; };
    case "RUSSIA": { _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []]; };
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
private _bossTemplates = [];

// ---------- BOSS ----------
if (_target == "CULT") then {

    private _sextans = missionNamespace getVariable ["Sextans_boss", objNull];
    private _niter   = missionNamespace getVariable ["Niter_boss", objNull];

    private _bossTemplate = objNull;

    if (random 100 <= 25 && {!isNull _sextans}) then {
        _bossTemplate = _sextans;
    } else {
        if (!isNull _niter) then {
            _bossTemplate = _niter;
        };
    };

    if (!isNull _bossTemplate) then {
        _unitsArray pushBack (typeOf _bossTemplate);
        _bossTemplates pushBack _bossTemplate;
    };
};

// ---------- GRUNTS ----------
if (isNil "_aiCount" || {_aiCount <= 0}) then {
    _aiCount = 10;
};

for "_i" from 1 to _aiCount do {
    _unitsArray pushBack (selectRandom _gruntPool);
};

// ========================================================================
// SPAWN GROUP
// ========================================================================
private _groupPos = _spawnPos getPos [random 100, random 360];
_groupPos = [_groupPos, 0, 20, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;

private _missionGroup = [
    _spawnPos,
    _missionSide,
    _unitsArray
] call BIS_fnc_spawnGroup;

{
    private _pos = getPosASL _x;
    private _ground = getTerrainHeightASL [_pos select 0, _pos select 1];
    _x setPosASL [_pos select 0, _pos select 1, _ground + 0.3];
} forEach units _missionGroup;

// ========================================================================
// SETUP UNIT
// ========================================================================

private _bossIndex = 0;

{
    _x setVariable ["MERC_is_barrack_unit", true, true];

    _x setBehaviour "AWARE";
    _x setCombatMode "red";

    _x allowFleeing 0;
    _x addRating 10000;

    if (_forEachIndex < count _bossTemplates) then {

        private _template = _bossTemplates select _bossIndex;

        _x setUnitLoadout (getUnitLoadout _template);
        _x setRank "COLONEL";

        _x setVariable ["MERC_is_cult_boss", true, true];

        _bossIndex = _bossIndex + 1;
    };

    _allTargets pushBack _x;

} forEach units _missionGroup;

// ========================================================================
// PATROL & ALERT SYSTEM
// ========================================================================

// Patrol Area
[_missionGroup, _spawnPos, 300] call BIS_fnc_taskPatrol;

_missionGroup setBehaviour "AWARE";
_missionGroup setCombatMode "YELLOW";

// Tingkatkan kemampuan deteksi
{
    _x setSkill ["spotDistance",1];
    _x setSkill ["spotTime",1];
} forEach units _missionGroup;


// ========================================================================
// HIT EVENT
// ========================================================================

{
    _x addEventHandler ["Hit", {

        params ["_unit","","","_instigator"];

        private _grp = group _unit;

        if (_grp getVariable ["MERC_alert",false]) exitWith {};

        _grp setVariable ["MERC_alert",true];

        _grp setBehaviour "COMBAT";
        _grp setCombatMode "RED";

        while {count waypoints _grp > 0} do {
            deleteWaypoint [_grp,0];
        };

        private _wp = _grp addWaypoint [getPos _instigator,0];
        _wp setWaypointType "SAD";

    }];

} forEach units _missionGroup;


// ========================================================================
// ENEMY DETECTION
// ========================================================================

[_missionGroup] spawn {

    params ["_grp"];

    while {{alive _x} count units _grp > 0} do {

        if !(_grp getVariable ["MERC_alert",false]) then {

            {
                private _enemy = _x findNearestEnemy _x;

                if (!isNull _enemy) exitWith {

                    _grp setVariable ["MERC_alert",true];

                    _grp setBehaviour "COMBAT";
                    _grp setCombatMode "RED";

                    while {count waypoints _grp > 0} do {
                        deleteWaypoint [_grp,0];
                    };

                    _grp reveal [_enemy,4];

                    private _wp = _grp addWaypoint [getPos _enemy,0];
                    _wp setWaypointType "SAD";

                };

            } forEach units _grp;

        };

        sleep 2;

    };

};
// ========================================================================
// 5. KENDARAAN PATROLI (CARA TRIGGER - TANPA BIS_fnc_forceSpeed)
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
    default                      { _vehPool = []; };
};

if (count _vehPool > 0) then {
    _vehCount = if (_isMajor) then { 2 } else { if (random 100 <= 15) then { 1 } else { 0 } };
    for "_v" from 1 to _vehCount do {
        private _vPos = _spawnPos getPos [45 + (_v*5), random 360];
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
        };
        // -------------------------------------
        
        // Buat awak untuk kendaraan (jika belum ada)
        if (count (crew _vic) == 0) then {
            createVehicleCrew _vic;
        };
        (crew _vic) joinSilent _missionGroup;
        
        // Tambahkan semua awak ke _allTargets
        {
            _x setVariable ["MERC_is_mission_target", true, true];
            _x setCombatMode "RED";
            _x allowFleeing 0;
            _x addRating 10000;
            _allTargets pushBack _x;
        } forEach (crew _vic);
        
        // ---- PATROLI KHUSUS UNTUK PESAWAT ----
        if (_vic isKindOf "Air") then {
            // Buat group terpisah untuk pesawat agar tidak terpengaruh patroli darat
            private _airGroup = createGroup [_missionSide, true];
            (crew _vic) joinSilent _airGroup;
            // Hapus waypoint default
            while {count waypoints _airGroup > 0} do { deleteWaypoint [_airGroup, 0]; };
            // Patroli di udara mengcover area HVT
            [_airGroup, _spawnPos, 300] call BIS_fnc_taskPatrol;
            _airGroup setBehaviour "AWARE";
            _airGroup setCombatMode "RED";
            // Simpan group ini untuk cleanup nanti
            missionNamespace setVariable [format ["MERC_air_group_%1", _id], _airGroup, true];
        };
    };
};


// Patroli untuk seluruh group (kendaraan darat dan infanteri)
// Sudah ada di bagian 4: [_missionGroup, _spawnPos, 100] call BIS_fnc_taskPatrol;
// Kita biarkan saja, pesawat sudah di-group terpisah dan patroli sendiri.

// ========================================================================
// SIMPAN SEMUA TARGET UNTUK REFERENSI (biar cleanup berfungsi)
// ========================================================================
private _hvt = objNull;

if (count _allTargets > 0) then {
    _hvt = selectRandom _allTargets;
};

missionNamespace setVariable [format ["MERC_targets_%1", _id], _allTargets, true];

// ========================================================================
// 6. MARKER AREA PENCARIAN (ukuran dinamis)
// ========================================================================
private _centerPos = _spawnPos;
private _markerSizeX = 150;
private _markerSizeY = 150;

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

private _hvtMarker = createMarker [format ["MERC_HVT_%1", time], _centerPos];
_hvtMarker setMarkerShape "ELLIPSE";
_hvtMarker setMarkerSize [_markerSizeX, _markerSizeY];
_hvtMarker setMarkerColor "ColorRed";
_hvtMarker setMarkerAlpha 0.4;
_hvtMarker setMarkerBrush "Border";
_hvtMarker setMarkerText "Search Area";

// ========================================================================
// 7. EVENT HANDLER: HVT MATI = MISI SUKSES
// ========================================================================
if (!isNull _hvt) then {

    _hvt addEventHandler ["Killed", {
        params ["_unit", "_killer"];

        private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];

        if (count _contract > 0) then {
            _contract params ["", "", "", "", "_rewardRange", "_repReward", "_giver", "_target"];
            private _reward = (_rewardRange select 0) + round random ((_rewardRange select 1) - (_rewardRange select 0));
            ["hvt", _unit, _giver, _reward, _repReward] call MERC_fnc_missionSuccess;
        };

        { if (markerText _x == "Search Area") then { deleteMarker _x; }; } forEach allMapMarkers;
    }];

};