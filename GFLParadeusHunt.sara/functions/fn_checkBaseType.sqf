/*
    Author: Modder
    File: fn_checkBaseType.sqf
    Description: Mengecek apakah suatu kendaraan bisa di-spawn di tipe base tertentu.
    🔧 FIX P16 (Revisi Komandan): 
        - Helikopter (termasuk attack) bisa diakses di HQ, AIRBASE, HARBOR.
        - Pesawat hanya di AIRBASE.
        - Kapal hanya di HARBOR.
        - CITY, FACTORY, RADIO hanya mobil/truk.
*/

params [["_baseObject", objNull], ["_vecClassname", ""]];

if (isNull _baseObject || _vecClassname == "") exitWith { false };

private _baseType = _baseObject getVariable ["merc_base_type", "CITY"];
private _isAllowed = false;

// Kategori dasar
private _isAir    = _vecClassname isKindOf "Air";
private _isPlane  = _vecClassname isKindOf "Plane";
private _isHeli   = _vecClassname isKindOf "Helicopter";
private _isBoat   = _vecClassname isKindOf "Ship";
private _isTank   = _vecClassname isKindOf "Tank";
private _isCar    = _vecClassname isKindOf "Car";
private _isTruck  = _vecClassname isKindOf "Truck";

switch (_baseType) do {
    case "MAIN_BASE";  // HQ Utama
    case "BASE": {      // HQ Sekunder
        // Semua kendaraan darat + semua helikopter (termasuk attack)
        // Tidak boleh pesawat, tidak boleh kapal
        if (!_isPlane && !_isBoat) then { _isAllowed = true; };
    };
    case "AIRBASE": {
        // Semua udara (helikopter + pesawat)
        if (_isAir) then { _isAllowed = true; };
    };
    case "HARBOR": {
        // Kapal + helikopter (helikopter bisa mendarat di harbor)
        if (_isBoat || _isHeli) then { _isAllowed = true; };
    };
    case "CITY"; case "RADIO"; case "FACTORY": {
        // Hanya mobil dan truk
        if (_isCar || _isTruck) then { _isAllowed = true; };
    };
};

_isAllowed