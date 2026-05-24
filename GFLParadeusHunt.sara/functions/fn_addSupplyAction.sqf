/*
    File: fn_addSupplyAction.sqf
    Description: Menambahkan aksi Arsenal berfaksi ke truk supply.
*/
params [["_truck", objNull]];
if (isNull _truck) exitWith {};

_truck addAction [
    "<t color='#FFA500'>[RAMPAS] Akses Gudang Senjata</t>",
    {
        params ["_target", "_caller"];
        
        // Ambil faksi dari truk
        private _faction = _target getVariable ["MERC_supplyFaction", "MERC"];
        
        // Kosongkan kargo virtual truk
        [_target, true, false] call BIS_fnc_clearVirtualCargo;
        
        // Isi sesuai faksi
        switch (_faction) do {
            case "USA": {
                [_target, ["rhs_weap_m4a1_carryhandle", "rhs_weap_m16a4_carryhandle", "rhs_weap_m249_pip"], false, true] call BIS_fnc_addVirtualWeaponCargo;
                [_target, ["rhs_mag_30Rnd_556x45_M855A1_Stanag", "rhsusf_200Rnd_556x45_box"], false, true] call BIS_fnc_addVirtualMagazineCargo;
                [_target, ["rhsusf_acc_ACOG", "rhsusf_acc_nt4_black", "rhs_weap_M136", "rhs_m136_mag"], false, true] call BIS_fnc_addVirtualItemCargo;
                [_target, ["rhsusf_assault_eagleaiii_coy"], false, true] call BIS_fnc_addVirtualBackpackCargo;
            };
            case "RUSSIA": {
                [_target, ["rhs_weap_ak74m", "rhs_weap_akm", "rhs_weap_pkp"], false, true] call BIS_fnc_addVirtualWeaponCargo;
                [_target, ["rhs_30Rnd_545x39_7N10_AK", "rhs_100Rnd_762x54mmR"], false, true] call BIS_fnc_addVirtualMagazineCargo;
                [_target, ["rhs_acc_1p29", "rhs_acc_dtk", "rhs_weap_rpg7", "rhs_rpg7_PG7VL_mag"], false, true] call BIS_fnc_addVirtualItemCargo;
                [_target, ["rhs_sidor"], false, true] call BIS_fnc_addVirtualBackpackCargo;
            };
            case "MERC": {
                [_target, ["arifle_SDAR_F", "SMG_01_F", "srifle_DMR_06_olive_F", "LMG_Mk200_F"], false, true] call BIS_fnc_addVirtualWeaponCargo;
                [_target, ["20Rnd_556x45_UW_mag", "30Rnd_45ACP_Mag_SMG_01", "20Rnd_762x51_Mag", "200Rnd_65x39_cased_Box"], false, true] call BIS_fnc_addVirtualMagazineCargo;
                [_target, ["optic_ACO_grn", "muzzle_snds_acp", "HandGrenade"], false, true] call BIS_fnc_addVirtualItemCargo;
                [_target, ["B_FieldPack_oli"], false, true] call BIS_fnc_addVirtualBackpackCargo;
            };
        };

        // Buka Arsenal dengan filter dari truk
        ["Open", [true, _target]] call BIS_fnc_arsenal;
        hint format ["Anda mengakses gudang senjata faksi %1!", _faction];
    },
    nil,
    1.5,
    true,
    true,
    "",
    "alive _target && {player distance _target < 7}"
];