/*
    Author: Modder
    File: fn_spawnRandomMerc.sqf
    Description: Spawn patroli Mercenary (Sangvis/Mange) atau Truk Supply berfaksi.
    🔧 FINAL: Data-driven. Pool kendaraan & unit dari factions.sqf.
            25% Truk Supply dengan kargo sesuai faksi (USA/RUS/MERC).
*/

params [["_pos", [0,0,0]]];

if (!isServer) exitWith {};

// 1. TENTUKAN TIPE SPAWN
private _isSupplyTruck = (random 100 < 25);
private _supplyFaction = selectRandom ["USA", "RUSSIA", "MERC"];

// 2. PILIH KENDARAAN
private _vehClass = "";
private _groupSize = 0;

if (_isSupplyTruck) then {
    switch (_supplyFaction) do {
        case "USA": {
            _vehClass = "rhsusf_M1078A1P2_B_d_flatbed_fmtv_usarmy";
            if (!isClass (configFile >> "CfgVehicles" >> _vehClass)) then {
                _vehClass = "B_Truck_01_transport_F";
            };
        };
        case "RUSSIA": {
            _vehClass = "RHS_Ural_Open_MSV_01";
            if (!isClass (configFile >> "CfgVehicles" >> _vehClass)) then {
                _vehClass = "O_Truck_02_transport_F";
            };
        };
        case "MERC": {
            if (!isNil "MERC_vehicles_MERC" && {count MERC_vehicles_MERC > 4}) then {
                _vehClass = MERC_vehicles_MERC select 4;
            } else {
                _vehClass = "I_Truck_02_transport_F";
            };
        };
    };
    _groupSize = 3 + floor random 2;
} else {
    private _combatVehicles = if (!isNil "MERC_vehicles_MERC") then {
        MERC_vehicles_MERC select [0, 4]
    } else {
        ["I_MRAP_03_hmg_F", "I_MRAP_03_F", "I_C_Offroad_02_LMG_F"]
    };
    _vehClass = selectRandom _combatVehicles;
    _groupSize = 4 + round random 4;
};

// 3. SPAWN KENDARAAN
private _spawnPos = [_pos, 0, 100, 7, 0, 0.3, 0] call BIS_fnc_findSafePos;
if (count _spawnPos == 0) exitWith { diag_log "MERC SPAWN: Tidak ada posisi aman."; };

private _veh = createVehicle [_vehClass, _spawnPos, [], 0, "NONE"];
_veh setDir random 360;

// 4. SPAWN GRUP PENJAGA
private _grp = createGroup independent;
private _unitPool = if (!isNil "MERC_factions_MERC") then { MERC_factions_MERC } else { ["I_Soldier_F", "I_Soldier_LAT_F"] };

for "_i" from 1 to _groupSize do {
    private _unit = _grp createUnit [selectRandom _unitPool, _spawnPos, [], 5, "NONE"];
    _unit moveInAny _veh;
};

// 5. KONFIGURASI TRUK SUPPLY
if (_isSupplyTruck) then {
    _veh setVariable ["MERC_supplyTruck", true, true];
    _veh setVariable ["MERC_supplyFaction", _supplyFaction, true];
    _veh setVariable ["MERC_supplyLooted", false, true];
    
    // ISI KARGO
    switch (_supplyFaction) do {
        case "USA": {
            _veh setVariable ["MERC_supplyCargo", [
                ["rhs_weap_m4a1_carryhandle", "rhs_weap_m16a4_carryhandle", "rhs_weap_m249_pip"],
                ["rhs_mag_30Rnd_556x45_M855A1_Stanag", "rhsusf_200Rnd_556x45_box", "rhs_mag_m67"],
                ["rhsusf_acc_ACOG", "rhsusf_acc_nt4_black"],
                ["rhsusf_assault_eagleaiii_coy"]
            ], true];
        };
        case "RUSSIA": {
            _veh setVariable ["MERC_supplyCargo", [
                ["rhs_weap_ak74m", "rhs_weap_akm", "rhs_weap_pkp"],
                ["rhs_30Rnd_545x39_7N10_AK", "rhs_100Rnd_762x54mmR", "rhs_mag_rgd5"],
                ["rhs_acc_1p29", "rhs_acc_dtk"],
                ["rhs_sidor"]
            ], true];
        };
        case "MERC": {
            _veh setVariable ["MERC_supplyCargo", [
                ["arifle_SDAR_F", "SMG_01_F", "srifle_DMR_06_olive_F"],
                ["20Rnd_556x45_UW_mag", "30Rnd_45ACP_Mag_SMG_01", "HandGrenade"],
                ["optic_ACO_grn", "muzzle_snds_acp"],
                ["B_FieldPack_oli"]
            ], true];
        };
    };
    
    [_grp, _pos, 200] call BIS_fnc_taskPatrol;
    _grp setBehaviour "SAFE";
    _grp setSpeedMode "LIMITED";
    
    diag_log format ["MERC SUPPLY: Truk %1 faksi %2 di %3", _vehClass, _supplyFaction, _pos];
} else {
    [_grp, _pos, 5000] call BIS_fnc_taskPatrol;
    _grp setBehaviour "SAFE";
    _grp setSpeedMode "LIMITED";
};

// 6. CLEANUP
_veh addEventHandler ["Killed", {
    params ["_unit"];
    if (_unit getVariable ["MERC_supplyTruck", false]) then {
        systemChat "Truk supply hancur! Kargo tidak bisa diselamatkan.";
    };
    { moveOut _x; } forEach (crew _unit);
    (group driver _unit) setBehaviour "COMBAT";
}];

diag_log format ["MERC SPAWN: %1 (%2 unit) tipe %3", _vehClass, _groupSize, ["Tempur", "Supply"] select _isSupplyTruck];