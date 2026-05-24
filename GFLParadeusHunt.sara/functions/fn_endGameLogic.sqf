/*
    Author: Modder
    File: fn_endGameLogic.sqf
    Description: Menangani progres akhir permainan (7x Cult HQ Destruction).
    🔧 FIX A2: Reward menggunakan merc_rewards (EXTREME tier), fallback 15000.
*/

params [["_cultHQ", objNull]];

if (isNull _cultHQ) exitWith {};

// Tambahkan Event Handler setiap kali HQ Cult dibuat
_cultHQ addEventHandler ["Killed", {
    params ["_unit"];

    // 1. Ambil data progres dari server
    private _count = missionNamespace getVariable ["cult_hq_destroyed_count", 0];
    _count = _count + 1;
    missionNamespace setVariable ["cult_hq_destroyed_count", _count, true];

    // 2. Hitung reward dari config, fallback 15000
    private _reward = 15000;
    if (!isNil "merc_rewards") then {
        {
            if ((_x select 0) == "EXTREME") exitWith {
                private _range = _x select 1;
                _reward = floor random [
                    _range select 0,
                    ((_range select 0) + (_range select 1)) / 2,
                    _range select 1
                ];
            };
        } forEach merc_rewards;
    };

    // 3. Berikan hadiah ke semua player
    {
        private _money = _x getVariable ["merc_money", 0];
        _x setVariable ["merc_money", _money + _reward, true];
    } forEach allPlayers;

    // 4. Notifikasi global
    [format ["CULT HQ DESTROYED! Status: [%1/7] | Reward: $%2", _count, _reward]] remoteExec ["systemChat", 0];

    // 5. Cek Kondisi Menang (7 Kali)
    if (_count >= 7) then {
        [] spawn {
            sleep 3;
            "LayerKemenangan" cutText ["<t color='#DAA520' size='4'>VICTORY</t><br/>Sahrani telah dibersihkan dari pengaruh Cult!", "PLAIN DOWN", -1, true, true];
            sleep 15;
            ["EveryoneWon", true, 5] remoteExec ["BIS_fnc_endMission", 0];
        };
    } else {
        private _text = format ["Sisa HQ Cult yang harus dihancurkan: %1", (7 - _count)];
        [_text] remoteExec ["hint", 0];
        profileNamespace setVariable ["merc_persistent_cult_count", _count];
        saveProfileNamespace;
    };
}];

diag_log format ["END GAME LOGIC: Cult HQ [%1] monitored.", _cultHQ];