/*
    File: Mission\fn_cultBrainWatcher.sqf
    Description: Mencari Cult Boss dan menjalankan Cult Brain
*/

if (!isServer) exitWith {};

while {true} do {

    {
        if (
            alive _x &&
            {_x getVariable ["MERC_is_cult_boss", false]} &&
            {!(_x getVariable ["MERC_cultBrainRunning", false])}
        ) then {

            // Tandai agar tidak dijalankan dua kali
            _x setVariable ["MERC_cultBrainRunning", true];

            [_x] spawn {
                params ["_unit"];

                // Compile hanya ketika Brain benar-benar dibutuhkan
                [_unit] call compile preprocessFileLineNumbers
                    "InsurgencyFunction\Mission\fn_cultBrain.sqf";

                // Brain sudah selesai
                _unit setVariable ["MERC_cultBrainRunning", false];
            };
        };

    } forEach allUnits;

    sleep 5;
};