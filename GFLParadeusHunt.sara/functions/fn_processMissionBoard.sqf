/*
=========================================================
fn_processMissionBoard.sqf
=========================================================

SYSTEM:
- Generate HQ mission board
- Limit active missions
- Mission accept system
- Mission runtime
- Mission fail/success
- Cult night mission
- Replace failed mission
- Mission timer system

🔧 FIX: Path file sudah diganti dengan panggilan fungsi yang benar.
=========================================================
*/

// =====================================================
// SETTINGS
// =====================================================

private _maxBoardMission = 4;

private _hqPos =
missionNamespace getVariable
[
    "merc_hq_position",
    [0,0,0]
];


// =====================================================
// STORAGE
// =====================================================

if (isNil "merc_boardMissions") then
{
    merc_boardMissions = [];
};

if (isNil "merc_activeMissions") then
{
    merc_activeMissions = [];
};


// =====================================================
// GENERATE BOARD MISSIONS
// =====================================================

// 🔧 PERBAIKAN: Panggil fungsi yang terdaftar, bukan preprocess file.
private _rawMissions = [player] call MERC_fnc_generateMission;

_rawMissions = _rawMissions call BIS_fnc_arrayShuffle;


// =====================================================
// LIMIT TO 4 MISSIONS
// =====================================================

private _selectedMissions =
_rawMissions select
[
    0,
    (_maxBoardMission min (count _rawMissions))
];


// =====================================================
// CREATE BOARD MISSIONS
// =====================================================

{
    private _mission = _x;

    private _missionID       = _mission select 0;
    private _missionName     = _mission select 1;
    private _description     = _mission select 2;

    private _rewardFaction   = _mission select 3;
    private _enemyFaction    = _mission select 4;

    private _difficulty      = _mission select 8;

    private _nightOnly       = _mission select 9;
    private _allowVehicle    = _mission select 10;
    private _neutralMission  = _mission select 11;

    private _missionRadius   = _mission select 12;

    private _successState    = _mission select 13;
    private _failState       = _mission select 14;

    private _duration        = _mission select 15;


    // =================================================
    // POSITION GENERATION
    // =================================================

    private _missionPos = [0,0,0];

    switch (_rewardFaction) do
    {

        // ---------------------------------------------
        // HQ/CIV MISSIONS
        // ---------------------------------------------

        case "HQ":
        {
            _missionPos =
            _hqPos getPos
            [
                random 5000,
                random 360
            ];
        };

        case "CIV":
        {
            _missionPos =
            _hqPos getPos
            [
                random 5000,
                random 360
            ];
        };


        // ---------------------------------------------
        // USA/RUSSIA
        // ---------------------------------------------

        case "USA":
        {
            _missionPos =
            [
                random worldSize,
                random worldSize,
                0
            ];
        };

        case "RUSSIA":
        {
            _missionPos =
            [
                random worldSize,
                random worldSize,
                0
            ];
        };

    };


    // =================================================
    // MARKER
    // =================================================

    private _markerName =
    format
    [
        "mission_%1",
        floor random 999999
    ];

    private _marker =
    createMarker
    [
        _markerName,
        _missionPos
    ];

    _marker setMarkerShape "ELLIPSE";

    _marker setMarkerSize
    [
        _missionRadius,
        _missionRadius
    ];

    _marker setMarkerColor "ColorYellow";

    _marker setMarkerAlpha 0.7;

    _marker setMarkerText _missionName;


    // =================================================
    // STORE BOARD MISSION
    // =================================================

    merc_boardMissions pushBack
    [
        _mission,          // 0
        _missionPos,       // 1
        _markerName,       // 2
        false              // 3 accepted
    ];


    // =================================================
    // CIV WARNING
    // =================================================

    if (_rewardFaction == "CIV") then
    {
        systemChat
        format
        [
            "WARNING: %1 may be annexed if ignored.",
            _missionName
        ];
    };

} forEach _selectedMissions;


// =====================================================
// CULT RANDOM EVENT
// =====================================================

private _hour = daytime;

