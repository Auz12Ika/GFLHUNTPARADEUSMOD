/*
    Author: Modder
    File: fn_HQplayer.sqf
    Description: Full Mobile HQ System - Eitan AFV Version.
    Fitur: 
    1. HQ adalah VIP (Hancur = Semua Player Mati + Penalti).
    2. Deploy Mode & Teleport Sekali Pakai.
    3. Arsenal, Hire Mercenary, Base Builder, Confiscate, Garage, Skip Time, Save, Intel.
    4. Auto-Respawn HQ di posisi awal (editor) 5 detik setelah hancur.
    🔧 FINAL: HQ mati = pemain mati + teleport direset + HQ baru muncul dalam 5 detik.
*/

params [["_hqVeh", objNull]];

if (isNull _hqVeh) exitWith {};

// =====================================================
// 1. INISIALISASI & SIMPAN POSISI AWAL (EDITOR)
// =====================================================
_hqVeh setVariable ["isDeployed", true, true];
_hqVeh engineOn false;
_hqVeh lock 2;

if (isNil {_hqVeh getVariable "MERC_HQ_HomePos"}) then {
    _hqVeh setVariable ["MERC_HQ_HomePos", getPos _hqVeh, true];
};
missionNamespace setVariable ["MERC_Player_HQ", _hqVeh, true];
missionNamespace setVariable ["merc_hq_position", getPos _hqVeh, true];

deleteMarker "marker_mobile_hq";
private _m = createMarker ["marker_mobile_hq", getPos _hqVeh];
_m setMarkerType "b_hq";
_m setMarkerColor "ColorGreen";
_m setMarkerText "ACTIVE MERC HQ";

if (markerType "respawn_guerrila" == "") then {
    createMarker ["respawn_guerrila", getPos _hqVeh];
};
"respawn_guerrila" setMarkerPos getPos _hqVeh;
"respawn_guerrila" setMarkerType "b_hq";
"respawn_guerrila" setMarkerColor "ColorGreen";
"respawn_guerrila" setMarkerText "GFL MAIN BASE";

// =====================================================
// 2. EVENT: HQ HANCUR (Pemain Mati, Denda, Teleport Reset, Respawn 5 Detik)
// =====================================================
_hqVeh addEventHandler ["Killed", {
    params ["_unit"];
    
    private _penalty = 5000;
    if (!isNil "merc_penalty") then {
        { if ((_x select 0) == "HQ_VIC_DESTROYED") exitWith { _penalty = _x select 1; }; } forEach merc_penalty;
    };
    private _currentMoney = missionNamespace getVariable ["merc_money", 0];
    missionNamespace setVariable ["merc_money", (_currentMoney - _penalty), true];

    "Bo_Mk82" createVehicle (getPos _unit);

    [format ["Denda Kerugian: -$%1. HQ Baru sedang dikirim.", _penalty]] remoteExec ["MERC_fnc_triggerHQFailure", 0];
}];

MERC_fnc_triggerHQFailure = {
    params [["_msg", ""]];
    if (!hasInterface) exitWith {};

    titleText [format ["<t color='#ff0000' size='2'>HQ DESTROYED</t><br/>%1", _msg], "PLAIN DOWN", -1, true, true];
    sleep 2;
    
    // Server menyiapkan HQ baru dan reset teleport
    if (isServer) then {
        [] spawn {
            sleep 5;
            
            private _homePos = missionNamespace getVariable ["MERC_Player_HQ", objNull] getVariable ["MERC_HQ_HomePos", [16850, 17050, 0]];
            
            private _newHQ = createVehicle [typeOf (missionNamespace getVariable ["MERC_Player_HQ", objNull]), _homePos, [], 0, "NONE"];
            _newHQ setVariable ["MERC_HQ_HomePos", _homePos, true];
            [_newHQ] remoteExec ["MERC_fnc_HQplayer", 0, true];
            
            // Reset teleport untuk semua pemain
            {
                _x setVariable ["MERC_teleport_used", false, true];
            } forEach allPlayers;
            
            diag_log "HQ SYSTEM: HQ respawn di lokasi awal. Teleport direset.";
        };
    };

    // Pemain mati setelah server siapkan HQ baru
    if (alive player) then {
        player setDamage 1;
    };
};

// =====================================================
// 3. DEPLOY & PACK UP (Manual)
// =====================================================
_hqVeh addAction [
    "<t color='#00FF00'>[HQ] DEPLOY BASE</t>", 
    {
        params ["_target", "_caller"];
        _target setVariable ["isDeployed", true, true];
        "respawn_guerrila" setMarkerPos getPos _target;
        _target engineOn false; _target lock 2;
        hint "HQ Deployed. Respawn point updated.";
    },
    nil, 6, true, true, "", "!(_target getVariable ['isDeployed', false]) && (speed _target < 1)"
];

_hqVeh addAction [
    "<t color='#FF0000'>[HQ] PACK UP</t>", 
    {
        params ["_target", "_caller"];
        _target setVariable ["isDeployed", false, true]; _target lock 0;
        hint "HQ Packed Up.";
    },
    nil, 6, true, true, "", "(_target getVariable ['isDeployed', false])"
];

