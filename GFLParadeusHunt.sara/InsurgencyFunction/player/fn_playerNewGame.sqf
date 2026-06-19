/*
    Author: Modder
    File: fn_playerNewGame.sqf
    Description: Deletes save slot arrays, triggers wipeout visual simulations, and updates logging tracking data.
*/
if (!hasInterface) exitWith {
    diag_log "MERC NEWGAME ERROR: Execution triggered on headless client or raw server environment. Aborting execution.";
};

params [["_slot", 1]];

diag_log format ["[MERC NEWGAME LOG] === INITIATING WIPE PROTOCOL FOR ARCHIVE DATA SLOT: %1 ===", _slot];
systemChat format ["[SYSTEM]: Initializing wipe sequence authentication protocols for Data Slot %1...", _slot];

// Pop-up Konfirmasi Keamanan (English)
private _confirm = [
    format ["Are you absolutely sure you want to clear data variables and establish a completely NEW GAME archive on Slot %1?\n\nCRITICAL WARNING: This completely deletes persistent structures, detonates your active Command Post, and neutralizes all personnel!", _slot], 
    "CRITICAL PROTOCOL: AUTHORIZE TOTAL DATA WIPE", 
    "CONFIRM EXTINCTION", 
    "ABORT OPERATIONS"
] call BIS_fnc_guiMessage;

if (!(_confirm)) exitWith {
    diag_log format ["[MERC NEWGAME LOG] Data wipe execution sequence on Slot %1 aborted by operator authorization.", _slot];
    systemChat "[SYSTEM]: Wipe protocol terminated.";
};

if (_confirm) then {
    // CHK-POINT A: PEMBERSIHAN PROFILE DATABASE
    diag_log format ["[MERC NEWGAME LOG] CHK-A: Flushing profileNamespace values linked to Slot %1...", _slot];
    
    profileNamespace setVariable [format ["merc_save_money_slot_%1", _slot], nil];
    profileNamespace setVariable [format ["MERC_save_base_objects_slot_%1", _slot], nil];
    profileNamespace setVariable [format ["MERC_save_hq_position_slot_%1", _slot], nil];
    profileNamespace setVariable [format ["MERC_save_hq_direction_slot_%1", _slot], nil];
    profileNamespace setVariable [format ["MERC_save_arsenal_weapons_slot_%1", _slot], nil];
    profileNamespace setVariable [format ["MERC_save_counters_slot_%1", _slot], nil];
    
    saveProfileNamespace;
    diag_log "[MERC NEWGAME LOG] CHK-A: Local profileNamespace data buffers cleanly purged.";

    // CHK-POINT B: PELEDAKAN OBJEK FISIK COMMAND POST MOBILE HQ
    private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
    if (!isNull _hq && {alive _hq}) then {
        private _explosion = "ExplosionEffectsBig" createVehicle (getPosATL _hq);
        _hq setDamage 1;
        
        if (!isNil "HQ_fnc_HQ_destroy") then {
            [] remoteExec ["HQ_fnc_HQ_destroy", 2];
        };
    };

    // CHK-POINT C: ELIMINASI MASSAL SELURUH PERSONIL PLAYER DI SERVER
    [
        "<t color='#FF0000' size='1.5' weight='bold'>TOTAL SECURITY DATA WIPE EXECUTED!</t><br/>Command infrastructure compromised, personnel safely scrubbed from network arrays.",
        "PLAIN DOWN",
        2
    ] remoteExec ["titleText", 0];

    {
        if (alive _x) then {
            diag_log format ["[MERC NEWGAME LOG] CHK-C: Neutralizing contract asset trace: %1", name _x];
            _x setDamage 1; 
        };
    } forEach allPlayers;

    // CHK-POINT D: VAPORISASI STRUKTUR BANGUNAN DI MAP
    private _oldObjects = missionNamespace getVariable ["MERC_base_objects", []];
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach _oldObjects;
    missionNamespace setVariable ["MERC_base_objects", [], true];

    // CHK-POINT E: PENGEMBALIAN VARIABEL FINANSIAL KE DEFAULT AWAL MULA GAME
    missionNamespace setVariable ["merc_money", 5000, true];
    missionNamespace setVariable ["rep_USA", 0, true];
    missionNamespace setVariable ["rep_RUSSIA", 0, true];

    diag_log format ["[MERC NEWGAME LOG] === WIPE COMPLETED SECURELY ON DATA SLOT %1. CONSOLING SESSIONS WORLDWIDE ===", _slot];
    hint format ["Data Slot %1 Successfully Wiped Clean!\n\nCommand assets neutralized and balances scaled to starting limits.\nRe-establish your military footprint from the ground up.", _slot];
};