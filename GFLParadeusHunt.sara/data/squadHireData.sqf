/*
    File: data\squadHireData.sqf
    Description: Squad manifests and skill tier definitions with dynamic weapon pools.
*/

// Skill tiers: [Display Name, Price Multiplier, Skill Value, Description]
MERC_squadHire_skillTiers = [
    [
        "ROOKIE",
        0.5,
        0.3, // Perbaikan: Menjadi 0.3 agar lebih rendah dari Experienced
        "Basic training. Reduced cost, reduced accuracy and reaction time. Suitable for garrison duty."
    ],
    [
        "EXPERIENCED",
        0.7,
        0.5, // Perbaikan: Menjadi 0.5 agar seimbang di tengah
        "Combat-ready operative. Standard performance and reliability in most firefights."
    ],
    [
        "VETERAN",
        1.0,
        0.7,
        "High skill. Excellent marksmanship and tactical awareness. Proven in multiple engagements."
    ],
    [
        "ELITE",
        1.5,
        0.9,
        "Peak combat performance. Maximum lethality, near-perfect accuracy, and advanced weapon handling."
    ]
];

// Squad manifests: [Display Name, Base Cost, Units Array, Weapons Pool Array, Vehicle Class, Description]
MERC_squadHire_manifests = [
[
        "Sangvis Recon Team", 
        5000,                
        ["SF_Jaeger", "SF_Vespid", "SF_Vespid", "SF_Ripper"], // 🌟 FIX: Nama unit disesuaikan dengan Path asli Mod
        [
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Jaeger: SL
            ["srifle_DMR_01_F", "10Rnd_762x54_Mag", "", ""],                           // Vespid 1: Marksman
            ["srifle_GM6_F", "5Rnd_127x108_Mag", "", ""],                               // Vespid 2: Anti-Material
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "", ""]              // Ripper: AR
        ],
        "CUP_I_LR_Transport_AAF", 
        "Recon squad specializing in long-range harassment. Includes: 1x Jaeger (SL/AR), 1x Vespid (Marksman), 1x Vespid (Anti-Material Rifle), 1x Ripper (AR). Deployed with a CUP Armed Light Pickup."
    ],
    [
        "Sangvis Assault Team",
        4500,
        ["SF_Jaeger", "SF_Ripper", "SF_Ripper", "SF_Ripper"], // 🌟 FIX: Striker diganti menjadi SF_Ripper
        [
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Jaeger: SL
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "", ""],             // Ripper: AR
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "", ""],             // Ripper: AR
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "", ""]              // Ripper: AR
        ],
        "CUP_I_LR_SF_HMG_AAF", 
        "Standard front-line assault squad. Includes: 1x Jaeger (SL/AR), 3x Ripper (AR). Deployed with a CUP Light Transport Vehicle."
    ],
    [
        "Mangi Anti-Vehicle Team",
        9000,
        ["GFL_Mangi_Strike_Captain", "GFL_Mangi_Blaster", "GFL_Mangi_Blaster", "GFL_Mangi_Mechanist"], // 🌟 FIX: Menggunakan classname asli dari foto 201722~1.jpg
        [
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "", ""],                                 // Strike Captain: Squad Leader
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "launch_MRAWS_green_F", "MRAWS_HEAT_F"], // Blaster 1: Heavy AT
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "launch_B_Titan_F", "Titan_AA"],         // Blaster 2: Heavy AA
            ["arifle_Katiba_F", "30Rnd_65x39_caseless_green_mag", "", ""]                                  // Mechanist
        ],
        "CUP_B_M1135_ATGMV_Woodland", 
        "Heavy anti-armor and anti-air defense detachment. Includes: 1x Strike Captain (SL), 2x Blaster (Heavy AT/AA), 1x Spotter. Deployed with an armored CUP BTR-80 Autocannon APC."
    ],
	[
        "HOC Combat Team (Humvee AT)",
        6500,
        ["GFL_HOC_Team_Leader", "GFL_HOC_Doll_A", "GFL_HOC_Doll_AT", "GFL_HOC_Doll_Crewman"], // 🌟 FIX: Classname asli HOC dari 201A80~1.jpg
        [
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Team Leader
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Doll A
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "launch_NLAW_F", "NLAW_F"], // Doll AT (Membawa AT Launcher)
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""]               // Crewman (Medic role)
        ],
        "CUP_B_nM1036_TOW_DF_USA_WDL", 
        "HOC anti-tank mobile support block. Includes: 1x Team Leader, 1x Assault Doll, 1x AT Specialist, 1x Support Crewman. Deployed with a CUP HMMWV TOW Anti-Tank Guided Missile Vehicle."
    ],
    [
        "HOC Combat Team (Humvee HMG)",
        5800,
        ["GFL_HOC_Team_Leader", "GFL_HOC_Doll_A", "GFL_HOC_Doll_B", "GFL_HOC_Doll_Crewman"], // 🌟 FIX: Menggunakan kombinasi Doll A & B
        [
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Team Leader
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Doll A
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Doll B
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""]               // Crewman (Medic role)
        ],
        "CUP_B_HMMWV_M2_GPK_NATO_T", 
        "HOC standard security motorized block. Includes: 1x Team Leader, 2x Assault Doll, 1x Support Crewman. Deployed with a CUP HMMWV .50 Cal M2 Heavy Machine Gun Vehicle."
    ],
    [
        "HOC Combat Team (Humvee AA)",
        7000,
        ["GFL_HOC_Team_Leader", "GFL_HOC_Doll_A", "GFL_HOC_Doll_AT", "GFL_HOC_Doll_Crewman"], // 🌟 FIX: Menggunakan Doll AT untuk memegang AA Launcher
        [
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Team Leader
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""],              // Doll A
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "launch_B_Titan_F", "Titan_AA"], // Doll AT diberi senjata Anti-Air Titan
            ["arifle_MSBS65_F", "30Rnd_65x39_caseless_msbs_mag", "", ""]               // Crewman (Medic role)
        ],
        "CUP_B_nM1097_AVENGER_AFU", 
        "HOC airspace denial mechanized block. Includes: 1x Team Leader, 1x Assault Doll, 1x AA Specialist, 1x Support Crewman. Deployed with a CUP HMMWV Avenger Air-Defense Support Vehicle."
    ]
];