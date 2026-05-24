/*
    Author: Modder
    File: fn_spawnGroup.sqf
    Description: Spawn 1 grup AI dari pool faksi (FUNGSI DASAR).
    🔧 FIX P1: Dipisahkan dari batch controller untuk mencegah rekursi.
    
    Params:
        _pos        - Posisi spawn
        _factionID  - "USA" / "RUSSIA" / "CULT" / "MERC" / "CIV"
        _baseType   - "CITY" / "BASE" / "MAIN_BASE" / "AIRBASE" / dll
        _isPatrol   - true = patroli, false = garrison
    
    Returns: Group atau grpNull
*/

params [
    ["_pos", [0,0,0], [[]]],
    ["_factionID", "USA", [""]],
    ["_baseType", "CITY", [""]],
    ["_isPatrol", true, [true]]
];

if (!isServer) exitWith { grpNull };

// --- TENTUKAN SIDE & UNIT POOL ---
private _side = west;
private _unitPool = [];

switch (toUpper _factionID) do {
    case "USA": {
        _side = west;
        _unitPool = if (!isNil "MERC_factions_USA") then { MERC_factions_USA } else { ["B_Soldier_F", "B_Soldier_GL_F", "B_Soldier_LAT_F", "B_Soldier_AR_F", "B_Medic_F"] };
    };
    case "RUSSIA": {
        _side = east;
        _unitPool = if (!isNil "MERC_factions_RUS") then { MERC_factions_RUS } else { ["O_Soldier_F", "O_Soldier_GL_F", "O_Soldier_LAT_F", "O_Soldier_AR_F", "O_Medic_F"] };
    };
    case "CULT": {
        _side = east;
        _unitPool = if (!isNil "MERC_factions_CULT") then { MERC_factions_CULT } else { ["I_Soldier_F", "I_Soldier_LAT_F", "I_Soldier_AR_F"] };
    };
    case "MERC": {
        _side = independent;
        _unitPool = if (!isNil "MERC_factions_MERC") then { MERC_factions_MERC } else { ["I_Soldier_F", "I_Soldier_LAT_F", "I_Soldier_AR_F"] };
    };
    case "CIV": {
        _side = civilian;
        _unitPool = if (!isNil "MERC_factions_CIV") then { MERC_factions_CIV } else { ["C_man_1", "C_man_polo_1_F", "C_man_shorts_1_F"] };
    };
    default {
        diag_log format ["MERC SPAWN: Faksi tidak dikenal: %1", _factionID];
        grpNull
    };
};

if (count _unitPool == 0) exitWith {
    diag_log format ["MERC SPAWN: Unit pool kosong untuk faksi %1", _factionID];
    grpNull
};

// --- TENTUKAN UKURAN GRUP BERDASARKAN TIPE BASE ---
private _groupSize = 4;
switch (_baseType) do {
    case "MAIN_BASE": { _groupSize = 6 + (round random 4); };  // 6-10
    case "AIRBASE":   { _groupSize = 5 + (round random 3); };  // 5-8
    case "BASE":      { _groupSize = 4 + (round random 4); };  // 4-8
    case "CITY":      { _groupSize = 3 + (round random 3); };  // 3-6
    case "FACTORY":   { _groupSize = 3 + (round random 3); };  // 3-6
    case "RADIO":     { _groupSize = 2 + (round random 2); };  // 2-4
    case "HARBOR":    { _groupSize = 3 + (round random 3); };  // 3-6
    default           { _groupSize = 3 + (round random 3); };
};

_groupSize = _groupSize min 10; // Batas maksimal 10 per grup

// --- SPAWN GRUP ---
private _grp = createGroup [_side, true];

for "_i" from 1 to _groupSize do {
    private _uClass = selectRandom _unitPool;
    private _spawnPos = [_pos, 0, 40, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
    
    if (count _spawnPos == 0) then {
        _spawnPos = _pos getPos [random 30, random 360];
    };
    
    private _unit = _grp createUnit [_uClass, _spawnPos, [], 5, "NONE"];
    _unit setSkill (0.3 + random 0.4);
};

// --- SET BEHAVIOR ---
if (_isPatrol) then {
    [_grp, _pos, 200] call BIS_fnc_taskPatrol;
    _grp setBehaviour "SAFE";
    _grp setSpeedMode "LIMITED";
} else {
    // Garrison: diam di posisi, jaga area
    _grp setBehaviour "SAFE";
    _grp setSpeedMode "NORMAL";
    {
        _x disableAI "PATH";
        _x setUnitPos "UP";
    } forEach (units _grp);
};

// --- SET VARIABEL ---
_grp setVariable ["MERC_OriginFaction", _factionID, true];
_grp setVariable ["MERC_OriginBaseType", _baseType, true];

diag_log format ["MERC SPAWN: Grup %1 (%2 unit) spawned untuk %3 di %4", _grp, _groupSize, _factionID, _baseType];

_grp