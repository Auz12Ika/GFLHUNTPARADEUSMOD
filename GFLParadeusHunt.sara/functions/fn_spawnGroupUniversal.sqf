/*
    Author: Modder
    File: fn_spawnGroupUniversal.sqf
    Description: Batch spawn controller — maks 3 grup per siklus, quota per base.
    🔧 FIX P1: Sekarang memanggil MERC_fnc_spawnGroup (fungsi dasar), bukan dirinya sendiri.
    
    Params:
        _pos        - Posisi spawn
        _factionID  - "USA" / "RUSSIA" / "CULT" / "MERC" / "CIV"
        _baseType   - "CITY" / "BASE" / "MAIN_BASE" / "AIRBASE" / dll
        _baseName   - Nama unik lokasi (untuk tracking progres)
*/

params [
    ["_pos", [0,0,0], [[]]],
    ["_factionID", "USA", [""]],
    ["_baseType", "CITY", [""]],
    ["_baseName", "Unknown", [""]]
];

if (!isServer) exitWith {};

// --- KONFIGURASI QUOTA PER BASE ---
private _maxAI = 40;
private _vicLimit = 2;

switch (_baseType) do {
    case "MAIN_BASE": { _maxAI = 80; _vicLimit = 4; };
    case "WAR_ZONE":  { _maxAI = 120; _vicLimit = 5; };
    case "AIRBASE":   { _maxAI = 50; _vicLimit = 3; };
};

// --- AMBIL PROGRES ---
private _progVar = format ["MERC_ProgAI_%1", _baseName];
private _currentAI = missionNamespace getVariable [_progVar, 0];
private _vicVar = format ["MERC_ProgVic_%1", _baseName];
private _currentVic = missionNamespace getVariable [_vicVar, 0];

// --- LIMITER: MAKS 3 GRUP PER SIKLUS ---
private _maxBatch = 3;
private _spawnedInBatch = 0;

diag_log format ["MERC SPAWNER: Batch spawn untuk %1 (AI: %2/%3, Grup dispawn: %4)", _baseName, _currentAI, _maxAI, _spawnedInBatch];

while { (_currentAI < _maxAI) && (_spawnedInBatch < _maxBatch) } do {
    
    // Cek quota global
    private _totalAI = { side _x != civilian } count allUnits;
    if (_totalAI >= 120) exitWith {
        diag_log "MERC SPAWNER: Global limit 120 AI tercapai.";
    };
    
    // 🔧 FIX: Panggil fungsi dasar, bukan diri sendiri
    private _grp = [_pos, _factionID, _baseType, true] call MERC_fnc_spawnGroup;
    
    if (!isNull _grp) then {
        private _unitCount = count (units _grp);
        _currentAI = _currentAI + _unitCount;
        _spawnedInBatch = _spawnedInBatch + 1;
        
        // Tandai grup pertama sebagai Remnant (tidak dihapus saat despawn)
        if (_currentAI <= 25) then {
            _grp setVariable ["MERC_Remnant", true, true];
        };
        
        _grp setVariable ["MERC_OriginBase", _baseName, true];
    };
    
    // --- SPAWN KENDARAAN (20% chance, kalau ada quota) ---
    if (_currentVic < _vicLimit && random 100 > 80) then {
        private _vicPool = [];
        switch (toUpper _factionID) do {
            case "USA":    { _vicPool = if (!isNil "MERC_vehicles_USA") then { MERC_vehicles_USA } else { ["B_MRAP_01_hmg_F", "B_MRAP_01_F"] }; };
            case "RUSSIA": { _vicPool = if (!isNil "MERC_vehicles_RUS") then { MERC_vehicles_RUS } else { ["O_MRAP_02_hmg_F", "O_MRAP_02_F"] }; };
            case "CULT":   { _vicPool = if (!isNil "MERC_vehicles_CULT") then { MERC_vehicles_CULT } else { ["C_Offroad_01_F", "C_Van_01_transport_F"] }; };
            case "MERC":   { _vicPool = if (!isNil "MERC_vehicles_MERC") then { MERC_vehicles_MERC } else { ["I_MRAP_03_hmg_F"] }; };
            default        { _vicPool = ["C_Offroad_01_F"]; };
        };
        
        if (count _vicPool > 0) then {
            private _vicClass = selectRandom _vicPool;
            private _vicPos = [_pos, 5, 50, 7, 0, 0.3, 0] call BIS_fnc_findSafePos;
            if (count _vicPos > 0) then {
                private _veh = createVehicle [_vicClass, _vicPos, [], 0, "NONE"];
                createVehicleCrew _veh;
                _currentVic = _currentVic + 1;
                (group (driver _veh)) setVariable ["MERC_Remnant", (_currentVic <= 2), true];
                (group (driver _veh)) setVariable ["MERC_OriginBase", _baseName, true];
            };
        };
    };
    
    sleep 3;
};

// --- SIMPAN PROGRES ---
missionNamespace setVariable [_progVar, _currentAI, true];
missionNamespace setVariable [_vicVar, _currentVic, true];

// --- STATUS ---
private _activeVar = format ["MERC_Active_%1", _baseName];
if (_currentAI >= _maxAI) then {
    missionNamespace setVariable [_activeVar, true, true];
    diag_log format ["MERC SPAWNER: %1 FULLY DEPLOYED (%2/%3)", _baseName, _currentAI, _maxAI];
} else {
    missionNamespace setVariable [_activeVar, false, true];
    diag_log format ["MERC SPAWNER: %1 batch selesai, menunggu siklus berikutnya (%2/%3)", _baseName, _currentAI, _maxAI];
};