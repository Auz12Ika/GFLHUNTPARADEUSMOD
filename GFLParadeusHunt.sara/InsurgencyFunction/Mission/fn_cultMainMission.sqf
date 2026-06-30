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
    ["<t color='#00FF00'>Cult campaign completed!</t>"] remoteExec ["hint", 0];
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
// 4. SPAWN BOSS & GRUNT
// ========================================================================
private _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
if (count _gruntPool == 0) then { _gruntPool = ["GFL_Unitas_015"]; };

// Boss: Niter dan Sextans
private _bossClasses = ["Niter_boss", "Sextans_boss"];
private _bosses = [];
private _bossGroup = createGroup [west, true];

{
    private _bossTemplate = missionNamespace getVariable [_x, objNull];
    if (!isNull _bossTemplate) then {
        private _pos = _spawnPos getPos [random 30, random 360];
        private _boss = _bossGroup createUnit [typeOf _bossTemplate, _pos, [], 0, "NONE"];
        _boss setUnitLoadout (getUnitLoadout _bossTemplate);
        _boss setRank "COLONEL";
        _boss setCombatMode "YELLOW";
        _boss setBehaviour "SAFE";
        _boss allowFleeing 0;
        _boss addRating 10000;
        _boss setVariable ["MERC_is_cult_boss", true, true];
        _boss setVariable ["MERC_is_mission_target", true, true];
        _allTargets pushBack _boss;
        _bosses pushBack _boss;
        
        if (!isNil "fn_cultBrain") then { [_boss] call fn_cultBrain; };
    };
} forEach _bossClasses;

// Grunts: 20 unit
private _gruntGroup = createGroup [west, true];
for "_i" from 1 to 20 do {
    private _pos = _spawnPos getPos [random 150, random 360];
    private _unit = _gruntGroup createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
    _unit setCombatMode "YELLOW";
    _unit setBehaviour "SAFE";
    _unit allowFleeing 0;
    _unit addRating 10000;
    _unit setVariable ["MERC_is_cult_grunt", true, true];
    _unit setVariable ["MERC_is_mission_target", true, true];
    _allTargets pushBack _unit;
};

(units _gruntGroup) joinSilent _bossGroup;
deleteGroup _gruntGroup;

// ========================================================================
// 5. SPAWN KENDARAAN (1 MBT + 2 APC + 1 Osiris)
// ========================================================================
private _mbtClass = "O_T_MBT_02_railgun_ghex_F";
private _apcClass = "CUP_B_M1128_MGS_Desert";
private _osirisClass = "Osiris";

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
    (crew _vic) joinSilent _bossGroup;
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

// Hapus waypoint default
while {count waypoints _airGroup > 0} do { deleteWaypoint [_airGroup, 0]; };

// Patroli khusus untuk pesawat
[_airGroup, _spawnPos, 400] call BIS_fnc_taskPatrol;
_airGroup setBehaviour "AWARE";
_airGroup setCombatMode "YELLOW";

// Simpan group untuk cleanup nanti
missionNamespace setVariable [format ["MERC_air_group_%1", _id], _airGroup, true];

// 🔥 Hapus spawn Bellador (sudah jadi mini-boss di unit biasa)

// ========================================================================
// 6. PATROL & WAYPOINT
// ========================================================================
[_bossGroup, _spawnPos, 150] call BIS_fnc_taskPatrol;
_bossGroup setBehaviour "SAFE";
_bossGroup setCombatMode "YELLOW";

// ========================================================================
// 7. RESPON MECHANISM (jika boss masih hidup)
// ========================================================================
[_spawnPos, _bosses, _gruntPool, _allTargets, _id] spawn {
    params ["_spawnPos", "_bosses", "_gruntPool", "_allTargets", "_id"];
    private _respawnDelay = 1800; // 30 menit
    while {true} do {
        sleep _respawnDelay;
        private _bossAlive = { alive _x } count _bosses;
        if (_bossAlive > 0) then {
            private _currentUnits = _allTargets select { alive _x && (_x distance _spawnPos) < 300 && !(_x isKindOf "LandVehicle") };
            private _count = count _currentUnits;
            // 🔥 Ubah dari 50 menjadi 20
            if (_count < 20) then {
                private _toSpawn = 20 - _count;
                private _grp = group (_bosses select 0);
                if (isNull _grp) then { _grp = createGroup [west, true]; };
                for "_i" from 1 to _toSpawn do {
                    private _pos = _spawnPos getPos [random 150, random 360];
                    private _unit = _grp createUnit [selectRandom _gruntPool, _pos, [], 0, "NONE"];
                    _unit setCombatMode "YELLOW";
                    _unit allowFleeing 0;
                    _unit addRating 10000;
                    _unit setVariable ["MERC_is_cult_grunt", true, true];
                    _allTargets pushBack _unit;
                };
                diag_log format ["[MERC] Respawning %1 Cult units at AO", _toSpawn];
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
    
    [format ["<t color='#00FF00' size='1.5'>CULT AO DESTROYED</t><br/>Progress: %1 / 7", _newProgress]] remoteExec ["hint", 0];
};
// ========================================================================
// 9. MARKER AO (tidak ada marker untuk misi ke-7)
// ========================================================================
if (_progress < 5) then { // progress 0-5 = misi 1-6, progress 6 = misi ke-7
    private _aoMarker = createMarker [format ["MERC_Cult_AO_%1", time], _spawnPos];
    _aoMarker setMarkerShape "ELLIPSE";
    _aoMarker setMarkerSize [150, 150];
    _aoMarker setMarkerColor "ColorRed";
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
[format ["<t color='#FFA500'>CULT MAIN MISSION</t><br/>Destroy the Cult AO! Progress: %1 / 7", _progress+1]] remoteExec ["hint", 0];

diag_log format ["[MERC] Cult Main Mission #%1 spawned at %2", _progress+1, _spawnPos];

_missionGroup = _bossGroup; // untuk reference