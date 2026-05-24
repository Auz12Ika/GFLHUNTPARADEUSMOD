/*
    Author: Modder
    File: fn_addReputation.sqf
    Description: Menambah/mengurangi reputasi faksi, clamp -600..600.
    🔧 FIX P10: Threshold dari merc_factions (fallback hardcode).
                Trigger hunter team nyata saat reputasi sangat rendah.
*/

params [["_faction", ""], ["_amount", 0]];

if (_faction == "") exitWith { 0 };

// --- NAMA VARIABEL REPUTASI ---
private _varName = format ["rep_%1", _faction];
private _current = missionNamespace getVariable [_varName, 0];

// --- UPDATE NILAI ---
_current = (_current + _amount) max -600 min 600;
missionNamespace setVariable [_varName, _current, true];

// --- BACA THRESHOLD DARI CONFIG (FALLBACK) ---
private _thresholdAlly   = 60;
private _thresholdNeutral = 0;
private _thresholdHostile = -40;
private _thresholdHunt   = -100;

if (!isNil "merc_factions") then {
    {
        if ((_x select 0) == _faction) exitWith {
            private _repRules = _x select 2;
            _thresholdAlly    = _repRules select 0;
            _thresholdNeutral = _repRules select 1;
            _thresholdHostile = _repRules select 2;
            _thresholdHunt    = _repRules select 3;
        };
    } forEach merc_factions;
};

// --- NOTIFIKASI & TRIGGER BERDASARKAN THRESHOLD ---
switch (_faction) do {

    case "USA": {
        if (_current >= _thresholdAlly) then {
            systemChat "USA support is now available.";
        };
        if (_current <= _thresholdHostile) then {
            systemChat "USA forces are hostile near their territory.";
        };
        if (_current <= _thresholdHunt) then {
            systemChat "USA recon squads deployed to hunt you!";
            // 🔧 Trigger hunter team nyata (server side)
            if (isServer) then {
                [] spawn MERC_fnc_usaHunterTeam;
            } else {
                [] remoteExec ["MERC_fnc_usaHunterTeam", 2];
            };
        };
    };

    case "RUSSIA": {
        if (_current >= _thresholdAlly) then {
            systemChat "Russian support is now available.";
        };
        if (_current <= _thresholdHostile) then {
            systemChat "Russian forces are hostile near their territory.";
        };
        if (_current <= _thresholdHunt) then {
            systemChat "Russian recon squads deployed to hunt you!";
            // 🔧 Trigger hunter team nyata
            if (isServer) then {
                [] spawn MERC_fnc_rusHunterTeam;
            } else {
                [] remoteExec ["MERC_fnc_rusHunterTeam", 2];
            };
        };
    };

    case "CIV": {
        if (_current <= _thresholdHunt) then {
            systemChat "Civilians no longer trust your group.";
        };
    };

    case "CULT": {
        if (_current <= -50) then {
            systemChat "Cult activity has intensified.";
        };
    };

};

_current