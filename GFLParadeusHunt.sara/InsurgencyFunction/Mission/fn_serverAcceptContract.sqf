/*
    File: InsurgencyFunction\Mission\fn_serverAcceptContract.sqf
    Description: Master Router Server - Mencari posisi daratan darat secara aman dan memicu sub-misi.
*/

if (!isServer) exitWith {};

params [["_missionData", []], ["_playerCaller", objNull]];
if (count _missionData == 0) exitWith {};

_missionData params [
    "_id",
    "_title",
    "_difficulty",
    "_timeLimit",
    "_rewardRange",
    "_repReward",
    "_giver",
    "_target",
    "_nightOnly",
    "_desc"
];

// ============================================================
// FUNGSI PENCARIAN POSISI SPAWN (UNTUK SEMUA MISI)
// ============================================================
private _fnc_findSpawnPos = {
    params ["_center", "_minDist", "_maxDist", "_factionFilter", "_avoidPositions"];
    private _pos = [0,0,0];
    private _found = false;
    private _attempts = 0;
    
    while {!_found && _attempts < 100} do {
        _attempts = _attempts + 1;
        private _dist = _minDist + random (_maxDist - _minDist);
        private _dir = random 360;
        private _testPos = _center getPos [_dist, _dir];
        
        // 1. Coba isFlatEmpty
        private _flatPos = _testPos isFlatEmpty [150, 0, 0.5, 5, 0, false];
        if (count _flatPos > 0) then {
            _pos = _flatPos;
            _found = true;
        };
        
        // 2. Fallback: BIS_fnc_findSafePos
        if (!_found) then {
            private _safePos = [_testPos, 0, 100, 5, 0, 20, 0] call BIS_fnc_findSafePos;
            if (count _safePos > 0) then {
                _pos = _safePos;
                _found = true;
            };
        };
        
        // 3. Validasi: tidak di air
        if (_found && surfaceIsWater _pos) then { _found = false; };
        
		// ============================================================
		// 4. VALIDASI AREA HQ
		// Radius HQ = 75m
		// Radius pengecekan = 150m
		// ============================================================

		if (_found) then {

			private _validArea = true;

			private _centerHeight = getTerrainHeightASL _pos;

			{
				private _radius = _x;

				for "_dir" from 0 to 330 step 30 do {

					private _checkPos = _pos getPos [_radius,_dir];

					// Jangan sampai menyentuh laut
					if (surfaceIsWater _checkPos) exitWith {
						_validArea = false;
					};

					// Jangan terlalu curam
					private _h = getTerrainHeightASL _checkPos;

					if (abs (_h - _centerHeight) > 6) exitWith {
						_validArea = false;
					};

				};

				if (!_validArea) exitWith {};

			} forEach [75,100,125,150];

			if (!_validArea) then {
				_found = false;
			};

		};
        
        // 5. Validasi: tidak terlalu dekat dengan posisi yang sudah dipakai (min 200m)
        if (_found) then {
            private _nearUsed = false;
            {
                if (_pos distance _x < 200) then { _nearUsed = true; };
            } forEach _avoidPositions;
            if (_nearUsed) then { _found = false; };
        };
        
        // 6. Filter faksi (USA utara Y>10240, RUSSIA selatan Y<10240)
        if (_found && _factionFilter != "") then {
            private _testY = _pos select 1;
            if (_factionFilter == "USA") then {
                if (_testY <= 10240) then { _found = false; };
            };
            if (_factionFilter == "RUSSIA") then {
                if (_testY >= 10240) then { _found = false; };
            };
        };
    };
    
    if (!_found) then { _pos = [0,0,0]; };
    _pos
};
// Variabel untuk menyimpan posisi yang sudah dipakai (agar tidak berulang)
private _usedPositions = missionNamespace getVariable ["MERC_used_spawn_positions", []];


