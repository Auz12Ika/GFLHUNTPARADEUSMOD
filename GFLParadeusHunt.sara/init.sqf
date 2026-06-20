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
	
	// Fungsi server: mengisi ulang papan kontrak dengan 5 misi acak
		MERC_fnc_rerollMission = {
			private _pool = missionNamespace getVariable ["MERC_mission_contract_pool", []];
			if (count _pool == 0) exitWith { diag_log "ERROR: MERC_mission_contract_pool kosong!"; };

			private _indices = [];
			for "_i" from 0 to (count _pool - 1) do { _indices pushBack _i; };
			_indices = _indices call BIS_fnc_arrayShuffle;

			private _numToShow = 5 min (count _pool);
			private _newMissions = [];
			for "_i" from 0 to (_numToShow - 1) do {
				_newMissions pushBack (_pool select (_indices select _i));
			};

			missionNamespace setVariable ["MERC_active_missions", _newMissions, true];
			diag_log format ["MERC BOARD: %1 misi baru di-roll ke papan.", count _newMissions];
		};
		
		// Fungsi penyelesaian misi (dipanggil via remoteExec dari sub-misi)
		MERC_fnc_missionSuccess = {
			params ["_type", "_target"];

			// 1. Kosongkan kontrak aktif agar pemain bisa ambil misi baru
			missionNamespace setVariable ["MERC_active_running_contract", [], true];

			// 2. Tandai kontrak selesai agar self-destruct bekerja
			//    (variabel ini sudah dipantau oleh waitUntil di self-destruct)
			//    Tidak perlu action tambahan.

			// 3. Opsional: Beri notifikasi server
			diag_log format ["MERC SUCCESS: Misi tipe '%1' selesai. Target: %2", _type, _target];
			};
			
		// Fungsi penyelesaian misi (dipanggil via remoteExec dari sub-misi)
		MERC_fnc_missionSuccess = {
		params ["_type", "_target", "_giver", "_reward", "_repReward"];

		// 1. Kosongkan kontrak aktif agar pemain bisa ambil misi baru
		missionNamespace setVariable ["MERC_active_running_contract", [], true];

		// 2. Tambah uang ke dana bersama
		if (_reward > 0) then {
			private _currentMoney = missionNamespace getVariable ["merc_money", 0];
			missionNamespace setVariable ["merc_money", _currentMoney + _reward, true];
		};

		// 3. Ubah reputasi faksi
		if (_repReward > 0 && _giver != "") then {
			if (_target == "CULT") then {
				[_giver, _repReward] call MERC_fnc_addReputation;
				if (_giver == "USA") then { ["RUSSIA", _repReward * 0.5] call MERC_fnc_addReputation; }
				else { ["USA", _repReward * 0.5] call MERC_fnc_addReputation; };
			} else {
				[_giver, _repReward] call MERC_fnc_addReputation;
				[_target, -(_repReward * 1.15)] call MERC_fnc_addReputation;
			};
		};

		// 4. Kirim notifikasi sukses ke semua client
		private _msg = format ["MISI SUKSES: Target %1 berhasil diselesaikan!\nReward: $%2 | Reputasi %3: +%4", _target, _reward, _giver, _repReward];
		[_msg] remoteExec ["systemChat", 0];

		// 5. Re-roll papan misi (opsional, bisa juga tidak)
		call MERC_fnc_rerollMission;

		diag_log format ["MERC SUCCESS: Misi tipe '%1' selesai. Target: %2 | Reward: $%3", _type, _target, _reward];
		};

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