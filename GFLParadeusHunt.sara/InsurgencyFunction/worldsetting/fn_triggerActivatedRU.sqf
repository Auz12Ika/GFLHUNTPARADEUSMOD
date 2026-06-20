/*
    File: fn_triggerActivatedRU.sqf
    Description: Spawner untuk trigger EAST (RU Army, CULT sebagai OPFOR, MERC 50/50)
*/
params ["_trigger"];

private _modules = synchronizedObjects _trigger;
if (count _modules == 0) exitWith {};

private _playersInside = allPlayers select {alive _x && _x inArea _trigger};
if (count _playersInside == 0) exitWith {};

private _center = getPos _trigger;
private _nearestPlayer = [_playersInside, _center] call BIS_fnc_nearestPosition;
private _playerDist = _nearestPlayer distance _trigger;

{
    private _factionType = _x getVariable ["factionType", ""];
    if (_factionType == "") then { continue; };
    if (_x getVariable ["spawned", false]) then { continue; };

    _x setVariable ["spawned", true, true];

    private _grp = grpNull;
    private _vic = objNull;
    private _side = civilian;
    private _unitPool = [];
    private _vicPool = [];
    private _aiCount = 0;
    private _spawnDist = _x getVariable ["spawnDist", 500];

    switch (_factionType) do {

        // ================================================================
        // RU ARMY (East)
        // ================================================================
        case "RU": {
            _side = east;
            _unitPool = MERC_factions_RUS;
            _vicPool = MERC_vehicles_RUS;

            if (_playerDist <= 500) then { _aiCount = 10; }
            else { if (_playerDist <= 750) then { _aiCount = 6; } else { _aiCount = 4; }; };

            private _spawnPos = _center;
            if (_playerDist > 750) then {
                _spawnPos = _nearestPlayer getPos [500, random 360];
                if (surfaceIsWater _spawnPos) then { _spawnPos = _center getPos [random 500, random 360]; };
            };

            _grp = createGroup [_side, true];
            for "_i" from 1 to _aiCount do {
                private _pos = if (_playerDist > 750) then {
                    [_spawnPos, 10, 100, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
                } else {
                    [_center, 50, 250, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
                };
                if (count _pos == 0) then { _pos = _spawnPos getPos [random 50, random 360]; };
                private _unit = _grp createUnit [selectRandom _unitPool, _pos, [], 5, "NONE"];
                _unit setSkill 0.8;
				[_unit] call TAG_fnc_randomizeKroco;
            };

            if (_playerDist > 750) then {
                _grp setBehaviour "COMBAT"; _grp setCombatMode "RED"; _grp setSpeedMode "FULL";
                _grp move (getPos _nearestPlayer);
            } else {
                [_grp, _center, _spawnDist / 2] call BIS_fnc_taskPatrol;
                _grp setBehaviour "AWARE";
            };

            // Kendaraan
            if (count _vicPool > 0) then {
                private _chosenVic = selectRandom _vicPool;
                private _vicPos = [_spawnPos, _spawnDist, _spawnDist + 60, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
                if (count _vicPos == 0) then { _vicPos = _spawnPos getPos [_spawnDist, random 360]; };
                if (_chosenVic isKindOf "Air") then {
                    _vic = createVehicle [_chosenVic, [_vicPos select 0, _vicPos select 1, 200], [], 0, "FLY"];
                    _vic flyInHeight 150;
                } else {
                    _vic = createVehicle [_chosenVic, _vicPos, [], 0, "NONE"];
                };
                createVehicleCrew _vic;
                [group (driver _vic), _center, _spawnDist] call BIS_fnc_taskPatrol;
                (group (driver _vic)) setBehaviour "AWARE";
                (group (driver _vic)) setSpeedMode "NORMAL";
            };

            _x setVariable ["spawnedGroup", _grp, true];
            _x setVariable ["spawnedVic", _vic, true];

            // Agresif setelah kehilangan 70% atau kendaraan hancur
            [_grp, _vic, _center] spawn {
                params ["_infGrp", "_reconVic", "_centerPos"];
                private _vicCrewGrp = if (!isNull _reconVic) then { group (driver _reconVic) } else { grpNull };
                private _initialCount = count (units _infGrp);
                waitUntil { sleep 3; (!isNull _vicCrewGrp && {{alive _x} count (units _vicCrewGrp) == 0}) || ({alive _x} count (units _infGrp) < (_initialCount * 0.70)) || {!isNull ((leader _infGrp) findNearestEnemy _centerPos)} };
                if (!isNull _infGrp && {{alive _x} count (units _infGrp) > 0}) then {
                    while {count waypoints _infGrp > 0} do { deleteWaypoint [_infGrp, 0]; };
                    _infGrp setBehaviour "COMBAT"; _infGrp setCombatMode "RED"; _infGrp setSpeedMode "FULL";
                    [_infGrp] spawn {
                        params ["_hGrp"];
                        while {!isNull _hGrp && {{alive _x} count (units _hGrp) > 0}} do {
                            private _plrs = allPlayers select {alive _x};
                            if (count _plrs > 0) then { _hGrp move (getPos ([_plrs, leader _hGrp] call BIS_fnc_nearestPosition)); };
                            sleep 15;
                        };
                    };
                };
            };
        };

			// ================================================================
			// CULT (Insurgen Sipil - Infiltrasi Luar Kota & Kru 1 Kendaraan)
			// ================================================================
			case "CULT": {
			
			private _time = daytime; 
			private _isNight = (_time >= 17 || _time < 7);
    
			if (!_isNight) exitWith {
				// Jika siang, reset variabel spawned agar trigger bisa aktif lagi nanti malam
				_x setVariable ["spawned", false, true];
			};
			
			_side = west; 
			_unitPool = MERC_factions_CULT; 
			_vicPool = MERC_vehicles_CULT; 

			private _aiCount = _x getVariable ["aiCount", 6]; 
			private _spawnDist = _x getVariable ["spawnDist", 500];

			// 1. Cari titik aman di pinggiran kota
			private _rawPos = _center getPos [800, random 360];
			private _spawnPos = [_rawPos, 0, 60, 6, 0, 0.3, 0] call BIS_fnc_findSafePos;

			// 2. Spawn kendaraan
			private _vic = objNull;
			if (count _vicPool > 0) then {
				private _chosenVic = selectRandom _vicPool;
				_vic = createVehicle [_chosenVic, _spawnPos, [], 0, "NONE"];
				_vic setDir (random 360);
			};

			_grp = createGroup [_side, true];

			// 3. Logika Spawn Bos Sextans (Peluang 20%)
			private _cultBosses = missionNamespace getVariable ["Merc_factions_CULTBOSS", []];
			
			// Pastikan Sextans ada di index 0 dari array CULTBOSS
			if (count _cultBosses > 0 && {random 1 < 0.20}) then {
				private _bossClass = _cultBosses select 0; 
				private _bossTemplate = missionNamespace getVariable [_bossClass, objNull];
				
				if (!isNull _bossTemplate) then {
					private _boss = _grp createUnit [typeOf _bossTemplate, _spawnPos, [], 0, "NONE"];
					_boss setUnitLoadout (getUnitLoadout _bossTemplate);
					_boss setRank "COLONEL";
					
					// Simpan tipe bos untuk dibaca oleh fn_cultBrain
					_boss setVariable ["isBossType", _bossClass, true];
					
					// Skill tinggi untuk Sextans
					_boss setSkill 0.95; 

					if (!isNull _vic) then { _boss moveInCommander _vic; };
				};
			};

			// 4. Spawn Pasukan Kroco
			for "_i" from 1 to _aiCount do {
				_unit setSkill 0.8;
				private _unit = _grp createUnit [selectRandom _unitPool, _spawnPos, [], 5, "NONE"];
				if (!isNull _vic) then {
					if (_vic emptyPositions "Driver" > 0) then { _unit moveInDriver _vic; }
					else { if (_vic emptyPositions "Gunner" > 0) then { _unit moveInGunner _vic; }
					else { if (_vic emptyPositions "Cargo" > 0) then { _unit moveInCargo _vic; }; }; };
				};
			};

			// 5. Waypoint Global
			private _wp = _grp addWaypoint [_center, 0];
			_wp setWaypointType "MOVE";
			_wp setWaypointBehaviour "AWARE"; 
			_wp setWaypointSpeed "NORMAL";

			// 6. Pencatatan Variabel
			_x setVariable ["spawnedGroup", _grp, true];
			_x setVariable ["spawnedVic", _vic, true];
		};
        // ================================================================
        // MERC (50/50 East atau West)
        // ================================================================
		case "MERC": {
		_side = if (random 100 < 30) then { east } else { independent };

		private _roll = random 100;
		private _mercType = "";
		if (_roll < 25) then { _unitPool = MERC_factions_SF; _vicPool = MERC_vehicles_SF; _mercType = "SF"; }
		else { if (_roll < 50) then { _unitPool = MERC_factions_Mangi; _vicPool = MERC_vehicles_Mangi; _mercType = "MANGI"; }
		else { if (_roll < 75) then { _unitPool = MERC_factions_Vanjager; _vicPool = MERC_vehicles_Vanjager; _mercType = "VANJAGER"; }
		else { _x setVariable ["spawned", false, true]; continue; }; }; };

		_aiCount = _x getVariable ["aiCount", 4];

		private _randomDist = 400 + random 200;
		private _spawnPos = _center getPos [_randomDist, random 360];
		private _nearRoads = _spawnPos nearRoads 200;
		if (count _nearRoads > 0) then { _spawnPos = getPos (selectRandom _nearRoads); }
		else { _spawnPos = [_spawnPos, 0, 150, 5, 0, 0.5, 0] call BIS_fnc_findSafePos; };

		_vic = objNull;
		if (count _vicPool > 0) then { _vic = createVehicle [selectRandom _vicPool, _spawnPos, [], 0, "NONE"]; _vic setDir (random 360); };

		_grp = createGroup [_side, true];

		private _unitsSpawned = 0;
		
		// Spawn Unit dalam Kendaraan dengan Skill 0.8
		if (!isNull _vic) then {
			if (_vic emptyPositions "Driver" > 0 && _unitsSpawned < _aiCount) then { 
				private _unit = _grp createUnit [selectRandom _unitPool, _spawnPos, [], 0, "NONE"]; 
				_unit setSkill 0.8; 
				_unit moveInDriver _vic; 
				_unitsSpawned = _unitsSpawned + 1; 
			};
			if (_vic emptyPositions "Gunner" > 0 && _unitsSpawned < _aiCount) then { 
				private _unit = _grp createUnit [selectRandom _unitPool, _spawnPos, [], 0, "NONE"]; 
				_unit setSkill 0.8; 
				_unit moveInGunner _vic; 
				_unitsSpawned = _unitsSpawned + 1; 
			};
			private _cargoSeats = _vic emptyPositions "Cargo";
			while {_cargoSeats > 0 && _unitsSpawned < _aiCount} do { 
				private _unit = _grp createUnit [selectRandom _unitPool, _spawnPos, [], 0, "NONE"]; 
				_unit setSkill 0.8; 
				_unit moveInCargo _vic; 
				_unitsSpawned = _unitsSpawned + 1; 
				_cargoSeats = _vic emptyPositions "Cargo"; 
			};
		};
		
		// Spawn Unit Jalan Kaki dengan Skill 0.8
		while {_unitsSpawned < _aiCount} do { 
			private _pos = if (!isNull _vic) then { _vic getPos [random 15, random 360] } else { _spawnPos getPos [random 15, random 360] }; 
			private _unit = _grp createUnit [selectRandom _unitPool, _pos, [], 5, "NONE"]; 
			_unit setSkill 0.8; 
			_unitsSpawned = _unitsSpawned + 1; 
		};

		_grp setBehaviour "AWARE";
		_grp setCombatMode "YELLOW";
		_grp setSpeedMode "NORMAL";
		private _wpMerc = _grp addWaypoint [_center, 0]; _wpMerc setWaypointType "MOVE"; _wpMerc setWaypointCompletionRadius 80;

		(leader _grp) addEventHandler ["Hit", {
			params ["_unit", "_source", "_damage", "_instigator"];
			if (!isNull _instigator) then {
				private _grp = group _unit;
				if (behaviour (leader _grp) != "COMBAT") then {
					_grp setBehaviour "COMBAT";
					_grp setCombatMode "RED";
					while {count waypoints _grp > 0} do { deleteWaypoint [_grp, 0]; };
					_grp move (getPos _instigator);
					_grp reveal [_instigator, 4];
				};
			};
		}];

		private _isGoingToCenter = (random 100) < 50;
		[_grp, _center, _isGoingToCenter] spawn {
			params ["_grp", "_centerPos", "_isGoingToCenter"];
			waitUntil { sleep 4; (isNull _grp) || {(leader _grp) distance _centerPos < 120} || {({alive _x} count units _grp) == 0} };
			if ({alive _x} count units _grp > 0) then {
				while {count waypoints _grp > 0} do { deleteWaypoint [_grp, 0]; };
				if (_isGoingToCenter) then { [_grp, _centerPos, 120] call BIS_fnc_taskPatrol; _grp setBehaviour "SAFE"; }
				else { [_grp, _centerPos, 350] call BIS_fnc_taskPatrol; _grp setBehaviour "AWARE"; };
			};
		};

		_x setVariable ["spawnedGroup", _grp, true];
		_x setVariable ["spawnedVic", _vic, true];
	};
		/////////////////////////////////
        // CIV
		////////////////////////////////
        case "CIV": {
            _side = civilian; _unitPool = MERC_factions_CIV; _vicPool = MERC_vehicles_CIV; _aiCount = 8;
            _grp = createGroup [_side, true];
            for "_i" from 1 to _aiCount do {
                private _pos = [_center, 50, 250, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
                if (count _pos == 0) then { _pos = _center getPos [50, random 360]; };
                _grp createUnit [selectRandom _unitPool, _pos, [], 5, "NONE"];
            };
            [_grp, _center, _spawnDist / 2] call BIS_fnc_taskPatrol; _grp setBehaviour "SAFE";
            _x setVariable ["spawnedGroup", _grp, true];
        };
    };
} forEach _modules;