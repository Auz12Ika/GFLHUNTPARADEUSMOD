/*
    File: fn_openArsenalHQ.sqf
    Description: Buka Arsenal HQ dengan whitelist GFL2 + Vanilla + SMA.
                 🔧 FINAL: Mode Open dengan objek kargo HQ, bukan boolean true.
*/

if (!hasInterface) exitWith {};

private _hq = missionNamespace getVariable ["MERC_Player_HQ", objNull];
if (isNull _hq) exitWith { hint "HQ not found."; };

// Pastikan data arsenal sudah termuat
if (isNil "MERC_arsenal_weapons" || {count MERC_arsenal_weapons == 0}) exitWith {
    hint "Arsenal data not loaded yet. Please wait.";
};

// Gabungkan uniform, vest, headgear ke dalam items
private _allItems = MERC_arsenal_items + MERC_arsenal_uniforms + MERC_arsenal_vests + MERC_arsenal_headgear;

// Hapus kargo virtual HQ dulu (pakai sintaks aman)
_hq call BIS_fnc_clearVirtualCargo;

// Isi ulang kargo virtual HQ dengan data GFL2 + Vanilla + SMA
[_hq, MERC_arsenal_weapons, false, true] call BIS_fnc_addVirtualWeaponCargo;
[_hq, MERC_arsenal_magazines, false, true] call BIS_fnc_addVirtualMagazineCargo;
[_hq, _allItems, false, true] call BIS_fnc_addVirtualItemCargo;
[_hq, MERC_arsenal_backpacks, false, true] call BIS_fnc_addVirtualBackpackCargo;

// Buka Arsenal dengan objek kargo HQ (agar isi kargo muncul)
["Open", _hq] call BIS_fnc_arsenal;

hint "Arsenal HQ accessed. Equipment ready.";