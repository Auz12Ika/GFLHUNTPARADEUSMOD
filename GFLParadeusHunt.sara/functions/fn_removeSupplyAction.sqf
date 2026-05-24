/*
    File: fn_removeSupplyAction.sqf
    Description: Menghapus semua aksi dari truk supply yang hancur.
*/
params [["_truck", objNull]];
if (isNull _truck) exitWith {};

{
    _truck removeAction _x;
} forEach (actionIDs _truck);