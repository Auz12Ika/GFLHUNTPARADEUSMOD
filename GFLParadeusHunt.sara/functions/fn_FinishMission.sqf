/*
    Author: Modder
    File: fn_finishMission.sqf
    Description: Resolusi misi (sukses/gagal), reward, penalti.
*/

params [["_mission", []], ["_success", true]];

if (!hasInterface) exitWith {};

// --- DATA MISI ---
private _missionID       = _mission select 0;
private _missionName     = _mission select 1;
private _rewardFaction   = _mission select 3;
private _enemyFaction    = _mission select 4;
private _difficulty      = _mission select 8;

// --- HITUNG REWARD UANG ---
private _moneyReward = 0;

// Coba pakai merc_rewards dari config, fallback ke nilai default
{
    if ((_x select 0) == _difficulty) exitWith {
        private _range = _x select 1;
        _moneyReward = floor random [
            _range select 0,
            ((_range select 0) + (_range select 1)) / 2,
            _range select 1
        ];
    };
} forEach (if (!isNil "merc_rewards") then { merc_rewards } else { [["LOW",[1000,3000]], ["MEDIUM",[3000,7000]], ["HIGH",[7000,15000]], ["EXTREME",[15000,30000]]] });

// --- CULT BONUS ---
if (_enemyFaction == "CULT") then {
    private _multiplier = if (!isNil "merc_cult_bonus") then { merc_cult_bonus select 0 } else { 1.5 };
    _moneyReward = floor (_moneyReward * _multiplier);
};

// --- TAMBAH / KURANG UANG ---
private _money = player getVariable ["merc_money", 0];
if (_success) then {
    player setVariable ["merc_money", _money + _moneyReward, true];
} else {
    // Denda kecil jika gagal
    private _penalty = floor (_moneyReward * 0.2);
    player setVariable ["merc_money", (_money - _penalty) max 0, true];
};

// --- HITUNG REPUTASI ---
private _repAmount = 0;
{
    if ((_x select 0) == _difficulty) exitWith {
        private _range = _x select 1;
        _repAmount = floor random [_range select 0, ((_range select 0)+(_range select 1))/2, _range select 1];
    };
} forEach (if (!isNil "merc_reputation_rewards") then { merc_reputation_rewards } else { [["LOW",[5,15]], ["MEDIUM",[10,25]], ["HIGH",[20,40]], ["EXTREME",[40,70]]] });

// Cult bonus untuk reputasi
if (_enemyFaction == "CULT") then {
    _repAmount = floor (_repAmount * 1.3);
};

if (_success) then {
    [_rewardFaction, _repAmount] call MERC_fnc_addReputation;
} else {
    [_rewardFaction, -(_repAmount * 0.5)] call MERC_fnc_addReputation;
};

// --- PESAN ---
if (_success) then {
    systemChat format ["MISI SUKSES: %1 | +$%2 | Rep %3 +%4", _missionName, _moneyReward, _rewardFaction, _repAmount];
} else {
    systemChat format ["MISI GAGAL: %1 | Rep %2 -%3", _missionName, _rewardFaction, floor (_repAmount * 0.5)];
};

// --- HAPUS MARKER MISI PEMAIN ---
private _activeMission = player getVariable ["MERC_activeMission", nil];
if (!isNil "_activeMission") then {
    private _markerName = _activeMission select 2;
    deleteMarker _markerName;
    player setVariable ["MERC_activeMission", nil, false];
};

// 🔧 Tidak ada lagi dead code defend_factory / defend_radio.
// Semua konsekuensi chaos diserahkan ke interaksi pemain di lapangan.