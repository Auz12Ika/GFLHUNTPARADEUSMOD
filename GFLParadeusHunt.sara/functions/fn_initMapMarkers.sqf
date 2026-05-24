/*
    Author: Modder
    File: fn_initWorldMapping.sqf
    Description: Menentukan HQ USA & Russia secara acak, membagi wilayah.
    🔧 FIX P12: Radius klaim dari merc_factions (fallback 1580).
               Persistensi ownership ke profileNamespace.
*/

if (!isServer) exitWith {};

private _minDistHQ = 3000;

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

// 1. CARI MILBASE BESAR
private _allMilBases = nearestObjects [[worldSize/2, worldSize/2, 0], ["Land_Mil_Barracks_i_F", "Land_ControlTower_01_F"], worldSize];
private _potentialPositions = [];
{ if (!surfaceIsWater (getPos _x)) then { _potentialPositions pushBack (getPos _x); }; } forEach _allMilBases;

if (count _potentialPositions < 2) exitWith { diag_log "ERROR: Tidak cukup Milbase untuk HQ!"; };

// 2. RANDOMISASI HQ
private _usaHQ = selectRandom _potentialPositions;
private _rusHQ = [0,0,0];
private _maxDistFound = 0;
{
    private _dist = _x distance _usaHQ;
    if (_dist > _minDistHQ && _dist > _maxDistFound) then { _rusHQ = _x; _maxDistFound = _dist; };
} forEach _potentialPositions;

missionNamespace setVariable ["merc_usa_mainbase_pos", _usaHQ, true];
missionNamespace setVariable ["merc_rus_mainbase_pos", _rusHQ, true];

private _mUSA = createMarker ["marker_usa_hq", _usaHQ];
_mUSA setMarkerType "flag_NATO"; _mUSA setMarkerText "USA MAIN OPERATIONAL BASE"; _mUSA setMarkerColor "ColorWest";

private _mRUS = createMarker ["marker_rus_hq", _rusHQ];
_mRUS setMarkerType "flag_CSAT"; _mRUS setMarkerText "RUSSIA MAIN OPERATIONAL BASE"; _mRUS setMarkerColor "ColorEast";

// 3. KLAIM WILAYAH + PERSISTENSI
private _locationData = missionNamespace getVariable ["merc_location_data", []];
private _ownershipData = [];

{
    _x params ["_pos", "_type", "_name"];
    private _owner = "NEUTRAL";
    if (_pos distance _usaHQ < _claimRadius) then { _owner = "USA"; }
    else { if (_pos distance _rusHQ < _claimRadius) then { _owner = "RUSSIA"; }; };

    missionNamespace setVariable [format ["owner_%1", _name], _owner, true];
    _ownershipData pushBack [_name, _owner];

    private _mName = format ["mark_city_%1", _name];
    if (_mName == "") then { _mName = format ["mark_infra_%1", _name]; };
    switch (_owner) do {
        case "USA": { _mName setMarkerColor "ColorWest"; };
        case "RUSSIA": { _mName setMarkerColor "ColorEast"; };
        default { _mName setMarkerColor "ColorWhite"; };
    };
} forEach _locationData;

// Simpan ownership ke profil
profileNamespace setVariable ["merc_save_ownership", _ownershipData];
profileNamespace setVariable ["merc_save_claim_radius", _claimRadius];
saveProfileNamespace;

systemChat format ["HQ Established. Distance: %1 m. Territory claimed.", floor(_usaHQ distance _rusHQ)];