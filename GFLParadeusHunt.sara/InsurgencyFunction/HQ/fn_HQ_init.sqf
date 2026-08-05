/*
    File: fn_HQ_init.sqf
    Description: Inisialisasi dasar HQ (Server: marker, Client: flag).
*/
params [["_hqVeh", objNull]];
if (isNull _hqVeh) exitWith {};

// Flag dasar (client & server)
_hqVeh setVariable ["isDeployed", false, true];
_hqVeh engineOn false;
_hqVeh lock 0;

// Simpan posisi awal
if (isNil {missionNamespace getVariable "MERC_HQ_HomePos"}) then {
    missionNamespace setVariable ["MERC_HQ_HomePos", getPosATL _hqVeh, true];
};

// Variabel global
missionNamespace setVariable ["MERC_Player_HQ", _hqVeh, true];
missionNamespace setVariable ["merc_hq_position", getPosATL _hqVeh, true];

// HANYA SERVER yang mengelola marker
if (isServer) then {
    // Marker mobile
    deleteMarker "marker_mobile_hq";
    private _m = createMarker ["marker_mobile_hq", getPosATL _hqVeh];
    _m setMarkerType "b_hq";
    _m setMarkerColor "ColorGreen";
    _m setMarkerText "ACTIVE MERC HQ";

    // Update marker mobile setiap 3 detik
    [_hqVeh] spawn {
        params ["_veh"];
        while {alive _veh} do {
            "marker_mobile_hq" setMarkerPos (getPosATL _veh);
            sleep 3;
        };
    };

    // Marker respawn
    if (markerType "respawn_guerrila" == "") then {
        createMarker ["respawn_guerrila", getPosATL _hqVeh];
        "respawn_guerrila" setMarkerType "b_hq";
        "respawn_guerrila" setMarkerColor "ColorGreen";
        "respawn_guerrila" setMarkerText "GFL MAIN BASE";
    };
    "respawn_guerrila" setMarkerPos (getPosATL _hqVeh);
};