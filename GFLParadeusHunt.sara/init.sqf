/*
    File: init.sqf
    Description: Master Mission Init (Base Builder + Vehicle Store System + Squad Hire + Sector Manager)
*/

// ========================================================================
// A. LOAD DATA (Berjalan di Server & Client)
// ========================================================================
call compile preprocessFileLineNumbers "data\factions.sqf";
call compile preprocessFileLineNumbers "data\reputation_config.sqf";

//Memuat katalog base object
if (isNil "MERC_baseBuilder_objects") then {
    call compile preprocessFileLineNumbers "data\baseBuilderData.sqf";
};
// Memuat katalog Hire
if (isNil "MERC_squadHire_manifests") then {
    call compile preprocessFileLineNumbers "data\squadHireData.sqf";
};
// Memuat katalog manifes kendaraan baru Anda
if (isNil "MERC_vehicle_shop_list") then {
    call compile preprocessFileLineNumbers "data\vehicleShopData.sqf";
};
// Memuat database papan kontrak misi
if (isNil "MERC_mission_contract_pool") then {
    call compile preprocessFileLineNumbers "data\missionData.sqf";
};

MERC_fnc_setupStore = compile preprocessFileLineNumbers "data\fn_setupStore.sqf";

// ========================================================================
// B. SERVER AUTHORITIES (Data, Respawn, Purchase, & Spawner)
// ========================================================================
if (isServer) then {
    diag_log "HQ SYSTEM (SERVER): Initializing main systems...";
    
    missionNamespace setVariable ["MERC_HQ_IsDestroyed", false, true];
    missionNamespace setVariable ["MERC_teleport_used", false, true];

    if (isNil {missionNamespace getVariable "merc_money"}) then {
        missionNamespace setVariable ["merc_money", 100000, true]; 
    };
    if (isNil "MERC_base_objects") then {
        missionNamespace setVariable ["MERC_base_objects", [], true];
    };
        
    call compile preprocessFileLineNumbers "InsurgencyFunction\HQ\fn_HQ_arsenalData.sqf";

    // HQ Init Loop Engine
    [] spawn {
        waitUntil { !isNull (missionNamespace getVariable ["MERC_Player_HQ", objNull]) };
        private _hqVeh = missionNamespace getVariable ["MERC_Player_HQ", objNull];
        _hqVeh setVariable ["MERC_HQ_HomePos", getPosATL _hqVeh, true];
        _hqVeh setVariable ["MERC_HQ_HomeDir", getDir _hqVeh, true];

        [_hqVeh] call HQ_fnc_HQ_init;
        [_hqVeh] call HQ_fnc_HQ_destroy;
    };

    // HQ Respawn Engine Loop
    [] spawn {
        while {true} do {
            if (missionNamespace getVariable ["MERC_HQ_IsDestroyed", false]) then {
                missionNamespace setVariable ["MERC_teleport_used", false, true];
                sleep 5;
                private _oldHq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
                private _homePos = missionNamespace getVariable ["MERC_HQ_HomePos", [16850, 17050, 0]];
                private _type = typeOf _oldHq;
                
                if (!isNull _oldHq) then { deleteVehicle _oldHq; };
                private _newHq = createVehicle [_type, _homePos, [], 0, "NONE"];
                _newHq setDir 0; _newHq setPosATL _homePos;
                
                missionNamespace setVariable ["MERC_Player_HQ", _newHq, true];
                missionNamespace setVariable ["merc_hq_position", _homePos, true];
                "respawn_guerrila" setMarkerPos _homePos;
                
                [_newHq] call HQ_fnc_HQplayer; 
                missionNamespace setVariable ["MERC_HQ_IsDestroyed", false, true];
            };
            sleep 2;
        };
    };
	
	MERC_fnc_ServerPayArsenal = {
		params ["_price", "_player"];
		private _currentMoney = missionNamespace getVariable ["merc_money", 0];
		
		// Validasi akhir di sisi server
		if (_currentMoney < _price) exitWith {
			["Akses Gagal: Dana Kontrak Kelompok tidak cukup!"] remoteExec ["hint", _player];
		};
		
		// Potong uang secara global (Sync ke semua player)
		missionNamespace setVariable ["merc_money", _currentMoney - _price, true];
		
		// Buka Virtual Arsenal asli bawaan Arma di PC player yang membeli
		["Open", [true]] remoteExec ["BIS_fnc_arsenal", _player];
		
		// Notifikasi berhasil
		["Akses Arsenal Diberikan! $5000 dipotong dari dana kelompok."] remoteExec ["hint", _player];
	};

    // FNC SERVER: Pembelian Objek Base Builder
    MERC_fnc_ServerBuyObject = {
        params ["_class", "_price", "_spawnPos", "_dir", "_player"];
        private _currentMoney = missionNamespace getVariable ["merc_money", 0];
        if (_currentMoney < _price) exitWith {
            ["Construction Failed: Insufficient funds!"] remoteExec ["hint", _player];
        };
        missionNamespace setVariable ["merc_money", _currentMoney - _price, true];
        
        private _builtObject = createVehicle [_class, _spawnPos, [], 0, "CAN_COLLIDE"];
        _builtObject setDir _dir;
        _builtObject setPosATL _spawnPos;
        _builtObject enableSimulationGlobal true;
        
        private _currentList = +(missionNamespace getVariable ["MERC_base_objects", []]);
        _currentList pushBack _builtObject;
        missionNamespace setVariable ["MERC_base_objects", _currentList, true];
        ["Structure Purchased!"] remoteExec ["hint", _player];
    };

    // FNC SERVER: Real-Time Placement Base Builder
    MERC_fnc_ServerPlaceObject = {
        params ["_obj", "_pos", "_dir"];
        if (isNull _obj) exitWith {};
        _obj setDir _dir;
        _obj setPosATL _pos;
        _obj enableSimulationGlobal true;
        _obj setVelocity [0, 0, 0.1];
        _obj setPosATL _pos;
    };
	
	MERC_fnc_ServerHireSquad = {
        params ["_unitsArray", "_weaponsArray", "_vicClass", "_finalCost", "_skillValue", "_spawnPos", "_player"];
        
        if (typeName _vicClass != "STRING") then { _vicClass = "B_MRAP_01_F"; };
        
        private _currentMoney = missionNamespace getVariable ["merc_money", 0];
        if (_currentMoney < _finalCost) exitWith {
            ["Deployment Failed: Insufficient funds!"] remoteExec ["hint", _player];
        };
        
        missionNamespace setVariable ["merc_money", _currentMoney - _finalCost, true];

        private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
        private _validPos = []; private _attempts = 0;
        
        while {count _validPos == 0 && _attempts < 15} do {
            _attempts = _attempts + 1;
            private _testPos = getPosATL _hq getPos [20 + random 15, random 360];
            _testPos set [2, 0];
            if (!surfaceIsWater _testPos) then { _validPos = _testPos; };
        };
        if (count _validPos == 0) then { _validPos = getPosATL _hq getPos [25, random 360]; _validPos set [2, 0]; };

        private _vic = createVehicle [_vicClass, _validPos, [], 0, "NONE"];
        _vic setDir (random 360); _vic enableSimulationGlobal true;

        // PERBAIKAN KRITIKAL: faksi dikunci ke 'resistance' agar tidak error parameter di server
        private _group = [_validPos, resistance, _unitsArray] call BIS_fnc_spawnGroup;
        sleep 0.5;
        if (!isNull _group) then {
            {
                private _unit = _x; _unit moveInAny _vic; 
                if (count _weaponsArray > _forEachIndex) then {
                    private _loadout = _weaponsArray select _forEachIndex;
                    _loadout params ["_wpn", "_mag", "_launch", "_launchMag"];
                    removeAllWeapons _unit;
                    if (_mag != "" && _wpn != "") then { _unit addMagazines [_mag, 6]; _unit addWeapon _wpn; };
                    if (_launchMag != "" && _launch != "") then { _unit addMagazines [_launchMag, 3]; _unit addWeapon _launch; };
                };
               _unit setSkill _skillValue; // Mengatur skill umum dulu
				_unit setSkill ["aimingAccuracy", (_skillValue * 0.85)]; // Tulis ulang dengan hati-hati
				_unit setSkill ["aimingSpeed", _skillValue];
				_unit setSkill ["courage", 1.0];
            } forEach (units _group);

            [_group, getPosATL _vic, 150] call BIS_fnc_taskPatrol;
        };
        ["Reinforcements Deployed! Squad is inside the vehicle."] remoteExec ["hint", _player];
    };
	
	// FNC SERVER: Spawner Kendaraan
    MERC_fnc_ServerBuyVehicle = {
        params ["_class", "_price", "_type", "_storeIndex", "_player"];
        private _currentMoney = missionNamespace getVariable ["merc_money", 0];
        
        // 1. Validasi Keuangan
        if (_currentMoney < _price) exitWith {
            ["Purchase Failed: Insufficient funds!"] remoteExec ["hint", _player];
        };

        // 2. LOGIKA CARI PAD: Server menjahit nama variabel secara dinamis
        private _padVarName = if (_type == "AIR") then { format ["Pad_Air_%1", _storeIndex] } else { format ["Pad_Land_%1", _storeIndex] };
        private _targetPad = missionNamespace getVariable [_padVarName, objNull];

        // Validasi jika objek Pad belum ditaruh atau salah nama di Editor
        if (isNull _targetPad) exitWith {
            [format ["Deployment Failed: Target penanda '%1' tidak ditemukan!", _padVarName]] remoteExec ["hint", _player];
        };

        private _spawnPos = getPosATL _targetPad;
        private _dir = getDir _targetPad;

        // 3. VALIDASI BLOKADE: Cegah penumpukan kendaraan
        if (count (nearestObjects [_spawnPos, ["AllVehicles"], 6]) > 0) exitWith {
            ["Deployment Blocked: Clear the designated area first!"] remoteExec ["hint", _player];
        };

        // 4. PAKSA DI ATAS TANAH (Anti-Amblas): Naikkan koordinat Z +0.3 meter
        private _adjustedPos = [
            _spawnPos select 0,
            _spawnPos select 1,
            (_spawnPos select 2) + 0.3
        ];

        // Potong dana kelompok jika semua validasi di atas lolos
        missionNamespace setVariable ["merc_money", _currentMoney - _price, true];

        // 5. EKSEKUSI SPAWN: Gunakan "CAN_COLLIDE" agar dipaksa lahir tepat di atas Pad
        private _vic = createVehicle [_class, _adjustedPos, [], 0, "CAN_COLLIDE"];
        _vic setDir _dir;
        _vic setPosATL _adjustedPos; // Kunci ulang posisinya di atas tanah
        _vic enableSimulationGlobal true;

        ["Vehicle Delivered to the designated Sign Pad!"] remoteExec ["hint", _player];
    };
	
   // MERC_fnc_addReputation = {
   //     params [
   //         ["_giver", "", [""]],
   //         ["_target", "", [""]],
   //         ["_posPoin", 0, [0]]
   //     ];
   //
   //     if (_posPoin == 0) exitWith {};
   //
   //     private _negPoin = _posPoin * 1.15;
   //     private _currentUSA = missionNamespace getVariable ["rep_USA", 0];
   //     private _currentRUS = missionNamespace getVariable ["rep_RUSSIA", 0];
   //
   //     if (_target == "CULT") then {
   //         _currentUSA = (_currentUSA + _posPoin) min 100;
   //         _currentRUS = (_currentRUS + _posPoin) min 100;
   //     } else {
   //         if (_giver == "USA" && _target == "RUSSIA") then {
   //             _currentUSA = (_currentUSA + _posPoin) min 100;
   //             _currentRUS = (_currentRUS - _negPoin) max -100;
   //         };
   //         if (_giver == "RUSSIA" && _target == "USA") then {
   //             _currentRUS = (_currentRUS + _posPoin) min 100;
   //             _currentUSA = (_currentUSA - _negPoin) max -100;
   //         };
   //     };
   //
   //     missionNamespace setVariable ["rep_USA", _currentUSA, true];
   //     missionNamespace setVariable ["rep_RUSSIA", _currentRUS, true];
   // };
	//
	//MERC_fnc_generateContracts = {
   //     if (isNil "MERC_mission_contract_pool" || {count MERC_mission_contract_pool == 0}) exitWith {
   //         diag_log "ERROR: MERC_mission_contract_pool kosong atau belum terdefinisi!";
   //     };
   //
   //     private _easyPool = [];
   //     private _medPool  = [];
   //     private _hardPool = [];
   //
   //     // 1. Klasifikasikan misi berdasarkan tingkat kesulitan dari Master Pool
   //     {
   //         private _diff = _x select 2; // Index 2 adalah string DIFFICULTY ("EASY", "MEDIUM", "HARD")
   //         switch (upperCase _diff) do {
   //             case "EASY":   { _easyPool pushBack _x; };
   //             case "MEDIUM": { _medPool pushBack _x; };
   //             case "HARD":   { _hardPool pushBack _x; };
   //             default        { _easyPool pushBack _x; }; // Fallback aman
   //         };
   //     } forEach MERC_mission_contract_pool;
   //
   //     private _selectedMissions = [];
   //
   //     // 2. Ambil secara acak 2 Misi EASY (Menggunakan algoritma Shuffle bawaan BIS)
   //     private _shuffledEasy = _easyPool call BIS_fnc_arrayShuffle;
   //     for "_i" from 0 to 1 do {
   //         if (_i < count _shuffledEasy) then { _selectedMissions pushBack (_shuffledEasy select _i); };
   //     };
   //
   //     // 3. Ambil secara acak 2 Misi MEDIUM
   //     private _shuffledMed = _medPool call BIS_fnc_arrayShuffle;
   //     for "_i" from 0 to 1 do {
   //         if (_i < count _shuffledMed) then { _selectedMissions pushBack (_shuffledMed select _i); };
   //     };
   //
   //     // 4. Ambil secara acak 1 Misi HARD
   //     if (count _hardPool > 0) then {
   //         _selectedMissions pushBack (selectRandom _hardPool);
   //     };
   //
   //     // 5. Broadcast hasilnya ke seluruh Client (Public Variable) agar UI sinkron di semua player
   //     missionNamespace setVariable ["MERC_active_missions", _selectedMissions, true];
   //     diag_log format ["HQ Log: Papan Kontrak diperbarui! %1 misi berhasil di-roll.", count _selectedMissions];
   // };
   //
   //
   // // --- FUNGSI 2: LOOP MONITORING WAKTU SERVER (AUTO-RESET JAM 12 & 24) ---
   // [] spawn {
   //     // Tunggu sampai master pool selesai di-load oleh system (mencegah script berjalan terlalu cepat)
   //     waitUntil { !isNil "MERC_mission_contract_pool" };
   //
   //     // Roll pertama kali saat server baru menyala / restart mission
   //     call MERC_fnc_generateContracts;
   //
   //     // Catat jam in-game saat ini sebagai patokan awal deteksi pergantian jam
   //     private _lastHour = floor daytime;
   //
   //     while {true} do {
   //         private _currentHour = floor daytime; // Mengambil angka bulat jam (0 s/d 23)
   //
   //         // Deteksi jika jarum jam in-game berpindah/ganti jam
   //         if (_currentHour != _lastHour) then {
   //             
   //             // Kondisi: Jika jam menyentuh tepat jam 12 Siang ATAU jam 00:00/24:00 Malam
   //             if (_currentHour == 12 || _currentHour == 0) then {
   //                 
   //                 // Eksekusi pengacakan ulang misi
   //                 call MERC_fnc_generateContracts;
   //
   //                 // Kirim pesan alert estetik ke systemChat seluruh player yang sedang online
   //                 private _alertMsg = if (_currentHour == 12) then {
   //                     "🟢 [HQ BOARD]: Midday rotation complete. New strategic contracts are now available."
   //                 } else {
   //                     "🌙 [HQ BOARD]: Midnight rotation complete. Black-ops and night contracts updated."
   //                 };
   //                 
   //                 [_alertMsg, { systemChat _this; }] remoteExec ["spawn", 0];
   //             };
   //
   //             // Perbarui tracker jam terakhir
   //             _lastHour = _currentHour;
   //         };

            // Loop berjalan ringan setiap 10 detik real-time (Sangat aman untuk performa server)
            sleep 10; 
   //     };
};


