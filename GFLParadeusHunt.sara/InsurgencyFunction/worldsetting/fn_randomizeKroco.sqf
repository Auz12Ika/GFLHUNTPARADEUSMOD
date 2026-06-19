/*
    Author: Modder
    Description: Mengacak senjata kroco berdasarkan spesialisasi kelasnya.
                 Menjamin senjata Boss tidak akan tersentuh jika mengandung keyword tertentu.
*/
TAG_fnc_randomizeKroco = {
    params ["_unit"];
    if (isNull _unit || {!alive _unit}) exitWith {};

    // Ambil nama kelas unit dan paksa jadi huruf kecil semua agar akurat saat dicocokkan
    private _classLower = toLower (typeOf _unit);

    // 🛑 PROTEKSI BOSS: Jika kelas mengandung kata kunci di bawah, JANGAN ACAK (Gunakan Loadout Eden)
    if ((_classLower find "captain") != -1 || (_classLower find "boss") != -1 || (_classLower find "leader") != -1) exitWith {
        diag_log format ["MERC SYSTEM: Melompati acak senjata untuk unit BOSS (%1)", typeOf _unit];
    };

    // =====================================================
    // 📦 POOL SENJATA RANDOM (Silakan sesuaikan classname mod kamu di sini)
    // =====================================================
    private _poolRifle = ["rhs_weap_ak74m", "rhs_weap_m4a1_carryhandle", "CUP_arifle_AK74", "CUP_arifle_M4A1"];
    private _poolMG    = ["rhs_weap_pkm", "rhs_weap_m249_pip_L", "CUP_lmg_PKM", "CUP_lmg_m249"];
    private _poolAT    = ["rhs_weap_rpg7", "CUP_launch_RPG7V"];

    // =====================================================
    // 🔍 DETEKSI KELAS OTOMATIS (Class-Based Matching)
    // =====================================================
    private _isMG = (_classLower find "machinegunner") != -1 || (_classLower find "mg") != -1 || (_classLower find "blaster") != -1;
    private _isAT = (_classLower find "rpg") != -1 || (_classLower find "at") != -1 || (_classLower find "aa") != -1 || (secondaryWeapon _unit != "");

    // Hapus total senjata utama bawaan beserta isinya agar tidak menumpuk di inventory
    private _oldPrimary = primaryWeapon _unit;
    if (_oldPrimary != "") then { _unit removeWeapon _oldPrimary; };

    private _chosenWeapon = "";

    // ⚔️ Eksekusi Pengacakan Senjata Utama
    if (_isMG) then {
        _chosenWeapon = selectRandom _poolMG; // Masuk kelas Heavy/Machine Gunner
    } else {
		_chosenWeapon = selectRandom _poolRifle;
    };

    // Suntik Senjata Utama Baru + Amunisi Otomatis dari Config Engine
    if (_chosenWeapon != "") then {
        private _mags = getArray (configFile >> "CfgWeapons" >> _chosenWeapon >> "magazines");
        if (count _mags > 0) then {
            private _mag = _mags select 0;
            for "_i" from 1 to 5 do { _unit addMagazine _mag; }; // Beri 5 Magazin cadangan
        };
        _unit addWeapon _chosenWeapon;
    };

    // 🚀 Eksekusi Pengacakan Senjata Sekunder (Khusus Kelas AT / Anti-Tank)
    if (_isAT) then {
        private _oldLauncher = secondaryWeapon _unit;
        if (_oldLauncher != "") then { _unit removeWeapon _oldLauncher; };
        
        private _chosenLauncher = selectRandom _poolAT;
        if (_chosenLauncher != "") then {
            private _launcherMags = getArray (configFile >> "CfgWeapons" >> _chosenLauncher >> "magazines");
            if (count _launcherMags > 0) then {
                private _lMag = _launcherMags select 0;
                for "_i" from 1 to 2 do { _unit addMagazine _lMag; }; // Beri 2 Roket cadangan
            };
            _unit addWeapon _chosenLauncher;
        };
    };
    
    // Perintahkan AI untuk langsung memegang senjata barunya
    _unit selectWeapon (primaryWeapon _unit);
};