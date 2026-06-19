// fn_Barrack

params ["_spawnPos", "_missionData", "_aiCount"];
// _aiCount sekarang diambil dari parameter ke-3, _missionData params disesuaikan urutannya
_missionData params ["_id", "_missionType", "_difficulty", "", "_target"];

private _missionGroup = createGroup [independent, true];

// =========================================================================
// 1. TENTUKAN SETUP FAKSI, BOSS (DUA-DUANYA UNTUK CULT), & KENDARAAN
// =========================================================================
private _gruntPool = [];
private _bossArray = []; 
private _vehClass = "";

switch (_target) do {
    case "CULT": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_CULT", []];
        _bossArray = ["Sextans_boss", "Niter_boss"]; // Kedua boss dipastikan keluar bersamaan
        _vehClass = "rhs_uaz_open_MSV_01"; 
    };
    case "USA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_USA", []];
        _bossArray = ["rhsusf_army_ocp_rifleman"]; 
        _vehClass = "rhsusf_m1151_m2_v2_wd";     
    };
    case "RUSSIA": {
        _gruntPool = missionNamespace getVariable ["MERC_factions_RUS", []];
        _bossArray = ["rhs_msv_emr_machinegunner"]; 
        _vehClass = "rhs_tigr_sts_3camo";         
    };
};

// =========================================================================
// 2. SPAWN STRUKTUR BARAK MENGGUNAKAN FILE SQE YANG SESUAI
// =========================================================================
private _sqeComposition = "";
if (_target == "CULT") then {
    _sqeComposition = selectRandom ["CULT BARRACK_1", "CULT BARRACK 2"];
} else {
    _sqeComposition = selectRandom ["BARRACK 1", "BARRACK2"];
};

[_spawnPos, 0, _sqeComposition] call MERC_fnc_spawnSQE; 


// =========================================================================
// 3. SPAWN SANG BOSS (UNTUK CULT DI-SPAWN DUA-DUANYA & WAJIB DI-KILL)
// =========================================================================
{
    if (_x != "") then {
        private _barrackBoss = _missionGroup createUnit [_x, _spawnPos, [], 0, "NONE"];
        // Penanda wajib eliminasi untuk misi bersih-bersih
        _barrackBoss setVariable ["MERC_is_mission_target", true, true];
    };
} foreach _bossArray;


// =========================================================================
// 4. PENGERAHAN PASUKAN PENGAWAL (MENGIKUTI JUMLAH AI DARI SERVER)
// =========================================================================
// Proteksi cadangan (Fallback): Jika karena suatu hal _aiCount tidak terkirim/nil, diisi nilai default aman
if (isNil "_aiCount" || {typeName _aiCount != "SCALAR"} || {_aiCount <= 0}) then {
    _aiCount = 15; 
};

if (count _gruntPool > 0) then {
    for "_i" from 1 to _aiCount do {
        private _unit = _missionGroup createUnit [selectRandom _gruntPool, _spawnPos getPos [random 30, random 360], [], 0, "NONE"];
        
        // PENTING: Karena misi bersih-bersih, tandai semua kroco sebagai target juga!
        _unit setVariable ["MERC_is_mission_target", true, true];
        
        // AI bergerak aktif berpatroli merapat ke pangkalan
        _unit doMove (_spawnPos getPos [random 10, random 360]);
    };
};


// =========================================================================
// 5. SPAWN KENDARAAN RINGAN PENJAGA AREA
// =========================================================================
if (_vehClass != "") then {
    private _vic = createVehicle [_vehClass, _spawnPos getPos [20, random 360], [], 0, "NONE"];
    _vic setDir (random 360);

    createVehicleCrew _vic;
    (crew _vic) joinSilent _missionGroup;
    
    // Kru kendaraan otomatis masuk hitungan target yang wajib dibersihkan
    {
        _x setVariable ["MERC_is_mission_target", true, true];
    } forEach (crew _vic);
};