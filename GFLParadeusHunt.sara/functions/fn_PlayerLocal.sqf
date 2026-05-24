/*
    Author: Modder
    File: fn_PlayerLocal.sqf
    Description: Inisialisasi client-side.
    🔧 FIX P3: Hapus auto-save 5 menit. Hanya load data saat masuk.
               Save manual tersedia di HQ BTR-82A.
               Auto-save harian diatur oleh fn_serverWorker.sqf (jam 17:00 in-game).
*/

if (!hasInterface) exitWith {};

// Bekali alat navigasi WAJIB
player linkItem "ItemMap";
player linkItem "ItemCompass";
player linkItem "ItemWatch";

// Pindahkan ke side Resistance agar marker "respawn_guerrila" dikenali
if (side player != resistance) then {
    [player] joinSilent createGroup resistance;
};

if (isHidden player) then {
    player hideObjectGlobal false;
};
player enableSimulationGlobal true;

// 2. Perbaikan utama: paksa unit berdiri normal
player switchMove "AmovPercMstpSlowWrflDnon";

// 3. Pastikan posisi aman (pindahkan ke marker HQ)
private _spawnPos = getMarkerPos "respawn_guerrila";
if (count _spawnPos > 0) then {
    player setPos _spawnPos;
};


// Muat data dari profileNamespace saat pemain masuk
[] spawn {
        if (hasCustomFace player && {face player != "Custom"}) then {
        [player, "Custom"] remoteExec ["setFace", 0, true];
    };
	
    waitUntil { time > 5 };
    [] call MERC_fnc_playerLoad;
    systemChat "MERC SYSTEM: Data profil berhasil dimuat.";
};