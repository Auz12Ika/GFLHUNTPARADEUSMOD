/*
    File: InsurgencyFunction\Missions\fn_cultMainMission.sqf
    Description: Misi Utama Cult – Hancurkan AO Cult sebanyak 7 kali.
                 Progress disimpan di MERC_cult_progress.
*/

params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "", "", "_giver", "_target"];

// ========================================================================
// 1. CEK PROGRESS & INISIALISASI
// ========================================================================
private _progress = missionNamespace getVariable ["MERC_cult_progress", 0];
if (_progress >= 7) exitWith {
    diag_log "[MERC] Cult campaign already completed!";
    [parseText "<t color='#00FF00'>Cult campaign completed!</t>"] remoteExec ["hint", 0];
};

// ========================================================================
// 2. TENTUKAN JUMLAH HQ PALSU & SPAWN STRUKTUR
// ========================================================================
// SPAWN KOMPOSISI Cult HQ
private _compArray = missionNamespace getVariable ["MERC_comp_Cult_HQ", []];
if (count _compArray == 0) then {
    diag_log "[MERC] WARNING: MERC_comp_Cult_HQ not found or empty!";
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
// 3. SPAWN AO STRUKTUR (HQ + BANGUNAN)
// ========================================================================
private _fakeHQCount = 0;
if (_progress >= 3 && _progress < 6) then { _fakeHQCount = 1; };
if (_progress >= 6) then { _fakeHQCount = 2; };
private _totalHQ = 1 + _fakeHQCount;

diag_log format ["[MERC] Cult Mission #%1: Spawning %2 HQ (fake: %3)", _progress+1, _totalHQ, _fakeHQCount];

private _allTargets = [];
private _allVehicles = [];
private _hqObjects = [];
private _hqReal = objNull;

// Fungsi untuk spawn HQ
private _fnc_spawnHQ = {
    params ["_pos", "_isReal"];
    // Pastikan posisi 3D
    if (count _pos < 3) then { _pos set [2, 0]; };
    private _hq = createVehicle ["Land_Cargo_HQ_V1_F", _pos, [], 0, "NONE"];
    _hq setDir random 360;
    _hq setPos _pos;  // ← setPos (bukan setPosATL) agar menerima array 2D/3D
    _hq setVectorUp (surfaceNormal _pos);
    _hq setVariable ["MERC_is_cult_hq", true, true];
    if (_isReal) then { _hq setVariable ["MERC_hq_real", true, true]; };
    _hqObjects pushBack _hq;
    _allTargets pushBack _hq;
    _hq
};

// Spawn HQ asli di posisi spawn
_hqReal = [_spawnPos, true] call _fnc_spawnHQ;

// Spawn HQ palsu di sekitar (jarak ~150m)
private _fakePositions = [];
for "_i" from 1 to _fakeHQCount do {
    private _angle = random 360;
    private _dist = 500 + random 50;
    private _pos = _spawnPos getPos [_dist, _angle];
    // Cari posisi darat
    private _safePos = [_pos, 0, 30, 5, 0, 20, 0] call BIS_fnc_findSafePos;
    if (count _safePos > 0 && !surfaceIsWater _safePos) then { _pos = _safePos; };
    [_pos, false] call _fnc_spawnHQ;
    _fakePositions pushBack _pos;
};

// Tambahkan beberapa bangunan pelengkap (opsional)
private _extraBuildings = [
    "Land_HBarrier_Big_F", "Land_HBarrier_5_F", "Land_CzechHedgehog_01_F"
];
for "_i" from 1 to 10 do {
    private _pos = _spawnPos getPos [random 150, random 360];
    private _bld = createVehicle [selectRandom _extraBuildings, _pos, [], 0, "NONE"];
    _bld setDir random 360;
    _bld setPosATL _pos;
    _bld setVectorUp (surfaceNormal _pos);
    _allTargets pushBack _bld;
};

// ========================================================================
// 4. SPAWN BOSS & GRUNT (BIS_fnc_spawnGroup)
// ========================================================================

private _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
if (count _gruntPool == 0) then {
    _gruntPool = ["GFL_Unitas_015"];
};

// ========================================================================
// BOSS
// ========================================================================

private _bossClasses = ["Niter_boss","Sextans_boss"];
private _bossArray = [];
private _bossTemplates = [];

{
    private _bossTemplate = missionNamespace getVariable [_x,objNull];

    if (!isNull _bossTemplate) then {
        _bossArray pushBack (typeOf _bossTemplate);
        _bossTemplates pushBack _bossTemplate;
    };

} forEach _bossClasses;

private _bossGroup = [
    _spawnPos,
    west,
    _bossArray
] call BIS_fnc_spawnGroup;

private _bosses = [];

{
    private _bossTemplate = _bossTemplates select _forEachIndex;

    _x setUnitLoadout (getUnitLoadout _bossTemplate);

    _x setRank "COLONEL";
    _x setBehaviour "AWARE";
    _x setCombatMode "YELLOW";
    _x allowFleeing 0;
    _x addRating 10000;

    _x setVariable ["MERC_is_cult_boss",true,true];
    _x setVariable ["MERC_is_mission_target",true,true];

    _allTargets pushBack _x;
    _bosses pushBack _x;

} forEach units _bossGroup;



// ========================================================================
// GRUNTS
// ========================================================================

private _gruntArray = [];

for "_i" from 1 to 20 do {
    _gruntArray pushBack (selectRandom _gruntPool);
};
private _groupPos = _spawnPos getPos [random 200, random 360];
_groupPos = [_groupPos, 0, 20, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;

private _gruntGroup = [
    _spawnPos,
    west,
    _gruntArray
] call BIS_fnc_spawnGroup;

{
    private _pos = getPosATL _x;
    _pos set [2, 0.3];
    _x setPosATL _pos;
} forEach units _gruntGroup;

{
    _x setBehaviour "AWARE";
    _x setCombatMode "YELLOW";
    _x allowFleeing 0;
    _x addRating 10000;

    _x setVariable ["MERC_is_cult_grunt",true,true];
    _x setVariable ["MERC_is_mission_target",true,true];

    _allTargets pushBack _x;

} forEach units _gruntGroup;

// Patrol grunt lama dihapus; role masing-masing akan mendapat patrol sendiri setelah pembagian group.

// ========================================================================
// 5. SPAWN KENDARAAN (1 MBT + 2 APC + 1 Osiris)
// ========================================================================
private _mbtClass = "O_T_MBT_02_railgun_ghex_F";
private _apcClass = "CUP_B_M1128_MGS_Desert";
private _osirisClass = "Osiris";

// Group kendaraan terpisah agar crew tidak ikut role infantry.
private _vehicleGroup = createGroup [west, true];

// Fungsi untuk spawn kendaraan DARAT dengan awak (MBT & APC)
private _fnc_spawnVehicle = {
    params ["_class", "_pos"];
    private _vic = createVehicle [_class, _pos, [], 0, "NONE"];
    _vic setDir random 360;
    _vic setPosATL _pos;
    _vic setVectorUp (surfaceNormal _pos);
    _vic setVariable ["MERC_is_mission_target", true, true];
    _allVehicles pushBack _vic;
    _allTargets pushBack _vic;
    
    createVehicleCrew _vic;
    (crew _vic) joinSilent _vehicleGroup;
    {
        _x setVariable ["MERC_is_mission_target", true, true];
        _allTargets pushBack _x;
    } forEach (crew _vic);
    _vic
};

// Spawn MBT
private _mbtPos = _spawnPos getPos [80, random 360];
[_mbtClass, _mbtPos] call _fnc_spawnVehicle;

// Spawn 2 APC
for "_i" from 1 to 2 do {
    private _pos = _spawnPos getPos [60 + (_i*25), random 360];
    [_apcClass, _pos] call _fnc_spawnVehicle;
};

// SPAWN OSIRIS (TERBANG) - DIBUAT TERPISAH

private _osirisPos = _spawnPos getPos [120, random 360];
private _osiris = createVehicle [_osirisClass, [_osirisPos select 0, _osirisPos select 1, 300], [], 0, "FLY"];
_osiris flyInHeight 300;
_osiris setVariable ["MERC_is_mission_target", true, true];
_allVehicles pushBack _osiris;
_allTargets pushBack _osiris;

// Buat awak
createVehicleCrew _osiris;

// Pindahkan awak ke group terpisah (agar tidak terpengaruh patroli darat)
private _airGroup = createGroup [west, true];
(crew _osiris) joinSilent _airGroup;

// Tambahkan semua awak ke _allTargets
{
    _x setVariable ["MERC_is_mission_target", true, true];
    _allTargets pushBack _x;
} forEach (crew _osiris);

// Hapus waypoint default dari group boss lama.
// Boss akan dipindahkan ke Commando group di sistem role di bawah.
while {count waypoints _bossGroup > 0} do {
    deleteWaypoint [_bossGroup, 0];
};

// ========================================================================
// 6. ROLE, POSITION, PATROL & ALERT SYSTEM
// ========================================================================
//
// Cult HQ:
// Commando = Niter + Sextans (satu group)
// Guard    = 2
// Assault  = 2
// Recon    = semua grunt tersisa
//
// Recon / Guard mendeteksi musuh:
//     -> Assault diberi path menuju player.
//
// Guard:
//     -> patrol mengelilingi Commando.
//
// Commando:
//     -> PATH OFF selama Guard masih hidup.
//     -> PATH ON setelah semua Guard mati.
// ========================================================================

// Group role terpisah.
private _commandoGroup = createGroup [west, true];
private _sextansGroup = createGroup [west, true];
private _guardGroup = createGroup [west, true];
private _assaultGroup = createGroup [west, true];
private _reconGroup = createGroup [west, true];

// Niter = Commando. PATH OFF sampai semua Guard mati.
private _niter = objNull;
private _sextans = objNull;

if (count _bosses > 0) then { _niter = _bosses select 0; };
if (count _bosses > 1) then { _sextans = _bosses select 1; };

if (!isNull _niter) then {
    [_niter] joinSilent _commandoGroup;
    _niter setVariable ["MERC_is_cult_commando", true, true];
    _niter disableAI "PATH";
    _commandoGroup selectLeader _niter;
};

// Sextans = special Recon independen. Tidak memanggil Assault saat mendeteksi musuh.
if (!isNull _sextans) then {
    [_sextans] joinSilent _sextansGroup;
    _sextans setVariable ["MERC_cult_role", "SEXTANS_RECON", true];
};

// Grunt dibagi random:
// 2 Guard -> 2 Assault -> sisanya Recon.
private _rolePool = +units _gruntGroup;
_rolePool = _rolePool call BIS_fnc_arrayShuffle;

// Guard = maksimal 2.
for "_i" from 1 to 2 do {
    if (count _rolePool > 0) then {
        private _unit = _rolePool deleteAt 0;
        [_unit] joinSilent _guardGroup;
        _unit setVariable ["MERC_cult_role", "GUARD", true];
    };
};

// Assault = maksimal 2.
for "_i" from 1 to 2 do {
    if (count _rolePool > 0) then {
        private _unit = _rolePool deleteAt 0;
        [_unit] joinSilent _assaultGroup;
        _unit setVariable ["MERC_cult_role", "ASSAULT", true];
    };
};

// Sisanya Recon.
{
    [_x] joinSilent _reconGroup;
    _x setVariable ["MERC_cult_role", "RECON", true];
} forEach _rolePool;

// Cari building/tower yang punya building position AI.
private _enterableBuildings = nearestObjects [_spawnPos, ["House", "Building"], 150];
_enterableBuildings = _enterableBuildings select {
    count (_x buildingPos -1) > 0
};

// Helper untuk menempatkan unit pada building/tower.
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

if (!isNull _niter && {count _enterableBuildings > 0}) then {
    _commandoBuilding = selectRandom _enterableBuildings;
    _niter setPosATL (getPosATL _commandoBuilding);
};

// Helper posisi acak di radius tertentu dari tengah AO.
private _randomRadiusPos = {
    params ["_center", "_radius"];
    private _pos = _center getPos [random _radius, random 360];
    private _safePos = [_pos, 0, 20, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
    if (count _safePos > 0) then { _safePos } else { _pos };
};

// Guard tersebar 15m dari Niter. PATH tetap aktif.
{
    private _pos = [_niter, 15] call _randomRadiusPos;
    _x setPosATL [_pos select 0, _pos select 1, 0];
} forEach units _guardGroup;

// Assault tersebar 255m dari tengah HQ.
{
    private _pos = [_spawnPos, 255] call _randomRadiusPos;
    _x setPosATL [_pos select 0, _pos select 1, 0];
} forEach units _assaultGroup;

// Recon tersebar 350m dari tengah HQ.
{
    private _pos = [_spawnPos, 350] call _randomRadiusPos;
    _x setPosATL [_pos select 0, _pos select 1, 0];
} forEach units _reconGroup;

// Sextans mulai jauh sebagai special recon dan tidak mengikuti alert system.
if (!isNull _sextans) then {
    private _pos = [_spawnPos, 500] call _randomRadiusPos;
    _sextans setPosATL [_pos select 0, _pos select 1, 0];
};

// ========================================================================
// GUARD PROTECTION
// ========================================================================
if (count _bosses > 0 && {count units _guardGroup > 0}) then {

    private _guardCenter = getPosATL (_bosses select 0);
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
// Cult HQ:
// Recon   = 350m
// Assault = 255m
// Sextans = 500m
// ========================================================================
if (count units _assaultGroup > 0) then {
    [_assaultGroup, _spawnPos, 255] call BIS_fnc_taskPatrol;
};

if (count units _reconGroup > 0) then {
    [_reconGroup, _spawnPos, 350] call BIS_fnc_taskPatrol;
};

if (!isNull _sextans) then {
    [_sextansGroup, _spawnPos, 500] call BIS_fnc_taskPatrol;
};

// Semua infantry role AWARE/YELLOW.
{
    _x setBehaviour "AWARE";
    _x setCombatMode "YELLOW";
    _x setSkill ["spotDistance",1];
    _x setSkill ["spotTime",1];
} forEach (_bosses + units _guardGroup + units _assaultGroup + units _reconGroup + units _sextansGroup);

// ========================================================================
// ALERT SYSTEM
// Recon / Guard -> Assault
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
// COMMANDO UNLOCK
// Commando bergerak hanya setelah semua Guard mati.
// ========================================================================
if (count _bosses > 0) then {

    [_bosses, _guardGroup] spawn {
        params ["_bosses", "_guardGroup"];

        waitUntil {
            sleep 2;
            ({alive _x} count _bosses) == 0 ||
            ({alive _x} count units _guardGroup) == 0
        };

        if ({alive _x} count _bosses > 0) then {
            {
                _x enableAI "PATH";
            } forEach _bosses;

            private _grp = group (_bosses select 0);
            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
        };
    };
};

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

missionNamespace setVariable [format ["MERC_cult_commando_group_%1", _id], _commandoGroup, true];
missionNamespace setVariable [format ["MERC_cult_guard_group_%1", _id], _guardGroup, true];
missionNamespace setVariable [format ["MERC_cult_assault_group_%1", _id], _assaultGroup, true];
missionNamespace setVariable [format ["MERC_cult_recon_group_%1", _id], _reconGroup, true];
missionNamespace setVariable [format ["MERC_cult_sextans_group_%1", _id], _sextansGroup, true];

// ========================================================================
// 7. RESPON MECHANISM (jika boss masih hidup)
// ========================================================================
[_spawnPos, _bosses, _guardGroup, _gruntPool, _allTargets, _id, _reconGroup] spawn {
    params ["_spawnPos", "_bosses", "_guardGroup", "_gruntPool", "_allTargets", "_id", "_reconGroup"];
    private _respawnDelay = 600; // 10 menit

    // Reinforcement baru aktif setelah semua Guard mati.
    waitUntil {
        sleep 2;
        ({alive _x} count _bosses) == 0 ||
        ({alive _x} count units _guardGroup) == 0
    };

    // Jika kedua boss sudah mati sebelum timer aktif, tidak perlu reinforcement.
    if (({alive _x} count _bosses) == 0) exitWith {};

    while {{alive _x} count _bosses > 0} do {
        sleep _respawnDelay;

        // Boss harus masih hidup setelah 10 menit sebelum reinforcement dipanggil.
        if (({alive _x} count _bosses) > 0) then {
            private _currentUnits = _allTargets select { alive _x && (_x distance _spawnPos) < 300 && !(_x isKindOf "LandVehicle") };
            private _count = count _currentUnits;

            // Maksimal 20 infantry aktif di sekitar HQ.
            if (_count < 20) then {
                private _toSpawn = 20 - _count;
                private _grp = _reconGroup;
                if (isNull _grp) then { _grp = createGroup [west, true]; };

                for "_i" from 1 to _toSpawn do {
                    private _pos = _spawnPos getPos [random 150, random 360];
                    private _unit = _grp createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
                    _unit setCombatMode "YELLOW";
                    _unit allowFleeing 0;
                    _unit addRating 10000;
                    _unit setVariable ["MERC_is_cult_grunt", true, true];
                    _unit setVariable ["MERC_is_mission_target", true, true];
                    _allTargets pushBack _unit;
                };

                diag_log format ["[MERC] Reinforcement: spawned %1 Cult units at AO", _toSpawn];
            };
        };
    };
};

// ========================================================================
// 8. MONITOR SUKSES (BOSS MATI = MISI SELESAI)
// ========================================================================
private _hqRealVar = _hqReal;
private _bossesVar = _bosses;
private _allTargetsVar = _allTargets;
private _progressVar = _progress + 1;
private _targetVar = _target;
private _giverVar = _giver;
private _missionDataVar = _missionData;
private _spawnPosVar = _spawnPos; // tambahkan ini

[_hqRealVar, _bossesVar, _allTargetsVar, _id, _progressVar, _targetVar, _giverVar, _missionDataVar, _spawnPosVar] spawn {
    params ["_hq", "_bosses", "_allTargets", "_id", "_newProgress", "_target", "_giver", "_missionData", "_spawnPos"];
    
    // 🔥 Log status boss setiap 10 detik
    while {true} do {
        sleep 10;
        private _aliveCount = { alive _x } count _bosses;
        private _nullCount = { isNull _x } count _bosses;
        diag_log format ["[MERC] Boss status: alive=%1, null=%2, total=%3", _aliveCount, _nullCount, count _bosses];
        if (_aliveCount == 0) exitWith {}; // keluar dari loop jika semua mati
    };
    
    // Tunggu sampai semua boss mati
    waitUntil {
        sleep 5;
        private _bossDead = { alive _x } count _bosses == 0;
        _bossDead
    };
    
    diag_log "[MERC] Cult AO destroyed! All bosses eliminated.";
    
    missionNamespace setVariable ["MERC_cult_progress", _newProgress, true];
    
    // Ambil reward dari missionData (aman karena sudah di-pass)
    private _rewardRange = _missionData select 4;
    private _repReward = _missionData select 5;
    private _reward = (_rewardRange select 0) + round random ((_rewardRange select 1) - (_rewardRange select 0));
    
    // Panggil fungsi sukses dengan parameter yang valid
    ["cult_clear", _target, _giver, _reward, _repReward] call MERC_fnc_missionSuccess;
    
    [parseText format ["<t color='#00FF00' size='1.5'>CULT AO DESTROYED</t><br/>Progress: %1 / 7", _newProgress]] remoteExec ["hint", 0];

	if (_newProgress >= 7) then {
    sleep 5;

	[format ["MERC_%1", _id], true] call BIS_fnc_deleteTask;

    ["END1", true, 2] remoteExec ["BIS_fnc_endMission", 0];
	};
};
// ========================================================================
// 9. MARKER AO (tidak ada marker untuk misi ke-7)
// ========================================================================
if (_progress < 5) then { // progress 0-5 = misi 1-6, progress 6 = misi ke-7
    private _aoMarker = createMarker [format ["MERC_Cult_AO_%1", time], _spawnPos];
    _aoMarker setMarkerShape "ELLIPSE";
    _aoMarker setMarkerSize [150, 150];
    _aoMarker setMarkerColor "ColorRED";
    _aoMarker setMarkerAlpha 0.3;
    _aoMarker setMarkerBrush "Border";
    _aoMarker setMarkerText format ["Cult AO (%1/7)", _progress+1];
} else {
    diag_log "[MERC] Cult mission #7: No marker displayed (hidden AO)";
};

// ========================================================================
// 10. SIMPAN SEMUA TARGET UNTUK CLEANUP
// ========================================================================
missionNamespace setVariable [format ["MERC_targets_%1", _id], _allTargets, true];
missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], _allTargets, true];

// Broadcast info
[parseText format ["<t color='#FFA500'>CULT MAIN MISSION</t><br/>Destroy the Cult AO! Progress: %1 / 7", _progress+1]] remoteExec ["hint", 0];

diag_log format ["[MERC] Cult Main Mission #%1 spawned at %2", _progress+1, _spawnPos];

_missionGroup = _bossGroup; // untuk reference