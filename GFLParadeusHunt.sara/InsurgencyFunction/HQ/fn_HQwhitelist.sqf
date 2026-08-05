/*
    File: fn_HQWhitelist.sqf
    Description:
    Receive HQ Arsenal whitelist from server.
*/

params ["_whitelist"];

if !(_whitelist isEqualType []) exitWith {};

if ((count _whitelist) != 4) exitWith {};

missionNamespace setVariable [
    "MERC_HQ_ArsenalWhitelist",
    _whitelist
];