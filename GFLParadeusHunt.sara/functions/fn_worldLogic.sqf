/*
    Author: Modder
    File: fn_worldLogic.sqf
    Description: Ekspansi radius mingguan, perang besar, persistensi state.
    🔧 FIX P13: Radius dari merc_factions + simpan state ke profileNamespace.
*/

if (!isServer) exitWith {};

// --- BACA RADIUS KLAIM DARI CONFIG ---
private _claimRadius = 1580;
if (!isNil "merc_factions") then {
    {
        if ((_x select 0) in ["USA", "RUSSIA"]) exitWith {
            _claimRadius = (_x select 4) select 0;
        };
    } forEach merc_factions;
};
missionNamespace setVariable ["merc_claim_radius", _claimRadius, true];

// Muat persistensi jika ada
private _loadedRadius = profileNamespace getVariable ["merc_save_claim_radius", nil];
if (!isNil "_loadedRadius") then {
    _claimRadius = _loadedRadius;
    missionNamespace setVariable ["merc_claim_radius", _claimRadius, true];
};

private _ownershipData = profileNamespace getVariable ["merc_save_ownership", []];
if (count _ownershipData > 0) then {
    { _x params ["_name", "_owner"]; missionNamespace setVariable [format ["owner_%1", _name], _owner, true]; } forEach _ownershipData;
};

private _usaHQ = missionNamespace getVariable ["merc_usa_mainbase_pos", [0,0,0]];
private _rusHQ = missionNamespace getVariable ["merc_rus_mainbase_pos", [0,0,0]];
private _locationData = missionNamespace getVariable ["merc_location_data", []];

// --- EKSPANSI MINGGUAN ---
[] spawn {
    private _lastUpdateDay = date select 2;
    private _daysPassed = 0;

    while {true} do {
        private _currentDay = date select 2;
        if (_currentDay != _lastUpdateDay) then {
            _lastUpdateDay = _currentDay;
            _daysPassed = _daysPassed + 1;

            if (_daysPassed >= 7) then {
                _daysPassed = 0;

                private _rad = missionNamespace getVariable ["merc_claim_radius", 1580];
                private _newRad = sqrt(((pi * (_rad^2)) + 1000000) / pi);
                missionNamespace setVariable ["merc_claim_radius", _newRad, true];

                // Simpan radius baru ke profil
                profileNamespace setVariable ["merc_save_claim_radius", _newRad];

                private _locData = missionNamespace getVariable ["merc_location_data", []];
                private _ownershipData = [];
                {
                    _x params ["_p", "_t", "_n"];
                    private _v = format ["owner_%1", _n];
                    private _currentOwner = missionNamespace getVariable [_v, "NEUTRAL"];
                    if (_currentOwner == "NEUTRAL") then {
                        if (_p distance (missionNamespace getVariable ["merc_usa_mainbase_pos", [0,0,0]]) < _newRad) then {
                            missionNamespace setVariable [_v, "USA", true];
                            format ["mark_%1", _n] setMarkerColor "ColorWest";
                            _currentOwner = "USA";
                        } else {
                            if (_p distance (missionNamespace getVariable ["merc_rus_mainbase_pos", [0,0,0]]) < _newRad) then {
                                missionNamespace setVariable [_v, "RUSSIA", true];
                                format ["mark_%1", _n] setMarkerColor "ColorEast";
                                _currentOwner = "RUSSIA";
                            };
                        };
                    };
                    _ownershipData pushBack [_n, _currentOwner];
                } forEach _locData;

                profileNamespace setVariable ["merc_save_ownership", _ownershipData];
                saveProfileNamespace;

                // Cek Perang Besar
                private _neutrals = { (missionNamespace getVariable [format["owner_%1", _x select 2], "NEUTRAL"]) == "NEUTRAL" } count _locData;
                if (_neutrals == 0) then {
                    missionNamespace setVariable ["merc_major_war_active", true, true];
                    ["MajorWarTriggered", ["PERANG TOTAL: Perbatasan Memanas!"]] call BIS_fnc_showNotification;
                    {
                        private _mName = format ["mark_%1", _x select 2];
                        _mName setMarkerBrush "Cross";
                        _mName setMarkerColor "ColorOrange";
                    } forEach _locData;

                    [_locData] spawn {
                        params ["_locData"];
                        sleep 86400;
                        {
                            private _n = _x select 2;
                            private _owner = missionNamespace getVariable [format["owner_%1", _n], "NEUTRAL"];
                            private _mName = format ["mark_%1", _n];
                            _mName setMarkerBrush "Solid";
                            if (_owner == "USA") then { _mName setMarkerColor "ColorWest" } else { _mName setMarkerColor "ColorEast" };
                        } forEach _locData;
                        missionNamespace setVariable ["merc_major_war_active", false, true];
                    };
                };
            };
        };
        sleep 30;
    };
};