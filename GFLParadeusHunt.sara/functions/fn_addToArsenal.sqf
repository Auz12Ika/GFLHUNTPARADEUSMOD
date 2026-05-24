/*
    File: fn_addToArsenal.sqf
    Description: Tambah item ke Arsenal HQ dengan threshold 20.
*/

params [["_classname", ""], ["_category", ""]];

if (!isServer || _classname == "") exitWith {};

private _arrayVar = switch (_category) do {
    case "weapon":   { "MERC_arsenal_weapons" };
    case "magazine": { "MERC_arsenal_magazines" };
    case "item":     { "MERC_arsenal_items" };
    case "backpack": { "MERC_arsenal_backpacks" };
    case "uniform":  { "MERC_arsenal_uniforms" };
    case "vest":     { "MERC_arsenal_vests" };
    case "headgear": { "MERC_arsenal_headgear" };
    default          { "" };
};

if (_arrayVar == "") exitWith { diag_log format ["GFL ARSENAL: Kategori salah: %1", _category]; };

// Counter per item
private _counterVar = format ["MERC_counter_%1", _classname];
private _count = missionNamespace getVariable [_counterVar, 0];
_count = _count + 1;
missionNamespace setVariable [_counterVar, _count, true];

// Threshold 20
if (_count >= 20) then {
    private _array = missionNamespace getVariable [_arrayVar, []];
    if (!(_classname in _array)) then {
        _array pushBack _classname;
        missionNamespace setVariable [_arrayVar, _array, true];
        publicVariable _arrayVar;
        systemChat format ["ITEM UNLOCKED: %1 sekarang UNLIMITED!", _classname];
    };
} else {
    systemChat format ["Item disimpan: %1 (%2/20)", _classname, _count];
};

diag_log format ["GFL ARSENAL: %1 ditambahkan, counter %2/20", _classname, _count];