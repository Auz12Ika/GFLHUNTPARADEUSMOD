/*
    Author: Modder
    File: fn_initWorldMapping.sqf
    Description: Menentukan lokasi HQ USA & Russia secara acak di Milbase besar, 
                 memaksimalkan jarak, dan membagi wilayah.
*/

if (!isServer) exitWith {};

private _minDistHQ = 3000; // Jarak minimal antar HQ (3km)
private _claimRadius = 1580; // Radius untuk cakupan area ~2.5km2
if (!isNil "merc_factions") then {
    // Cari faksi USA atau RUSIA untuk mendapatkan radius klaim
    {
        if ((_x select 0) in ["USA", "RUSSIA"]) exitWith {
            _claimRadius = (_x select 4) select 0;
        };
    } forEach merc_factions;
};

missionNamespace setVariable ["merc_claim_radius", _claimRadius, true];
// 1. CARI SEMUA MILBASE BESAR DI SAHRANI
// Kita mencari objek spesifik militer atau lokasi bernama militer
private _allMilBases = nearestObjects [[worldSize/2, worldSize/2, 0], ["Land_Mil_Barracks_i_F", "Land_ControlTower_01_F"], worldSize];
private _potentialPositions = [];

{
    private _pos = getPos _x;
    // Pastikan di daratan (bukan dermaga kecil) dan tidak terlalu dekat pinggir map
    if (!surfaceIsWater _pos) then {
        _potentialPositions pushBack _pos;
    };
} forEach _allMilBases;

if (count _potentialPositions < 2) exitWith {diag_log "ERROR: Tidak cukup Milbase untuk HQ!";};

// 2. RANDOMISASI HQ DENGAN JARAK MAKSIMAL
private _usaHQ = selectRandom _potentialPositions;
private _rusHQ = [0,0,0];

// Cari posisi Russia yang terjauh dari USA tapi tetap > 3km
private _maxDistFound = 0;
{
    private _dist = _x distance _usaHQ;
    if (_dist > _minDistHQ && _dist > _maxDistFound) then {
        _rusHQ = _x;
        _maxDistFound = _dist;
    };
} forEach _potentialPositions;

// Simpan posisi HQ ke variabel global agar bisa diakses script lain
missionNamespace setVariable ["merc_usa_mainbase_pos", _usaHQ, true];
missionNamespace setVariable ["merc_rus_mainbase_pos", _rusHQ, true];

// Buat Marker untuk HQ (Visual Check)
private _mUSA = createMarker ["marker_usa_hq", _usaHQ];
_mUSA setMarkerType "flag_NATO";
_mUSA setMarkerText "USA MAIN OPERATIONAL BASE";
_mUSA setMarkerColor "ColorWest";

private _mRUS = createMarker ["marker_rus_hq", _rusHQ];
_mRUS setMarkerType "flag_CSAT";
_mRUS setMarkerText "RUSSIA MAIN OPERATIONAL BASE";
_mRUS setMarkerColor "ColorEast";


// 3. LOGIKA AMBIL ALIH WILAYAH (Radius 2.5km2)
private _locationData = missionNamespace getVariable ["merc_location_data", []];

{
    _x params ["_pos", "_type", "_name"];
    private _owner = "NEUTRAL";

    if (_pos distance _usaHQ < _claimRadius) then {
        _owner = "USA";
    } else {
        if (_pos distance _rusHQ < _claimRadius) then {
            _owner = "RUSSIA";
        };
    };

    // Set variabel kepemilikan pada lokasi tersebut
    missionNamespace setVariable [format ["owner_%1", _name], _owner, true];

    // Update warna marker yang dibuat di fn_initMapMarkers.sqf
    private _mName = format ["mark_city_%1", _name];
    if (_mName == "") then { _mName = format ["mark_infra_%1", _name]; };
    
    switch (_owner) do {
        case "USA": { _mName setMarkerColor "ColorWest"; };
        case "RUSSIA": { _mName setMarkerColor "ColorEast"; };
        default { _mName setMarkerColor "ColorWhite"; };
    };

} forEach _locationData;

systemChat format ["HQ Established. Distance: %1 meters. Territory claimed.", floor(_usaHQ distance _rusHQ)];