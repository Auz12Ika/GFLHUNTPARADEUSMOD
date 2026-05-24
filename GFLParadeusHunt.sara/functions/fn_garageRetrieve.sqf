/*
    File: fn_garageRetrieve.sqf
    Description: Retrieve vehicle from garage. Hologram follows player cursor.
                 SPACE = confirm, ESC = cancel. Max 100m from HQ.
    🔧 FIX: Event handler scope aman, menggunakan ghost setVariable.
*/
params [["_index", -1, [0]]];

if (!hasInterface) exitWith {};
if (_index < 0 || {isNil "MERC_garage_data"} || {_index >= count MERC_garage_data}) exitWith {
    hint "Invalid vehicle selection.";
};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "HQ not found."; };

// Get vehicle data
private _entry = MERC_garage_data select _index;
_entry params ["_class", "_displayName"];

// Initial spawn position: 10m in front of player
private _dist = 10;
private _startPos = player getPos [_dist, getDir player];
_startPos set [2, 0];

// Create hologram
private _ghost = createVehicle [_class, _startPos, [], 0, "NONE"];
_ghost enableSimulationGlobal false;
_ghost allowDamage false;
_ghost setObjectMaterialGlobal [0, "A3\Data_F\Glass\glass_screen.rvmat"];

// Status variables on ghost
_ghost setVariable ["MERC_retrieve_confirmed", false, true];
_ghost setVariable ["MERC_retrieve_cancelled", false, true];

// Display hint
hint parseText format [
    "<t size='1.3' color='#00FFAA'>RETRIEVE VEHICLE</t><br/>" +
    "<t color='#FFFFFF'>%1</t><br/><br/>" +
    "<t color='#FFFF00'>Move</t> - Hologram follows you<br/>" +
    "<t color='#00FF00'>SPACE</t> - Confirm<br/>" +
    "<t color='#FF0000'>ESC</t> - Cancel<br/><br/>" +
    "<t color='#FFA500'>Max distance from HQ: 100m</t>",
    _displayName
];

// 🔧 FIX: Store event handler IDs to clean up later
private _spaceHandlerID = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_display", "_key"];
    if (_key == 57) then { // SPACE
        private _ghost = missionNamespace getVariable ["MERC_retrieve_ghost", objNull];
        if (!isNull _ghost) then {
            _ghost setVariable ["MERC_retrieve_confirmed", true, true];
        };
    };
}];

private _escHandlerID = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_display", "_key"];
    if (_key == 1) then { // ESC
        private _ghost = missionNamespace getVariable ["MERC_retrieve_ghost", objNull];
        if (!isNull _ghost) then {
            _ghost setVariable ["MERC_retrieve_cancelled", true, true];
        };
    };
}];

// Store ghost globally so event handler can access it
missionNamespace setVariable ["MERC_retrieve_ghost", _ghost];

// Input loop
[_ghost, _hq, _class, _displayName, _index, _spaceHandlerID, _escHandlerID] spawn {
    params ["_ghost", "_hq", "_class", "_displayName", "_index", "_spaceHandlerID", "_escHandlerID"];
    
    private _distance = 10;
    
    while {alive _ghost && !(_ghost getVariable ["MERC_retrieve_confirmed", false]) && !(_ghost getVariable ["MERC_retrieve_cancelled", false])} do {
        private _playerPos = getPos player;
        private _playerDir = getDir player;
        private _newPos = _playerPos getPos [_distance, _playerDir];
        _newPos set [2, 0];
        
        _ghost setVehiclePosition [_newPos, [], 0, "NONE"];
        _ghost setDir _playerDir;
        
        private _distToHQ = _ghost distance _hq;
        if (_distToHQ > 100) then {
            hintSilent format ["TOO FAR: %1m / 100m from HQ", round _distToHQ];
        } else {
            hintSilent format ["Distance: %1m / 100m from HQ", round _distToHQ];
        };
        
        sleep 0.05;
    };
    
    // Remove event handlers
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _spaceHandlerID];
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _escHandlerID];
    missionNamespace setVariable ["MERC_retrieve_ghost", nil];
    
    if (_ghost getVariable ["MERC_retrieve_confirmed", false]) then {
        private _finalDist = _ghost distance _hq;
        if (_finalDist <= 100) then {
            private _finalPos = getPos _ghost;
            private _finalDir = getDir _ghost;
            deleteVehicle _ghost;
            
            private _veh = createVehicle [_class, _finalPos, [], 0, "NONE"];
            _veh setDir _finalDir;
            
            MERC_garage_data deleteAt _index;
            publicVariable "MERC_garage_data";
            
            diag_log format ["[GARAGE] Retrieved: %1 by %2. Remaining: %3", _displayName, name player, count MERC_garage_data];
            systemChat format ["Vehicle retrieved: %1. Remaining: %2", _displayName, count MERC_garage_data];
        } else {
            deleteVehicle _ghost;
            hint format ["Cannot place vehicle: %.0fm from HQ (max 100m). Vehicle remains in garage.", _finalDist];
            diag_log format ["[GARAGE] Retrieve cancelled (too far): %1 by %2", _displayName, name player];
        };
    } else {
        deleteVehicle _ghost;
        hint "Retrieve cancelled. Vehicle remains in garage.";
        diag_log format ["[GARAGE] Retrieve cancelled: %1 by %2", _displayName, name player];
    };
};