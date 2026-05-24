/*
    File: fn_spawnInitialHQ.sqf
    Description: Spawn BTR HQ di Isla de Zora (Sahrani). Buat marker respawn.
*/

if (!isServer) exitWith {};

// Posisi aman di Isla de Zora (pojok kanan bawah Sahrani)
private _initialPos = [16850, 17050, 0];

// Cari posisi darat yang valid di sekitar situ
_initialPos = [_initialPos, 0, 100, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;

// Spawn BTR HQ
private _hqVeh = createVehicle ["rhs_btr82a_msv", _initialPos, [], 0, "NONE"];
_hqVeh setVariable ["isDeployed", false, true];
_hqVeh setVariable ["MERC_HQ_HomePos", _initialPos, true]; // Simpan posisi awal untuk respawn
missionNamespace setVariable ["MERC_Player_HQ", _hqVeh, true];

// Buat marker respawn di Isla de Zora
if (markerType "respawn_guerrila" == "") then {
    createMarker ["respawn_guerrila", _initialPos];
};
"respawn_guerrila" setMarkerPos _initialPos;
"respawn_guerrila" setMarkerType "b_hq";
"respawn_guerrila" setMarkerColor "ColorGreen";
"respawn_guerrila" setMarkerText "GFL MAIN BASE";

// Jalankan menu HQ untuk semua client
[_hqVeh] remoteExec ["MERC_fnc_HQplayer", 0, true];

diag_log format ["GFL SETUP: HQ awal spawned di Isla de Zora: %1", _initialPos];