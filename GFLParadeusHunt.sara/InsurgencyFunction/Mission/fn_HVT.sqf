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
    };
    case "MERC_ENEMY_Vanjager": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_Vanjager", []];
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

private _spawnGroup = [
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
    _x setCombatMode "RED";

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

} forEach units _spawnGroup;

// ========================================================================
// ROLE, POSITION, PATROL & ALERT SYSTEM
// ========================================================================

// HVT: 1 Commando, 1 Guard, 1 Assault, sisanya Recon.
// Randomness hanya menentukan unit mana yang mendapat role.
private _infantryTargets = units _spawnGroup;
private _hvtCandidates = _infantryTargets select { alive _x && (vehicle _x == _x) };

if (count _hvtCandidates > 0) then {
    if (_target == "CULT") then {
        _hvt = _hvtCandidates select 0;
    } else {
        _hvt = selectRandom _hvtCandidates;
    };
};

if (!isNull _hvt) then {
    _hvt setVariable ["MERC_is_hvt", true, true];
    _hvt setVariable ["MERC_is_mission_target", true, true];
	_hvt setVariable ["MERC_taskID", _id];
};

// Buat group role terpisah.
private _commandoGroup = createGroup [_missionSide, true];
private _guardGroup = createGroup [_missionSide, true];
private _assaultGroup = createGroup [_missionSide, true];
private _reconGroup = createGroup [_missionSide, true];

// Commando = HVT/Commander.
if (!isNull _hvt) then {
    [_hvt] joinSilent _commandoGroup;
    _commandoGroup selectLeader _hvt;
    _hvt disableAI "PATH";
};

// Unit lain diacak sebelum dibagi ke role.
private _rolePool = +_infantryTargets;
if (!isNull _hvt) then {
    private _hvtIndex = _rolePool find _hvt;
    if (_hvtIndex >= 0) then {
        _rolePool deleteAt _hvtIndex;
    };
};
_rolePool = _rolePool call BIS_fnc_arrayShuffle;

// Guard: maksimal 1.
if (count _rolePool > 0) then {
    private _unit = _rolePool deleteAt 0;
    [_unit] joinSilent _guardGroup;
};

// Assault: maksimal 1.
if (count _rolePool > 0) then {
    private _unit = _rolePool deleteAt 0;
    [_unit] joinSilent _assaultGroup;
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

// Tempatkan unit dalam building/tower random.
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
private _commandoBuilding = objNull;

if (!isNull _hvt && {count _enterableBuildings > 0}) then {
    _commandoBuilding = selectRandom _enterableBuildings;
    _hvt setPosATL (getPosATL _commandoBuilding);
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
    private _pos = [_hvt, 15] call _randomRadiusPos;
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
// Mereka tidak diberi patrol radius biasa.
// ========================================================================
if (!isNull _hvt && {count units _guardGroup > 0}) then {

    private _guardCenter = getPosATL _hvt;
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
// Recon  = 350m
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
} forEach (_infantryTargets);

// ========================================================================
// ALERT SYSTEM
//
// Recon / Guard melihat musuh:
//     -> Assault diberi target dan path menuju player.
//
// Guard:
//     -> tetap melindungi Commando.
//
// Commando:
//     -> PATH OFF selama Guard masih hidup.
//     -> PATH ON setelah semua Guard mati.
// ========================================================================

private _alertGroups = [_reconGroup, _guardGroup];

{
    private _grp = _x;

    [_grp, _assaultGroup, _commandoGroup, _hvt] spawn {
        params ["_grp", "_assaultGroup", "_commandoGroup", "_hvt"];

        while {{alive _x} count units _grp > 0} do {

            {
                if (alive _x) then {

                    private _enemy = _x findNearestEnemy _x;

                    if (!isNull _enemy && {alive _enemy}) then {

                        // Simpan target untuk seluruh mission.
                        _grp setVariable ["MERC_alert", true, true];
                        _grp setVariable ["MERC_alertTarget", _enemy, true];

                        // ==================================================
                        // ASSAULT REACTION
                        // ==================================================
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

                        // ==================================================
                        // GUARD tetap combat tetapi tidak meninggalkan
                        // area Commando.
                        // ==================================================
                        if (_grp == group _hvt) then {
                            _grp setBehaviour "COMBAT";
                            _grp setCombatMode "RED";
                        };

                    };
                };

            } forEach units _grp;

            sleep 2;
        };
    };

} forEach _alertGroups;

// ========================================================================
// COMMANDO UNLOCK
// Commando hanya bergerak setelah Guard benar-benar habis.
// ========================================================================
if (!isNull _hvt) then {

    [_hvt, _guardGroup] spawn {
        params ["_hvt", "_guardGroup"];

        waitUntil {
            sleep 2;
            !alive _hvt || {({alive _x} count units _guardGroup) == 0}
        };

        if (alive _hvt) then {
            _hvt enableAI "PATH";

            private _grp = group _hvt;
            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
        };
    };
};

// ========================================================================
// GUARD / RECON ALERT MONITOR
// Jika target hilang/mati, Assault kembali ke patrol normal.
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
// 5. KENDARAAN PATROLI (CARA TRIGGER - TANPA BIS_fnc_forceSpeed)
// ========================================================================
private _vehPool = [];
private _vehCount = 0;
private _isMajor = false;

switch (_target) do {
    case "CULT":                 { _vehPool = missionNamespace getVariable ["MERC_vehicles_CULT", []]; };
    case "MERC_ENEMY_Vanjager":  { _vehPool = missionNamespace getVariable ["MERC_vehicles_Vanjager", []]; };
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


// Infanteri sudah dipisah ke Commando / Guard / Assault / Recon.
// Kendaraan darat tetap menggunakan _missionGroup, pesawat menggunakan _airGroup.

// ========================================================================
// SIMPAN SEMUA TARGET UNTUK REFERENSI (biar cleanup berfungsi)
// ========================================================================
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
_hvtMarker setMarkerColor "ColorRED";
_hvtMarker setMarkerAlpha 0.4;
_hvtMarker setMarkerBrush "Border";
_hvtMarker setMarkerText "Search Area";

// ========================================================================
// 7. EVENT HANDLER: HVT MATI = MISI SUKSES
// ========================================================================
if (!isNull _hvt) then {
	_hvt addEventHandler ["Killed", {
		params ["_unit", "_killer"];

		private _id = _unit getVariable ["MERC_taskID", ""];

		private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];

		if (count _contract > 0) then {
			_contract params ["", "", "", "", "_rewardRange", "_repReward", "_giver", "_target"];
			private _reward = (_rewardRange select 0) + round random ((_rewardRange select 1) - (_rewardRange select 0));
			["hvt", _unit, _giver, _reward, _repReward] call MERC_fnc_missionSuccess;
		};

		if (_id != "") then {
			[format ["MERC_%1", _id], true] call BIS_fnc_deleteTask;
		};

		{ 
			if (markerText _x == "Search Area") then { 
				deleteMarker _x; 
			}; 
		} forEach allMapMarkers;
	}];

};