/*
    File: worldsetting\fn_cultBrain.sqf
    Description: Otak Cult (Anti-Air Bos)
*/
params ["_unit"];
if (isNull _unit || !alive _unit) exitWith {};


_unit setBehaviour "COMBAT";
_unit setCombatMode "YELLOW";
_unit setSpeedMode "NORMAL";

// 1. DAFTAR UNIT CULT (WHITELIST)
private _cultPool = missionNamespace getVariable ["MERC_factions_CULT", []];
private _cultBosses = ["Niter_boss"];
private _whiteList = _cultPool + _cultBosses;


// ========================================================================
// 1. SELALU MUSUH DENGAN PLAYER (Anti-Reputasi)
// ========================================================================
_unit setBehaviour "COMBAT";
_unit setCombatMode "RED";
_unit setSpeedMode "NORMAL";

// 1. Logika Khusus Bos Niter (80% Akurasi, dengan Reinforcement)
if (typeOf _unit == "Niter_boss") then {
    [_unit] spawn {
        params ["_boss"];
        while {alive _boss} do {
            private _airTargets = _boss nearEntities [["Air"], 1500];
            private _validAir = _airTargets select {alive _x && !(_x isKindOf "ParachuteBase") && (getPosATL _x select 2) > 20};
            
            if (count _validAir > 0) then {
                private _target = _validAir select 0;
                (group _boss) reveal [_target, 4];
                _boss doTarget _target;
                
                // Skill Niter
                _boss setSkill ["aimingAccuracy", 0.85]; 
                _boss setSkill ["aimingShake", 0.3];
                _boss setSkill ["aimingSpeed", 0.8];
                
                _boss forceWeaponFire [currentWeapon _boss, "FullAuto"];
            };
            sleep 1.5;
        };
    };
};

// 2. Logika Khusus Bos Sextans (95% Akurasi, Fokus Anti-Air Mematikan)
if (typeOf _unit == "Sextans_boss") then {
    [_unit] spawn {
        params ["_boss"];
        while {alive _boss} do {
            // Sextans punya radar lebih jauh (2500m)
            private _airTargets = _boss nearEntities [["Air"], 2500];
            private _validAir = _airTargets select {alive _x && !(_x isKindOf "ParachuteBase") && (getPosATL _x select 2) > 20};
            
            if (count _validAir > 0) then {
                private _target = _validAir select 0;
                (group _boss) reveal [_target, 4];
                _boss doTarget _target;
                
                // Skill Sextans (Lebih mematikan)
                _boss setSkill ["aimingAccuracy", 0.95];
                _boss setSkill ["aimingShake", 0.6]; // Shake lebih rendah = makin stabil
                _boss setSkill ["aimingSpeed", 1.0]; // Reaksi lebih cepat
                
                _boss forceWeaponFire [currentWeapon _boss, "FullAuto"];
            };
            sleep 1.0; // Sextans memproses target lebih cepat (setiap 1 detik)
        };
    };
};