/*
    File: InsurgencyFunction\Missions\fn_serverAcceptContract.sqf
    Description: Master Router Server - Mencari posisi daratan darat secara aman dan memicu sub-misi.
*/

if (!isServer) exitWith {};

params [["_missionData", []], ["_playerCaller", objNull]];
if (count _missionData == 0) exitWith {};

// ============================================================
// KOREKSI INDEKS PARAMS (Sesuai struktur missionData.sqf):
// [0] _id  [1] _title  [2] _difficulty  [3] _timeLimit
// [4] _rewardRange  [5] _repReward  [6] _giver  [7] _target
// [8] _nightOnly    [9] _desc
// ============================================================
_missionData params [
    "_id",
    "_title",
    "_difficulty",
    "_timeLimit",
    "_rewardRange",
    "_repReward",
    "_giver",
    "_target",
    "_nightOnly",
    "_desc"
];

// Hitung reward aktual dari range [Min, Max]
private _reward = (_rewardRange select 0) + round (random ((_rewardRange select 1) - (_rewardRange select 0)));

// ============================================================
// 1. Kunci papan kontrak secara global
// ============================================================
missionNamespace setVariable ["MERC_active_running_contract", _missionData, true];

// ============================================================
// 2. Ambil posisi Mobile HQ
// ============================================================
private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { diag_log "MERC SERVER ERROR: Mobile HQ Object missing!"; };
private _hqPos = getPosATL _hq;

private _spawnPos    = [0,0,0];
private _findAttempts = 0;
private _posFound    = false;

// ============================================================
// 3. Loop pencarian daratan datar (maks 150 percobaan)
// ============================================================
while {!_posFound && _findAttempts < 150} do {
    _findAttempts = _findAttempts + 1;

    private _dist    = (random 3000) + 2000;
    private _dir     = random 360;
    private _testPos = _hqPos getPos [_dist, _dir];

    private _flatPos = _testPos isFlatEmpty [
        6,      // Radius bersih wajib
        0,      // Daratan kering saja
        5,      // Radius deteksi objek statis
        0,      // Mode daratan
        true,  // Bukan tepi pantai
        objNull
    ];

    if (count _flatPos > 0) then {
        private _testY = _flatPos select 1;

        // Filter regional: USA di utara, RUSSIA di selatan (Y=10240 = batas tengah Sahrani)
        switch (_target) do {
            case "USA":    { if (_testY > 10240) then { _spawnPos = _flatPos; _posFound = true; }; };
            case "RUSSIA": { if (_testY < 10240) then { _spawnPos = _flatPos; _posFound = true; }; };
            default        { _spawnPos = _flatPos; _posFound = true; }; // CULT & MERC_ENEMY bebas
        };
    };
};

// ============================================================
// 4. Proteksi: batalkan jika daratan tidak ditemukan
// ============================================================
if (_spawnPos isEqualTo [0,0,0]) exitWith {
    missionNamespace setVariable ["MERC_active_running_contract", [], true];
    ["Gagal menemukan koordinat taktis yang aman di sektor faksi target. Hubungi Command HQ atau pindahkan Mobile HQ."] remoteExec ["hint", _playerCaller];
    diag_log "MERC SERVER CRITICAL: Spawn aborted! No flat land found within 2-5 KM radius.";
};

// ============================================================
// LOLOS: POSISI VALID TERKONFIRMASI
// ============================================================

// 5. Buat Marker area misi di peta
private _markerName    = format ["MERC_Marker_%1", tickTime];
private _missionMarker = createMarker [_markerName, _spawnPos];
_missionMarker setMarkerShape "ELLIPSE";
_missionMarker setMarkerSize [200, 200];
_missionMarker setMarkerColor "ColorRed";
_missionMarker setMarkerBrush "Border";

// 6. Kirim Task Jurnal ke semua client
[_target, _id, _title, _difficulty, _reward, _repReward, _spawnPos, _markerName] remoteExec ["MERC_fnc_ClientCreateTask", 0, true];

// ============================================================
// 7. HITUNG _aiCount — SATU TITIK UNTUK SEMUA MISI
// ============================================================
private _minEnemies = 5;
private _maxEnemies = 10;

switch (toUpper _difficulty) do {
    case "EASY":                   { _minEnemies = 5;  _maxEnemies = 10; };
    case "MED"; case "MEDIUM":     { _minEnemies = 10; _maxEnemies = 15; };
    case "HARD":                   { _minEnemies = 18; _maxEnemies = 25; };
    default                        { _minEnemies = 10; _maxEnemies = 15; };
};

private _aiCount = floor (random [_minEnemies, (_minEnemies + _maxEnemies) / 2, _maxEnemies]);

diag_log format ["MERC SERVER: Difficulty=%1 | aiCount=%2 | Reward=$%3", _difficulty, _aiCount, _reward];

// ============================================================
// 8. DISPATCH KE SUB-MISI — SEKALI SAJA
// ============================================================
private _categoryScript = "";
if (_id find "kill"      >= 0) then { _categoryScript = "HVT.sqf"; };
if (_id find "convoy"    >= 0) then { _categoryScript = "Convoy.sqf"; };
if (_id find "barrack"   >= 0) then { _categoryScript = "Barrack.sqf"; };
if (_id find "roadblock" >= 0) then { _categoryScript = "Roadblock.sqf"; };

if (_categoryScript != "") then {
    [_spawnPos, _missionData, _aiCount] execVM format ["InsurgencyFunction\Missions\%1", _categoryScript];
    diag_log format ["MERC SERVER: Spawning [%1] at %2 with %3 guards.", _categoryScript, _spawnPos, _aiCount];
} else {
    diag_log format ["MERC SERVER ERROR: Undefined category for Mission ID: [%1]", _id];
};

// Re-roll misi di papan setelah kontrak diterima
call MERC_fnc_rerollMission;

// ============================================================
// 9. SELF‑DESTRUCT BASE 1 MENIT SETELAH MISI SELESAI
// ============================================================
[_id, _spawnPos] spawn {
    params ["_id", "_spawnPos"];

    // Tunggu sampai kontrak aktif dihapus (pertanda misi selesai/sukses/gagal)
    waitUntil {
        sleep 2;
        private _contract = missionNamespace getVariable ["MERC_active_running_contract", []];
        count _contract == 0  // kontrak kosong = misi sudah berakhir
    };

    // Tunggu 1 menit agar pemain bisa melihat hasil akhir / mengambil loot
    sleep 60;

    // Hapus semua objek bangunan yang disimpan oleh sub‑misi
    private _objs = missionNamespace getVariable [format ["MERC_mission_objects_%1", _id], []];
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach _objs;
    missionNamespace setVariable [format ["MERC_mission_objects_%1", _id], nil, true];

    // Hapus marker yang masih tersisa (prefix MERC_)
    {
        if (markerText _x find "HVT Location" >= 0 || markerText _x find "Search Area" >= 0 ||
            markerText _x find "Barrack AO" >= 0 || markerText _x find "Roadblock Area" >= 0) then {
            deleteMarker _x;
        };
    } forEach allMapMarkers;
};