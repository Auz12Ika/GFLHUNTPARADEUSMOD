/*
    Author: Gemini
    File: fn_spawnCultHQ.sqf
    Description: Spawn 7 Cult HQ secara acak di peta.
                 Setiap HQ dijaga bos Goliath_elite.
    🔧 FIX: Bos Goliath_elite. Bos mati = counter endgame jalan.
*/

if (!isServer) exitWith {};

private _hqCount = 7;
private _minDistFromMainHQ = 2000;
private _minDistBetweenHQ = 1200;
private _minDistFromCity = 800;

private _blacklistPos = [
    missionNamespace getVariable ["merc_usa_mainbase_pos", [0,0,0]],
    missionNamespace getVariable ["merc_rus_mainbase_pos", [0,0,0]]
];

private _spawnedPositions = [];

for "_i" from 1 to _hqCount do {
    private _validPos = [];
    private _attempts = 0;

    while {count _validPos == 0 && _attempts < 100} do {
        _attempts = _attempts + 1;
        private _testPos = [random worldSize, random worldSize, 0];

        if (!surfaceIsWater _testPos) then {
            private _ok = true;
            { if (_testPos distance _x < _minDistFromMainHQ) exitWith { _ok = false; }; } forEach _blacklistPos;
            { if (_testPos distance _x < _minDistBetweenHQ) exitWith { _ok = false; }; } forEach _spawnedPositions;
            private _nearCities = (missionNamespace getVariable ["merc_location_data", []]) select {
                (_x select 1 == "CITY") && {_testPos distance (_x select 0) < _minDistFromCity}
            };
            if (count _nearCities > 0) then { _ok = false; };
            if (_ok) then { _validPos = _testPos; };
        };
        sleep 0.01;
    };

    if (count _validPos == 0) then {
        diag_log format ["CULT HQ SPAWN: Gagal posisi #%1", _i];
        continue;
    };

    _spawnedPositions pushBack _validPos;

    // --- BOSS GOLIATH ELITE ---
    private _hqGroup = createGroup east;
    private _boss = _hqGroup createUnit ["tacgirls_paradeus_goliath_elite", _validPos, [], 20, "NONE"];
    _boss setSkill 1.0;
    _boss setRank "COLONEL";
    _boss allowFleeing 0;
    _boss setVariable ["Cult_HQ_Boss", true, true];

    // Pengawal
    for "_j" from 1 to (3 + floor random 3) do {
        private _guard = _hqGroup createUnit [selectRandom ["tacgirls_paradeus_doppel", "tacgirls_paradeus_rodelero"], _validPos, [], 10, "NONE"];
        _guard setSkill 0.8;
    };

    [_hqGroup, _validPos, 100] call BIS_fnc_taskPatrol;
    _hqGroup setBehaviour "COMBAT";

    // --- MARKER ---
    private _markerName = format ["cult_hq_%1", _i];
    private _mrk = createMarker [_markerName, _validPos];
    _mrk setMarkerType "KIA";
    _mrk setMarkerColor "ColorRed";
    _mrk setMarkerText format ["Cult HQ #%1", _i];
    _mrk setMarkerSize [0.8, 0.8];

    // --- DAFTARKAN KE END GAME LOGIC ---
    [_boss] call MERC_fnc_endGameLogic;

    diag_log format ["CULT HQ SPAWN: HQ #%1 dengan Goliath_elite di %2", _i, _validPos];
};

missionNamespace setVariable ["cult_hq_destroyed_count", 0, true];
profileNamespace setVariable ["merc_persistent_cult_count", 0];
saveProfileNamespace;

systemChat "INTEL: 7 Cult HQ telah diidentifikasi. Bos Goliath menjaga masing-masing.";