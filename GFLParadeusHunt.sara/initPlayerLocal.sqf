/*
    File: initPlayerLocal.sqf
    Description: Player Universal Action Handler, Client Shop System, 
                 Auto-Pickup Synchronization & Guardian Menu Loop.
*/

if (!hasInterface) exitWith {};

// Menunggu sampai player sepenuhnya siap masuk ke dalam game map
waitUntil {!isNull player && player == player};

// ========================================================================
// SECTION 1. PLAYER INITIALIZATION & FACTION ALIGNMENT
// ========================================================================
player linkItem "ItemMap";
player linkItem "ItemCompass";
player linkItem "ItemWatch";

if (side player != resistance) then {
    [player] joinSilent createGroup resistance;
};

// ========================================================================
// SECTION 2. DATA PRE-LOAD & DATABASE SYNCHRONIZATION
// ========================================================================
if (isNil "MERC_baseBuilder_objects") then {
    call compile preprocessFileLineNumbers "data\baseBuilderData.sqf";
};
if (isNil "MERC_squadHire_manifests") then {
    call compile preprocessFileLineNumbers "data\squadHireData.sqf";
};

if (isNil "MERC_vehicle_shop_list") then {
    call compile preprocessFileLineNumbers "data\vehicleShopData.sqf";
};

// Loop muat data profile saat pertama kali masuk server
[] spawn {
    waitUntil { !isNull player && alive player };
    waitUntil { !isNull (missionNamespace getVariable ["MERC_Player_HQ", objNull]) };
    sleep 3; 
    private _lastUsedSlot = profileNamespace getVariable ["MERC_last_used_slot", 1];
    [_lastUsedSlot] call MERC_fnc_playerLoad;

    if (!(player getVariable ["MERC_initialSpawn_done", false])) then {
        player setVariable ["MERC_initialSpawn_done", true, true];
        systemChat "Menyelaraskan posisi ke Command Post...";
        sleep 1;
        player setDamage 1;
        forceRespawn player;
    };
};

// Loop otomatis untuk memberikan scroll-action pada bangunan pangkalan
[] spawn {
    waitUntil { sleep 2; !isNil "MERC_base_objects" };
    while {true} do {
        {
            /* PERBAIKAN KRITIKAL: Loop background akan melewati (skip) objek yang 
                sedang dipegang player agar menu [LIFT]/[SELL] tidak tumpang tindih.
            */
            if (alive _x && {count (actionIDs _x) == 0} && {_x != (player getVariable ["MERC_held_object", objNull])}) then {
                [_x] call MERC_fnc_initObjectActions;
            };
        } forEach (missionNamespace getVariable ["MERC_base_objects", []]);
        sleep 5; 
    };
};

// Inisialisasi papan kontrak pertama kali (client-side)
if (isNil "MERC_active_missions" || {count MERC_active_missions == 0}) then {
    [] remoteExec ["MERC_fnc_rerollMission", 2];
};

