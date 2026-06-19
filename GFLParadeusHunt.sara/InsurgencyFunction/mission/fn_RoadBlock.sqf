/*
    File: fn_RoadBlock.sqf
    Description: Sub-misi Roadblock Otomatis. Menempel pada jalan raya,
                 memakai faksi dinamis, dan membangun objek berdasarkan komposisi 3D editor (.sqe).
*/
params ["_spawnPos", "_missionData", "_aiCount"];
_missionData params ["_id", "", "_difficulty", "", "_target"];

private _missionGroup = createGroup [independent, true];

// ========================================================================
// 1. WAJIB DI JALAN BESAR: Geser Posisi ke Segmen Jalan Terdekat & Ambil Arahnya
// ========================================================================
private _nearRoads = _spawnPos nearRoads 150;
private _roadDir = 0;

if (count _nearRoads > 0) then {
    private _closestRoad = _nearRoads select 0;
    _spawnPos = getPos _closestRoad;
    _roadDir = getDir _closestRoad; // Arah hadap checkpoint mengikuti sudut jalan raya
};

// ========================================================================
// 2. DINAMIS FACTION: Ambil Data Prajurit & Kendaraan Sesuai Target Misi
// ========================================================================
private _gruntPool = [];
private _checkpointVicClass = "";

switch (_target) do {
    case "CULT": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
        _checkpointVicClass = selectRandom (missionNamespace getVariable ["MERC_vehicles_CULT", ["rhs_uaz_open_MSV_01"]]);
    };
    case "MERC_ENEMY": {
        _gruntPool = (missionNamespace getVariable ["MERC_factions_SF", []]) + (missionNamespace getVariable ["MERC_factions_Mangi", []]);
        _checkpointVicClass = selectRandom (missionNamespace getVariable ["MERC_vehicles_SF", ["CUP_I_LR_SF_HMG_AAF"]]);
    };
    case "USA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
        _checkpointVicClass = selectRandom (missionNamespace getVariable ["MERC_vehicles_USA", ["rhsusf_m1151_m2_v2_wd"]]);
    };
    case "RUSSIA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
        _checkpointVicClass = selectRandom (missionNamespace getVariable ["MERC_vehicles_RUS", ["rhs_tigr_sts_3camo"]]);
    };
    default {
        // Cadangan jika target faksi tidak terdefinisi
        _gruntPool = (missionNamespace getVariable ["MERC_factions_SF", []]) + (missionNamespace getVariable ["MERC_factions_Mangi", []]);
        _checkpointVicClass = "CUP_I_BTR80A_ION";
    };
};

// ========================================================================
// 3. STRUKTUR .SQE: Ekstraksi Data Komposisi dan Kalkulasi Rotasi Matriks Jalan
// ========================================================================
// Konversi format .sqe [X, Z, Y] ke sistem Arma [X, Y, Z] serta konversi Radian ke Derajat
private _compositionData = [
    ["Land_fort_rampart", [-20.597168, -4.2229004, 1.4744482], 90],
    ["Land_Razorwire_F", [-15.758057, 6.932373, 2.5599432], 180],
    ["Land_Razorwire_F", [-20.299072, 3.1828613, 2.6125002], 90],
    ["Land_HBarrier_5_F", [-15.505615, 5.1787109, 2.3783002], 180],
    ["Land_HBarrier_5_F", [-18.800781, 3.0354004, 2.4395151], 270],
    ["Land_WoodenBox_F", [10.278809, -3.0012207, 3.7839422], 15],
    ["Land_PaperBox_closed_F", [10.583984, -4.5478516, 4.4001408], 180],
    ["Land_Sack_F", [9.8991699, -1.5275879, 4.2255373], 15],
    ["Land_Sack_F", [11.02417, -2.277832, 4.4672527], 330],
    ["Land_fort_bagfence_long", [6.0300293, -0.90112305, 3.1973972], 270],
    ["Land_fort_bagfence_long", [6.0300293, 1.973877, 3.4573956], 270],
    ["Land_CamoNet_EAST", [10.678711, -2.222168, 5.2706165], 90],
    ["Land_fort_bagfence_round", [8.8024902, 4.6115723, 4.3586426], 0],
    ["Land_fort_rampart", [14.140137, -1.9304199, 5.0819626], 270],
    ["Land_fort_rampart", [-7.2419434, -2.9973145, 0.1399498], 270],
    ["Land_Sacks_goods_F", [10.749023, -1.2858887, 4.5823822], 90]
];

{
    _x params ["_type", "_relPos", "_relDir"];
    _relPos params ["_relX", "_relY", "_relZ"];
    
    // Algoritma Rotasi 2D: Agar susunan objek berputar mengikuti kelokan jalan raya secara akurat
    private _rotX = (_relX * cos _roadDir) + (_relY * sin _roadDir);
    private _rotY = (-_relX * sin _roadDir) + (_relY * cos _roadDir);
    private _finalPos = _spawnPos vectorAdd [_rotX, _rotY, _relZ];
    
    private _obj = createVehicle [_type, _finalPos, [], 0, "CAN_COLLIDE"];
    _obj setDir (_roadDir + _relDir);
    _obj setPosATL _finalPos; // Mengunci ketinggian absolut sesuai blueprint 3D editor
} forEach _compositionData;

// ========================================================================
// 4. SPAWN KENDARAAN: Diambil Sesuai Faksi Aktif
// ========================================================================
if (_checkpointVicClass != "") then {
    // Menempatkan kendaraan bersenjata sedikit mundur di belakang barikade agar posisinya taktis
    private _vicPos = _spawnPos getPos [12, _roadDir + 180];
    private _vic = createVehicle [_checkpointVicClass, _vicPos, [], 0, "NONE"];
    _vic setDir _roadDir;
    
    createVehicleCrew _vic;
    (crew _vic) joinSilent _missionGroup;
};

// ========================================================================
// 5. SPAWN INFANTERI: Mengisi Checkpoint dengan Pasukan Pembersih Global
// ========================================================================
if (count _gruntPool > 0) then {
    for "_i" from 1 to _aiCount do {
        private _guardPos = _spawnPos getPos [random 15, random 360];
        private _guard = _missionGroup createUnit [selectRandom _gruntPool, _guardPos, [], 0, "NONE"];
        
        // Perintah siaga menjaga perimeter jalan raya
        _guard doMove (_spawnPos getPos [random 5, random 360]);
    };
};