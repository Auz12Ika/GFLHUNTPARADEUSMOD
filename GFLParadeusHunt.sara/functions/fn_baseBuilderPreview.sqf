/*
    File: fn_baseBuilderPreview.sqf
    Description: Base Builder hologram. WASD=jalan, MiddleMouse=rotasi mode, SPACE=confirm, ESC=cancel.
*/
params [["_classname", ""], ["_cost", 0]];

if (!hasInterface || _classname == "") exitWith {};
if (_cost <= 0) exitWith {};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "HQ not found."; };

private _money = player getVariable ["merc_money", 0];
if (_money < _cost) exitWith { hint format ["Need $%1, you have $%2.", _cost, _money]; };

// --- HOLOGRAM ---
private _dist = 10;
private _startPos = player getPos [_dist, getDir player];
private _ghost = createVehicle [_classname, _startPos, [], 0, "NONE"];
_ghost enableSimulationGlobal false;
_ghost allowDamage false;

// --- STATUS ---
_ghost setVariable ["MERC_builder_confirmed", false, true];
_ghost setVariable ["MERC_builder_cancelled", false, true];
private _modes = ["RAISE", "LOWER", "ROT_L", "ROT_R", "FLOAT", "GROUND", "RESET"];
private _modeIndex = 0;

// --- EVENT HANDLER (SPACE & ESC) ---
private _spaceID = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    if (_this select 1 == 57) then {
        private _g = missionNamespace getVariable ["MERC_builder_ghost", objNull];
        if (!isNull _g) then { _g setVariable ["MERC_builder_confirmed", true, true]; };
    };
}];
private _escID = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    if (_this select 1 == 1) then {
        private _g = missionNamespace getVariable ["MERC_builder_ghost", objNull];
        if (!isNull _g) then { _g setVariable ["MERC_builder_cancelled", true, true]; };
    };
}];

// --- EVENT HANDLER (Middle Mouse) ---
private _mouseID = (findDisplay 46) displayAddEventHandler ["MouseButtonDown", {
    if (_this select 1 == 2) then {
        private _g = missionNamespace getVariable ["MERC_builder_ghost", objNull];
        if (!isNull _g) then {
            private _idx = _g getVariable ["MERC_builder_modeIndex", 0];
            _idx = (_idx + 1) % 7;
            _g setVariable ["MERC_builder_modeIndex", _idx];
            _g setVariable ["MERC_builder_modeChanged", true];
        };
    };
}];

missionNamespace setVariable ["MERC_builder_ghost", _ghost];
_ghost setVariable ["MERC_builder_modeIndex", _modeIndex];

// --- HINT KONTROL ---
hint parseText format [
    "<t size='1.3' color='#00FFAA'>BASE BUILDER</t><br/>" +
    "<t color='#FFFFFF'>%1 ($%2)</t><br/><br/>" +
    "<t color='#FFFF00'>WASD</t> - Move<br/>" +
    "<t color='#FFFF00'>Middle Mouse</t> - Mode<br/>" +
    "<t color='#00FF00'>SPACE</t> - Confirm<br/>" +
    "<t color='#FF0000'>ESC</t> - Cancel<br/>" +
    "<t color='#FFA500'>Max 100m from HQ</t>",
    getText (configFile >> "CfgVehicles" >> _classname >> "displayName"), _cost
];

