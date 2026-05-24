/*
    Author: Modder
    File: fn_initVehicleStore.sqf
    Description: Dealer kendaraan dinamis berdasarkan lokasi (Airbase, Harbor, City).
*/

if (!isServer && hasInterface) exitWith {};

private _locationData = missionNamespace getVariable ["merc_location_data", []];

// --- DAFTAR STOK (WHITELIST) ---
private _civCars = [
    ["C_Offroad_01_F", 1500, "Offroad"],
    ["C_SUV_01_F", 2500, "SUV"],
    ["C_Van_01_transport_F", 4000, "Truck Van"]
];

private _mercenaryArmed = [
    ["B_G_Offroad_01_armed_F", 8000, "Offroad (HMG)"],
    ["I_C_Offroad_02_LMG_F", 9500, "MB 4WD (LMG)"]
];

private _airAssets = [
    ["C_Heli_Light_01_civil_F", 25000, "Hummingbird (Civilian)"],
    ["I_C_Plane_Civil_01_F", 35000, "Caesar BTT (Plane)"],
    ["C_IDAP_Heli_Transport_02_F", 45000, "AW101 Transport"]
];

private _seaAssets = [
    ["C_Boat_Civil_01_F", 5000, "Motorboat"],
    ["C_Rubberboat", 2000, "Rescue Boat"],
    ["I_C_Boat_Transport_02_F", 12000, "RHIB (High Speed)"]
];

{
    _x params ["_pos", "_type", "_name"];
    
    // Tentukan Stok berdasarkan Tipe Lokasi
    private _availableStock = [];
    private _markerIcon = "loc_CarService";
    private _storeName = "Vehicle Store";

    switch (_type) do {
        case "AIRBASE": {
            _availableStock = _airAssets; 
            _markerIcon = "loc_Transmitter";
            _storeName = "Aircraft Dealer";
        };
        case "HARBOR": {
            _availableStock = _civCars + _mercenaryArmed + _seaAssets;
            _markerIcon = "loc_Quay";
            _storeName = "Harbor & Land Export";
        };
        case "CITY": {
            _availableStock = _civCars + _mercenaryArmed;
            _markerIcon = "loc_CarService";
            _storeName = "Local Car Dealer";
        };
    };

    if (count _availableStock > 0) then {
        // 1. Spawn Dealer NPC
        private _dealerGrp = createGroup civilian;
        private _dealer = _dealerGrp createUnit ["C_man_p_beggar_F", _pos, [], 0, "NONE"];
        _dealer setDir (random 360);
        _dealer allowDamage false;
        _dealer disableAI "MOVE";

        // 2. Tambahkan Menu Beli
        {
            _x params ["_vClass", "_vPrice", "_vName"];
            [
                _dealer,
                [
                    format ["<t color='#00FF00'>[BUY] %1 (%2 cr)</t>", _vName, _vPrice], 
                    {
                        params ["_target", "_caller", "_id", "_args"];
                        _args params ["_class", "_price", "_displayName"];

                        private _money = _caller getVariable ["merc_money", 0];
                        if (_money >= _price) then {
                            // Cari posisi spawn (Air/Sea/Land)
                            private _spawnPos = [];
                            if (_class isKindOf "Ship") then {
                                _spawnPos = [getPos _target, 10, 150, 5, 2, 0, 0] call BIS_fnc_findSafePos; // Cari air
                            } else {
                                _spawnPos = (getPos _target) findEmptyPosition [5, 50, _class]; // Cari darat/runway
                            };

                            if (count _spawnPos > 0) then {
                                _caller setVariable ["merc_money", _money - _price, true];
                                private _veh = createVehicle [_class, _spawnPos, [], 0, "NONE"];
                                _veh setDir (getDir _target);
                                hint format ["%1 Berhasil dibeli!", _displayName];
                            } else {
                                hint "Tidak ada ruang aman untuk spawn!";
                            };
                        } else { hint "Uang tidak cukup!"; };
                    },
                    [_vClass, _vPrice, _vName], 1.5, true, true, "", "true", 5
                ]
            ] remoteExec ["addAction", 0, true];
        } forEach _availableStock;

        // 3. Marker Map
        private _m = createMarker [format["vstore_%1", _name], _pos];
        _m setMarkerType _markerIcon;
        _m setMarkerColor "ColorGreen";
        _m setMarkerText _storeName;
    };
} forEach _locationData;