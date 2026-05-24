/*
    File: fn_transferSupply.sqf
    Description: Memindahkan kargo truk supply ke Arsenal HQ.
                 Menambah counter unlock. Jika counter cukup, item jadi Unlimited.
    🔧 Dipanggil dari aksi di HQ.
*/
params [["_truck", objNull], ["_hq", objNull]];

if (!isServer) exitWith {};
if (isNull _truck || isNull _hq) exitWith {};

private _cargo = _truck getVariable ["MERC_supplyCargo", []];
if (count _cargo == 0) exitWith { systemChat "Truk ini tidak membawa kargo."; };

private _faction = _truck getVariable ["MERC_supplyFaction", "UNKNOWN"];
_cargo params [["_weapons", []], ["_magazines", []], ["_items", []], ["_backpacks", []]];

// Transfer ke Arsenal HQ
{
    [_hq, _x, true] call BIS_fnc_addVirtualWeaponCargo;
} forEach _weapons;
{
    [_hq, _x, true] call BIS_fnc_addVirtualMagazineCargo;
} forEach _magazines;
{
    [_hq, _x, true] call BIS_fnc_addVirtualItemCargo;
} forEach _items;
{
    [_hq, _x, true] call BIS_fnc_addVirtualBackpackCargo;
} forEach _backpacks;

// Update counter unlock global
private _counterVar = format ["MERC_unlock_%1", _faction];
private _counter = missionNamespace getVariable [_counterVar, 0];
_counter = _counter + 1;
missionNamespace setVariable [_counterVar, _counter, true];

// Cek threshold unlimited (default 5 kali transfer)
private _threshold = if (!isNil "merc_unlock_requirement") then { merc_unlock_requirement select 0 } else { 5 };
if (_counter >= _threshold) then {
    missionNamespace setVariable [format ["MERC_unlock_%1_done", _faction], true, true];
    systemChat format ["GUDANG: Senjata faksi %1 sekarang UNLIMITED di Arsenal HQ!", _faction];
};

// Kosongkan truk
_truck setVariable ["MERC_supplyCargo", [], true];
_truck setVariable ["MERC_supplyLooted", true, true];

systemChat format ["Kargo faksi %1 telah ditransfer ke gudang HQ. (%2/%3)", _faction, _counter, _threshold];