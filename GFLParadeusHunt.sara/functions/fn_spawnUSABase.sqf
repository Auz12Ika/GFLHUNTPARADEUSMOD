/*
    Author: Modder
    File: fn_spawnUSABase.sqf
    Description: Sistem spawn pertahanan pangkalan USA (Air Superpower).
                 Doktrin: Heli attack dominan, darat hanya Humvee/MRAP.
                 Infantry AT/AA hanya di MAIN_BASE & AIRBASE. Tidak ada tank berat.
    🔧 FINAL: Data-driven dari MERC_factions_USA & MERC_vehicles_USA.
*/

params [["_basePos", [0,0,0]], ["_baseType", "BASE"]];

if (!isServer) exitWith {};

private _isMainBase = (_baseType == "MAIN_BASE");
private _isAirbase = (_baseType == "AIRBASE");
private _isBase = (_baseType == "BASE");
private _isCity = (_baseType == "CITY");
private _isFactory = (_baseType == "FACTORY");
private _isRadio = (_baseType == "RADIO");
private _isBigBase = (_isMainBase || _isAirbase || _isBase);

// =====================================================
// 1. INFANTRY GARRISON (ringan)
// =====================================================
[_basePos, "USA", _baseType, false] call MERC_fnc_spawnGroupUniversal;

// =====================================================
// 2. INFANTRY AT (HANYA MAIN_BASE & AIRBASE)
// =====================================================
if (_isMainBase || _isAirbase) then {
    private _atCount = if (_isMainBase) then { 2 + floor random 2 } else { 1 + floor random 1 };
    private _atGrp = createGroup west;
    private _atPool = ["rhsusf_army_ocp_maaf", "rhsusf_army_ocp_javelin", "B_Soldier_AT_F"];
    
    for "_i" from 1 to _atCount do {
        private _atPos = [_basePos, 10, 60, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _atPos > 0) then {
            private _u = _atGrp createUnit [selectRandom _atPool, _atPos, [], 5, "NONE"];
            _u setSkill (0.5 + random 0.3);
        };
    };
    [_atGrp, _basePos, 100] call BIS_fnc_taskPatrol;
    _atGrp setBehaviour "COMBAT";
    _atGrp setVariable ["GFL_Remnant", true, true];
};

// =====================================================
// 3. INFANTRY AA (HANYA MAIN_BASE & AIRBASE)
// =====================================================
if (_isMainBase || _isAirbase) then {
    private _aaCount = if (_isMainBase) then { 2 + floor random 1 } else { 1 + floor random 1 };
    private _aaGrp = createGroup west;
    private _aaPool = ["rhsusf_army_ocp_aa", "B_Soldier_AA_F"];
    
    for "_i" from 1 to _aaCount do {
        private _aaPos = [_basePos, 15, 70, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _aaPos > 0) then {
            private _u = _aaGrp createUnit [selectRandom _aaPool, _aaPos, [], 5, "NONE"];
            _u setSkill (0.5 + random 0.3);
        };
    };
    [_aaGrp, _basePos, 100] call BIS_fnc_taskPatrol;
    _aaGrp setBehaviour "COMBAT";
    _aaGrp setVariable ["GFL_Remnant", true, true];
};

// =====================================================
// 4. KENDARAAN DARAT (HUMMVEE / MRAP — RINGAN)
// =====================================================
private _vehCount = switch (true) do {
    case (_isMainBase): { 2 + floor random 2 };
    case (_isAirbase):  { 2 };
    case (_isBase):     { 1 + floor random 1 };
    case (_isCity):     { 1 };
    case (_isFactory):  { 1 };
    default             { 0 };
};

