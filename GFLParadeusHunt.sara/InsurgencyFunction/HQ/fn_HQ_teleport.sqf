/*
    File: fn_HQ_teleport.sqf
    Description: Sistem Teleportasi HQ (Terkunci Global)
*/
if !("ItemMap" in (assignedItems player)) then { player linkItem "ItemMap"; };

params [["_hqVeh", objNull]];
if (isNull _hqVeh) exitWith {};

_hqVeh addAction [
    "<t color='#FF0000'>[TELEPORT] Relocate HQ (One Time)</t>",
    {
        if (missionNamespace getVariable ["MERC_teleport_used", false]) exitWith { 
            hint "Teleportasi sudah digunakan! Tunggu HQ baru."; 
        };

        openMap [true, true];
        hint "Klik pada peta untuk memindahkan Mobile HQ.";
        
        onMapSingleClick {
            onMapSingleClick "";
            private _clickPos = _pos; 
            
            if (surfaceIsWater _clickPos) exitWith {
                hint "Gagal: Lokasi berada di atas air.";
                openMap [false, false];
            };
            
            private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
            if (!isNull _hq) then {
                missionNamespace setVariable ["MERC_teleport_used", true, true];
                
                _hq setPosATL _clickPos;
                "respawn_guerrila" setMarkerPos _clickPos;
                missionNamespace setVariable ["merc_hq_position", _clickPos, true];
                
                { 
                    if (alive _x && isPlayer _x) then { 
                        _x setPosATL (_clickPos getPos [random 10, random 360]); 
                    };
                } forEach allPlayers;
                
                hint "Relokasi Sukses!";
            };
            openMap [false, false];
        };
    },
    nil, 1, true, true, "", 
    "(_target getVariable ['isDeployed', false]) && !(missionNamespace getVariable ['MERC_teleport_used', false])", 
    15
];