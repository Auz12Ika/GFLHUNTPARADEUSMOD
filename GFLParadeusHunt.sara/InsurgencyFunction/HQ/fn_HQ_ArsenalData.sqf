/*
    File: fn_HQ_ArsenalData.sqf
    Description: Sistem Arsenal (Starter Unlimited + Notifikasi Progres Setoran Loot)
*/
if (!isServer) exitWith {};

private _targetThreshold = 20; // Ambang batas senjata baru

if (isNil "MERC_UnlockedWeapons") then { MERC_UnlockedWeapons = []; };
if (isNil "MERC_UnlockedMagazines") then { MERC_UnlockedMagazines = []; };
if (isNil "MERC_UnlockedItems") then { MERC_UnlockedItems = []; };
if (isNil "MERC_UnlockedBackpacks") then { MERC_UnlockedBackpacks = []; };
if (isNil "MERC_ItemStorage") then { MERC_ItemStorage = createHashMap; }; 

// =========================================================================
// 1. MUAT STARTER PACK & JADIKAN UNLIMITED SEJAK AWAL
// =========================================================================
call compile preprocessFileLineNumbers "data\arsenalHQ.sqf";

{ MERC_UnlockedWeapons pushBackUnique _x; } forEach MERC_arsenal_weapons;
{ MERC_UnlockedMagazines pushBackUnique _x; } forEach MERC_arsenal_magazines;
{ MERC_UnlockedBackpacks pushBackUnique _x; } forEach MERC_arsenal_backpacks;
{ MERC_UnlockedItems pushBackUnique _x; } forEach (MERC_arsenal_items + MERC_arsenal_uniforms + MERC_arsenal_vests + MERC_arsenal_headgear);

publicVariable "MERC_UnlockedWeapons";
publicVariable "MERC_UnlockedMagazines";
publicVariable "MERC_UnlockedItems";
publicVariable "MERC_UnlockedBackpacks";

// Pastikan barang starter langsung masuk ke kotak HQ saat server mulai
// [FIXED]: Menambahkan kurung siku kosong sebelum spawn
[] spawn {
    waitUntil { !isNull (missionNamespace getVariable ["MERC_Player_HQ", objNull]) };
    private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
    
    [_hq, MERC_UnlockedWeapons, true] call BIS_fnc_addVirtualWeaponCargo;
    [_hq, MERC_UnlockedMagazines, true] call BIS_fnc_addVirtualMagazineCargo;
    [_hq, MERC_UnlockedItems, true] call BIS_fnc_addVirtualItemCargo;
    [_hq, MERC_UnlockedBackpacks, true] call BIS_fnc_addVirtualBackpackCargo;
};

// =========================================================================
// 2. ENGINE DETEKSI SETORAN BARANG BARU + NOTIFIKASI PROGRES
// =========================================================================
// [FIXED]: Menambahkan kurung siku sebelum spawn dan memasukkan parameter threshold
[_targetThreshold] spawn {
    params ["_limit"];
    
    while {true} do {
        uiSleep 5; // Scan kotak setiap 5 detik
        private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
        
        if (!isNull _hq) then {
            private _isUpdated = false;

            private _weaps = getWeaponCargo _hq;
            private _mags = getMagazineCargo _hq;
            private _items = getItemCargo _hq;
            private _backs = getBackpackCargo _hq;

            // Fungsi proses dengan tambahan ekstraksi Nama Senjata untuk Notifikasi
            private _fnc_processCargo = {
                params ["_cargoData", "_unlockedArray", "_configType"];
                private _classes = _cargoData select 0;
                private _counts = _cargoData select 1;
                
                {
                    private _cls = _x;
                    private _qty = _counts select _forEachIndex;
                    
                    // Cek apakah barang ini BELUM unlimited (barang loot baru)
                    if (!(_cls in _unlockedArray)) then {
                        private _currentQty = MERC_ItemStorage getOrDefault [_cls, 0];
                        _currentQty = _currentQty + _qty;
                        
                        // Tarik nama asli senjata/item dari sistem Arma
                        private _displayName = getText (configFile >> _configType >> _cls >> "displayName");
                        if (_displayName == "") then { _displayName = _cls; }; // Failsafe jika nama tidak terbaca
                        
                        if (_currentQty >= _limit) then {
                            _unlockedArray pushBackUnique _cls;
                            MERC_ItemStorage deleteAt _cls; // Reset hitungan
                            _isUpdated = true;
                            
                            // Notifikasi UNLOCK ke semua player!
                            private _msg = format ["<t color='#00FF00' size='1.2'>ARSENAL UNLOCKED!</t><br/>%1 sekarang tersedia tanpa batas!", _displayName];
                            [_msg] remoteExec ["hint", 0];
                            
                        } else {
                            MERC_ItemStorage set [_cls, _currentQty];
                            
                            // Notifikasi PROGRES SETORAN ke player
                            private _msg = format ["Setoran Diterima:<br/><t color='#FFFF00'>%1</t><br/>Progress: %2 / %3", _displayName, _currentQty, _limit];
                            [_msg] remoteExec ["hint", 0];
                        };
                    };
                } forEach _classes;
            };

            // Jalankan fungsi dengan parameter config yang sesuai
            [_weaps, MERC_UnlockedWeapons, "CfgWeapons"] call _fnc_processCargo;
            [_mags, MERC_UnlockedMagazines, "CfgMagazines"] call _fnc_processCargo;
            [_items, MERC_UnlockedItems, "CfgWeapons"] call _fnc_processCargo;
            [_backs, MERC_UnlockedBackpacks, "CfgVehicles"] call _fnc_processCargo; // Tas ada di CfgVehicles

            // Bersihkan wujud fisik dari kotak agar tidak menggandakan hitungan
            if (count (_weaps select 0) > 0) then { clearWeaponCargoGlobal _hq; };
            if (count (_mags select 0) > 0) then { clearMagazineCargoGlobal _hq; };
            if (count (_items select 0) > 0) then { clearItemCargoGlobal _hq; };
            if (count (_backs select 0) > 0) then { clearBackpackCargoGlobal _hq; };

            // Injeksi barang yang baru di-unlock ke BIS Arsenal
            if (_isUpdated) then {
                publicVariable "MERC_UnlockedWeapons";
                publicVariable "MERC_UnlockedMagazines";
                publicVariable "MERC_UnlockedItems";
                publicVariable "MERC_UnlockedBackpacks";
                
                [_hq, MERC_UnlockedWeapons, true] call BIS_fnc_addVirtualWeaponCargo;
                [_hq, MERC_UnlockedMagazines, true] call BIS_fnc_addVirtualMagazineCargo;
                [_hq, MERC_UnlockedItems, true] call BIS_fnc_addVirtualItemCargo;
                [_hq, MERC_UnlockedBackpacks, true] call BIS_fnc_addVirtualBackpackCargo;
            };
        };
    };
};