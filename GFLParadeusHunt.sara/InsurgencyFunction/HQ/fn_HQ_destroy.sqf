/*
    File: fn_HQ_destroy.sqf
    Description: Trigger Kehancuran (Server Side Only)
*/
params [["_hqVeh", objNull]];
if (isNull _hqVeh) exitWith {};
if (!isServer) exitWith {}; 

_hqVeh removeAllEventHandlers "Killed";

_hqVeh addEventHandler ["Killed", {
    missionNamespace setVariable ["MERC_HQ_IsDestroyed", true, true];
    
    private _homePos = missionNamespace getVariable ["MERC_HQ_HomePos", [16850, 17050, 0]];
    "respawn_guerrila" setMarkerPos _homePos;
    
    ["TaskFailed", ["", "HQ Hancur! Menunggu unit baru dikirim..."]] remoteExec ["BIS_fnc_showNotification", 0];
}];