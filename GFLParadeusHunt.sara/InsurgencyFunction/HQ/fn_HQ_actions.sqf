/*
    File: InsurgencyFunction\HQ\fn_HQ_actions.sqf
    Description: Semua aksi pelayanan di HQ (Terpusat)
*/
params [["_hqVeh", objNull]];
if (isNull _hqVeh) exitWith {};

// 1. [MISSION] Contracts
_hqVeh addAction [
    "<t color='#FFFFFF'>[MISSION] Contracts</t>", 
    { [] call MERC_fnc_processMissionBoard; }, 
    nil, 5, true, true, "", 
    "(_target getVariable ['isDeployed', false]) && (_this distance _target < 10)", 
    10
];

// 2. [HIRE] Recruit Personnel (BAGIAN YANG TERPOTONG SEBELUMNYA SUDAH DIPERBAIKI)
_hqVeh addAction [
    "<t color='#FF8C00'>[HIRE] Recruit Personnel</t>", 
    { createDialog "MERC_SquadHireDialog"; }, 
    nil, 4, true, true, "", 
    "(_target getVariable ['isDeployed', false]) && (_this distance _target < 10)", 
    10
];

// 3. [DATABASE] Save Progress
_hqVeh addAction [
    "<t color='#00FF00'>[DATABASE] Save Progress</t>", 
    {
        params ["_target", "_caller"];
        [] remoteExec ["MERC_fnc_playerSave", _caller];
        if (isServer) then { saveProfileNamespace; };
        hint "Progress Saved.";
    }, 
    nil, 1.5, true, true, "", 
    "(_target getVariable ['isDeployed', false]) && (_this distance _target < 10)", 
    10
];

// 4. [INTEL] Operation Status
_hqVeh addAction [
    "<t color='#E3E3E3'>[INTEL] Operation Status</t>", 
    {
		private _money = missionNamespace getVariable ["merc_money", 0];
        private _cultCount = missionNamespace getVariable ["cult_hq_destroyed_count", 0];
        // 🛠️ Mengambil data reputasi dari missionNamespace (ganti "merc_reputation" jika nama variabel di config-mu berbeda)
        private _reputation = missionNamespace getVariable ["merc_reputation", 0]; 

        // Menampilkan status lengkap beserta reputasi di slot %3
        hint parseText format ["<t size='1.2' color='#DAA520'>MERC STATUS</t><br/>Money: $%1<br/>Cult HQ Destroyed: %2 / 7<br/>Reputation: %3", _money, _cultCount, _reputation];
    }, 
    nil, 1.4, true, true, "", 
    "(_target getVariable ['isDeployed', false]) && (_this distance _target < 10)", 
    10
];