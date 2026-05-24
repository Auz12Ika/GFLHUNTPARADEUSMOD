/*
    Author: Modder
    File: fn_serverWorker.sqf
    Description: Sistem Auto Save harian jam 17:00 in-game.
    🔧 FIX P15: Nama fungsi MERC_fnc_playerSave akan diselaraskan dengan CfgFunctions nanti.
*/

if (!isServer) exitWith {};

[] spawn {
    private _lastSaveDay = -1;

    while {true} do {
        private _currentHour = daytime;
        private _today = date select 2;

        if (_currentHour >= 17 && _currentHour < 17.01 && _lastSaveDay != _today) then {
            {
                if (alive _x) then {
                    [] remoteExec ["MERC_fnc_playerSave", _x];
                };
            } forEach allPlayers;

            _lastSaveDay = _today;
            diag_log format ["MERC SYSTEM: Auto Save harian jam %1 in-game.", _currentHour];

            ["AutoSaveNotification", ["SISTEM", "Auto-save harian berhasil (Jam 17:00)"]] remoteExec ["BIS_fnc_showNotification", 0];
        };

        sleep 10;
    };
};