/*
    File: Mission\fn_cultBrain.sqf
    Description: Otak Cult (Spawner Goliath untuk Niter + Olin & Anti-Air untuk Sextans)
*/
params ["_unit"];
if (isNull _unit || !alive _unit) exitWith {};

_unit addEventHandler ["HandleDamage", {
    params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];
    
    // Jika sumber damage null, abaikan
    if (isNull _source) exitWith { 0 };
    
    // Cek apakah sumber damage adalah player atau kendaraan player
    private _isPlayer = false;
    if (isPlayer _source) then {
        _isPlayer = true;
    } else {
        // Cek apakah sumber adalah kendaraan yang dikendarai player
        if (_source isKindOf "LandVehicle" || _source isKindOf "Air" || _source isKindOf "Ship") then {
            private _crew = crew _source;
            { if (isPlayer _x) exitWith { _isPlayer = true; }; } forEach _crew;
        };
        // Cek instigator (sering dipakai untuk damage dari kendaraan)
        if (!isNull _instigator && isPlayer _instigator) then {
            _isPlayer = true;
        };
    };
    
    // Jika bukan player, damage diabaikan (0)
    if (!_isPlayer) exitWith { 0 };
    
    // Damage dari player: biarkan normal
    _damage
}];

// ========================================================================
// 1. DAFTAR UNIT CULT (WHITELIST)
// ========================================================================
private _cultPool = missionNamespace getVariable ["MERC_factions_CULT", []];
private _cultBosses = ["Niter_boss"];
private _whiteList = _cultPool + _cultBosses;

// ========================================================================
// 2. LOGIKA KHUSUS BOS NITER (SPAWN GOLIATH – TANPA ANTI-AIR)
// ========================================================================
if (typeOf _unit == "Niter_boss") then {
    [_unit] spawn {
        params ["_boss"];
        private _goliathSpawned = false;
        while {alive _boss} do {
            // Cek teman di radius 50m (kecuali diri sendiri)
            private _nearFriendly = (units (group _boss)) select {
                alive _x && _x != _boss && (_x distance _boss) < 50
            };
            if (count _nearFriendly == 0 && !_goliathSpawned) then {
                // Spawn 4 Goliath (random HE/AT)
                private _goliathClasses = ["GFL_Goliath_AT", "GFL_Goliath_HE"]; // <-- ganti dengan classname sebenarnya
                for "_i" from 1 to 4 do {
                    private _gClass = selectRandom _goliathClasses;
                    private _pos = _boss getPos [5 + random 10, random 360];
                    private _goliath = createVehicle [_gClass, _pos, [], 0, "NONE"];
                    _goliath setDir random 360;
                    _goliath setVariable ["MERC_is_mission_target", true, true];
                    _goliath addRating 10000;
                    // Cari musuh terdekat (player)
                    private _enemy = _boss findNearestEnemy _boss;
                    if (!isNil "_enemy" && !isNull _enemy) then {
                        _goliath move (getPos _enemy);
                        _goliath doTarget _enemy;
                    };
                };
                _goliathSpawned = true;
            };
            if (!alive _boss) exitWith {};
            sleep 10;
        };
    };
};

// ========================================================================
// 3. LOGIKA KHUSUS BOS SEXTANS (SPAWN OLIN T-HEAT + ANTI-AIR)
// ========================================================================
if (typeOf _unit == "Sextans_boss") then {
    // --- SPAWNER OLIN T-HEAT KE INVENTORY ---
    [_unit] spawn {
        params ["_boss"];
        private _ammoClass = "Olin_T_HEAT"; // ganti dengan classname sebenarnya
        while {alive _boss} do {
            private _mags = magazines _boss;
            private _currentCount = {_x == _ammoClass} count _mags;
            private _maxMags = 20;
            if (_currentCount < _maxMags) then {
                _boss addMagazine _ammoClass;
            };
            sleep 30; // setiap 30 detik
        };
    };

    // --- ANTI-AIR SEXTANS (dengan filter side) ---
    [_unit] spawn {
        params ["_boss"];
        while {alive _boss} do {
            private _airTargets = _boss nearEntities [["Air"], 2500];
            private _validAir = _airTargets select {
                alive _x &&
                !(_x isKindOf "ParachuteBase") &&
                (getPosATL _x select 2) > 20 &&
                side _x != side _boss   // <-- FILTER: JANGAN SERANG TEMAN
            };
            if (count _validAir > 0) then {
                private _target = _validAir select 0;
                (group _boss) reveal [_target, 4];
                _boss doTarget _target;
                _boss setSkill ["aimingAccuracy", 0.95];
                _boss setSkill ["aimingShake", 0.6];
                _boss setSkill ["aimingSpeed", 1.0];
                _boss forceWeaponFire [currentWeapon _boss, "FullAuto"];
            };
            sleep 1.0;
        };
    };
};