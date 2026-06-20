/*
    File: fn_HQ_deploy.sqf
    Description: Logika Toggle Deploy / Pack Up Base.
*/
if (!hasInterface) exitWith {};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith {};

// Cek status deploy saat ini
if (_hq getVariable ["isDeployed", false]) then {
    // --- Mode Pack Up ---
    _hq setVariable ["isDeployed", false, true];
    hint "HQ Packed Up! Siap bergerak.";
} else {
    // --- Mode Deploy ---
    if (speed _hq > 2) exitWith { hint "Kendaraan masih bergerak! Berhenti dahulu untuk deploy."; };
    _hq setVariable ["isDeployed", true, true];
    "respawn_guerrila" setMarkerPos (getPosATL _hq);
    _hq engineOn false;
    hint "HQ Deployed! Seluruh sistem online.";
};