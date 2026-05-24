/*
    Author: Modder
    File: fn_spawnRUSBase.sqf
    Description: Sistem spawn pertahanan base Rusia.
                 Doktrin: Tank MBT + Tank AA + Infantry AT + Infantry AA di mana-mana (kecuali radio).
                 Heli Ka-52 hanya di MAIN_BASE & AIRBASE. Tidak ada pesawat.
    🔧 FINAL: Data-driven. Semua dari MERC_factions_RUS & MERC_vehicles_RUS.
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
private _hasTank = !_isRadio;

// =====================================================
// 1. INFANTRY GARRISON
// =====================================================
[_basePos, "RUSSIA", _baseType, false] call MERC_fnc_spawnGroupUniversal;

// =====================================================
// 2. INFANTRY AT (selalu jika ada tank)
// =====================================================
if (_hasTank) then {
    private _atCount = switch (true) do {
        case (_isMainBase): { 4 + floor random 3 };
        case (_isAirbase):   { 2 + floor random 2 };
        case (_isBase):      { 2 + floor random 2 };
        case (_isCity):      { 2 + floor random 2 };
        case (_isFactory):   { 2 + floor random 2 };
        default              { 0 };
    };

    if (_atCount > 0) then {
        private _atGrp = createGroup east;
        private _atPool = if (!isNil "MERC_factions_RUS") then {
            MERC_factions_RUS select { _x find "at" >= 0 || _x find "rpg" >= 0 || _x find "AT" >= 0 || _x find "RPG" >= 0 }
        } else {
            ["O_Soldier_AT_F", "O_Soldier_LAT_F"]
        };
        if (count _atPool == 0) then { _atPool = ["O_Soldier_AT_F", "O_Soldier_LAT_F"]; };

        for "_i" from 1 to _atCount do {
            private _atPos = [_basePos, 10, 80, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
            if (count _atPos > 0) then {
                private _u = _atGrp createUnit [selectRandom _atPool, _atPos, [], 5, "NONE"];
                _u setSkill (0.5 + random 0.3);
            };
        };
        [_atGrp, _basePos, 120] call BIS_fnc_taskPatrol;
        _atGrp setBehaviour "COMBAT";
        _atGrp setVariable ["GFL_Remnant", true, true];
    };
};

// =====================================================
// 3. INFANTRY AA (selalu ada)
// =====================================================
private _aaCount = switch (true) do {
    case (_isMainBase): { 3 + floor random 2 };
    case (_isAirbase):   { 2 + floor random 2 };
    case (_isBase):      { 2 + floor random 1 };
    case (_isCity):      { 1 + floor random 1 };
    case (_isFactory):   { 1 + floor random 1 };
    case (_isRadio):     { 1 };
    default              { 0 };
};

if (_aaCount > 0) then {
    private _aaGrp = createGroup east;
    private _aaPool = if (!isNil "MERC_factions_RUS") then {
        MERC_factions_RUS select { _x find "aa" >= 0 || _x find "AA" >= 0 }
    } else {
        ["O_Soldier_AA_F"]
    };
    if (count _aaPool == 0) then { _aaPool = ["O_Soldier_AA_F"]; };

    for "_i" from 1 to _aaCount do {
        private _aaPos = [_basePos, 15, 90, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _aaPos > 0) then {
            private _u = _aaGrp createUnit [selectRandom _aaPool, _aaPos, [], 5, "NONE"];
            _u setSkill (0.5 + random 0.3);
        };
    };
    [_aaGrp, _basePos, 120] call BIS_fnc_taskPatrol;
    _aaGrp setBehaviour "COMBAT";
    _aaGrp setVariable ["GFL_Remnant", true, true];
};

// =====================================================
// 4. TANK MBT + TANK AA
// =====================================================
if (_hasTank) then {
    // MBT
    private _mbtCount = switch (true) do {
        case (_isMainBase): { 2 + floor random 2 };
        case (_isAirbase):   { 1 + floor random 1 };
        case (_isBase):      { 1 + floor random 1 };
        case (_isCity):      { 1 };
        case (_isFactory):   { 1 };
        default              { 0 };
    };

    for "_i" from 1 to _mbtCount do {
        private _mbtPool = if (!isNil "MERC_vehicles_RUS" && {count MERC_vehicles_RUS >= 4}) then {
            MERC_vehicles_RUS select [2, 3]  // BTR, T-72, T-90
        } else {
            ["O_MBT_02_cannon_F"]
        };
        private _mbtClass = selectRandom _mbtPool;
        private _mbtPos = [_basePos, 15, 70, 8, 0, 0.3, 0] call BIS_fnc_findSafePos;
        if (count _mbtPos > 0) then {
            private _veh = createVehicle [_mbtClass, _mbtPos, [], 0, "NONE"];
            _veh setDir random 360;
            createVehicleCrew _veh;
            [group driver _veh, _basePos, 200] call BIS_fnc_taskPatrol;
            (group driver _veh) setBehaviour "COMBAT";
        };
    };

    // AA Tank
    private _aaTankCount = switch (true) do {
        case (_isMainBase): { 1 + floor random 1 };
        default             { 1 };
    };

    for "_i" from 1 to _aaTankCount do {
        private _aaClass = selectRandom ["rhs_zsu234_aa", "O_APC_Tracked_02_AA_F"];
        private _aaPos = [_basePos, 20, 80, 8, 0, 0.3, 0] call BIS_fnc_findSafePos;
        if (count _aaPos > 0) then {
            private _veh = createVehicle [_aaClass, _aaPos, [], 0, "NONE"];
            _veh setDir random 360;
            createVehicleCrew _veh;
            [group driver _veh, _basePos, 200] call BIS_fnc_taskPatrol;
            (group driver _veh) setBehaviour "COMBAT";
        };
    };
};

// =====================================================
// 5. HELI KA-52 (hanya MAIN_BASE & AIRBASE)
// =====================================================
if (_isMainBase || _isAirbase) then {
    private _heliClass = if (!isNil "MERC_vehicles_RUS" && {count MERC_vehicles_RUS > 6}) then {
        MERC_vehicles_RUS select 6
    } else {
        "O_Heli_Attack_02_F"
    };
    
    private _heliCount = if (_isMainBase) then { 2 } else { 1 };
    for "_i" from 1 to _heliCount do {
        private _heliPos = [_basePos, 50, 150, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _heliPos > 0) then {
            private _heli = createVehicle [_heliClass, _heliPos, [], 0, "FLY"];
            _heli setDir random 360;
            createVehicleCrew _heli;
            (group driver _heli) setBehaviour "COMBAT";
            driver _heli flyInHeight 80;
        };
    };
};

// =====================================================
// 6. BANGUNAN (hanya base besar)
// =====================================================
if (_isBigBase) then {
    private _bunkerClasses = ["Land_BagBunker_Small_F", "Land_BagBunker_Tower_F", "Land_PillboxBunker_01_hex_F", "Land_Bunker_01_small_F"];
    private _towerClasses = ["Land_Tower_01_F", "Land_GuardTower_01_F"];
    private _smallBuildings = ["Land_GuardShed", "Land_Shed_02_F", "Land_CratesWooden_F", "Land_TentA_F"];

    // HQ Rusia
    if (_isMainBase) then {
        private _hqBuilding = selectRandom ["Land_Cargo_HQ_V1_F", "Land_Medevac_house_V1_F", "Land_StoneHouseBig_V1_F"];
        private _hqObj = createVehicle [_hqBuilding, _basePos, [], 0, "NONE"];
        _hqObj setDir random 360;
        _hqObj allowDamage true;
    };

    // Hangar
    if (_isAirbase) then {
        private _hangar = createVehicle ["Land_Hangar_F", _basePos getPos [30, 0], [], 0, "NONE"];
        _hangar setDir random 360;
        _hangar allowDamage true;
    };

    // 3 Bunker
    for "_i" from 1 to 3 do {
        private _bunkerPos = [_basePos, 40, 100, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _bunkerPos > 0) then {
            private _bunker = createVehicle [selectRandom _bunkerClasses, _bunkerPos, [], 0, "NONE"];
            _bunker setDir random 360;
            private _grp = createGroup east;
            private _unitPool = if (!isNil "MERC_factions_RUS") then { MERC_factions_RUS } else { ["O_Soldier_F", "O_Soldier_LAT_F"] };
            for "_j" from 1 to 2 do {
                private _unit = _grp createUnit [selectRandom _unitPool, _bunkerPos, [], 2, "NONE"];
                _unit setUnitPos "UP";
                _unit disableAI "PATH";
            };
            _grp setVariable ["GFL_Remnant", true, true];
        };
    };

    // 1-2 Tower
    for "_i" from 1 to (1 + floor random 2) do {
        private _towerPos = [_basePos, 50, 130, 4, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _towerPos > 0) then {
            private _tower = createVehicle [selectRandom _towerClasses, _towerPos, [], 0, "NONE"];
            _tower setDir random 360;
            private _grp = createGroup east;
            private _unitPool = if (!isNil "MERC_factions_RUS") then { MERC_factions_RUS } else { ["O_Soldier_F"] };
            private _unit = _grp createUnit [selectRandom _unitPool, _towerPos, [], 0, "NONE"];
            _unit moveInAny _tower;
            _unit setSkill 0.6;
        };
    };

    // 1-2 Bangunan kecil
    for "_i" from 1 to (1 + floor random 2) do {
        private _smallPos = [_basePos, 30, 90, 3, 0, 0.4, 0] call BIS_fnc_findSafePos;
        if (count _smallPos > 0) then {
            createVehicle [selectRandom _smallBuildings, _smallPos, [], 0, "NONE"] setDir random 360;
        };
    };

    // Crate loot
    if (_isMainBase || _isAirbase || _isBase) then {
        private _cratePos = _basePos getPos [5, random 360];
        private _crate = createVehicle ["Box_East_Wps_F", _cratePos, [], 0, "CAN_COLLIDE"];
        _crate setDir random 360;
        _crate allowDamage false;
        {
            _crate addWeaponCargoGlobal [_x, 1];
        } forEach ["rhs_weap_ak74m", "rhs_weap_pkp", "rhs_weap_rpg7"];
        {
            _crate addMagazineCargoGlobal [_x, 3];
        } forEach ["rhs_30Rnd_545x39_7N10_AK", "rhs_100Rnd_762x54mmR", "rhs_rpg7_PG7VL_mag"];
        {
            _crate addItemCargoGlobal [_x, 1];
        } forEach ["rhs_acc_1p29", "Vest_PlateCarrier2_rgr", "H_HelmetO_ocamo"];
    };
};

diag_log format ["RUSSIA BASE SPAWN: %1 siap (MBT+AA+AT+AA Inf).", _baseType];