// --- LOOP ---
[_ghost, _hq, _classname, _cost, _spaceID, _escID, _mouseID, _modes] spawn {
    params ["_ghost", "_hq", "_classname", "_cost", "_spaceID", "_escID", "_mouseID", "_modes"];
    
    private _distance = 10;
    private _floatMode = false;
    
    while {alive _ghost && !(_ghost getVariable ["MERC_builder_confirmed", false]) && !(_ghost getVariable ["MERC_builder_cancelled", false])} do {
        private _playerPos = getPos player;
        private _playerDir = getDir player;
        private _newPos = _playerPos getPos [_distance, _playerDir];
        
        if (!_floatMode) then {
            _ghost setVehiclePosition [_newPos, [], 0, "NONE"];
        } else {
            _ghost setPos _newPos;
        };
        
        private _distToHQ = _ghost distance _hq;
        hintSilent format ["%1 | Dist: %2m | Mode: %3",
            getText (configFile >> "CfgVehicles" >> _classname >> "displayName"),
            round _distToHQ,
            ["MOVE", _modes select (_ghost getVariable ["MERC_builder_modeIndex", 0])] select ((_ghost getVariable ["MERC_builder_modeIndex", 0]) > 0)
        ];
        
        if (_ghost getVariable ["MERC_builder_modeChanged", false]) then {
            _ghost setVariable ["MERC_builder_modeChanged", false];
            private _idx = _ghost getVariable ["MERC_builder_modeIndex", 0];
            private _mode = _modes select _idx;
            
            switch (_mode) do {
                case "RAISE": { _ghost setPos (getPos _ghost vectorAdd [0,0,0.5]); };
                case "LOWER": { _ghost setPos (getPos _ghost vectorAdd [0,0,-0.5]); };
                case "ROT_L": { _ghost setDir (getDir _ghost + 15); };
                case "ROT_R": { _ghost setDir (getDir _ghost - 15); };
                case "FLOAT": { _floatMode = !_floatMode; hintSilent format ["Float: %1", _floatMode]; };
                case "GROUND": { _ghost setVehiclePosition [getPos _ghost, [], 0, "NONE"]; _floatMode = false; };
                case "RESET": { _ghost setDir (getDir player); _ghost setVehiclePosition [_playerPos getPos [_distance, _playerDir], [], 0, "NONE"]; _floatMode = false; };
            };
        };
        
        sleep 0.05;
    };
    
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _spaceID];
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _escID];
    (findDisplay 46) displayRemoveEventHandler ["MouseButtonDown", _mouseID];
    missionNamespace setVariable ["MERC_builder_ghost", nil];
    
    if (_ghost getVariable ["MERC_builder_confirmed", false]) then {
        if (_ghost distance _hq <= 100 && {!surfaceIsWater getPos _ghost}) then {
            private _finalPos = getPos _ghost;
            private _finalDir = getDir _ghost;
            deleteVehicle _ghost;
            
            private _obj = createVehicle [_classname, _finalPos, [], 0, "NONE"];
            _obj setDir _finalDir;
            
            private _money = player getVariable ["merc_money", 0];
            player setVariable ["merc_money", _money - _cost, true];
            
            MERC_base_objects pushBack [typeOf _obj, getPos _obj, getDir _obj, _cost];
            publicVariable "MERC_base_objects";
            
            // Add edit action
            _obj addAction [
                "<t color='#FFA500'>[EDIT] Building</t>",
                {
                    params ["_target"];
                    private _options = ["Move", "Dismantle"];
                    private _choice = _options select (floor random count _options);
                    
                    if (_choice == "Dismantle") then {
                        private _cost = 0;
                        {
                            if ((_x select 0) == typeOf _target) exitWith { _cost = (_x select 2) * 0.5; };
                        } forEach (flatten MERC_baseBuilder_objects);
                        
                        private _money = player getVariable ["merc_money", 0];
                        player setVariable ["merc_money", _money + _cost, true];
                        
                        MERC_base_objects deleteAt (MERC_base_objects findIf {(_x select 0) == typeOf _target && {(_x select 1) distance getPos _target < 1}});
                        publicVariable "MERC_base_objects";
                        
                        deleteVehicle _target;
                        systemChat format ["Dismantled. Refund: $%1.", _cost];
                    };
                },
                nil, 1.5, true, true, "", "true", 5
            ];
            
            systemChat format ["Built: %1. Cost: $%2. Remaining: $%3.",
                getText (configFile >> "CfgVehicles" >> _classname >> "displayName"),
                _cost,
                player getVariable ["merc_money", 0]
            ];
        } else {
            deleteVehicle _ghost;
            hint "Cannot build here.";
        };
    } else {
        deleteVehicle _ghost;
        hint "Build cancelled.";
    };
};