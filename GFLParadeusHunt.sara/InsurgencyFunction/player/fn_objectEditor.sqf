/*
    Author: Modder
    File: fn_objectEditor.sqf
    Description: Real-time Base Editing Engine (Crash Fixed, Standard Pitch/Bank).
*/
if (!hasInterface) exitWith {};

params [["_mode", ""], ["_args", []]];

private _fnc_lookupPrice = {
    params [["_class", ""]];
    private _price = 1000; 
    if (_class == "") exitWith { _price };
    {
        {
            if (_x select 0 == _class) exitWith { _price = _x select 2; };
        } forEach _x;
    } forEach (missionNamespace getVariable ["MERC_baseBuilder_objects", []]);
    _price
};

switch (_mode) do {
    case "START_PICKUP": {
        _args params [["_obj", objNull]];
        if (isNull _obj) exitWith {};

        private _held = player getVariable ["MERC_held_object", objNull];
        if (!isNull _held) exitWith { hint "Error: You are already carrying another structure!"; };

        player setVariable ["MERC_held_object", _obj, true];
        player setVariable ["MERC_held_offset", [0, 5, 0.5]]; 
        player setVariable ["MERC_held_rot", [0, 0, 0]];     

        _obj enableSimulationGlobal false;
        
        // Perbaikan: Baris disableCollisionWith DIHAPUS dari sini karena merusak tabrakan secara permanen.
        
        for "_i" from 0 to 7 do {
            _obj setObjectTextureGlobal [_i, "#(rgb,8,8,3)color(1,1,1,0.5)"];
        };

        removeAllActions _obj;

        private _frameID = addMissionEventHandler ["EachFrame", {
            ["EACH_FRAME", []] call MERC_fnc_objectEditor;
        }];
        player setVariable ["MERC_held_frame_id", _frameID];

        private _deathEH = player addEventHandler ["Killed", {
            params ["_unit"];
            ["HANDLE_DEATH", [_unit]] call MERC_fnc_objectEditor;
        }];
        player setVariable ["MERC_held_death_eh", _deathEH];

        [] call MERC_fnc_setupEditorActions;
        hint "Structure Lifted!\nUse your Action Menu to translate and rotate the object.";
    };

    case "EACH_FRAME": {
        private _obj = player getVariable ["MERC_held_object", objNull];
        if (isNull _obj) exitWith {};

        private _offset = player getVariable ["MERC_held_offset", [0, 5, 0.5]];
        private _rot = player getVariable ["MERC_held_rot", [0, 0, 0]];
        _rot params ["_yaw", "_pitch", "_roll"];

        private _atlPos = player modelToWorld _offset;
        _obj setPosATL _atlPos;

        _obj setDir (getDir player + _yaw);
        [_obj, _pitch, _roll] call BIS_fnc_setPitchBank;
    };

    case "MANIPULATE": {
        _args params [["_actionType", ""]];
        private _offset = player getVariable ["MERC_held_offset", [0, 5, 0.5]];
        private _rot = player getVariable ["MERC_held_rot", [0, 0, 0]];
        switch (_actionType) do {
            case "UP":    { _offset set [2, (_offset select 2) + 0.25]; };
            case "DOWN":  { _offset set [2, (_offset select 2) - 0.25]; };
            case "FRONT": { _offset set [1, (_offset select 1) + 0.50]; };
            case "BACK":  { _offset set [1, (_offset select 1) - 0.50]; };
            case "CW":    { _rot set [0, (_rot select 0) + 15]; };
            case "CCW":   { _rot set [0, (_rot select 0) - 15]; };
            case "P_UP":  { _rot set [1, (_rot select 1) + 15]; };
            case "P_DN":  { _rot set [1, (_rot select 1) - 15]; };
            case "RESET": { _offset = [0, 5, 0.5]; _rot = [0, 0, 0]; hint "Object transformations reset to defaults."; };
        };

        player setVariable ["MERC_held_offset", _offset];
        player setVariable ["MERC_held_rot", _rot];
    };

    case "PLACE": {
        _args params [["_snapToGround", false]];
        private _obj = player getVariable ["MERC_held_object", objNull];
        if (isNull _obj) exitWith {};

        private _frameID = player getVariable ["MERC_held_frame_id", -1];
        if (_frameID != -1) then { removeMissionEventHandler ["EachFrame", _frameID]; };
        
        private _deathEH = player getVariable ["MERC_held_death_eh", -1];
        if (_deathEH != -1) then { player removeEventHandler ["Killed", _deathEH]; };
        for "_i" from 0 to 7 do { _obj setObjectTextureGlobal [_i, ""]; };
        if (_snapToGround) then {
            private _currentPos = getPosATL _obj;
            _obj setPosATL [_currentPos select 0, _currentPos select 1, 0];
            _obj setVectorUp surfaceNormal (getPosATL _obj);
        };

        // Perbaikan: Kita tidak memakai _obj enableSimulationGlobal true langsung di sini.
        // Kita kirim koordinat akhirnya ke server menggunakan fungsi yang sudah Anda buat sebelumnya.
        [_obj, getPosATL _obj, getDir _obj] remoteExec ["MERC_fnc_ServerPlaceObject", 2];

        [_obj] call MERC_fnc_initObjectActions;
        player setVariable ["MERC_held_object", objNull, true];
        [] call MERC_fnc_clearEditorActions;
        hint "Structure safely integrated and anchored to the base grid!";
    };

    case "SELL": {
        _args params [["_obj", objNull], ["_returnRate", 0.50]];
        if (isNull _obj) exitWith {};

        private _cost = [typeOf _obj] call _fnc_lookupPrice;
        private _refundValue = round (_cost * _returnRate);
        private _bank = missionNamespace getVariable ["merc_money", 0];
        missionNamespace setVariable ["merc_money", _bank + _refundValue, true];
        private _pangkalanRegistry = missionNamespace getVariable ["MERC_base_objects", []];
        _pangkalanRegistry = _pangkalanRegistry - [_obj];
        missionNamespace setVariable ["MERC_base_objects", _pangkalanRegistry, true];

        deleteVehicle _obj;
        hint parseText format ["<t color='#FFD700' size='1.2' weight='bold'>ASSET LIQUIDATED</t><br/>Refund Disbursed: <t color='#00FF00'>+$%1</t> (%2%3 Recovery)", _refundValue, (_returnRate * 100), "%"];
    };

    case "HANDLE_DEATH": {
        _args params [["_unit", player]];
        private _obj = _unit getVariable ["MERC_held_object", objNull];
        if (isNull _obj) exitWith {};

        private _frameID = player getVariable ["MERC_held_frame_id", -1];
        if (_frameID != -1) then { removeMissionEventHandler ["EachFrame", _frameID]; };

        ["SELL", [_obj, 0.75]] call MERC_fnc_objectEditor;
        player setVariable ["MERC_held_object", objNull, true];
        [] call MERC_fnc_clearEditorActions;
    };
};