if (_hour >= 17 || _hour <= 5) then
{

    if ((random 100) < 40) then
    {

        private _cultList = [];

        {
            private _enemyFaction = _x select 4;
            
            // 🔧 PERBAIKAN: Cek tipe data sebelum cek "CULT"
            private _isCultMission = if (_enemyFaction isEqualType []) then {
                "CULT" in _enemyFaction
            } else {
                _enemyFaction == "CULT"
            };
            
            if (_isCultMission) then {
                _cultList pushBack _x;
            };

        } forEach merc_missions;


        if ((count _cultList) > 0) then
        {

            private _cultMission =
            selectRandom _cultList;

            private _missionName =
            _cultMission select 1;

            private _missionRadius =
            _cultMission select 12;


            // -----------------------------------------
            // POSITION
            // -----------------------------------------

            private _cultPos =
            [
                random worldSize,
                random worldSize,
                0
            ];


            // -----------------------------------------
            // MARKER
            // -----------------------------------------

            private _markerName =
            format
            [
                "cult_%1",
                floor random 999999
            ];

            private _marker =
            createMarker
            [
                _markerName,
                _cultPos
            ];

            _marker setMarkerShape "ELLIPSE";

            _marker setMarkerSize
            [
                _missionRadius,
                _missionRadius
            ];

            _marker setMarkerColor "ColorRed";

            _marker setMarkerAlpha 0.8;

            _marker setMarkerText
            "UNKNOWN SIGNAL";


            // -----------------------------------------
            // STORE
            // -----------------------------------------

            merc_boardMissions pushBack
            [
                _cultMission,
                _cultPos,
                _markerName,
                false
            ];


            systemChat
            "UNKNOWN RADIO SIGNAL DETECTED";

        };

    };

};


// =====================================================
// ACTIVE MISSION LOOP
// =====================================================

{
    private _activeMission = _x;

    private _mission        = _activeMission select 0;
    private _missionPos     = _activeMission select 1;
    private _markerName     = _activeMission select 2;

    private _startTime      = _activeMission select 3;

    private _successState   = _activeMission select 4;
    private _failState      = _activeMission select 5;

    private _duration       = _activeMission select 6;

    private _missionID      = _mission select 0;
    private _missionName    = _mission select 1;

    private _rewardFaction  = _mission select 3;
    private _enemyFaction   = _mission select 4;


    // =================================================
    // TIMER
    // =================================================

    private _timePassed =
    time - _startTime;


    // =================================================
    // TIME FAIL
    // =================================================

    if (_timePassed >= _duration) then
    {

        // 🔧 PERBAIKAN: Panggil fungsi yang terdaftar.
        [_activeMission, false] remoteExec ["MERC_fnc_finishMission", 2];


        deleteMarker _markerName;

        merc_activeMissions deleteAt
        (
            merc_activeMissions find _activeMission
        );


        // ---------------------------------------------
        // REPLACE MISSION BEFORE 5AM
        // ---------------------------------------------

        if (daytime < 5) then
        {
            [] call MERC_fnc_generateMission;
        };

    };


    // =================================================
    // CULT DAY FAIL
    // =================================================

    // 🔧 PERBAIKAN: Gunakan logika yang sama untuk pengecekan Cult.
    private _enemyFactionData = _mission select 4;
    private _isCultMission = if (_enemyFactionData isEqualType []) then {
        "CULT" in _enemyFactionData
    } else {
        _enemyFactionData == "CULT"
    };

    if (_isCultMission) then
    {

        if !(daytime >= 17 || daytime <= 5) then
        {

            [_activeMission, false] remoteExec ["MERC_fnc_finishMission", 2];


            deleteMarker _markerName;

            merc_activeMissions deleteAt
            (
                merc_activeMissions find _activeMission
            );

        };

    };


    // =================================================
    // FAIL CONDITIONS
    // =================================================

    switch (_failState) do
    {

        // ---------------------------------------------
        // VIP DEAD
        // ---------------------------------------------

        case "VIP_DEAD":
        {

            private _vip =
            _activeMission select 7;

            if (!alive _vip) then
            {

                [_activeMission, false] remoteExec ["MERC_fnc_finishMission", 2];

            };

        };


        // ---------------------------------------------
        // AREA LOST
        // ---------------------------------------------

        case "AREA_LOST":
        {

            // Placeholder
            // future territory control system

        };


        // ---------------------------------------------
        // OBJECTIVE DESTROYED
        // ---------------------------------------------

        case "OBJECTIVE_DESTROYED":
        {

            // Placeholder

        };


        // ---------------------------------------------
        // TARGET ESCAPED
        // ---------------------------------------------

        case "TARGET_ESCAPED":
        {

            // Placeholder

        };

    };


    // =================================================
    // SUCCESS CONDITIONS
    // =================================================

    switch (_successState) do
    {

        case "KILL_ALL_ENEMIES":
        {

            // Placeholder

        };

        case "CAPTURE_AREA":
        {

            // Placeholder

        };

        case "DESTROY_OBJECTIVE":
        {

            // Placeholder

        };

        case "VIP_ESCAPED":
        {

            // Placeholder

        };

    };

} forEach merc_activeMissions;