// ============================================================
// 0. CEK KHUSUS: MISI UTAMA CULT
// ============================================================
if (_id find "cult_main" >= 0) then {
    private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
    if (isNull _hq) then {
        diag_log "MERC SERVER ERROR: Mobile HQ missing for Cult mission!";
        ["Cult Mission Failed: Mobile HQ not found!"] remoteExec ["hint", _playerCaller];
        exit;
    };
    private _hqPos = getPosATL _hq; // ✅ DEKLARASIKAN DULU

    private _spawnPos = [_hqPos, 4000, 12000, "", _usedPositions] call _fnc_findSpawnPos;

    // 🔥 FALLBACK: jika masih (0,0,0), cari dengan radius lebih besar atau pakai HQ
    if (_spawnPos isEqualTo [0,0,0]) then {
        diag_log "[MERC] WARNING: _fnc_findSpawnPos returned 0,0,0 – trying fallback...";
        
        // Coba cari di radius 5000-15000
        _spawnPos = [_hqPos, 5000, 15000, "", _usedPositions] call _fnc_findSpawnPos;
        
        // Jika masih gagal, pakai posisi HQ + offset acak (pastikan darat)
        if (_spawnPos isEqualTo [0,0,0]) then {
            diag_log "[MERC] WARNING: Fallback with HQ offset...";
            private _attempt = 0;
            while {_attempt < 50 && (_spawnPos isEqualTo [0,0,0] || surfaceIsWater _spawnPos)} do {
                _attempt = _attempt + 1;
                private _offset = [random 2000 - 1000, random 2000 - 1000, 0];
                private _testPos = _hqPos vectorAdd _offset;
               private _flat = _testPos isFlatEmpty [30, 0, 0.5, 5, 0, false];
				if (count _flat > 0) then {
					if (!surfaceIsWater _flat) then {
						_spawnPos = _flat;
					};
				};
            };
            // Jika masih gagal, paksa pakai posisi HQ (meskipun mungkin di air, tapi ini darurat)
            if (_spawnPos isEqualTo [0,0,0]) then {
                _spawnPos = _hqPos;
                diag_log "[MERC] CRITICAL: Using HQ position as last resort!";
            };
        };
    };

    if (_spawnPos isEqualTo [0,0,0]) then {
        diag_log "MERC SERVER CRITICAL: Cult mission spawn location not found!";
        ["Cult Mission Failed: Cannot find suitable location!"] remoteExec ["hint", _playerCaller];
        exit;
    };

    _usedPositions pushBack _spawnPos;
    missionNamespace setVariable ["MERC_used_spawn_positions", _usedPositions, true];

    private _aiCount = 50;
    [_spawnPos, _missionData, _aiCount] execVM "InsurgencyFunction\Mission\fn_cultMainMission.sqf";
    
    diag_log format ["[MERC] Cult Main Mission spawned at %1", _spawnPos];
    exit;
};

// ============================================================
// (LANJUTKAN: proses misi reguler)
// ============================================================

private _reward = (_rewardRange select 0) + round (random ((_rewardRange select 1) - (_rewardRange select 0)));

// 1. Kunci papan kontrak
missionNamespace setVariable ["MERC_active_running_contract", _missionData, true];

// 2. Ambil posisi Mobile HQ
private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) then {
    diag_log "MERC SERVER ERROR: Mobile HQ Object missing!";
    missionNamespace setVariable ["MERC_active_running_contract", [], true];
    exit;
};
private _hqPos = getPosATL _hq;

private _spawnPos = [_hqPos, 1000, 5000, _target, _usedPositions] call _fnc_findSpawnPos;

// 🔥 FALLBACK: jika masih (0,0,0), cari dengan radius lebih besar
if (_spawnPos isEqualTo [0,0,0]) then {
    diag_log "[MERC] WARNING: _fnc_findSpawnPos returned 0,0,0 – trying fallback...";
    
    // Coba cari di radius 2000-8000
    _spawnPos = [_hqPos, 2000, 8000, _target, _usedPositions] call _fnc_findSpawnPos;
    
    // Jika masih gagal, pakai posisi HQ + offset acak
    if (_spawnPos isEqualTo [0,0,0]) then {
        diag_log "[MERC] WARNING: Fallback with HQ offset...";
        private _attempt = 0;
        while {_attempt < 50 && (_spawnPos isEqualTo [0,0,0] || surfaceIsWater _spawnPos)} do {
            _attempt = _attempt + 1;
            private _offset = [random 2000 - 1000, random 2000 - 1000, 0];
            private _testPos = _hqPos vectorAdd _offset;
            private _flat = _testPos isFlatEmpty [30, 0, 0.5, 5, 0, false];
			if (count _flat > 0) then {
				if (!surfaceIsWater _flat) then {
					_spawnPos = _flat;
				};
			};
        };
        // Jika masih gagal, paksa pakai posisi HQ
        if (_spawnPos isEqualTo [0,0,0]) then {
            _spawnPos = _hqPos;
            diag_log "[MERC] CRITICAL: Using HQ position as last resort!";
        };
    };
};