// ========================================================================
// SECTION 3. BASE BUILDER SHOP SYSTEMS (UI & LOGIC)
// ========================================================================
MERC_fnc_openShop = {
    createDialog "MERC_GenericShopDialog";
    private _display = uiNamespace getVariable ["MERC_Shop_Dlg", displayNull];
    if (isNull _display) exitWith {};

    private _listCtrl = _display displayCtrl 8001;
    private _moneyCtrl = _display displayCtrl 8005;

    private _currentMoney = missionNamespace getVariable ["merc_money", 0];
    _moneyCtrl ctrlSetStructuredText parseText format ["<t size='1.4' valign='middle' color='#FFFFFF'>Contract Funds: <t color='#00FF00'>$%1</t></t>", _currentMoney];

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
    private _picCtrl = _display displayCtrl 8006;
    private _descCtrl = _display displayCtrl 8003;
    private _buyBtn = _display displayCtrl 8004;
    
    private _class = _listCtrl lbData _index;
    private _price = _listCtrl lbValue _index;
    private _category = _listCtrl lbTooltip _index;
    private _name = _listCtrl lbText _index;
    private _currentMoney = missionNamespace getVariable ["merc_money", 0];

    private _imagePath = getText (configFile >> "CfgVehicles" >> _class >> "editorPreview");
    if (_imagePath == "") then { _imagePath = getText (configFile >> "CfgVehicles" >> _class >> "picture"); };
    if (_imagePath == "" || _imagePath == "pictureStatic" || _imagePath == "pictureThing") then {
        _imagePath = format ["\A3\EditorPreviews_F\Data\CfgVehicles\%1.jpg", _class];
    };
    if (_imagePath != "" && {(_imagePath select [0, 1]) != "\"}) then { _imagePath = "\" + _imagePath; };
    _picCtrl ctrlSetText _imagePath; 

    _descCtrl ctrlSetStructuredText parseText format [
        "<t size='2.2' color='#DAA520' weight='bold'>%1</t><br/>" +
        "<t size='1.7' color='#A9A9A9'>Category: %2</t><br/>" +
        "<t size='1.4' color='#808080'>Classname: %3</t><br/><br/>" +
        "<t size='2.0' color='#FFD700'>Construction Cost: $%4</t><br/><br/>" +
        "<t size='1.5' color='#FFFFFF'>Structure will automatically enter dynamic placement mode upon acquisition.</t>",
        _name, _category, _class, _price
    ];

    if (_currentMoney >= _price) then {
        _buyBtn ctrlSetBackgroundColor [0, 0.45, 0, 1];
    } else {
        _buyBtn ctrlSetBackgroundColor [0.55, 0, 0, 1];
    };
};

MERC_fnc_onShopBuyPressed = {
    private _display = uiNamespace getVariable ["MERC_Shop_Dlg", displayNull];
    if (isNull _display) exitWith {};
    
    private _listCtrl = _display displayCtrl 8001;
    private _index = lbCurSel _listCtrl;

    if (_index == -1) exitWith { hint "Pilih struktur bangunan terlebih dahulu!"; };

    private _class = _listCtrl lbData _index;
    private _price = _listCtrl lbValue _index;
    private _currentMoney = missionNamespace getVariable ["merc_money", 0];

    if (_currentMoney < _price) exitWith { hint "Konstruksi Gagal: Dana Kontrak Anda tidak mencukupi!"; };

    // 1. Ambil objek Mobile HQ yang sudah terdaftar di sistem
    private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
    if (isNull _hq) exitWith { hint "Konstruksi Gagal: Mobile HQ tidak ditemukan atau belum di-deploy!"; };

    // 2. Hitung koordinat 18 meter tepat di sebelah kiri HQ (-18 pada sumbu X)
    private _spawnPos = _hq modelToWorld [-18, 0, 0]; 
    _spawnPos set [2, 0]; // Pastikan posisi menempel sempurna di atas permukaan tanah (ATL)
    
    // Samakan rotasi bangunan dengan arah hadap HQ agar rapi
    private _dir = getDir _hq;

    // 3. Kirim perintah beli ke server (SISTEM AUTO-ANGKAT & LOOP WAITUNTIL DIHAPUS TOTAL)
    [_class, _price, _spawnPos, _dir, player] remoteExec ["MERC_fnc_ServerBuyObject", 2];

    closeDialog 0;
    hint "Struktur berhasil dibeli! Bangunan muncul 18 meter di sebelah kiri Mobile HQ. Silakan gunakan menu scroll [LIFT] secara manual untuk memindahkannya.";
};

// ========================================================================
// SECTION 3B. SQUAD HIRE RECRUITMENT SYSTEMS (UI & LOGIC)
// ========================================================================
MERC_fnc_openHireMenu = {
    createDialog "MERC_SquadHireDialog";
    private _display = uiNamespace getVariable ["MERC_Hire_Dlg", displayNull];
    if (isNull _display) exitWith {};

    private _listCtrl = _display displayCtrl 9001;
    private _skillCtrl = _display displayCtrl 9002;
    private _moneyCtrl = _display displayCtrl 9005;

    private _currentMoney = missionNamespace getVariable ["merc_money", 0];
    _moneyCtrl ctrlSetStructuredText parseText format ["<t size='1.4' valign='middle' color='#FFFFFF'>Total Balance: <t color='#00FF00'>$%1</t></t>", _currentMoney];

    // Isi daftar squad
    lbClear _listCtrl;
    {
        _x params ["_name", "_baseCost", "_units", "_vic", "_desc"];
        private _idx = _listCtrl lbAdd _name;
        _listCtrl lbSetValue [_idx, _baseCost];
        _listCtrl lbSetData [_idx, str(_forEachIndex)];
    } forEach MERC_squadHire_manifests;

    // Isi daftar skill
    lbClear _skillCtrl;
    {
        _x params ["_tierName", "_multiplier", "_skillValue", "_tierDesc"];
        private _idx = _skillCtrl lbAdd _tierName;
        _skillCtrl lbSetData [_idx, str([_multiplier, _skillValue])];
    } forEach MERC_squadHire_skillTiers;
    _skillCtrl lbSetCurSel 2; // Default ke VETERAN
};

MERC_fnc_onHireSelectionChanged = {
    [] call MERC_fnc_updateHireUI;
};

MERC_fnc_updateHireUI = {
    private _display = uiNamespace getVariable ["MERC_Hire_Dlg", displayNull];
    if (isNull _display) exitWith {};

    private _listCtrl = _display displayCtrl 9001;
    private _skillCtrl = _display displayCtrl 9002;
    private _descCtrl = _display displayCtrl 9003;
    private _buyBtn = _display displayCtrl 9006;

    private _idx = lbCurSel _listCtrl;
    private _skillIdx = lbCurSel _skillCtrl;
    if (_idx == -1 || _skillIdx == -1) exitWith {};

    // Ambil data squad
    private _dataIdx = parseNumber(_listCtrl lbData _idx);
    (MERC_squadHire_manifests select _dataIdx) params ["_name", "_baseCost", "_units", "_weapons", "_vicClass", "_desc"];

    // Ambil data skill
    private _skillData = call compile (_skillCtrl lbData _skillIdx);
    _skillData params ["_multiplier", "_skillValue"];
    private _tierName = _skillCtrl lbText _skillIdx;
    private _tierDesc = (MERC_squadHire_skillTiers select _skillIdx) select 3;

    private _finalCost = round (_baseCost * _multiplier);
    private _currentMoney = missionNamespace getVariable ["merc_money", 0];

    _descCtrl ctrlSetStructuredText parseText format [
        "<t size='1.8' color='#DAA520' weight='bold'>%1</t><br/>" +
        "<t size='1.5' color='#FFD700'>Deployment Cost: $%2</t><br/>" +
        "<t size='1.1' color='#808080'>Support Asset: %3</t><br/>" +
        "<t size='1.1' color='#808080'>Skill Level: %4 (Multiplier: x%5)</t><br/><br/>" +
        "<t size='1.25' color='#EAEAEA'>%6</t><br/><br/>" +
        "<t size='1.1' color='#A9A9A9'>%7</t>",
        _name, _finalCost, _vicClass, _tierName, _multiplier, _desc, _tierDesc
    ];

    if (_currentMoney >= _finalCost) then {
        _buyBtn ctrlSetBackgroundColor [0, 0.45, 0, 1];
    } else {
        _buyBtn ctrlSetBackgroundColor [0.55, 0, 0, 1];
    };
};

MERC_fnc_onHireBuyPressed = {
    private _display = uiNamespace getVariable ["MERC_Hire_Dlg", displayNull];
    if (isNull _display) exitWith {};

    private _listCtrl = _display displayCtrl 9001;
    private _skillCtrl = _display displayCtrl 9002;

    private _idx = lbCurSel _listCtrl;
    private _skillIdx = lbCurSel _skillCtrl;
    if (_idx == -1 || _skillIdx == -1) exitWith { hint "Select a squad and skill level first!"; };

    // Ambil data squad
    private _dataIdx = parseNumber(_listCtrl lbData _idx);
    (MERC_squadHire_manifests select _dataIdx) params ["_name", "_baseCost", "_units", "_weapons", "_vicClass", "_desc"];

    // Ambil data skill
    private _skillData = call compile (_skillCtrl lbData _skillIdx);
    _skillData params ["_multiplier", "_skillValue"];

    private _finalCost = round (_baseCost * _multiplier);

    private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
    if (isNull _hq) exitWith { hint "Deployment Failed: Mobile HQ not operational!"; };

    private _spawnPos = _hq modelToWorld [15, 0, 0]; _spawnPos set [2, 0];

   [_units, _weapons, _vicClass, _finalCost, _skillValue, _spawnPos, player] remoteExec ["MERC_fnc_ServerHireSquad", 2];
    closeDialog 0;
};
// ========================================================================
// SECTION 3C. DYNAMIC AUTOMATED VEHICLE VENDOR DETECTION (NPC_Vehicle_%1)
// ========================================================================
[] spawn {
    // Menunggu sampai player benar-benar masuk dan hidup di map
    waitUntil { !isNull player && alive player };
    sleep 3.5; // Jeda singkat setelah load arsenal agar prosesnya lancar

    // Melakukan loop pencarian dari nomor indeks 1 sampai 20
    for "_i" from 1 to 20 do {
        // Menjahit string menjadi "NPC_Vehicle_1", "NPC_Vehicle_2", dst.
        private _npcVarName = format ["NPC_Vehicle_%1", _i];
        
        // Mengambil objek asli di map yang memegang nama variabel tersebut
        private _npc = missionNamespace getVariable [_npcVarName, objNull];
        
        // Jika NPC kendaraan ditemukan secara fisik di dunia game, eksekusi setup
        if (!isNull _npc) then {
            
            // 1. Otomatis kunci pergerakan AI agar diam di dekat Pad
            _npc disableAI "PATH"; 
            
            // 2. Suntikkan menu belanja dengan MELEMPARKAN angka indeks (_i) sebagai argumen
            _npc addAction [
                "<t color='#00FFFF' scale='1.1' weight='bold'>Open Vehicle Shop</t>", 
                {
                    params ["_target", "_caller", "_actionId", "_customArgs"];
                    // _customArgs di bawah ini menangkap nilai _i (angka indeks toko)
                    private _storeIndex = _customArgs; 
                    
                    // Rekam angka indeks toko yang sedang dibuka ke memori lokal player
                    missionNamespace setVariable ["MERC_ActiveStoreIndex", _storeIndex];
                    
                    // Panggil fungsi UI Toko Kendaraan bawaan Anda
                    if (!isNil "MERC_fnc_openVehicleShop") then {
                        call MERC_fnc_openVehicleShop;
                    } else {
                        hint "Sistem Error: Fungsi MERC_fnc_openVehicleShop tidak ditemukan!";
                    };
                }, 
                _i, // Menyuntikkan angka _i dari loop saat ini ke parameter _customArgs di atas
                1.5, 
                true, 
                true, 
                "", 
                "alive _target && _this distance _target < 4" // Jarak interaksi roda mouse 4 meter
            ];
        };
    };
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

    // 1. Ambil nomor indeks toko aktif yang direkam saat player mengklik menu scroll wheel
    private _storeIndex = missionNamespace getVariable ["MERC_ActiveStoreIndex", 0];
    if (_storeIndex == 0) exitWith { hint "Connection Error: Active store index lost!"; };

    // 2. LOGIKA JAHIT: Rangkai nama variabel Pad target secara dinamis berdasarkan tipe & nomor indeks
    private _padVarName = if (_type == "AIR") then { format ["Pad_Air_%1", _storeIndex] } else { format ["Pad_Land_%1", _storeIndex] };
    
    // 3. Ambil objek fisik Pad dari map menggunakan nama hasil jahitan
    private _targetPad = missionNamespace getVariable [_padVarName, objNull];

    // Validasi jika Anda lupa menaruh atau salah menamai objek Pad di Editor
    if (isNull _targetPad) exitWith { 
        hint format ["Deployment Failed: Target penanda '%1' tidak ditemukan di map!", _padVarName]; 
    };

    private _spawnPos = getPosATL _targetPad;
    private _spawnDir = getDir _targetPad;

    // 4. Validasi rintangan di area spawn pad agar tidak bertumpuk/meledak
    if (count (nearestObjects [_spawnPos, ["AllVehicles"], 6]) > 0) exitWith {
        hint "Deployment Blocked: Clear the designated sign pad area first!";
    };

    // 5. Kirim order data koordinat matang ke fungsi server yang sudah stand-by di init.sqf Anda
    [_class, _price, _spawnPos, _spawnDir, player] remoteExec ["MERC_fnc_ServerBuyVehicle", 2];
    closeDialog 0;
};

// ========================================================================
// SECTION 3D. DYNAMIC AUTOMATED ARSENAL VENDOR DETECTION (NPC_Arsenal_%1)
// ========================================================================
[] spawn {
    // Menunggu sampai player benar-benar masuk dan hidup di map
    waitUntil { !isNull player && alive player };
    sleep 3; // Jeda singkat agar seluruh objek hasil copas di editor selesai dimuat

    // Melakukan loop pencarian dari angka 1 sampai 20 (bisa Anda naikkan batasan angkanya jika butuh lebih)
    for "_i" from 1 to 20 do {
        // Menjahit string menjadi "NPC_Arsenal_1", "NPC_Arsenal_2", dst.
        private _npcVarName = format ["NPC_Arsenal_%1", _i];
        
        // Mengambil objek asli yang memegang nama variabel tersebut di map
        private _npc = missionNamespace getVariable [_npcVarName, objNull];
        
        // Jika NPC tersebut ditemukan secara fisik di dunia game, eksekusi setup
        if (!isNull _npc) then {
            
            // 1. Otomatis kunci pergerakan AI agar tidak keluyuran (Sistem Auto-Kunci)
            _npc disableAI "PATH"; 
            
            // 2. Suntikkan menu interaksi belanja Arsenal langsung dari sisi Client
            _npc addAction [
                "<t color='#00FF00' scale='1.1' weight='bold'>Open Arsenal ($5000)</t>", 
                {
                    params ["_target", "_caller"];
                    
                    // Cek uang kelompok instan di client pembeli
                    private _money = missionNamespace getVariable ["merc_money", 0];
                    if (_money < 5000) exitWith { 
                        hint "Uang tidak cukup! Kelompok Anda memerlukan $5000 untuk membuka Arsenal."; 
                    };
                    
                    hint "Memverifikasi dana dengan HQ...";
                    
                    // Lempar perintah potong uang & buka senjata ke server
                    [5000, _caller] remoteExec ["MERC_fnc_ServerPayArsenal", 2];
                }, 
                nil, 
                1.5, 
                true, 
                true, 
                "", 
                "alive _target && _this distance _target < 4" // Jarak deteksi roda mouse 4 meter
            ];
        };
    };
};

// ========================================================================
// SECTION 4. OBJECT EDITOR ACTION GENERATORS
// ========================================================================
MERC_fnc_initObjectActions = {
    params [["_obj", objNull]];
    if (isNull _obj) exitWith {};
    removeAllActions _obj;

    private _name = getText (configFile >> "CfgVehicles" >> typeOf _obj >> "displayName");

    _obj addAction [format ["<t color='#00E5FF'>[LIFT] Re-align %1</t>", _name], {
        private _target = _this select 0;
        ["START_PICKUP", [_target]] call MERC_fnc_objectEditor;
    }, nil, 6, true, true, "", "_this distance _target < 12"];

    _obj addAction [format ["<t color='#FF3B30'>[DISMANTLE] Sell %1 (50%% Refund)</t>", _name], {
        private _target = _this select 0;
        ["SELL", [_target, 0.50]] call MERC_fnc_objectEditor;
    }, nil, 5, true, true, "", "_this distance _target < 12"];
};

MERC_fnc_setupEditorActions = {
    player setVariable ["MERC_editor_action_ids", [
        player addAction ["<t color='#00FF00'>[CONSTRUCTION] -> PLACE ON GROUND</t>", { ["PLACE", [true]] call MERC_fnc_objectEditor; }, nil, 25],
        player addAction ["<t color='#FFFF00'>[CONSTRUCTION] -> PLACE FLOATING</t>", { ["PLACE", [false]] call MERC_fnc_objectEditor; }, nil, 24],
        player addAction ["    └ Raise Structure (+Z)", { ["MANIPULATE", ["UP"]] call MERC_fnc_objectEditor; }, nil, 23],
        player addAction ["    └ Lower Structure (-Z)", { ["MANIPULATE", ["DOWN"]] call MERC_fnc_objectEditor; }, nil, 22],
        player addAction ["    └ Move Forward (+Y)", { ["MANIPULATE", ["FRONT"]] call MERC_fnc_objectEditor; }, nil, 21],
        player addAction ["    └ Move Backward (-Y)", { ["MANIPULATE", ["BACK"]] call MERC_fnc_objectEditor; }, nil, 20],
        player addAction ["    ↺ Rotate Left 15° (Yaw CCW)", { ["MANIPULATE", ["CCW"]] call MERC_fnc_objectEditor; }, nil, 19],
        player addAction ["    ↻ Rotate Right 15° (Yaw CW)", { ["MANIPULATE", ["CW"]] call MERC_fnc_objectEditor; }, nil, 18],
        player addAction ["    ▲ Pitch Up 15°", { ["MANIPULATE", ["P_UP"]] call MERC_fnc_objectEditor; }, nil, 17],
        player addAction ["    ▼ Pitch Down 15°", { ["MANIPULATE", ["P_DN"]] call MERC_fnc_objectEditor; }, nil, 16],
        player addAction ["    🗘 Reset Adjustments", { ["MANIPULATE", ["RESET"]] call MERC_fnc_objectEditor; }, nil, 15]
    ]];
};

MERC_fnc_clearEditorActions = {
    private _ids = player getVariable ["MERC_editor_action_ids", []];
    { player removeAction _x; } forEach _ids;
    player setVariable ["MERC_editor_action_ids", []];
};

MERC_fnc_secureRestore = {
    params ["_slot"];
    hint format ["Loading Archive Slot %1...\nSynchronizing world space...", _slot];
    [_slot] call MERC_fnc_playerLoad;
    sleep 1;
    private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
    if (!isNull _hq && {alive _hq}) then {
        private _safePos = _hq getPos [random 8, random 360];
        player setPosATL _safePos;
        hint format ["Slot %1 Restored Successfully!\nPersonnel relocated to new Command Post coordinates.", _slot];
    } else {
        hint "Restore Warning: Archive loaded, but Command Post object could not be verified.";
    };
};

// ========================================================================
// SECTION 5. MAIN HQ COMMAND TERMINAL INTERACTIONS
// ========================================================================
MERC_fnc_attachHqActions = {
    params [["_unit", objNull]];
    if (isNull _unit) exitWith {};
    removeAllActions _unit;

    private _condBase = "private _hq = missionNamespace getVariable ['MERC_Player_HQ', objNull]; !isNull _hq && {alive _hq} && {_target distance _hq < 8}";
    private _condDeployed = _condBase + " && {_hq getVariable ['isDeployed', false]}";

    _unit addAction ["<t color='#00FF00'>[HQ] TOGGLE COMMAND POST</t>", { call HQ_fnc_HQ_deploy; }, nil, 20, true, true, "", _condBase];
    _unit addAction ["<t color='#4287f5'>[ARMORY] Access Arsenal</t>", { call compile preprocessFileLineNumbers "InsurgencyFunction\HQ\fn_HQ_ArsenalHQ.sqf"; }, nil, 19, true, true, "", _condDeployed];
    
	_unit addAction [
		"<t color='#FFFF00'>[LOGISTICS] Rearm Nearby Vehicles</t>",
		{
			private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
			if (isNull _hq) exitWith { hint "Error: Mobile HQ tidak ditemukan."; };

			// Mendeteksi seluruh kendaraan darat, udara, dan laut dalam radius 50m dari HQ
			private _nearVehicles = nearestObjects [_hq, ["LandVehicle", "Air", "Ship"], 50];

			// 🔧 JANGAN keluarkan HQ dari list — kita ingin mengisinya juga!
			// Baris ini dihapus: _nearVehicles = _nearVehicles - [_hq];

			if (count _nearVehicles == 0) exitWith {
				hint "Rearm Gagal: Tidak ada kendaraan operasional terpantau dalam jarak 50 meter dari HQ.";
			};

			// Loop pengisian amunisi kendaraan
			private _rearmedCount = 0;
			{
				if (alive _x) then {
					_x setVehicleAmmo 1; // Mengisi penuh seluruh magasen senjata kendaraan
					_rearmedCount = _rearmedCount + 1;
				};
			} forEach _nearVehicles;

			hint format ["Logistics Success: Berhasil mengisi ulang amunisi untuk %1 kendaraan di sekitar HQ!", _rearmedCount];
		},
		nil, 15.45, true, true, "",
		_condDeployed
	];
	
    _unit addAction [
        "<t color='#FF8C00'>[TACTICAL] Relocate Mobile HQ (One-Time)</t>",
        {
            if (missionNamespace getVariable ["MERC_teleport_used", false]) exitWith { hint "Deployment Lockout: Strategic relocation already exhausted."; };
            openMap [true, true];
            hint "Left-click on the map matrix coordinates to re-deploy Mobile HQ.";
            onMapSingleClick {
                onMapSingleClick "";
                private _clickPos = _pos; 
                if (surfaceIsWater _clickPos) exitWith {
                    hint "Relocation Aborted: Command Post cannot deploy in maritime sectors.";
                    openMap [false, false];
                };
                private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
                if (!isNull _hq) then {
                    _hq setPosATL _clickPos;
                    "respawn_guerrila" setMarkerPos _clickPos;
                    missionNamespace setVariable ["MERC_teleport_used", true, true];
                    { if (alive _x) then { _x setPosATL (_clickPos getPos [random 10, random 360]); }; } forEach allPlayers;
                    hint "Mobile HQ and combat deployment units successfully re-routed!";
                };
                openMap [false, false];
            };
        },
        nil, 18, true, true, "",
        _condDeployed + " && {!(missionNamespace getVariable ['MERC_teleport_used', false])}"
    ];

    _unit addAction ["<t color='#FFFFFF'>[MISSIONS] Operations Board</t>", { [] call MERC_fnc_openContractBoard; }, nil, 17, true, true, "", _condDeployed];
    _unit addAction ["<t color='#FF8C00'>[LOGISTICS] Recruit Private Personnel</t>", { [] call MERC_fnc_openHireMenu; }, nil, 16, true, true, "", _condDeployed];
    _unit addAction ["<t color='#00E5FF'>[CONSTRUCTION] Purchase Infrastructure Structures</t>", { [] call MERC_fnc_openShop; }, nil, 15.5, true, true, "", _condDeployed];

    // Sub-Menu Database
    _unit addAction ["<t color='#00FF00'>[DATABASE] == SAVE PROGRESS TO PROFILE ==</t>", { hint "Pilih sub-slot di bawah untuk menyimpan."; }, nil, 15.4, false, true, "", _condDeployed];
    _unit addAction ["    └ Commit Save -> Data Slot 1", { [1] call MERC_fnc_playerSave; }, nil, 15.3, true, true, "", _condDeployed];
    _unit addAction ["    └ Commit Save -> Data Slot 2", { [2] call MERC_fnc_playerSave; }, nil, 15.2, true, true, "", _condDeployed];
    _unit addAction ["    └ Commit Save -> Data Slot 3", { [3] call MERC_fnc_playerSave; }, nil, 15.1, true, true, "", _condDeployed];

    _unit addAction ["<t color='#00FFFF'>[DATABASE] == RESTORE DATA FROM PROFILE ==</t>", { hint "Pilih sub-slot di bawah untuk memuat arsip."; }, nil, 15.0, false, true, "", _condDeployed];
    _unit addAction ["    └ Initialize Restore <- Data Slot 1", { [1] spawn MERC_fnc_secureRestore; }, nil, 14.9, true, true, "", _condDeployed];
    _unit addAction ["    └ Initialize Restore <- Data Slot 2", { [2] spawn MERC_fnc_secureRestore; }, nil, 14.8, true, true, "", _condDeployed];
    _unit addAction ["    └ Initialize Restore <- Data Slot 3", { [3] spawn MERC_fnc_secureRestore; }, nil, 14.7, true, true, "", _condDeployed];

    _unit addAction ["<t color='#FF0000'>[DATABASE] == CLEAR ARCHIVE / WIPE PROGRESS ==</t>", { hint "Pilih sub-slot di bawah untuk menghapus data."; }, nil, 14.6, false, true, "", _condDeployed];
    _unit addAction ["    └ Wipe Profile Records -> Slot 1 (New Game)", { [1] spawn MERC_fnc_playerNewGame; }, nil, 14.5, true, true, "", _condDeployed];
    _unit addAction ["    └ Wipe Profile Records -> Slot 2 (New Game)", { [2] spawn MERC_fnc_playerNewGame; }, nil, 14.4, true, true, "", _condDeployed];
    _unit addAction ["    └ Wipe Profile Records -> Slot 3 (New Game)", { [3] spawn MERC_fnc_playerNewGame; }, nil, 14.3, true, true, "", _condDeployed];

    _unit addAction [
        "<t color='#E3E3E3'>[INTEL] Strategic Status Overview</t>",
        {
            private _money = missionNamespace getVariable ["merc_money", 0];
            private _cultCount = missionNamespace getVariable ["cult_hq_destroyed_count", 0];
            private _repUS = missionNamespace getVariable ["us_reputation", 0];
            private _repRU = missionNamespace getVariable ["ru_reputation", 0];

            hint parseText format [
                "<t size='1.2' color='#DAA520'>MERC STATUS</t><br/>Money: $%1<br/>Cult HQ Destroyed: %2 / 7<br/><t color='#4C6EF5'>Reputation US:</t> %3<br/><t color='#FA5252'>Reputation RU:</t> %4", 
                _money, 
                _cultCount, 
                _repUS, 
                _repRU
            ];       
        },
        nil, 14, true, true, "",
        _condDeployed
    ];

    _unit addAction ["Configure Timeline Options>", { player setVariable ["MERC_showTimeMenu", !(player getVariable ["MERC_showTimeMenu", false])]; }, nil, 13, false, true, "", _condDeployed];
    private _hours = [1, 2, 3, 4, 6, 8, 12, 24, 48, 72];
    {
        private _jam = _x;
        _unit addAction [
            format ["    └ Skip Timeline forward by %1 Hours", _jam],
            {
                params ["_target", "_caller", "_id", "_args"];
                [_args] remoteExec ["MERC_fnc_ServerTimeSkip", 2];
                player setVariable ["MERC_showTimeMenu", false];
            },
            _jam, 12, true, true, "",
            _condDeployed + " && {player getVariable ['MERC_showTimeMenu', false]}"
        ];
    } forEach _hours;
};

// ========================================================================
// SECTION 6. RESPONDERS & LIFE CYCLE CONTROLLERS
// ========================================================================
[player] call MERC_fnc_attachHqActions;

player addEventHandler ["Respawn", {
    params ["_unit"];
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
    _unit linkItem "ItemWatch";
    [_unit] call MERC_fnc_attachHqActions;
}];

if (!isNil "GFL_Base_Teleport") then {
    GFL_Base_Teleport addAction [
        "<t color='#00FFFF'>[TELEPORT] Fast Travel to Mobile HQ Command Unit</t>",
        {
            private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
            if (!isNull _hq && {alive _hq}) then {
                player moveInAny _hq;
                hint "Translocation Successful.";
            } else {
                hint "Linkage Interrupted: Mobile HQ satellite tracking coordinates lost or unit destroyed.";
            };
        },
        nil, 6, true, true, "",
        "private _hq = missionNamespace getVariable ['MERC_Player_HQ', objNull]; !isNull _hq && {alive _hq}"
    ];
};


// ========================================================================
// SECTION 7. STRATEGIC CONTRACT BOARD SYSTEMS (UI & CLIENT LOGIC)
// ========================================================================

MERC_fnc_openContractBoard = {
    // Cek kontrak berjalan
    private _runningContract = missionNamespace getVariable ["MERC_active_running_contract", []];
    if (count _runningContract > 0) exitWith {
        hint "Ditolak: Selesaikan atau batalkan operasi yang aktif saat ini sebelum mengambil kontrak baru!";
    };

    // Buka dialog
    createDialog "MERC_ContractBoard_Dialog";
    private _display = findDisplay 47400;
    if (isNull _display) exitWith {};

    // Ambil kontrol
    private _listBox = _display displayCtrl 47410;
    private _descCtrl = _display displayCtrl 47412;
    private _acceptBtn = _display displayCtrl 47420;

    // Bersihkan listbox
    lbClear _listBox;

    // Ambil daftar misi yang sudah di-roll server
    private _activeMissions = missionNamespace getVariable ["MERC_active_missions", []];
    if (count _activeMissions == 0) exitWith { hint "Error: Tidak ada kontrak tersedia saat ini."; };

    // Tampilkan semua misi
    for "_i" from 0 to (count _activeMissions - 1) do {
        private _data = _activeMissions select _i;
        _data params ["_id", "_title", "_diff"];
        private _lbIndex = _listBox lbAdd format ["[%1] %2", toUpper _diff, _title];
        _listBox lbSetData [_lbIndex, str _i];  // simpan indeks lokal (0..4)
    };

    // Event: Pilihan berubah → tampilkan briefing + reward
    _listBox ctrlAddEventHandler ["LBSelChanged", {
        params ["_control", "_selIndex"];
        if (_selIndex < 0) exitWith {};

        private _localIndex = parseNumber (_control lbData _selIndex);
        private _activeMissions = missionNamespace getVariable ["MERC_active_missions", []];
        if (_localIndex < 0 || _localIndex >= count _activeMissions) exitWith {};

        private _data = _activeMissions select _localIndex;

        // Generate teks briefing
        private _fullText = [_data] call MISI_fnc_generateMissionDesc;

        // Tampilkan di panel deskripsi
        private _descCtrl = (findDisplay 47400) displayCtrl 47412;
        _descCtrl ctrlSetStructuredText parseText _fullText;
    }];

    // Event: Tombol Accept → kirim ke server
    _acceptBtn ctrlAddEventHandler ["ButtonClick", {
        private _selIndex = lbCurSel ((findDisplay 47400) displayCtrl 47410);
        if (_selIndex < 0) exitWith { hint "Pilih misi dulu!"; };

        private _localIndex = parseNumber (((findDisplay 47400) displayCtrl 47410) lbData _selIndex);
        private _activeMissions = missionNamespace getVariable ["MERC_active_missions", []];
        if (_localIndex < 0 || _localIndex >= count _activeMissions) exitWith { hint "Data misi tidak valid!"; };

        private _missionData = _activeMissions select _localIndex;

        // Kirim ke server
        [_missionData, player] remoteExec ["MISI_fnc_serverAcceptContract", 2];

        // Tutup dialog
        (findDisplay 47400) closeDisplay 0;
    }];
};

// Fungsi pembuatan task jurnal (dipanggil dari server via remoteExec)
MERC_fnc_ClientCreateTask = {
    params ["_target", "_id", "_title", "_difficulty", "_reward", "_repReward", "_spawnPos", "_markerName"];

    // Buat task dengan BIS_fnc_taskCreate
    private _taskID = format ["MERC_%1", _id];
    [
        side player,               // Faksi penerima task (mengikuti faksi pemain)
        [_taskID],                 // ID task unik
        [format ["%1 (%2)", _title, toUpper _difficulty], _title, _markerName], // Nama & marker
        _spawnPos,                 // Posisi yang ditunjuk task
        "CREATED",                 // Status awal
        5,                         // Prioritas
        true,                      // Terlihat di peta
        "attack",                  // Tipe ikon
        true                       // Tampilkan notifikasi
    ] call BIS_fnc_taskCreate;

    systemChat format ["TASK: %1 | Reward: $%2 | Rep: +%3", _title, _reward, _repReward];
};