/*
    File: fn_garageStore.sqf
    Description: Store vehicle into HQ garage. Data saved to missionNamespace.
*/
params [["_veh", objNull]];

if (isNull _veh) exitWith { diag_log "[GARAGE] Error: No vehicle provided."; };
if (!alive _veh) exitWith { diag_log "[GARAGE] Error: Vehicle is destroyed."; };

private _class = typeOf _veh;
private _displayName = getText (configFile >> "CfgVehicles" >> _class >> "displayName");

if (isNil "MERC_garage_data") then { MERC_garage_data = []; };

private _entry = [_class, _displayName, time, name player];
MERC_garage_data pushBack _entry;
publicVariable "MERC_garage_data";

deleteVehicle _veh;

diag_log format ["[GARAGE] Stored: %1 by %2. Total: %3", _displayName, name player, count MERC_garage_data];
systemChat format ["Vehicle stored: %1. Garage: %2", _displayName, count MERC_garage_data];