if (_spawnPos isEqualTo [0,0,0]) then {
    missionNamespace setVariable ["MERC_active_running_contract", [], true];
    ["Unable to find a suitable flat area for the mission. Please relocate your Mobile HQ and try again."] remoteExec ["hint", _playerCaller];
    diag_log "MERC SERVER CRITICAL: Spawn aborted! No flat land found.";
    exit;
};

_usedPositions pushBack _spawnPos;
missionNamespace setVariable ["MERC_used_spawn_positions", _usedPositions, true];

// 5. Marker & Task
private _markerName = format ["MERC_Marker_%1", time];
private _missionMarker = createMarker [_markerName, _spawnPos];
_missionMarker setMarkerShape "ELLIPSE";
_missionMarker setMarkerSize [200, 200];
_missionMarker setMarkerColor "ColorRed";
_missionMarker setMarkerBrush "Border";
_missionMarker setMarkerText "Mission Area";

[_target, _id, _title, _difficulty, _reward, _repReward, _spawnPos, _markerName] remoteExec ["MERC_fnc_ClientCreateTask", 0, true];

// 7. Hitung _aiCount
private _minEnemies = 5;
private _maxEnemies = 10;
switch (toUpper _difficulty) do {
    case "EASY":                   { _minEnemies = 5;  _maxEnemies = 10; };
    case "MED"; case "MEDIUM":     { _minEnemies = 10; _maxEnemies = 15; };
    case "HARD":                   { _minEnemies = 18; _maxEnemies = 25; };
    default                        { _minEnemies = 10; _maxEnemies = 15; };
};
private _aiCount = floor (random [_minEnemies, (_minEnemies + _maxEnemies) / 2, _maxEnemies]);

diag_log format ["MERC SERVER: Difficulty=%1 | aiCount=%2 | Reward=$%3", _difficulty, _aiCount, _reward];

// 8. Dispatch ke sub-misi
private _categoryScript = "";
if (_id find "kill"      >= 0) then { _categoryScript = "fn_HVT.sqf"; };
if (_id find "convoy"    >= 0) then { _categoryScript = "fn_Convoy.sqf"; };
if (_id find "barrack"   >= 0) then { _categoryScript = "fn_Barrack.sqf"; };
if (_id find "roadblock" >= 0) then { _categoryScript = "fn_RoadBlock.sqf"; };

if (_categoryScript != "") then {
    // 🔥 PERBAIKI PATH: tambahkan 's' di Mission
    [_spawnPos, _missionData, _aiCount] execVM format ["InsurgencyFunction\Mission\%1", _categoryScript];
    diag_log format ["MERC SERVER: Spawning [%1] at %2 with %3 guards.", _categoryScript, _spawnPos, _aiCount];
} else {
    diag_log format ["MERC SERVER ERROR: Undefined category for Mission ID: [%1]", _id];
};

call MERC_fnc_rerollMission;

// 9. Self-destruct
[_id, _spawnPos, _markerName] spawn {
    params ["_id", "_spawnPos", "_markerName"];

    waitUntil {
        sleep 2;
        private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];
        count _contract == 0
    };

    {
        if (markerText _x find "HVT Location" >= 0 || markerText _x find "Search Area" >= 0 ||
            markerText _x find "Barrack AO" >= 0 || markerText _x find "Roadblock Area" >= 0 ||
            markerText _x find "Mission Area" >= 0) then {
            deleteMarker _x;
        };
    } forEach allMapMarkers;

    sleep 20;

    private _hvtUnits = missionNamespace getVariable [format ["MERC_targets_%1", _id], []];
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach _hvtUnits;
    missionNamespace setVariable [format ["MERC_targets_%1", _id], nil, true];

    private _barrackUnits = missionNamespace getVariable [format ["MERC_barrack_units_%1", _id], []];
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach _barrackUnits;
    missionNamespace setVariable [format ["MERC_barrack_units_%1", _id], nil, true];

    private _objs = missionNamespace getVariable [format ["MERC_mission_objects_%1", _id], []];
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach _objs;
    missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], nil, true];

    deleteMarker _markerName;
};