// ========================================================================
// C. CLIENT INTERFACE (UI & Interaction Menu Logic)
// ========================================================================
if (hasInterface) then {
    
    // --- 🛒 BASE BUILDER SHOP UI SYSTEM ---
    MERC_fnc_openShop = {
        createDialog "MERC_GenericShopDialog";
        private _display = uiNamespace getVariable ["MERC_Shop_Dlg", displayNull];
        if (isNull _display) exitWith {};
        private _listCtrl = _display displayCtrl 8001;
        private _moneyCtrl = _display displayCtrl 8005;
        _moneyCtrl ctrlSetStructuredText parseText format ["<t size='1.4' valign='middle' color='#FFFFFF'>Total Balance: <t color='#00FF00'>$%1</t></t>", missionNamespace getVariable ["merc_money", 0]];

        lbClear _listCtrl;
        {
            private _categoryIdx = _forEachIndex;
            private _categoryName = MERC_baseBuilder_categories select _categoryIdx;
            {
                _x params ["_class", "_name", "_price"];
                private _index = _listCtrl lbAdd format ["[%1] %2", _categoryName, _name];
                _listCtrl lbSetData [_index, _class];
                _listCtrl lbSetValue [_index, _price];
                _listCtrl lbSetTooltip [_index, _categoryName]; 
            } forEach _x;
        } forEach MERC_baseBuilder_objects;
    };

    MERC_fnc_onShopSelectionChanged = {
        params ["_listCtrl", "_index"];
        private _display = ctrlParent _listCtrl;
        private _descCtrl = _display displayCtrl 8003;
        private _buyBtn = _display displayCtrl 8004;
        
        private _class = _listCtrl lbData _index;
        private _price = _listCtrl lbValue _index;
        private _category = _listCtrl lbTooltip _index;
        private _name = _listCtrl lbText _index;

        private _detailText = switch (_class) do {
            case "Land_BagBunker_Small_F": { "A small, chest-high sandbag bunker designed to accommodate 1-2 personnel." };
            case "Land_BagBunker_Tower_F": { "An elevated fortification tower built from heavy sandbags." };
            default { "Standard military-grade asset. Ready for field deployment." };
        };

        _descCtrl ctrlSetStructuredText parseText format [
            "<t size='2.0' color='#DAA520' weight='bold'>%1</t><br/>" +
            "<t size='1.4' color='#A9A9A9'>Category: %2</t><br/>" +
            "<t size='1.8' color='#FFD700'>Construction Cost: $%3</t><br/><br/>" +
            "<t size='1.35' color='#EAEAEA'>%4</t>", _name, _category, _price, _detailText
        ];
        _buyBtn ctrlSetBackgroundColor (if ((missionNamespace getVariable ["merc_money", 0]) >= _price) then {[0, 0.45, 0, 1]} else {[0.55, 0, 0, 1]});
    };

    MERC_fnc_onShopBuyPressed = {
        private _display = uiNamespace getVariable ["MERC_Shop_Dlg", displayNull];
        private _listCtrl = _display displayCtrl 8001;
        private _index = lbCurSel _listCtrl;
        if (_index == -1) exitWith { hint "Please select a structure first!"; };

        private _class = _listCtrl lbData _index;
        private _price = _listCtrl lbValue _index;
        if ((missionNamespace getVariable ["merc_money", 0]) < _price) exitWith { hint "Insufficient Contract Funds!"; };

        private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
        if (isNull _hq) exitWith { hint "Mobile HQ not found!"; };
        private _spawnPos = _hq modelToWorld [-10, 0, 0]; _spawnPos set [2, 0]; 
        [_class, _price, _spawnPos, getDir _hq, player] remoteExec ["MERC_fnc_ServerBuyObject", 2];
        closeDialog 0;
    };

    // --- 🚘 VEHICLE STORE UI SYSTEM (100% SEIRAMA DENGAN BASE BUILDER) ---
    MERC_fnc_openVehicleShop = {
        createDialog "MERC_VehicleShopDialog";
        private _display = uiNamespace getVariable ["MERC_VehShop_Dlg", displayNull];
        if (isNull _display) exitWith {};
        
        private _listCtrl = _display displayCtrl 8001;
        private _moneyCtrl = _display displayCtrl 8005;
        _moneyCtrl ctrlSetStructuredText parseText format ["<t size='1.4' valign='middle' color='#FFFFFF'>Total Balance: <t color='#00FF00'>$%1</t></t>", missionNamespace getVariable ["merc_money", 0]];

        lbClear _listCtrl;
        {
            _x params ["_class", "_name", "_price", "_type"]; 
            private _index = _listCtrl lbAdd format ["[%1] %2", _type, _name];
            _listCtrl lbSetData [_index, _class];
            _listCtrl lbSetValue [_index, _price];
            _listCtrl lbSetTooltip [_index, _type]; // Simpan tipe LAND/AIR di tooltip 
        } forEach MERC_vehicle_shop_list; 
    };

	MERC_fnc_onVehShopSelectionChanged = {
		params ["_listCtrl", "_index"];
		private _display = ctrlParent _listCtrl;
		private _descCtrl = _display displayCtrl 8003;
		private _buyBtn = _display displayCtrl 8004;
		
		private _class = _listCtrl lbData _index;
		private _price = _listCtrl lbValue _index;
		private _type = _listCtrl lbTooltip _index;
		private _name = _listCtrl lbText _index;

		// 🔧 Ambil deskripsi dari data kendaraan
		private _detailText = "Standard mercenary asset contract.";
		{
			if ((_x select 0) == _class) exitWith {
				_detailText = _x select 4; // indeks 4 = deskripsi
			};
		} forEach MERC_vehicle_shop_list;

		_descCtrl ctrlSetStructuredText parseText format [
			"<t size='2.0' color='#DAA520' weight='bold'>%1</t><br/>" +
			"<t size='1.4' color='#A9A9A9'>Classification: %2</t><br/>" +
			"<t size='1.8' color='#FFD700'>Acquisition Cost: $%3</t><br/><br/>" +
			"<t size='1.35' color='#EAEAEA'>%4</t>", _name, _type, _price, _detailText
		];
		_buyBtn ctrlSetBackgroundColor (if ((missionNamespace getVariable ["merc_money", 0]) >= _price) then {[0, 0.45, 0, 1]} else {[0.55, 0, 0, 1]});
	};
	
   MERC_fnc_onVehShopBuyPressed = {
        private _display = uiNamespace getVariable ["MERC_VehShop_Dlg", displayNull];
        private _listCtrl = _display displayCtrl 8001;
        private _index = lbCurSel _listCtrl;
        if (_index == -1) exitWith { hint "Please select a vehicle first!"; };

        private _class = _listCtrl lbData _index;
        private _price = _listCtrl lbValue _index;
        private _type = _listCtrl lbTooltip _index; // Menangkap data "LAND" atau "AIR"

        if ((missionNamespace getVariable ["merc_money", 0]) < _price) exitWith { hint "Insufficient Contract Funds!"; };

        // Ambil nomor indeks toko aktif yang direkam dari initPlayerLocal.sqf
        private _storeIndex = missionNamespace getVariable ["MERC_ActiveStoreIndex", 0];
        if (_storeIndex == 0) exitWith { hint "Connection Error: Active store index lost!"; };

        // KIRIM ORDER KE SERVER: Kirim _type dan _storeIndex agar dicari langsung oleh Server
        [_class, _price, _type, _storeIndex, player] remoteExec ["MERC_fnc_ServerBuyVehicle", 2];
        closeDialog 0;
    };
};