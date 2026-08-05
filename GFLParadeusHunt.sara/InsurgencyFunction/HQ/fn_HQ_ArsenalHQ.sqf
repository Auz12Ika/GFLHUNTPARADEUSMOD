/*
    File: fn_HQ_ArsenalHQ.sqf
    Description: Open HQ Arsenal (Client Local)
*/

if (!hasInterface) exitWith {};

systemChat "Membuka Arsenal...";

// ======================================================
// Pastikan Dummy Arsenal Local ada
// ======================================================

private _dummy = missionNamespace getVariable ["MERC_LocalArsenal", objNull];

if (isNull _dummy) then {

    _dummy = "Box_NATO_Equip_F" createVehicleLocal [0,0,0];

    _dummy allowDamage false;
    _dummy enableSimulation false;
    _dummy hideObject true;

    missionNamespace setVariable
    [
        "MERC_LocalArsenal",
        _dummy
    ];
};

// ======================================================
// Ambil whitelist terbaru
// ======================================================

private _wl = missionNamespace getVariable
[
    "MERC_HQ_ArsenalWhitelist",
    []
];

if (_wl isEqualTo []) exitWith
{
    hint "HQ Arsenal whitelist not received.";
};

// ======================================================
// Bersihkan Virtual Cargo lama
// ======================================================

clearWeaponCargo _dummy;
clearMagazineCargo _dummy;
clearItemCargo _dummy;
clearBackpackCargo _dummy;

// ======================================================
// Bangun ulang Virtual Arsenal
// ======================================================

[_dummy, _wl select 0, true] call BIS_fnc_addVirtualWeaponCargo;
[_dummy, _wl select 1, true] call BIS_fnc_addVirtualMagazineCargo;
[_dummy, _wl select 2, true] call BIS_fnc_addVirtualItemCargo;
[_dummy, _wl select 3, true] call BIS_fnc_addVirtualBackpackCargo;

// ======================================================
// Open BIS Arsenal
// ======================================================

["Open",[false,_dummy]] call BIS_fnc_arsenal;