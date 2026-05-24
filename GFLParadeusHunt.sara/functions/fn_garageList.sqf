/*
    File: fn_garageList.sqf
    Description: Show garage vehicle list as sub-actions on HQ.
*/
if (!hasInterface) exitWith {};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "HQ not found."; };

// Remove old sub-actions
private _oldIDs = _hq getVariable ["MERC_garageSubIDs", []];
{ _hq removeAction _x; } forEach _oldIDs;

if (isNil "MERC_garage_data" || {count MERC_garage_data == 0}) exitWith {
    hint "Garage is empty.";
    [] spawn {
        sleep 1;
        private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
        if (!isNull _hq) then {
            private _id = _hq addAction [
                "<t color='#00FFAA'>[GARAGE] Retrieve Vehicle</t>",
                { [] call MERC_fnc_garageList; },
                nil, 1.7, true, true, "", "true", 10
            ];
            _hq setVariable ["MERC_garageActionID", _id, false];
        };
    };
};

private _ids = [];
{
    _x params ["_class", "_name"];
    private _index = _forEachIndex;
    private _id = _hq addAction [
        format ["<t color='#00FFAA'>  >> %1</t>", _name],
        {
            params ["_target", "_caller", "_id", "_index"];
            [_index] call MERC_fnc_garageRetrieve;
            // Clean up sub-actions
            private _subIDs = _target getVariable ["MERC_garageSubIDs", []];
            { _target removeAction _x; } forEach _subIDs;
            _target setVariable ["MERC_garageSubIDs", [], false];
        },
        _index,
        1.5,
        true,
        true,
        "",
        "true"
    ];
    _ids pushBack _id;
} forEach MERC_garage_data;

_hq setVariable ["MERC_garageSubIDs", _ids, false];