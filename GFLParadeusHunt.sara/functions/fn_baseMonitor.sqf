/*
    File: fn_baseMonitor.sqf
    Description: Monitor jarak bangunan dari HQ. Hancurkan jika terlalu jauh >15 detik.
*/

if (!isServer) exitWith {};

[] spawn {
    while {true} do {
        private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
        if (!isNull _hq) then {
            private _toRemove = [];
            {
                _x params ["_classname", "_pos", "_dir", "_cost"];
                private _obj = nearestObject [_pos, _classname];
                
                if (!isNull _obj) then {
                    private _dist = _obj distance _hq;
                    
                    if (_dist > 400) then {
                        private _timer = _obj getVariable ["MERC_dismantle_timer", -1];
                        if (_timer < 0) then {
                            _obj setVariable ["MERC_dismantle_timer", time + 15, true];
                            _obj spawn {
                                private _obj = _this;
                                waitUntil {time >= (_obj getVariable ["MERC_dismantle_timer", time]) || {_obj distance (missionNamespace getVariable ["MERC_Player_HQ", objNull]) <= 400}};
                                if (time >= (_obj getVariable ["MERC_dismantle_timer", time]) && {_obj distance (missionNamespace getVariable ["MERC_Player_HQ", objNull]) > 400}) then {
                                    private _classname = typeOf _obj;
                                    private _cost = 0;
                                    {
                                        if ((_x select 0) == _classname) exitWith { _cost = (_x select 2) * 0.5; };
                                    } forEach (flatten MERC_baseBuilder_objects);
                                    
                                    if (_cost > 0) then {
                                        private _money = missionNamespace getVariable ["merc_money", 0];
                                        missionNamespace setVariable ["merc_money", _money + _cost, true];
                                        systemChat format ["A %1 was dismantled (too far from HQ). Refund: $%2.", getText (configFile >> "CfgVehicles" >> _classname >> "displayName"), _cost];
                                    };
                                    deleteVehicle _obj;
                                    _toRemove pushBack _x;
                                };
                            };
                        };
                    } else {
                        _obj setVariable ["MERC_dismantle_timer", -1, true];
                    };
                } else {
                    _toRemove pushBack _x;
                };
            } forEach MERC_base_objects;
            
            MERC_base_objects = MERC_base_objects - _toRemove;
            publicVariable "MERC_base_objects";
        };
        sleep 5;
    };
};