/*
    Author: Modder
    File: fn_PlayerLocal.sqf
    Description: Inisialisasi client-side.
    🔧 FIX P3: Hapus auto-save 5 menit. Hanya load data saat masuk.
               Save manual tersedia di HQ BTR-82A.
               Auto-save harian diatur oleh fn_serverWorker.sqf (jam 17:00 in-game).
*/

if (!hasInterface) exitWith {};

player linkItem "ItemMap";
player linkItem "ItemCompass";
player linkItem "ItemWatch";

if (side player != resistance) then {
    [player] joinSilent createGroup resistance;
};

if (isHidden player) then {
    player hideObjectGlobal false;
};
player enableSimulationGlobal true;
player switchMove "AmovPercMstpSlowWrflDnon";

// --- PROSES MUAT DATA & SINKRONISASI POSISI ---
[] spawn {
    if (hasCustomFace player && {face player != "Custom"}) then {
        [player, "Custom"] remoteExec ["setFace", 0, true];
    };
	
    waitUntil { time > 5 };
    [] call MERC_fnc_playerLoad; // Memuat data save fisik asli

    // Setelah load selesai, pindahkan Player ke dekat Mobil HQ yang sebenarnya
    private _hqPos = missionNamespace getVariable ["merc_hq_position", getPos player];
    player setPos (_hqPos getPos [random 4, random 360]);

    systemChat "MERC SYSTEM: Data profil berhasil dimuat dan posisi disinkronkan.";
};