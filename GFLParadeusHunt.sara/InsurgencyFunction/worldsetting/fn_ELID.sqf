/*
    fn_ELID.sqf
    Random ELID World Event
*/

if (!isServer) exitWith {};

missionNamespace setVariable ["MERC_ELID_Active", false, true];
missionNamespace setVariable ["MERC_ELID_Group", grpNull, true];
missionNamespace setVariable ["MERC_ELID_Units", [], true];

private _elidPool = [
    "WBK_SpecialZombie_Smasher_1",
    "WBK_SpecialZombie_Smasher_Acid_1",
    "WBK_SpecialZombie_Smasher_Hellbeast_1",
    "WBK_Goliaph_2"
];

while {true} do {

    sleep 600;

    if (missionNamespace getVariable ["MERC_ELID_Active", false]) then {
        continue;
    };

    if ((random 100) >= 10) then {
        continue;
    };

    private _players = allPlayers select {
        alive _x &&
        {!isNull _x}
    };

    if (_players isEqualTo []) then {
        continue;
    };

    private _targetPlayer = selectRandom _players;

    private _spawnPos = [
        getPosATL _targetPlayer,
        350,
        450,
        10,
        0,
        0.5,
        0,
        [],
        [[0,0,0],[0,0,0]]
    ] call BIS_fnc_findSafePos;

    if (_spawnPos isEqualTo [0,0,0]) then {
        continue;
    };

    if (surfaceIsWater _spawnPos) then {
        continue;
    };

    private _grp = createGroup [east, true];

    private _count = 1;
    if ((random 100) < 30) then {
        _count = 2;
    };

    private _spawned = [];

    for "_i" from 1 to _count do {

        private _class = selectRandom _elidPool;

        private _unit = _grp createUnit [
            _class,
            _spawnPos,
            [],
            0,
            "NONE"
        ];

        if (!isNull _unit) then {

            _unit enableSimulationGlobal true;

            _unit setBehaviour "COMBAT";
            _unit setCombatMode "RED";
            _unit setSpeedMode "FULL";

            _spawned pushBack _unit;
        };
    };

    if (_spawned isEqualTo []) then {
        deleteGroup _grp;
        continue;
    };

    missionNamespace setVariable [
        "MERC_ELID_Active",
        true,
        true
    ];

    missionNamespace setVariable [
        "MERC_ELID_Group",
        _grp,
        true
    ];

    missionNamespace setVariable [
        "MERC_ELID_Units",
        _spawned,
        true
    ];

    private _wp = _grp addWaypoint [
        getPosATL _targetPlayer,
        0
    ];

    _wp setWaypointType "SAD";
    _wp setWaypointBehaviour "COMBAT";
    _wp setWaypointCombatMode "RED";
    _wp setWaypointSpeed "FULL";

    [_grp, _spawned, _targetPlayer] spawn {

        params [
            "_grp",
            "_units",
            "_trackedPlayer"
        ];

        private _noTargetTime = time;
		
        while {true} do {

            sleep 5;

            _units = _units select {
                alive _x
            };

            if (_units isEqualTo []) exitWith {};

            private _target = objNull;
            private _bestDist = 600;

            {
                private _unit = _x;

                private _nearTargets = (_unit nearEntities [
                    [
                        "Man",
                        "Car",
                        "Tank",
                        "Motorcycle",
                        "APC"
                    ],
                    600
                ]) select {

                    alive _x &&
                    {side _x != east} &&
                    {_x != _unit}
                };

                {
                    private _dist = _unit distance _x;

                    if (_dist < _bestDist) then {
                        _bestDist = _dist;
                        _target = _x;
                    };

                } forEach _nearTargets;

            } forEach _units;

            if (!isNull _target) then {

                {
                    _x doMove (getPosATL _target);
                    _x doTarget _target;
                    _x doWatch _target;
                } forEach _units;

                _noTargetTime = time;

            } else {

                if (alive _trackedPlayer) then {

                    {
                        _x doMove (getPosATL _trackedPlayer);
                    } forEach _units;

                };

                if ((time - _noTargetTime) >= 10) exitWith {};

            };

        };

        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach _units;

        if (!isNull _grp) then {
            deleteGroup _grp;
        };

        missionNamespace setVariable [
            "MERC_ELID_Units",
            [],
            true
        ];

        missionNamespace setVariable [
            "MERC_ELID_Group",
            grpNull,
            true
        ];

        missionNamespace setVariable [
            "MERC_ELID_Active",
            false,
            true
        ];

    };

};