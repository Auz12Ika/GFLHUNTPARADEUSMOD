/*
    File: fn_baseBuilderMenu.sqf
    Description: Tampilkan menu pilihan kategori Base Builder.
*/

if (!hasInterface) exitWith {};

// Cek uang minimal
private _money = player getVariable ["merc_money", 0];
if (_money < 100) exitWith { hint "You need at least $100 to build."; };

// Tampilkan kategori
private _text = "<t size='1.3' color='#00FFAA'>BASE BUILDER</t><br/><br/>";
{
    _text = _text + format ["[%1] %2<br/>", _forEachIndex + 1, _x];
} forEach MERC_baseBuilder_categories;
_text = _text + "<br/><t color='#FFFF00'>Pilih kategori (ketik angka di console)</t>";

hint parseText _text;
systemChat "BASE BUILDER: Pilih kategori - 1:Bunker 2:Tower 3:Building 4:H-Wall 5:Sandbags 6:Turret 7:Mortar";

// Simpan pilihan untuk diproses nanti
player setVariable ["MERC_baseBuilder_category", nil, false];