/*
    File: InsurgencyFunction\Missions\Convoy.sqf
    Description: Misi Konvoi Patroli – Konvoi musuh berputar antar kota.
                 Faksi: USA, RUSSIA, MERC_ENEMY (CULT dihapus).
                 USA & Russia dapat menyewa Merc (persentase kecil).
                 Sukses jika truk kargo hancur. Gagal jika waktu habis.
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
    default            { _missionSide = east; };
};
private _missionGroup = createGroup [_missionSide, true];

// ========================================================================
// 2. POOL KENDARAAN & GRUNT (CULT DIHAPUS, MERC DITAMBAHKAN)
// ========================================================================
private _cargoTruckClass = "";
private _escortVehPool = [];
private _gruntPool = [];

// Pool Mercenary global (bisa disewa faksi mayor)
private _mercGruntPool = (missionNamespace getVariable ["MERC_factions_Vanjager", []]) +
                         (missionNamespace getVariable ["MERC_factions_SF", []]) +
                         (missionNamespace getVariable ["MERC_factions_Mangi", []]);

switch (_target) do {
    case "USA": {
        _cargoTruckClass = "rhsusf_M1078A1R_A_fmtv_wd";
        _escortVehPool = missionNamespace getVariable ["MERC_vehicles_USA", []];
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
        // USA bisa sewa Merc (20% kemungkinan unit Merc muncul)
        if (count _mercGruntPool > 0) then {
            _gruntPool = _gruntPool + _mercGruntPool;
            diag_log "MERC CONVOY: USA menggunakan tentara bayaran tambahan.";
        };
    };
    case "RUSSIA": {
        _cargoTruckClass = "rhs_typhoon_vdv";
        _escortVehPool = missionNamespace getVariable ["MERC_vehicles_RUS", []];
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
        // Russia bisa sewa Merc (20% kemungkinan unit Merc muncul)
        if (count _mercGruntPool > 0) then {
            _gruntPool = _gruntPool + _mercGruntPool;
            diag_log "MERC CONVOY: Russia menggunakan tentara bayaran tambahan.";
        };
    };
    case "MERC_ENEMY": {
        _cargoTruckClass = selectRandom ["RHS_Ural_Civ_03", "rhs_typhoon_vdv"];
        _escortVehPool = missionNamespace getVariable ["MERC_vehicles_SF", []];
        _gruntPool = _mercGruntPool;   // Murni Merc
    };
};

// ========================================================================
// 3. TENTUKAN KOTA YANG DILEWATI (4-6 KOTA) → LOOP
// ========================================================================
private _northernCities = [
    [13243, 3254, 0], [11687, 3196, 0], [10854, 2763, 0],
    [10007, 4128, 0], [11739, 5365, 0]
];
private _southernCities = [
    [6803, 10767, 0], [6047, 8836, 0], [7784, 9801, 0],
    [5192, 9296, 0], [8248, 12255, 0]
];

private _cityPool = [];
if (_target == "USA") then { _cityPool = _northernCities; }
else { if (_target == "RUSSIA") then { _cityPool = _southernCities; } else { _cityPool = _northernCities + _southernCities; }; };

private _numCities = 4 + floor random 3;
private _selectedCities = [];
for "_i" from 1 to _numCities do {
    private _city = selectRandom _cityPool;
    _selectedCities pushBack _city;
    _cityPool = _cityPool - [_city];
    if (count _cityPool == 0) then { _cityPool = _northernCities + _southernCities; };
};

_startPos = (_selectedCities select 0) findEmptyPosition [0, 50, _cargoTruckClass];
if (count _startPos == 0) then { _startPos = _selectedCities select 0; };

// ========================================================================
// 4. SPAWN KENDARAAN KONVOI
// ========================================================================
private _allVehicles = [];

// Truk kargo
private _truck = createVehicle [_cargoTruckClass, _startPos, [], 0, "NONE"];
_truck setDir random 360;
_truck setVariable ["MERC_is_mission_target", true, true];
_allVehicles pushBack _truck;

if (count _gruntPool > 0) then {
    private _driver = _missionGroup createUnit [selectRandom _gruntPool, _startPos, [], 0, "NONE"];
    _driver moveInDriver _truck;
};

// Kendaraan escort (0-2)
private _escortCount = switch (toUpper _difficulty) do { case "EASY": {0}; case "MEDIUM": {1}; default {2}; };
if (count _escortVehPool > 0) then {
    for "_v" from 1 to _escortCount do {
        private _escortPos = _startPos getPos [15 * _v, random 360];
        private _escort = createVehicle [selectRandom _escortVehPool, _escortPos, [], 0, "NONE"];
        _escort setDir (random 360);
        createVehicleCrew _escort;
        (crew _escort) joinSilent _missionGroup;
        _allVehicles pushBack _escort;
    };
};

// ========================================================================
// 5. SPAWN INFANTERI PENGIRING (JUMLAH AI DARI SERVER)
// ========================================================================
if (isNil "_aiCount" || {_aiCount <= 0}) then { _aiCount = 16; };
if (count _gruntPool > 0) then {
    for "_i" from 1 to _aiCount do {
        private _pos = _startPos getPos [random 30, random 360];
        private _unit = _missionGroup createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
        _unit setCombatMode "RED";
        _unit allowFleeing 0;
    };
};

// ========================================================================
// 6. WAYPOINT LOOP ANTAR KOTA
// ========================================================================
{
    private _wp = _missionGroup addWaypoint [_x, 0];
    if (_foreachIndex == 0) then {
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointFormation "COLUMN";
        _wp setWaypointCompletionRadius 30;
    } else {
        _wp setWaypointType "SAD";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointCompletionRadius 50;
    };
} forEach _selectedCities;

private _wpLoop = _missionGroup addWaypoint [_startPos, 0];
_wpLoop setWaypointType "CYCLE";

// ========================================================================
// 7. MARKER
// ========================================================================
private _centerX = 0; private _centerY = 0;
{ _centerX = _centerX + (_x select 0); _centerY = _centerY + (_x select 1); } forEach _selectedCities;
_centerX = _centerX / count _selectedCities;
_centerY = _centerY / count _selectedCities;
private _maxRadius = 200;
{ _maxRadius = _maxRadius max (_x distance [_centerX, _centerY]); } forEach _selectedCities;

private _patrolMarker = createMarker [format ["MERC_Convoy_%1", time], [_centerX, _centerY]];
_patrolMarker setMarkerShape "ELLIPSE";
_patrolMarker setMarkerSize [_maxRadius, _maxRadius];
_patrolMarker setMarkerColor "ColorOrange";
_patrolMarker setMarkerAlpha 0.3;
_patrolMarker setMarkerBrush "Border";
_patrolMarker setMarkerText "Convoy Patrol";

private _startMarker = createMarker [format ["%1_start", _patrolMarker], _startPos];
_startMarker setMarkerType "mil_warning";
_startMarker setMarkerColor "ColorRed";
_startMarker setMarkerText "Convoy Last Seen";

// ========================================================================
// 8. SELF-DESTRUCT
// ========================================================================
// ========================================================================
// 8. TANDAI KENDARAAN BISA DIAMBIL ALIH & SIMPAN HANYA UNIT UNTUK SELF-DESTRUCT
// ========================================================================
// Tandai truk sebagai bisa diambil alih
_truck setVariable ["MERC_vehicle_claimable", true, true];
_truck setVariable ["MERC_vehicle_origin", _id, true];   // Asal misi

// Tandai escort
{
    if (_x isKindOf "LandVehicle") then {
        _x setVariable ["MERC_vehicle_claimable", true, true];
        _x setVariable ["MERC_vehicle_origin", _id, true];
    };
} forEach _allVehicles;

// Simpan hanya unit/manusia untuk self-destruct, bukan kendaraan
private _unitsOnly = [];
{ _unitsOnly pushBack _x; } forEach (units _missionGroup);
missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _unitsOnly, true];

// Broadcast info ke pemain
[format ["<t color='#FFA500'>CONVOY VEHICLES</t><br/>Destroyed convoy vehicles can be claimed for your use!"]] remoteExec ["hintSilent", 0];
// ========================================================================
// 9. MONITOR SUKSES/GAGAL
// ========================================================================
private _timeLimit = _missionData select 3;
[_truck, _timeLimit, _id, _patrolMarker, _startMarker] spawn {
    params ["_truck", "_timeLimit", "_id", "_patrolMarker", "_startMarker"];
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

_missionGroup