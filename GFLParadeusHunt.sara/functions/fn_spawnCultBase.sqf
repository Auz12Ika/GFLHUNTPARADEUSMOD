/*
    Author: Modder
    File: fn_spawnCultBase.sqf
    Description: Membangun markas Cult (Paradeus) dengan bunker, HQ, tower, crate, dan BOSS.
    🔧 FINAL: Data-driven. Bos random Bellator137 / Niter. Bos mati = base hancur.
*/

params [["_basePos", [0,0,0]], ["_baseType", "BASE"]];

if (!isServer) exitWith {};

// --- POOL BANGUNAN ---
private _bunkerClasses = ["Land_BagBunker_Small_F", "Land_BagBunker_Tower_F", "Land_PillboxBunker_01_hex_F", "Land_Bunker_01_small_F"];
private _smallBuildings = ["Land_TentDome_F", "Land_TentA_F", "Land_GuardShed", "Land_Shed_02_F", "Land_CratesWooden_F"];
private _towerClasses = ["Land_Tower_01_F", "Land_GuardTower_01_F", "Land_Cargo_Patrol_V1_F"];

// --- HQ CULT ---
private _hqBuilding = selectRandom ["Land_Medevac_house_V1_F", "Land_Cargo_House_V1_F", "Land_StoneHouseBig_V1_F", "Land_Chapel_V1_F"];
private _hqObj = createVehicle [_hqBuilding, _basePos, [], 0, "NONE"];
_hqObj setDir random 360;
_hqObj allowDamage true;
_hqObj setVariable ["Cult_HQ", true, true];

// --- 3 BUNKER ---
for "_i" from 1 to 3 do {
    private _bunkerPos = [_basePos, 50, 120, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
    if (count _bunkerPos > 0) then {
        private _bunker = createVehicle [selectRandom _bunkerClasses, _bunkerPos, [], 0, "NONE"];
        _bunker setDir random 360;
        private _grp = createGroup east;
        private _unitPool = if (!isNil "MERC_factions_CULT") then { MERC_factions_CULT select [0,4] } else { ["I_Soldier_F", "I_Soldier_LAT_F"] };
        for "_j" from 1 to 2 do {
            private _unit = _grp createUnit [selectRandom _unitPool, _bunkerPos, [], 2, "NONE"];
            _unit setUnitPos "UP";
            _unit disableAI "PATH";
        };
        _grp setVariable ["GFL_Remnant", true, true];
    };
};

// --- 1-2 BANGUNAN KECIL ---
for "_i" from 1 to (1 + floor random 2) do {
    private _smallPos = [_basePos, 30, 100, 3, 0, 0.4, 0] call BIS_fnc_findSafePos;
    if (count _smallPos > 0) then {
        createVehicle [selectRandom _smallBuildings, _smallPos, [], 0, "NONE"] setDir random 360;
    };
};

// --- 1-2 TOWER ---
for "_i" from 1 to (1 + floor random 2) do {
    private _towerPos = [_basePos, 60, 140, 4, 0, 0.5, 0] call BIS_fnc_findSafePos;
    if (count _towerPos > 0) then {
        private _tower = createVehicle [selectRandom _towerClasses, _towerPos, [], 0, "NONE"];
        _tower setDir random 360;
        private _grp = createGroup east;
        private _unitPool = if (!isNil "MERC_factions_CULT") then { MERC_factions_CULT select [0,4] } else { ["I_Soldier_F"] };
        private _unit = _grp createUnit [selectRandom _unitPool, _towerPos, [], 0, "NONE"];
        _unit moveInAny _tower;
        _unit setSkill 0.6;
    };
};

// --- CRATE LOOT ---
private _cratePos = _basePos getPos [5, random 360];
private _crate = createVehicle ["Box_IND_Wps_F", _cratePos, [], 0, "CAN_COLLIDE"];
_crate setDir random 360;
_crate allowDamage false;
{
    _crate addWeaponCargoGlobal [_x, 1];
} forEach ["arifle_SDAR_F", "SMG_01_F"];
{
    _crate addMagazineCargoGlobal [_x, 3];
} forEach ["30Rnd_556x45_Stanag", "30Rnd_45ACP_Mag_SMG_01", "HandGrenade"];
{
    _crate addItemCargoGlobal [_x, 1];
} forEach ["optic_ACO_grn", "muzzle_snds_acp", "Vest_PlateCarrier1_rgr", "H_Beret_Colonel"];

// --- BOSS RANDOM ---
private _bossPool = ["tacgirls_paradeus_bellator137", "tacgirls_paradeus_niter"];
private _bossClass = selectRandom _bossPool;
private _bossGrp = createGroup east;
private _boss = _bossGrp createUnit [_bossClass, _basePos, [], 10, "NONE"];
_boss setSkill 1.0;
_boss setRank "COLONEL";
_boss allowFleeing 0;
_boss setVariable ["Cult_Boss", true, true];

// 2-3 pengawal elit (Doppel)
for "_i" from 1 to (2 + floor random 2) do {
    private _guard = _bossGrp createUnit ["tacgirls_paradeus_doppel", _basePos, [], 5, "NONE"];
    _guard setSkill 0.8;
};

[_bossGrp, _basePos, 80] call BIS_fnc_taskPatrol;
_bossGrp setBehaviour "COMBAT";

// --- EVENT: BOSS MATI = BASE HANCUR ---
_boss addEventHandler ["Killed", {
    params ["_unit"];
    
    private _buildings = nearestObjects [_unit, ["Building", "House", "Ruins"], 200];
    { if (!isPlayer _x && {getObjectType _x >= 8}) then { _x setDamage 1; }; } forEach _buildings;
    
    private _structures = nearestObjects [_unit, ["Static", "Thing"], 200];
    { _x setDamage 1; } forEach _structures;
    
    systemChat "BOSS CULT TELAH DIHANCURKAN! Markas Cult runtuh.";
    diag_log "CULT BASE: Boss mati, markas dihancurkan.";
}];

// --- GARRISON INFANTRY ---
[_basePos, "CULT", _baseType, true] call MERC_fnc_spawnGroupUniversal;

diag_log format ["CULT BASE: Markas %1 dengan BOSS %2 dibangun.", _baseType, _bossClass];