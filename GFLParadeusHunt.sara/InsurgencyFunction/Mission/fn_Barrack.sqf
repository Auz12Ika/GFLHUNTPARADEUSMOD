/*
    File: InsurgencyFunction\Missions\Barrack.sqf
    Description: Misi Barrack – Bunuh semua musuh (dengan boss untuk CULT).
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
                     (missionNamespace getVariable ["MERC_factions_SF", []]) +
                     (missionNamespace getVariable ["MERC_factions_Mangi", []]);
    };
};

// Fallback jika gruntPool kosong
if (count _gruntPool == 0) then {
    _gruntPool = ["B_Soldier_F"];
    diag_log "[MERC] WARNING: gruntPool empty, using fallback";
};

// ========================================================================
// 4. SPAWN BOSS (KHUSUS CULT) & GRUNTS (SEMUA SATU GROUP) - DEFEND BASE
// ========================================================================
private _allTargets = [];

// --- Buat group jika belum ada ---
if (isNil "_missionGroup" || {isNull _missionGroup}) then {
    private _side = switch (_target) do {
        case "CULT": { west };
        case "USA":  { west };
        case "RUSSIA": { east };
        case "MERC_ENEMY": { independent };
        default { east };
    };
    _missionGroup = createGroup [_side, true];
};

// --- SPAWN BOSS (CULT) ---
private _boss = objNull;
if (_target == "CULT") then {
    private _sextans = missionNamespace getVariable ["Sextans_boss", objNull];
    private _niter   = missionNamespace getVariable ["Niter_boss", objNull];

    if (random 100 <= 25 && !isNull _sextans) then {
        _boss = _missionGroup createUnit [typeOf _sextans, _spawnPos, [], 0, "NONE"];
        _boss setUnitLoadout (getUnitLoadout _sextans);
    } else {
        if (!isNull _niter) then {
            _boss = _missionGroup createUnit [typeOf _niter, _spawnPos, [], 0, "NONE"];
            _boss setUnitLoadout (getUnitLoadout _niter);
        } else {
            private _bossPool = missionNamespace getVariable ["MERC_factions_CULTBOSS", []];
            if (count _bossPool > 0) then {
                _boss = _missionGroup createUnit [selectRandom _bossPool, _spawnPos, [], 0, "NONE"];
            };
        };
    };

    if (!isNull _boss) then {
        _boss setRank "COLONEL";
        _boss setVariable ["MERC_is_barrack_unit", true, true];
        _boss setCombatMode "YELLOW";   // 🔥 Ubah ke YELLOW agar tidak terlalu agresif
        _boss allowFleeing 0;
        _boss addRating 10000;
        _allTargets pushBack _boss;

        // Terapkan fn_cultBrain jika ada (dengan filter side yang sudah diperbaiki)
        if (!isNil "fn_cultBrain") then {
            [_boss] call fn_cultBrain;
        };
    };
};

// --- SPAWN GRUNTS ---
if (isNil "_aiCount" || {_aiCount <= 0}) then { _aiCount = 10; };
for "_i" from 1 to _aiCount do {
    private _pos = _spawnPos getPos [random 40, random 360];
    private _empty = _pos findEmptyPosition [0, 10, selectRandom _gruntPool];
    if (count _empty > 0) then { _pos = _empty; };
    private _unit = _missionGroup createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
    _unit setVariable ["MERC_is_barrack_unit", true, true];
    _unit setCombatMode "YELLOW";   // 🔥 Ubah ke YELLOW
    _unit allowFleeing 0;
    _unit addRating 10000;
    _allTargets pushBack _unit;
};

// --- DEFEND BASE ---
[_missionGroup, _spawnPos, 50] call BIS_fnc_taskDefend;
_missionGroup setBehaviour "AWARE";
_missionGroup setCombatMode "YELLOW";
// ========================================================================
// 5. KENDARAAN STATIS (PARKIR) + PESAWAT PATROLI
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
            _x setCombatMode "YELLOW";
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
            _airGroup setCombatMode "YELLOW";
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
    
    private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];
    if (count _contract > 0) then {
        _contract params ["", "", "", "", "_rewardRange", "_repReward", "_giver", "_target"];
        private _reward = (_rewardRange select 0) + round random ((_rewardRange select 1) - (_rewardRange select 0));
        ["barrack", _targets select 0, _giver, _reward, _repReward] call MERC_fnc_missionSuccess;
    } else {
        ["barrack", _targets select 0] call MERC_fnc_missionSuccess;
    };
    
    deleteMarker _marker;
};

_missionGroup;