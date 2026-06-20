/*
    File: InsurgencyFunction\Missions\fn_generateMissionDesc.sqf
    Description: Generate briefing text profesional untuk papan kontrak.
    Parameter: [_missionData]  (array dari missionData.sqf)
    Return: String berformat parseText (Structured Text)
*/

params [["_missionData", []]];
if (count _missionData < 10) exitWith { "<t color='#FF0000'>ERROR: Invalid mission data.</t>" };

_missionData params ["_id", "_title", "_difficulty", "_timeLimit", "_rewardRange", "_repReward", "_giver", "_target", "_nightOnly", "_desc"];

// ================================================================
// 1. NAMA RESMI PEMBERI MISI
// ================================================================
private _giverName = switch (true) do {
    case (_giver in ["USA","US"]):          { "United States Army Command" };
    case (_giver in ["RUSSIA","RU"]):       { "Russian General Staff (GRU)" };
    case (_giver == "HQ"):                  { "MERC Strategic Headquarters" };
    default                                 { "Allied Command" };
};

// ================================================================
// 2. NAMA FAKSI TARGET
// ================================================================
private _targetName = switch (true) do {
    case (_target in ["USA","US"]):         { "US Armed Forces" };
    case (_target in ["RUSSIA","RU"]):      { "Russian Federation Forces" };
    case (_target == "CULT"):               { "Cult Paramilitary Forces" };
    case (_target == "MERC_ENEMY"):         { "Rogue Mercenary Contractors" };
    default                                 { "Hostile Forces" };
};

// ================================================================
// 3. TIPE MISI & KATA KERJA
// ================================================================
private _verbPhrase = "";
private _objectiveText = "";

if (_id find "kill" >= 0) then {
    _verbPhrase = "neutralize the designated HVT";
    _objectiveText = "Locate and eliminate the high-value target. Expect the target to be guarded by a personal security detail.";
};
if (_id find "convoy" >= 0) then {
    _verbPhrase = "ambush and destroy the enemy supply convoy";
    _objectiveText = "The primary objective is the cargo truck. Its destruction will cripple enemy logistics.";
};
if (_id find "barrack" >= 0) then {
    _verbPhrase = "clear the enemy barracks and eliminate all hostile personnel";
    _objectiveText = "Wipe out all enemy combatants in the area. No prisoners – complete liquidation required.";
};
if (_id find "roadblock" >= 0) then {
    _verbPhrase = "destroy the enemy roadblock";
    _objectiveText = "Neutralize all guards manning the checkpoint. Obstacles must be cleared to restore supply lines.";
};

// Fallback jika tidak ada yang cocok
if (_verbPhrase == "") then {
    _verbPhrase = "engage and destroy enemy forces";
    _objectiveText = "Eliminate all hostile forces in the area of operations.";
};

// ================================================================
// 4. PERKIRAAN JUMLAH MUSUH
// ================================================================
private _enemyCountText = switch (toUpper _difficulty) do {
    case "EASY":   { "5 to 10 lightly armed personnel" };
    case "MEDIUM": { "10 to 15 well-armed soldiers" };
    case "HARD":   { "18 to 25 heavily armed troops, possibly including elite mercenaries" };
    default        { "an unknown number of hostiles" };
};

// ================================================================
// 5. KENDARAAN MUSUH
// ================================================================
private _vehicleText = switch (true) do {
    case (_target in ["USA","US"]):    { "US military vehicles" };
    case (_target in ["RUSSIA","RU"]): { "Russian armored vehicles" };
    case (_target == "CULT"):          { "technicals and civilian trucks" };
    case (_target == "MERC_ENEMY"):    { "various armed vehicles" };
    default                            { "enemy transport vehicles" };
};

// ================================================================
// 6. ALASAN STRATEGIS (dipilih acak)
// ================================================================
private _strategicReasons = [];

if (_id find "barrack" >= 0 || _id find "roadblock" >= 0) then {
    _strategicReasons = [
        "This location serves as a critical staging point for enemy operations in the region.",
        "Intel suggests this base houses a weapons cache vital to the enemy's offensive capability.",
        "Eliminating this outpost will significantly disrupt enemy supply lines and communication.",
        "The enemy uses this position to coordinate attacks on allied patrols in the area."
    ];
};
if (_id find "convoy" >= 0) then {
    _strategicReasons = [
        "This convoy is transporting essential ammunition and fuel. Its destruction will delay enemy reinforcements.",
        "Intel indicates the cargo includes advanced weaponry intended for front-line units. Stopping it is a high priority.",
        "The supplies carried by this convoy are the lifeblood of the enemy's northern offensive.",
        "Intercepting this shipment will leave enemy forces in the sector dangerously low on provisions."
    ];
};
if (_id find "kill" >= 0) then {
    _strategicReasons = [
        "The target is a key commander whose removal will sow confusion and disrupt enemy command structure.",
        "This HVT is responsible for orchestrating attacks against allied forces. Neutralizing him is critical for regional stability.",
        "Eliminating this high-ranking figure will deliver a decisive psychological blow to the enemy.",
        "The target possesses valuable intelligence – ensure no escape."
    ];
};

private _strategicText = selectRandom _strategicReasons;

// ================================================================
// 7. BATAS WAKTU & MALAM
// ================================================================
private _timeText = format ["Time limit: %1 hour(s).", _timeLimit];
private _nightText = if (_nightOnly == "YES") then {
    "<br/>This operation must be carried out under the cover of darkness."
} else {
    ""
};

// ================================================================
// 8. REWARD LINE
// ================================================================
private _rewardLine = format [
    "<br/><br/>────────────────────────────<br/><t color='#FFD700'>REWARD: $%1 - $%2</t>   |   <t color='#00BFFF'>REPUTATION: +%3</t>",
    _rewardRange select 0,
    _rewardRange select 1,
    _repReward
];

// ================================================================
// 9. RAKIT TEKS FINAL
// ================================================================
private _finalText = format [
    "<t size='0.95' color='#CCCCCC'>" +
    "<t color='#FFA500'>BRIEFING FROM %1</t><br/><br/>" +
    "We have received a direct tasking from <t color='#FFD700'>%1</t>.<br/>" +
    "Our objective is to <t color='#00FF00'>%2</t> against <t color='#FF4444'>%3</t>.<br/><br/>" +
    "<t color='#00BFFF'>INTELLIGENCE ASSESSMENT:</t><br/>" +
    "Enemy strength estimated at <t color='#FFA500'>%4</t>.<br/>" +
    "The enemy is known to deploy <t color='#FFA500'>%5</t> in support of their operations.<br/><br/>" +
    "<t color='#FFD700'>STRATEGIC IMPORTANCE:</t><br/>" +
    "%6<br/><br/>" +
    "<t color='#00BFFF'>MISSION PARAMETERS:</t><br/>" +
    "%7. %8" +
    "%9" +
    "%10" +
    "</t>",
    _giverName,
    _verbPhrase,
    _targetName,
    _enemyCountText,
    _vehicleText,
    _strategicText,
    _timeText,
    _objectiveText,
    _nightText,
    _rewardLine
];

_finalText