if (_vehCount > 0) then {
    private _lightVehPool = if (!isNil "MERC_vehicles_USA") then {
        MERC_vehicles_USA select [0, 2]
    } else {
        ["B_MRAP_01_hmg_F", "B_MRAP_01_F"]
    };

    for "_i" from 1 to _vehCount do {
        private _vPos = [_basePos, 10, 60, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
        if (count _vPos > 0) then {
            private _veh = createVehicle [selectRandom _lightVehPool, _vPos, [], 0, "NONE"];
            _veh setDir random 360;
            createVehicleCrew _veh;
            [group driver _veh, _basePos, 150] call BIS_fnc_taskPatrol;
        };
    };
};

// =====================================================
// 5. HELI ATTACK (Patroli di MAIN_BASE & AIRBASE)
// =====================================================
if (_isMainBase || _isAirbase) then {
    // Heli standby (QRF)
    private _padPos = [_basePos, 10, 80, 10, 0, 0.3, 0] call BIS_fnc_findSafePos;
    private _heavyHeli = if (_isMainBase) then {
        if (!isNil "MERC_vehicles_USA" && {count MERC_vehicles_USA > 5}) then { MERC_vehicles_USA select 5 } else { "B_Heli_Attack_01_F" }
    } else {
        if (!isNil "MERC_vehicles_USA" && {count MERC_vehicles_USA > 3}) then { MERC_vehicles_USA select 3 } else { "B_Heli_Transport_01_F" }
    };

    if (count _padPos > 0) then {
        private _heliStatic = createVehicle [_heavyHeli, _padPos, [], 0, "NONE"];
        _heliStatic setDir random 360;
        [_heliStatic, _basePos] spawn {
            params ["_heli", "_p"];
            waitUntil { sleep 5; {side _x != west && _x distance _heli < 500} count allUnits > 0 || !alive _heli };
            if (alive _heli) then {
                createVehicleCrew _heli;
                (group driver _heli) setBehaviour "COMBAT";
                diag_log "USA QRF: Helikopter pangkalan lepas landas!";
            };
        };
    };

    // Heli patroli ringan (Little Bird)
    if (_isMainBase) then {
        private _lightHeliClass = if (!isNil "MERC_vehicles_USA" && {count MERC_vehicles_USA > 4}) then { MERC_vehicles_USA select 4 } else { "B_Heli_Light_01_armed_F" };
        for "_i" from 1 to 2 do {
            private _heliPos = [_basePos, 30, 120, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
            if (count _heliPos > 0) then {
                private _patrolHeli = createVehicle [_lightHeliClass, _heliPos, [], 0, "FLY"];
                createVehicleCrew _patrolHeli;
                (group driver _patrolHeli) setBehaviour "COMBAT";
                driver _patrolHeli flyInHeight 60;
                [group driver _patrolHeli, _basePos, 800] call BIS_fnc_taskPatrol;
            };
        };
    };
};

// =====================================================
// 6. BANGUNAN (hanya base besar)
// =====================================================
if (_isBigBase) then {
    private _bunkerClasses = ["Land_BagBunker_Small_F", "Land_BagBunker_Tower_F", "Land_Bunker_01_small_F"];
    private _towerClasses = ["Land_Tower_01_F", "Land_GuardTower_01_F"];
    private _smallBuildings = ["Land_GuardShed", "Land_TentA_F", "Land_CratesWooden_F"];

    if (_isMainBase) then {
        private _hqBuilding = selectRandom ["Land_Cargo_HQ_V1_F", "Land_Medevac_house_V1_F"];
        private _hqObj = createVehicle [_hqBuilding, _basePos, [], 0, "NONE"];
        _hqObj setDir random 360;
        _hqObj allowDamage true;
    };

    if (_isAirbase) then {
        private _hangar = createVehicle ["Land_Hangar_F", _basePos getPos [25, 0], [], 0, "NONE"];
        _hangar setDir random 360;
    };

    for "_i" from 1 to (2 + floor random 2) do {
        private _bunkerPos = [_basePos, 30, 80, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _bunkerPos > 0) then {
            private _bunker = createVehicle [selectRandom _bunkerClasses, _bunkerPos, [], 0, "NONE"];
            _bunker setDir random 360;
            private _grp = createGroup west;
            private _unitPool = if (!isNil "MERC_factions_USA") then { MERC_factions_USA } else { ["B_Soldier_F"] };
            for "_j" from 1 to 2 do {
                private _unit = _grp createUnit [selectRandom _unitPool, _bunkerPos, [], 2, "NONE"];
                _unit setUnitPos "UP";
                _unit disableAI "PATH";
            };
            _grp setVariable ["GFL_Remnant", true, true];
        };
    };

    for "_i" from 1 to (1 + floor random 1) do {
        private _towerPos = [_basePos, 40, 100, 4, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _towerPos > 0) then {
            private _tower = createVehicle [selectRandom _towerClasses, _towerPos, [], 0, "NONE"];
            _tower setDir random 360;
            private _grp = createGroup west;
            private _unitPool = if (!isNil "MERC_factions_USA") then { MERC_factions_USA } else { ["B_Soldier_F"] };
            private _unit = _grp createUnit [selectRandom _unitPool, _towerPos, [], 0, "NONE"];
            _unit moveInAny _tower;
            _unit setSkill 0.5;
        };
    };

    for "_i" from 1 to (1 + floor random 1) do {
        private _smallPos = [_basePos, 20, 70, 3, 0, 0.4, 0] call BIS_fnc_findSafePos;
        if (count _smallPos > 0) then {
            createVehicle [selectRandom _smallBuildings, _smallPos, [], 0, "NONE"] setDir random 360;
        };
    };

    if (_isMainBase || _isAirbase || _isBase) then {
        private _cratePos = _basePos getPos [5, random 360];
        private _crate = createVehicle ["Box_NATO_Wps_F", _cratePos, [], 0, "CAN_COLLIDE"];
        _crate setDir random 360;
        _crate allowDamage false;
        {
            _crate addWeaponCargoGlobal [_x, 1];
        } forEach ["rhs_weap_m4a1_carryhandle", "rhs_weap_m16a4_carryhandle", "rhs_weap_m249_pip"];
        {
            _crate addMagazineCargoGlobal [_x, 3];
        } forEach ["rhs_mag_30Rnd_556x45_M855A1_Stanag", "rhsusf_200Rnd_556x45_box", "HandGrenade"];
        {
            _crate addItemCargoGlobal [_x, 1];
        } forEach ["rhsusf_acc_ACOG", "Vest_PlateCarrier1_rgr", "H_HelmetB"];
    };
};

diag_log format ["USA BASE SPAWN: %1 siap (Air Power + Darat Ringan).", _baseType];