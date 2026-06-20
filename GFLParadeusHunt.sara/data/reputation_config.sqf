/*
    File: data\reputation_config.sqf
    Description: Pusat data reputasi, hunter team, & diplomasi Cult.
    🔧 FINAL: Inisialisasi agresif West/East vs Independent.
              Independent tetap teman dengan sesama Independent.
              Hunter team dipanggil tanpa mengubah setFriend di loop.
*/

// ========================================================================
// 1. INISIALISASI NILAI AWAL FAKSI & DIPLOMASI (Server Only)
// ========================================================================
if (isServer) then {
    private _factions = [
        ["rep_USA", 0],
        ["rep_RUSSIA", 0]
    ];

    {
        _x params ["_varName", "_startValue"];
        if (isNil {missionNamespace getVariable _varName}) then {
            missionNamespace setVariable [_varName, _startValue, true];
        };
    } forEach _factions;
    
    // 🔧 Diplomasi awal: West & East agresif ke Independent (pemain).
    //    Reputasi nanti yang akan memperbaiki hubungan.
    //    Cult (East/West) otomatis ikut karena side yang sama.
    east setFriend [independent, -1];
    independent setFriend [east, 0];
    west setFriend [independent, -1];
    independent setFriend [west, 0];
    
    // 🔧 Sesama Independent tetap teman (Mercenary tidak saling serang).
    independent setFriend [independent, 1];

    diag_log "REPUTATION DATA: Variabel rep_USA & rep_RUSSIA siap. Diplomasi awal agresif.";
};

// ========================================================================
// 2. DATA STRUKTUR TIER REPUTASI (Global)
// ========================================================================
/*
    Format Array: [Nilai_Min, Nilai_Max, "Nama_Tier", "Warna_Hex", Pengali_Hadiah_Uang]
*/
TAG_reputation_tiers = [
    [-100, -61,  "NEMESIS",   "#FF0000", 0.0],
    [-60,  -21,  "HOSTILE",   "#FF5555", 0.5],
    [-20,   19,  "NEUTRAL",   "#FFFFFF", 1.0],
    [20,    59,  "FRIENDLY",  "#55FF55", 1.25],
    [60,   100,  "ALLIED",    "#00FF00", 1.5]
];

// ========================================================================
// 3. FUNGSI UTILITY / HELPER DATA
// ========================================================================

// Mengambil info tier berdasarkan skor saat ini
TAG_fnc_getRepData = {
    params [["_score", 0, [0]]];
    private _matchedTier = TAG_reputation_tiers select 2; 
    {
        if (_score >= (_x select 0) && _score <= (_x select 1)) exitWith {
            _matchedTier = _x;
        };
    } forEach TAG_reputation_tiers;
    _matchedTier
};

// Mengambil skor mentah berdasarkan string nama faksi ("USA" atau "RUSSIA")
TAG_fnc_getFactionRep = {
    params [["_factionName", "", [""]]];
    if !(_factionName in ["USA", "RUSSIA"]) exitWith { 0 }; 
    
    private _varName = format ["rep_%1", _factionName];
    missionNamespace getVariable [_varName, 0]
};

// ========================================================================
// 4. ENGINE PERILAKU FAKSI (Server Only - Hunter Team)
// ========================================================================
if (isServer) then {
    [] spawn {
        missionNamespace setVariable ["TAG_nextUSAHunterTime", 0];
        missionNamespace setVariable ["TAG_nextRUSHunterTime", 0];

        while {true} do {
            private _repUSA = missionNamespace getVariable ["rep_USA", 0];
            private _repRUS = missionNamespace getVariable ["rep_RUSSIA", 0];
            private _playerHQ = missionNamespace getVariable ["MERC_Player_HQ", objNull];

            // --- USA Hunter ---
            if (_repUSA <= -61) then {
                if (time > (missionNamespace getVariable ["TAG_nextUSAHunterTime", 0]) && {!isNull _playerHQ}) then {
                    missionNamespace setVariable ["TAG_nextUSAHunterTime", time + 900];
                    
                    private _spawnPos = (getPos _playerHQ) getPos [800, random 360];
                    private _grp = createGroup [west, true];
                    for "_i" from 1 to 6 do {
                        private _unit = _grp createUnit [selectRandom MERC_factions_USA, _spawnPos, [], 10, "NONE"];
                        _unit setSkill 0.8;
                    };
                    if (count MERC_vehicles_USA > 0) then {
                        private _vic = createVehicle [selectRandom MERC_vehicles_USA, _spawnPos, [], 0, "NONE"];
                        createVehicleCrew _vic;
                        (group driver _vic) setBehaviour "COMBAT";
                    };
                    _grp setBehaviour "COMBAT";
                    _grp setCombatMode "RED";
                    _grp move (getPos _playerHQ);

                    systemChat "WARNING: USA hunter team deployed to your location!";
                };
            };

            // --- RUS Hunter ---
            if (_repRUS <= -61) then {
                if (time > (missionNamespace getVariable ["TAG_nextRUSHunterTime", 0]) && {!isNull _playerHQ}) then {
                    missionNamespace setVariable ["TAG_nextRUSHunterTime", time + 900];
                    
                    private _spawnPos = (getPos _playerHQ) getPos [800, random 360];
                    private _grp = createGroup [east, true];
                    for "_i" from 1 to 6 do {
                        private _unit = _grp createUnit [selectRandom MERC_factions_RUS, _spawnPos, [], 10, "NONE"];
                        _unit setSkill 0.8;
                    };
                    if (count MERC_vehicles_RUS > 0) then {
                        private _vic = createVehicle [selectRandom MERC_vehicles_RUS, _spawnPos, [], 0, "NONE"];
                        createVehicleCrew _vic;
                        (group driver _vic) setBehaviour "COMBAT";
                    };
                    _grp setBehaviour "COMBAT";
                    _grp setCombatMode "RED";
                    _grp move (getPos _playerHQ);

                    systemChat "WARNING: Russian hunter team deployed to your location!";
                };
            };

            sleep 5;
        };
    };
};