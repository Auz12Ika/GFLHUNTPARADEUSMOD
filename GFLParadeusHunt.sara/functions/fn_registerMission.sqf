/*
    Author: Modder
    File: fn_registerMission.sqf
    Description: Server-side: mendaftarkan misi ke array global dan menjalankan loop monitoring.
    🔧 NEW P4: Memproses misi yang diterima client, memonitor kondisi sukses/gagal.
*/

if (!isServer) exitWith {};

params [
    ["_mission", []],
    ["_missionPos", [0,0,0]],
    ["_markerName", ""],
    ["_player", objNull],
    ["_duration", 1800],
    ["_successState", "KILL_ALL_ENEMIES"],
    ["_failState", "TIME_EXPIRED"]
];

// Inisialisasi array global jika belum ada
if (isNil "merc_activeMissions") then {
    merc_activeMissions = [];
};

// Tambahkan misi ke daftar aktif
private _missionData = [_mission, _missionPos, _markerName, time, _player, _duration, _successState, _failState];
merc_activeMissions pushBack _missionData;
publicVariable "merc_activeMissions";

diag_log format ["MISSION REGISTER: %1 diterima oleh %2.", _mission select 1, name _player];

// Mulai loop monitoring jika belum berjalan
if (isNil "merc_monitorRunning") then {
    merc_monitorRunning = true;
    publicVariable "merc_monitorRunning";
    
    [] spawn {
        while {true} do {
            private _missionsToRemove = [];
            
            {
                _x params ["_msn", "_pos", "_mkr", "_startTime", "_plyr", "_dur", "_sucState", "_failState"];
                
                private _missionID = _msn select 0;
                private _missionName = _msn select 1;
                private _radius = _msn select 12;
                private _elapsed = time - _startTime;
                
                // Cek timer
                if (_elapsed >= _dur) then {
                    // Waktu habis: cek apakah pemain berada di dalam radius
                    if (alive _plyr && {_plyr distance _pos < _radius}) then {
                        // Sukses
                        [_msn, true] remoteExec ["MERC_fnc_finishMission", _plyr];
                        systemChat format ["MISI SELESAI: %1 berhasil!", _missionName];
                    } else {
                        // Gagal karena tidak hadir atau mati
                        [_msn, false] remoteExec ["MERC_fnc_finishMission", _plyr];
                        systemChat format ["MISI GAGAL: %1 tidak diselesaikan tepat waktu.", _missionName];
                    };
                    
                    // Hapus marker
                    deleteMarker _mkr;
                    _missionsToRemove pushBack _x;
                };
                
                // 🔧 TODO: Implementasi pengecekan kondisi sukses/gagal nyata (KILL_ALL_ENEMIES, CAPTURE_AREA, dll.)
                // Saat ini menggunakan timer + kehadiran sebagai mekanik dasar.
                
            } forEach merc_activeMissions;
            
            // Hapus misi yang sudah selesai dari array
            merc_activeMissions = merc_activeMissions - _missionsToRemove;
            publicVariable "merc_activeMissions";
            
            // Hapus flag jika tidak ada misi tersisa (opsional)
            if (count merc_activeMissions == 0) then {
                merc_monitorRunning = nil;
                publicVariable "merc_monitorRunning";
            };
            
            sleep 10; // Cek setiap 10 detik
        };
    };
};