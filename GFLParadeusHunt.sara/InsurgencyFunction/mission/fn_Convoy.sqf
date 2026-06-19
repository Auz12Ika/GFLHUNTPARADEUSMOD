//fn_convoy

params ["_spawnPos", "_missionData"];
_missionData params ["_id", "", "_difficulty", "", "_target"];

// 1. Tentukan Variabel Awal & Side Berdasarkan Target Faksi
private _cargoTruckClass = "";
private _escortClass = "";
private _gruntPool = [];
private _side = independent; // Default side jika tidak cocok

switch (_target) do {
    case "CULT": {
        _side = independent;
        _cargoTruckClass = selectRandom ["RHS_Ural_Civ_03", "RHS_Ural_Open_Civ_01"]; // Truk logistik cult [cite: 35, 36]
        _escortClass = "rhs_uaz_open_MSV_01";
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []]; 
    };
    case "USA": {
        _side = west; // Jika musuh/targetnya USA, maka Side menjadi WEST
        _cargoTruckClass = "rhsusf_M1078A1R_A_fmtv_wd"; // Truk logistik US Army [cite: 37, 38]
        _escortClass = "rhsusf_m1126_mk19_wd"; // Stryker MK19 [cite: 38, 39]
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []]; 
    };
    case "RUSSIA": {
        _side = east; // Jika musuh/targetnya RUSSIA, maka Side menjadi EAST
        _cargoTruckClass = "rhs_typhoon_vdv"; // Truk logistik Rusia [cite: 40, 41]
        _escortClass = "rhs_btr80a_msv"; // BTR Lapis baja Rusia [cite: 41, 42]
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []]; 
    };
};

// Logika Baru: 25% Kesempatan menggunakan MERC untuk tingkat HARD (Major Convoy)
if (_difficulty == "HARD" && (random 100 < 25)) then {
    // Menggabungkan semua faksi Mercenary yang tersedia di factions.sqf
    private _mercSF = missionNamespace getVariable ["MERC_factions_SF", []]; 
    private _mercMangi = missionNamespace getVariable ["MERC_factions_Mangi", []]; 
    private _mercVanjager = missionNamespace getVariable ["MERC_factions_Vanjager", []]; 
    
    private _combinedMercs = _mercSF + _mercMangi + _mercVanjager;
    
    if (count _combinedMercs > 0) then {
        _gruntPool = _combinedMercs; // Override grunt pool menjadi unit Mercenary
        diag_log format ["MERC SYSTEM: Convoy menggunakan tentara bayaran (Mercenary) untuk Target: %1", _target];
    };
};

// Buat grup dengan Side yang sudah ditentukan secara dinamis (West / East / Independent)
private _missionGroup = createGroup [_side, true]; 

// 2. Spawn Truk Kargo Utama (Wajib Dihancurkan) [cite: 43]
if (_cargoTruckClass != "") then {
    private _truck = createVehicle [_cargoTruckClass, _spawnPos, [], 0, "NONE"]; [cite: 43]
    _truck setVariable ["MERC_is_mission_target", true, true]; // Penanda hancur untuk sukses [cite: 44]
    
    // Isi kru supir truk dari grunt pool (Bisa faksi asli atau faksi merc)
    if (count _gruntPool > 0) then {
        private _driver = _missionGroup createUnit [selectRandom _gruntPool, _spawnPos, [], 0, "NONE"]; [cite: 44]
        _driver moveInDriver _truck; 
    };
};

// 3. Spawn Kendaraan Escort Berawak Senjata [cite: 45]
if (_escortClass != "") then {
    private _escortPos = _spawnPos getPos [15, random 360]; [cite: 45]
    private _escortVic = createVehicle [_escortClass, _escortPos, [], 0, "NONE"]; [cite: 46]
    createVehicleCrew _escortVic; [cite: 46]
    (crew _escortVic) joinSilent _missionGroup; 
};

// Tambahan infanteri barisan berjalan kaki untuk tingkat Hard (Major Convoy) 
if (_difficulty == "HARD" && count _gruntPool > 0) then { 
    for "_i" from 1 to 12 do { 
        private _soldier = _missionGroup createUnit [selectRandom _gruntPool, _spawnPos getPos [random 25, random 360], [], 0, "NONE"]; [cite: 47, 48]
    };
};

// 3. Spawn Kendaraan Escort Berawak Senjata
if (_escortClass != "") then {
    private _escortPos = _spawnPos getPos [15, random 360];
    private _escortVic = createVehicle [_escortClass, _escortPos, [], 0, "NONE"];
    createVehicleCrew _escortVic;
    (crew _escortVic) joinSilent _missionGroup;
};

// 4. Tambahan infanteri barisan berjalan kaki untuk tingkat Hard (Major Convoy)
if (_difficulty == "HARD" && count _gruntPool > 0) then {
    // Mengatur jumlah AI secara pasti menjadi 15 prajurit
    private _aiCount = 15; 
    
    for "_i" from 1 to _aiCount do {
        private _soldier = _missionGroup createUnit [selectRandom _gruntPool, _spawnPos getPos [random 25, random 360], [], 0, "NONE"];
        // Menyebarkan AI di sekitar convoy agar posisinya rapi
        _soldier doMove (_spawnPos getPos [random 15, random 360]);
    };
};