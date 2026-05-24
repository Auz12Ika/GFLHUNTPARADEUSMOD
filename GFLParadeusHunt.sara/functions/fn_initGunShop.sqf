/*
    Author: Modder
    File: fn_initGunShop.sqf
    Description: Menempatkan Gun Shop di setiap kota dengan sistem filter senjata.
*/

if (!isServer && hasInterface) exitWith {};

private _locationData = missionNamespace getVariable ["merc_location_data", []];
private _cities = _locationData select { _x select 1 == "CITY" };

{
    _x params ["_pos", "_type", "_name"];

    // 1. Spawn Objek Toko (Meja Senjata)
    private _shopObj = createVehicle ["Land_WoodenTable_large_F", _pos, [], 2, "NONE"];
    _shopObj setDir (random 360);
    _shopObj allowDamage false;

    // Tambahkan dekorasi peti di atasnya
    private _crate = createVehicle ["Box_IND_Wps_F", _pos, [], 0, "CAN_COLLIDE"];
    _crate attachTo [_shopObj, [0, 0, 0.7]];
    
    // 2. Tambahkan Action (AddAction) untuk Pemain
    [
        _shopObj,
        [
            "<t color='#FFD700'>[GUN SHOP] Open Arsenal (Price: 1000)</t>", 
            {
                params ["_target", "_caller"];
                
                // Cek apakah uang cukup (Asumsi variabel uang: merc_money)
                private _money = _caller getVariable ["merc_money", 0];
                
                if (_money >= 1000) then {
                    // Potong Uang
                    _caller setVariable ["merc_money", _money - 1000, true];
                    hint "Akses Arsenal Diberikan. Biaya 1000 telah dipotong.";
                    
                    // JALANKAN ARSENAL DENGAN FILTER
                    [_target, _caller] spawn {
                        params ["_obj", "_unit"];
                        
                        // Setup Filter: Kita hapus semua item RHS dari arsenal sementara
                        private _allWeapons = (configFile >> "CfgWeapons") call BIS_fnc_getCfgSubClasses;
                        private _filteredWeapons = _allWeapons select {
                            private _className = _x;
                            // FILTER: Tidak boleh mengandung prefix RHS (USA/RUS) atau faksi Cult
                            !(_className select [0,3] == "rhs") && 
                            !(_className select [0,3] == "RHS")
                        };

                        // Buka Arsenal
                        ["Open", [true, _obj, _unit]] call BIS_fnc_arsenal;
                        
                        // Batasi akses item (Hanya berikan item non-RHS)
                        [_obj, _filteredWeapons, true] call BIS_fnc_addVirtualWeaponCargo;
                    };
                } else {
                    hint "Uang tidak cukup! Kamu butuh 1000 untuk akses Arsenal.";
                };
            },
            nil, 1.5, true, true, "", "true", 3
        ]
    ] remoteExec ["addAction", 0, true];

    // Marker kecil di Map untuk Toko
    private _m = createMarker [format["shop_%1", _name], _pos];
    _m setMarkerType "loc_Gunsmith";
    _m setMarkerColor "ColorYellow";
    _m setMarkerText "Gun Shop";

} forEach _cities;