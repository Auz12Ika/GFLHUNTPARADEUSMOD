/*
    File: data\garageData.sqf
    Description: Garage data initialization. Load from profile.
*/

if (!isServer) exitWith {};

// Initialize garage data
MERC_garage_data = profileNamespace getVariable ["MERC_save_garage_data", []];
publicVariable "MERC_garage_data";

diag_log format ["[GARAGE] Data loaded. Total vehicles: %1", count MERC_garage_data];