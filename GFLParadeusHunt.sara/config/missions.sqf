merc_missions = [

    // =================================================
    // USA MISSIONS
    // =================================================

    [
        "destroy_major",                 // 0 ID
        "Destroy Enemy Outpost",         // 1 Name
        "Attack enemy military outpost and eliminate all resistance.",

        "USA",                           // 3 Reward faction
        "RUSSIA",                        // 4 Enemy faction

        [20,60],                         // 5 Reputation reward
        [25,75],                         // 6 Reputation penalty enemy

        [3000,12000],                    // 7 Money reward

        "HIGH",                          // 8 Difficulty

        false,                           // 9 Night only
        true,                            // 10 Allow vehicle
        false,                           // 11 Neutral mission

        1500,                             // 12 Mission radius

	"KILL_ALL_ENEMIES",              // 13 Success state
        "TIME_EXPIRED",                  // 14 Fail state
        3600                            // 15 Duration (1 jam)
    ],

    [
        "destroy_cult",
        "Destroy Cult Cell",
        "Eliminate cult presence operating during the night.",

        "USA",
        "CULT",

        [15,40],
        [0,0],

        [4000,15000],

        "MEDIUM",

        true,
        false,
        true,

        800,
	"KILL_ALL_ENEMIES",
        "DAYLIGHT_EXPIRED",              //Cult night mission gagal kalau siang
        2400
    ],

    [
        "destroy_merc",
        "Eliminate Mercenary Squad",
        "Destroy rival mercenary forces operating in the region.",

        "USA",
        "MERC",

        [20,50],
        [0,0],

        [5000,14000],

        "MEDIUM",

        false,
        true,
        false,

        1000,

	"KILL_ALL_ENEMIES",
        "TARGET_ESCAPED",                // Merc bisa kabur
        2700
    ],

    [
        "join_great_war",
        "Join Great War",
        "Participate in large scale faction warfare.",

        "USA",
        "RUSSIA",

        [50,120],
        [60,150],

        [10000,50000],

        "EXTREME",

        false,
        true,
        false,

        3000,

        "CAPTURE_AREA",
        "AREA_LOST",
        5400
    ],

    [
        "defend_asset_us",
        "Defend USA Asset",
        "Protect strategic USA infrastructure from enemy attack.",

        "USA",
        "RUSSIA",

        [20,60],
        [25,80],

        [5000,18000],

        "HIGH",

        false,
        true,
        false,

        1200,

        // 🔧 FIX: Tambah 3 elemen
        "DEFEND_OBJECTIVE",              // Bertahan
        "OBJECTIVE_DESTROYED",           // Gagal kalau aset hancur
        3000
    ],

    [
        "destroy_asset_us",
        "Destroy Russian Asset",
        "Destroy enemy communication or industrial infrastructure.",

        "USA",
        "RUSSIA",

        [25,70],
        [30,90],

        [7000,22000],

        "HIGH",

        false,
        true,
        false,

        1500,

        "DESTROY_OBJECTIVE",
        "TIME_EXPIRED",
        3600
    ],

    // =================================================
    // RUSSIA MISSIONS
    // =================================================

    [
        "destroy_major_ru",
        "Destroy Enemy Outpost",
        "Attack enemy military outpost and eliminate all resistance.",

        "RUSSIA",
        "USA",

        [20,60],
        [25,75],

        [3000,12000],

        "HIGH",

        false,
        true,
        false,

        1500,

        "KILL_ALL_ENEMIES",
        "TIME_EXPIRED",
        3600
    ],

    [
        "destroy_cult_ru",
        "Destroy Cult Cell",
        "Eliminate cult presence operating during the night.",

        "RUSSIA",
        "CULT",

        [15,40],
        [0,0],

        [4000,15000],

        "MEDIUM",

        true,
        false,
        true,

        800,

        "KILL_ALL_ENEMIES",
        "DAYLIGHT_EXPIRED",
        2400
    ],

    [
        "destroy_merc_ru",
        "Eliminate Mercenary Squad",
        "Destroy rival mercenary forces operating in the region.",

        "RUSSIA",
        "MERC",

        [20,50],
        [0,0],

        [5000,14000],

        "MEDIUM",

        false,
        true,
        false,

        1000,

        "KILL_ALL_ENEMIES",
        "TARGET_ESCAPED",
        2700
    ],

    [
        "join_great_war_ru",
        "Join Great War",
        "Participate in large scale faction warfare.",

        "RUSSIA",
        "USA",

        [50,120],
        [60,150],

        [10000,50000],

        "EXTREME",

        false,
        true,
        false,

        3000,

        "CAPTURE_AREA",
        "AREA_LOST",
        5400
    ],

    [
        "defend_asset_ru",
        "Defend Russian Asset",
        "Protect strategic Russian infrastructure from enemy attack.",

        "RUSSIA",
        "USA",

        [20,60],
        [25,80],

        [5000,18000],

        "HIGH",

        false,
        true,
        false,

        1200,

        "DEFEND_OBJECTIVE",              
        "OBJECTIVE_DESTROYED",          
        3000
    ],

    [
        "destroy_asset_ru",
        "Destroy USA Asset",
        "Destroy enemy communication or industrial infrastructure.",

        "RUSSIA",
        "USA",

        [25,70],
        [30,90],

        [7000,22000],

        "HIGH",

        false,
        true,
        false,

        1500,

        "DESTROY_OBJECTIVE",
        "TIME_EXPIRED",
        3600

    ],

    // =================================================
    // CIV MISSIONS
    // =================================================

    [
        "defend_city",
        "Defend City",
        "Protect civilians and hold the city against enemy assault.",

        "CIV",
        "",

        [10,30],
        [0,0],

        [2000,7000],

        "LOW",

        false,
        true,
        true,

        1000,

        "DEFEND_OBJECTIVE",              
        "AREA_LOST",                     
        1800
    ],

    [
        "defend_supply",
        "Defend Supply Convoy",
        "Escort and protect civilian supply movement.",

        "CIV",
        "MERC",

        [10,25],
        [0,0],

        [3000,9000],

        "LOW",

        false,
        true,
        true,

        1200,

        "VIP_ESCAPED",                  
        "VIP_DEAD",                      
        1800
    ],

    [
        "evacuate_civilians",
        "Evacuate Civilians",
        "Rescue civilians trapped in conflict zone.",

        "CIV",
        "CULT",

        [15,35],
        [0,0],

        [4000,10000],

        "MEDIUM",

        true,
        true,
        true,

        900

        "VIP_ESCAPED",                   
        "VIP_DEAD",                      
        2400
    ],

    // =================================================
    // HQ MISSIONS
    // =================================================

    [
        "take_factory",
        "Capture Factory",
        "Capture industrial production facility.",

        "HQ",
        ["RUSSIA","USA"],

        [0,0],
        [10,20],

        [7000,25000],

        "HIGH",

        false,
        true,
        true,

        1500,

        "CAPTURE_AREA",                  
        "AREA_LOST",                     
        3600
    ],

    [
        "take_radio",
        "Capture Radio Tower",
        "Secure communication infrastructure for strategic advantage.",

        "HQ",
        ["RUSSIA","USA"],

        [0,0],
        [10,20],

        [5000,12000],

        "MEDIUM",

        false,
        true,
        true,

        800,

        "CAPTURE_AREA",                  
        "AREA_LOST",                     
        2400
    ],

    [
        "secure_airbase",
        "Secure Airbase",
        "Capture airbase to unlock aircraft deployment.",

        "HQ",
	["RUSSIA","USA"],

	[0,0],
	[30,40],

        [15000,50000],

        "EXTREME",

        false,
        true,
        false,

        3000,

        "CAPTURE_AREA",                 
        "AREA_LOST",                    
        5400
    ],

    [
        "secure_harbor",
        "Secure Harbor",
        "Capture harbor to unlock naval deployment.",

        "HQ",
	["RUSSIA","USA"],

	[0,0],
	[30,40],

        [12000,35000],

        "HIGH",

        false,
        true,
        false,

        2000,

        "CAPTURE_AREA",                  
        "AREA_LOST",                    
        3600
    ]

];