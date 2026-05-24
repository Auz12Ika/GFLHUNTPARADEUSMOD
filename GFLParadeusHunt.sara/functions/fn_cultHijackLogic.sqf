/*
    Author: Modder
    File: fn_cultHijackLogic.sqf
    Description: Logika Cult untuk infiltrasi pangkalan kecil.
    🔧 FIX P11: Sekarang benar-benar spawn unit Cult di lokasi yang diinfiltrasi,
               mengubah kepemilikan, marker, dan memberi notifikasi pemain.
*/

if (!isServer) exitWith {};

private _locationData = missionNamespace getVariable ["merc_location_data", []];
if (count _locationData == 0) exitWith { diag_log "CULT HIJACK: Tidak ada data lokasi."; };

{
    _x params ["_pos", "_type", "_name"];

    // Hanya pangkalan kecil (bukan MAIN_BASE agar tidak terlalu mengganggu)
    if (_type in ["BASE", "AIRBASE", "FACTORY", "RADIO", "HARBOR", "CITY"]) then {

        // Peluang 20% infiltrasi
        if (random 100 < 20) then {

            // 1. Ubah kepemilikan menjadi CULT
            private _ownerVar = format ["owner_%1", _name];
            missionNamespace setVariable [_ownerVar, "CULT", true];

            // 2. Update marker
            private _mName = format ["mark_%1", _name];
            if (markerType _mName != "") then {
                _mName setMarkerColor "ColorGreen"; // Hijau warna Cult
                _mName setMarkerText format ["%1 [CULT INFESTED]", _name];
            };

            // 3. Spawn 1 grup Cult kecil di lokasi
            private _unitPool = if (!isNil "MERC_factions_CULT") then { MERC_factions_CULT } else { ["I_Soldier_F", "I_Soldier_LAT_F"] };
            private _grp = createGroup [east, true];
            private _spawnPos = [_pos, 5, 40, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
            if (count _spawnPos == 0) then { _spawnPos = _pos; };

            for "_i" from 1 to (4 + floor random 4) do {
                private _u = _grp createUnit [selectRandom _unitPool, _spawnPos, [], 10, "NONE"];
                _u setSkill 0.4;
            };
            [_grp, _pos, 100] call BIS_fnc_taskPatrol;
            _grp setBehaviour "COMBAT";
            _grp setVariable ["GFL_Remnant", true, true]; // Tidak dihapus oleh despawn

            // 4. Notifikasi ke pemain terdekat
            {
                if (_x distance _pos < 2000) then {
                    ["TaskAssigned", ["", format ["Infiltrasi Cult terdeteksi di %1!", _name]]] remoteExec ["BIS_fnc_showNotification", _x];
                };
            } forEach allPlayers;

            diag_log format ["WORLD EVENT: %1 telah jatuh ke tangan Cult melalui infiltrasi.", _name];
        };
    };
} forEach _locationData;