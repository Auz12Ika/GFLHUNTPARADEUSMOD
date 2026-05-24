if (!isServer) exitWith {};

// Panggil semua file config
call compile preprocessFileLineNumbers "config\mission.sqf";
call compile preprocessFileLineNumbers "config\reward.sqf";
call compile preprocessFileLineNumbers "config\faction.sqf";

// 1. Muat data player dari profil (sekali saja)
call MERC_fnc_playerLoad;

// 2. Jika new game, beri modal awal
if (isNil "merc_money" || {merc_money == 0}) then {
    missionNamespace setVariable ["merc_money", 5000, true];
    missionNamespace setVariable ["merc_reputation", 0, true];
    diag_log "GFL_SYSTEM: New Game detected.";
} else {
    diag_log format ["GFL_SYSTEM: Continue detected. Money: %1", merc_money];
};

// 3. Inisialisasi data arsenal (hanya jika new game / data kosong)
call MERC_fnc_initArsenalData;

// 4. Muat data garasi dari profil
call compile preprocessFileLineNumbers "data\garageData.sqf";

// 5. Start base monitor
[] spawn MERC_fnc_baseMonitor;

// 6. Data cleanup
{
    private _varName = _x;
    private _protected = ["merc_money", "merc_reputation", "merc_location_data", "GFL_Player_Inventory", "GFL_Captured_Bases"];
    private _isProtected = false;
    { if (_varName == _x) exitWith { _isProtected = true; }; } forEach _protected;
    if (!_isProtected && (_varName select [0,4] == "GFL_")) then {
        missionNamespace setVariable [_varName, nil];
    };
} forEach (allVariables missionNamespace);

missionNamespace setVariable ["GFL_WorldReady", false, true];
missionNamespace setVariable ["GFL_LockSpawn", false, true];

// 7. Mapping dunia
call MERC_fnc_initWorldMapping;
waitUntil { !(isNil "merc_location_data") };

// 8. Toko
[] spawn {
    sleep 2;
    call MERC_fnc_initGunShop;
    sleep 2;
    call MERC_fnc_initVehicleStore;
};

// 9. Cult HQ
[] spawn {
    waitUntil { !(isNil "merc_usa_mainbase_pos") && !(isNil "merc_rus_mainbase_pos") };
    sleep 10;
    call MERC_fnc_spawnCultHQ;
};

// 10. World Logic
[] spawn {
    waitUntil { !(isNil "merc_location_data") };
    sleep 5;
    call MERC_fnc_worldLogic;
};

// 11. Auto-save harian
[] spawn {
    call MERC_fnc_serverWorker;
};

// 12. Marker darurat
if (markerType "respawn_guerrila" == "") then {
    createMarker ["respawn_guerrila", [worldSize/2, worldSize/2, 0]];
    "respawn_guerrila" setMarkerType "b_hq";
    "respawn_guerrila" setMarkerColor "ColorGreen";
    "respawn_guerrila" setMarkerText "GFL MAIN BASE";
};

// 13. Master Controller
[] spawn {
    sleep 60;
    missionNamespace setVariable ["GFL_WorldReady", true, true];
    private _maxAI = 120;
    private _fpsCritical = 20; // Perbaiki ke nilai yang lebih realistis

    while {true} do {
        if (diag_fps < _fpsCritical) then {
            missionNamespace setVariable ["GFL_LockSpawn", true, true];
        } else {
            missionNamespace setVariable ["GFL_LockSpawn", false, true];
        };

        private _allPlayers = allPlayers select {alive _x};
        private _locations = missionNamespace getVariable ["merc_location_data", []];

        {
            _x params ["_pos", "_type", "_name", "_faction"];
            private _baseID = format["GFL_Active_%1", _name];
            private _nearPlayers = { (_x distance _pos) < 4000 } count _allPlayers;

            if (_nearPlayers > 0 && !(missionNamespace getVariable [_baseID, false])) then {
                if !(missionNamespace getVariable ["GFL_LockSpawn", false]) then {
                    private _owner = missionNamespace getVariable [format["owner_%1", _name], "NEUTRAL"];
                    switch (_owner) do {
                        case "USA": { [_pos, _type] spawn MERC_fnc_spawnUSABase; };
                        case "RUSSIA": { [_pos, _type] spawn MERC_fnc_spawnRUSBase; };
                        case "CULT": { [_pos, _type] spawn MERC_fnc_spawnCultBase; };
                    };
                    missionNamespace setVariable [_baseID, true];
                    sleep 5;
                };
            };

            if (_nearPlayers == 0 && (missionNamespace getVariable [_baseID, false])) then {
                missionNamespace setVariable [_baseID, false];
            };
        } forEach _locations;

        sleep 30;
    };
};

// 14. Auto-save & Cult Hijack
[] spawn {
    while {true} do {
        sleep 600;
        call MERC_fnc_playerSave;
        ["AutoSaveNotification", ["Progress saved."]] remoteExec ["BIS_fnc_showNotification", 0];
        call MERC_fnc_cultHijackLogic;
    };
};

// 15. System Controller
[] spawn {
    sleep 10;
    spawn MERC_fnc_systemController;
};