// =====================================================
// 4. TELEPORT SEKALI PAKAI
// =====================================================
_hqVeh addAction [
    "<t color='#FF0000'>[TELEPORT] Relocate HQ (One Time)</t>",
    {
        params ["_target", "_caller"];
        if (_caller getVariable ["MERC_teleport_used", false]) exitWith { hint "Teleport already used. Wait for HQ to respawn."; };
        _caller setVariable ["MERC_teleport_used", true, true];
        
        openMap [true, true];
        onMapSingleClick {
            onMapSingleClick ""; private _pos = _pos;
            if (surfaceIsWater _pos) exitWith { hint "Cannot place in water."; openMap [true, true]; player setVariable ["MERC_teleport_used", false, true]; };
            
            private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
            _hq setPos _pos; "respawn_guerrila" setMarkerPos _pos;
            { _x setPos (_pos getPos [random 10, random 360]); } forEach (allPlayers select {alive _x});
            openMap [false, false]; hint "HQ Relocated.";
        };
    },
    nil, 1.0, true, true, "", "(_target getVariable ['isDeployed', false])", 10
];

// =====================================================
// 5. MENU INTERAKSI UTAMA
// =====================================================

// Misi
_hqVeh addAction ["<t color='#FFFFFF'>[MISSION] Contracts</t>", { [] call MERC_fnc_processMissionBoard; }, nil, 5, true, true, "", "(_target getVariable ['isDeployed', false])"];

// Arsenal
_hqVeh addAction ["<t color='#4287f5'>[ARMORY] Access Arsenal</t>", { [] call MERC_fnc_openArsenalHQ; }, nil, 5, true, true, "", "(_target getVariable ['isDeployed', false])"];

// Hire Mercenary
_hqVeh addAction ["<t color='#FF8C00'>[HIRE] Recruit Personnel</t>", { [] call MERC_fnc_hireMercenary; }, nil, 4, true, true, "", "(_target getVariable ['isDeployed', false])"];

// Base Builder
_hqVeh addAction ["<t color='#964B00'>[BASE BUILDER] Build Structures</t>", { [] call MERC_fnc_baseBuilderMenu; }, nil, 3, true, true, "", "(_target getVariable ['isDeployed', false])"];

// Confiscate Vehicle
_hqVeh addAction [
    "<t color='#00FF00'>[CONFISCATE] Seize Vehicle</t>",
    {
        params ["_target"];
        private _veh = cursorObject;
        if (isNull _veh || {!alive _veh} || {count crew _veh > 0} || {_veh distance _target > 75}) exitWith { hint "No empty vehicle within 75m."; };
        [_veh] remoteExec ["MERC_fnc_garageStore", 2];
    },
    nil, 1.5, true, true, "", "(_target getVariable ['isDeployed', false])", 10
];

// Garage Retrieve
_hqVeh addAction ["<t color='#00FFAA'>[GARAGE] Retrieve Vehicle</t>", { [] call MERC_fnc_garageList; }, nil, 1.7, true, true, "", "(_target getVariable ['isDeployed', false])", 10];

// Transfer Loot
_hqVeh addAction [
    "<t color='#FFA500'>[TRANSFER] Secure Inventory</t>",
    {
        params ["_target"];
        private _obj = cursorObject;
        if (isNull _obj || {_obj distance _target > 15}) exitWith { hint "No object within 15m."; };
        [_obj, _target] remoteExec ["MERC_fnc_transferSupply", 2];
    },
    nil, 1.8, true, true, "", "(_target getVariable ['isDeployed', false])", 10
];

// Logistics
_hqVeh addAction [
    "<t color='#00FFFF'>[LOGISTICS] Service Vehicle</t>",
    {
        params ["_target"];
        private _veh = cursorObject;
        if (isNull _veh || {_veh distance _target > 15}) exitWith { hint "No vehicle within 15m."; };
        _veh setDamage 0; _veh setVehicleAmmo 1; _veh setFuel 1;
        hint "Vehicle serviced.";
    },
    nil, 3, true, true, "", "(_target getVariable ['isDeployed', false])", 10
];

// Skip Time
_hqVeh addAction ["<t color='#87CEEB'>[REST] Skip Time</t>", { ["MENU"] call MERC_fnc_skipTime; }, nil, 1.3, true, true, "", "(_target getVariable ['isDeployed', false])", 10];

// Save
_hqVeh addAction [
    "<t color='#00FF00'>[DATABASE] Save Progress</t>", 
    {
        params ["_target", "_caller"];
        [] remoteExec ["MERC_fnc_playerSave", _caller];
        if (isServer) then { saveProfileNamespace; };
        hint "Progress Saved.";
    },
    nil, 1.5, true, true, "", "(_target getVariable ['isDeployed', false])", 10
];

// Intel
_hqVeh addAction [
    "<t color='#E3E3E3'>[INTEL] Operation Status</t>", 
    {
        params ["_target", "_caller"];
        private _money = _caller getVariable ["merc_money", 0];
        private _cultCount = missionNamespace getVariable ["cult_hq_destroyed_count", 0];
        hint parseText format [
            "<t size='1.2' color='#DAA520'>MERC STATUS</t><br/>" +
            "Money: $%1<br/>USA Rep: %2 | RUS Rep: %3<br/>Cult HQ: %4 / 7",
            [_money] call BIS_fnc_numberText,
            missionNamespace getVariable ["rep_USA", 0],
            missionNamespace getVariable ["rep_RUSSIA", 0],
            _cultCount
        ];
    },
    nil, 1.4, true, true, "", "(_target getVariable ['isDeployed', false])", 10
];

diag_log "HQ SYSTEM: Eitan AFV Mobile HQ Initialized (Final).";