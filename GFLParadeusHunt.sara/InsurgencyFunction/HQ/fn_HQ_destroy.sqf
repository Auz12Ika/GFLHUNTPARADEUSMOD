/*
    File: fn_HQ_destroy.sqf
    Description: Trigger Kehancuran (Server Side Only)
*/
params [["_hqVeh", objNull]];
if (isNull _hqVeh) exitWith {};
if (!isServer) exitWith {}; 

_hqVeh removeAllEventHandlers "Killed";

_hqVeh addEventHandler ["Killed", {
    missionNamespace setVariable ["MERC_HQ_IsDestroyed", true, true];
    
    private _homePos = missionNamespace getVariable ["MERC_HQ_HomePos", [16850, 17050, 0]];
    "respawn_guerrila" setMarkerPos _homePos;
    
    // ============================================================
    // 🔥 HUKUMAN: Potong 25% dari total uang
    // ============================================================
    private _currentMoney = missionNamespace getVariable ["merc_money", 0];
    private _penalty = floor (_currentMoney * 0.25); // 25% dari total
    private _newMoney = _currentMoney - _penalty;
    if (_newMoney < 0) then { _newMoney = 0; };
    missionNamespace setVariable ["merc_money", _newMoney, true];
    
    private _msg = format ["<t color='#FF0000' size='1.5'>HQ DESTROYED!</t><br/>You lost 25%% of your funds: -$%1", _penalty];
    [_msg] remoteExec ["hint", 0];
    diag_log format ["[MERC] HQ destroyed! Penalty: $%1, remaining: $%2", _penalty, _newMoney];
    // ============================================================
    
    ["TaskFailed", ["", "HQ Hancur! Menunggu unit baru dikirim..."]] remoteExec ["BIS_fnc_showNotification", 0];
}];