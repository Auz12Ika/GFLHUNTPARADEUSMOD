/*
    File: missionData.sqf
    Description: Master Contract Mission Pool dengan Integrasi Nilai Reputasi Langsung (Poin 1)
    Structure: [
        "Mission_ID",       // [0] ID Unik Misi
        "Display Name",     // [1] Nama di UI Listbox
        "Difficulty",       // [2] EASY / MEDIUM / HARD
        Time_Limit_Hours,   // [3] Batasan waktu (2 - 8 Jam)
        [Min_Reward, Max],  // [4] Rentang dana dasar
        Base_Rep_Reward,    // [5] HADIAH REPUTASI POSITIF LANGSUNG (Easy: 2, Med: 5, Hard: 12)
        "Giver_Faction",    // [6] "USA", "RUSSIA", atau "HQ"
        "Target_Faction",   // [7] "USA", "RUSSIA", "CULT", atau "MERC_ENEMY"
        "Night_Only",       // [8] "YES" atau "NO"
        "Description"       // [9] Deskripsi detail misi
    ]
*/

MERC_mission_contract_pool = [
    // ========================================================================
    // FIRST CONTRACT (EASY TIER) - Reputation: 2 | Reward: $2,000 - $4,000
    // ========================================================================
    [
        "RU_kill_cult_hvt", 
        "Kill Cult HVT", 
        "EASY", 
        2.0, 
        [2000, 2500], 
        2, 
        "RU", "CULT", 
        "YES", 
        "Eliminate a high-ranking cult leader operating under the cover of darkness. Intel shows weak camp defense."
    ],
	
	[
        "US_kill_cult_hvt", 
        "Kill Cult HVT", 
        "EASY", 
        2.0, 
        [2000, 2500], 
        2, 
        "US", "CULT", 
        "YES", 
        "Eliminate a high-ranking cult leader operating under the cover of darkness. Intel shows weak camp defense."
    ],
	
    [
        "hq_kill_merc_hvt", 
        "Kill Enemy's Merc HVT", 
        "EASY", 
        2.5, 
        [2500, 3200], 
        0, 
        "HQ", "MERC_ENEMY", 
        "NO", 
        "Track down and neutralize a rogue mercenary commander hoarding local tactical intel. Watch out for his bodyguards."
    ],
    [
        "hq_destroy_roadblock", 
        "Destroy Road Block", 
        "EASY", 
        3.0, 
        [3200, 4000], 
        0, 
        "HQ", "MERC_ENEMY", 
        "NO", 
        "Clear out a strategic hostile checkpoint disrupting local supply lines. Bring high-explosives."
    ],

    // ========================================================================
    // SITUATION CONTRACT (MEDIUM TIER) - Reputation: 5 | Reward: $5,000 - $9,000
    // ========================================================================
    [
        "us_kill_hvt_rus", 
        "Kill HVT Russian Officer (US Contract)", 
        "MEDIUM", 
        4.0, 
        [5000, 6200], 
        5, 
        "USA", "RUSSIA", 
        "NO", 
        "Infiltrate a well-fortified small Russian HQ and eliminate the commanding officer. Success increases US Trust."
    ],
    [
        "ru_kill_hvt_usa", 
        "Kill HVT USA Officer (RU Contract)", 
        "MEDIUM", 
        4.0, 
        [5000, 6200], 
        5, 
        "RUSSIA", "USA", 
        "NO", 
        "Infiltrate a small US Military outpost and neutralize their high-ranking officer. Success increases Russian Trust."
    ],
    [
        "us_destroy_cult_barrack", 
        "Clear Cult Barrack (US Request)", 
        "MEDIUM", 
        5.0, 
        [7500, 9000], 
        5, 
        "USA", "CULT", 
        "YES", 
        "Assault a cult staging ground within a 100x100m AO. Liquidate all 10-20 zealots. Cult Boss may lead the defense."
    ],
    [
        "ru_destroy_cult_barrack", 
        "Clear Cult Barrack (RU Request)", 
        "MEDIUM", 
        5.0, 
        [7500, 9000], 
        5, 
        "RUSSIA", "CULT", 
        "YES", 
        "Russian intelligence requested the complete purge of a cult barrack (100x100m AO). 10-20 hostiles expected."
    ],

    // ========================================================================
    // AO CONTRACT (HARD TIER) - Reputation: 12 | Reward: $15,000 - $25,000
    // ========================================================================
//   [
//       "ru_destroy_major_convoy_us", 
//       "Intercept US Major Convoy", 
//       "HARD", 
//       6.0, 
//       [15000, 19500], 
//       12, 
//       "RUSSIA", "USA", 
//       "NO", 
//       "Interdict a heavily protected US Army supply convoy. Guarded by 25% elite mercs and 75% regular forces."
//   ],
//   [
//       "us_destroy_major_convoy_ru", 
//       "Intercept Russian Major Convoy", 
//       "HARD", 
//       6.0, 
//       [15000, 19500], 
//       12, 
//       "USA", "RUSSIA", 
//       "NO", 
//       "Ambush a major Russian army logistics convoy. High priority target for the United States Command."
//   ],
    [
        "ru_destroy_barrack_us", 
        "Raid US Military Barrack Base", 
        "HARD", 
        8.0, 
        [20000, 25000], 
        12, 
        "RUSSIA", "USA", 
        "NO", 
        "Launch a massive assault on a US Army base within a 250x250m AO. Complete liquidation required (25-40 targets)."
    ],
    [
        "us_destroy_barrack_ru", 
        "Raid Russian Fortress Barrack", 
        "HARD", 
        8.0, 
        [20000, 25000], 
        12, 
        "USA", "RUSSIA", 
        "NO", 
        "Wipe out a large Russian fortification (250x250m AO). High-risk deployment. Expect up to 40 heavy combatants."
    ],
	// Main Mission
	[
		"cult_main_1",
		"Destroy Cult HQ", 
		"HARD",
		2, 
		[30000, 50000],
		0,
		"HQ",
		"CULT",
		"NO",
		"Destroy the Cult main base."
	]
];

