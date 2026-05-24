/*
    File: fn_skipTime.sqf
    Description: Skip waktu dengan pilihan durasi 1-22 jam.
    🔧 FINAL: Hanya pilihan durasi langsung. Tidak ada mode otomatis.
*/

if (!hasInterface) exitWith {};

params [["_mode", "MENU"], ["_hours", 0]];

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "HQ not found."; };

switch (_mode) do {

    // =================================================
    // MODE: MENU — Tampilkan pilihan durasi
    // =================================================
    case "MENU": {
        if (!(_hq getVariable ["isDeployed", false])) exitWith { hint "HQ must be deployed."; };

        // Hapus sub-menu lama
        private _oldIDs = _hq getVariable ["MERC_skipSubIDs", []];
        { _hq removeAction _x; } forEach _oldIDs;

        // Pilihan durasi: 1 sampai 12, lalu 16, 20, 22
        private _options = [1,2,3,4,5,6,7,8,9,10,11,12,16,20,22];

        private _ids = [];
        {
            private _hrs = _x;
            private _id = _hq addAction [
                format ["<t color='#87CEEB'>  >> %1 Hour(s)</t>", _hrs],
                {
                    params ["_target", "_caller", "_id", "_hrs"];
                    ["EXEC", _hrs] call MERC_fnc_skipTime;
                    // Hapus semua sub-menu
                    private _oldIDs = _target getVariable ["MERC_skipSubIDs", []];
                    { _target removeAction _x; } forEach _oldIDs;
                    _target setVariable ["MERC_skipSubIDs", [], false];
                },
                _hrs,
                1.5,
                true,
                true,
                "",
                "true"
            ];
            _ids pushBack _id;
        } forEach _options;

        _hq setVariable ["MERC_skipSubIDs", _ids, false];
    };

    // =================================================
    // MODE: EXEC — Jalankan skip waktu
    // =================================================
    case "EXEC": {
        // Cek cooldown (5 menit)
        private _lastSkip = player getVariable ["MERC_lastSkip", -60];
        if (time - _lastSkip < 60) exitWith {
            private _remaining = ceil (300 - (time - _lastSkip));
            hint format ["You must wait %1 seconds before resting again.", _remaining];
        };

        // Cek musuh dekat HQ (radius 100m)
        private _nearEnemies = nearestObjects [_hq, ["Man"], 100] select {
            side _x != side player && side _x != civilian && alive _x
        };
        if (count _nearEnemies > 0) exitWith {
            hint "Cannot rest! Enemies are too close to HQ.";
        };

        // --- EKSEKUSI SKIP ---
        titleText [format ["<t size='1.5' color='#87CEEB'>Resting %1 hour(s)...</t>", _hours], "BLACK OUT", 3, true, true];
        sleep 3;

        skipTime _hours;

        titleText ["<t size='1.5' color='#87CEEB'>You feel well rested.</t>", "BLACK IN", 3, true, true];

        player setVariable ["MERC_lastSkip", time, false];

        [] remoteExec ["MERC_fnc_playerSave", player];

        systemChat format ["Time skipped %1 hour(s). Progress saved.", _hours];
    };

};