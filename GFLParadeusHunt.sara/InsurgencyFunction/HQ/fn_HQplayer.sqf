/*
    File: HQplayer.sqf
    Description: Orcestra HQ
*/
params [["_hqVeh", objNull]];
if (isNull _hqVeh) exitWith {};

// Server Side Logic
if (isServer) then {
    [_hqVeh] call HQ_fnc_HQ_init;
    [_hqVeh] call HQ_fnc_HQ_destroy;
};

// Client Side Actions (Menu Interaksi)
if (hasInterface) then {
    removeAllActions _hqVeh;
    // fn_HQ_deploy tidak dipanggil di sini karena tombolnya sudah di player
    [_hqVeh] call HQ_fnc_HQ_teleport;
};