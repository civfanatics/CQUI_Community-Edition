/*
    ╔════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                   CQUI Default settings                                    ║
    ╠════════════════════════════════════════════════════════════════════════════════════════════╣
    ║ Created by LordYanaek for CQUI mod by chaorace.                                            ║
    ║ These are the settings loaded by DEFAULT in CQUI.                                          ║
    ║                                                                                            ║
    ║ !!! Attention: Don't write your custom settings in the original copy of this file !!!      ║
    ║                                                                                            ║
    ║ This file is where all default settings are stored, all changes to this file are lost      ║
    ║ whenever updating to a new CQUI version (particularly if using the Steam Workshop version).║
    ║                                                                                            ║
    ║ To change default settings permanently without the risk of losing them, create a           ║
    ║ copy of this file named "cqui_settings_local.sql" and make your changes there.             ║
    ║ The "cqui_settings_local.sql" file does not need to be a perfect copy and will work as     ║
    ║ long as it's valid SQL.                                                                    ║
    ╚════════════════════════════════════════════════════════════════════════════════════════════╝
*/


/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Checkbox settings                                       │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the default state of the CQUI configuration checkboxes.              │
    │Valid values are 0 (disabled) or 1 (enabled). Don't change the names or the first line!     │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Settings -- Don't touch this line!
    VALUES  ("CQUI_AlwaysOpenTechTrees", 0), -- Always opens the full tech trees instead of the civic/research picker panels
        ("CQUI_AutoapplyArchaeologistLens", 1), -- Automatically activates the archaeologist lens when selecting a archaeologist
        ("CQUI_AutoapplyBuilderLens", 1), -- Automatically activates the builder lens when selecting a builder
        ("CQUI_AutoapplyScoutLens", 1), -- Automatically activates the scout lens when selecting a scout
        ("CQUI_AutoExpandUnitActions", 1), -- Automatically reveals the secondary unit actions normally hidden inside an expando
        ("CQUI_RelocateCityStrike", 1), -- Relocate the City Strike button to above the city health and defense bars
        ("CQUI_RelocateEncampmentStrike", 0), -- Relocate the Encampment Strike button to above the encampment health and defense bars
        ("CQUI_ProductionQueue", 1), -- A production queue appears next to the production panel, allowing multiple constructions to be queued at once
        ("CQUI_ShowCultureGrowth", 1), -- Shows cultural growth overlay in cityview
        ("CQUI_ShowPolicyReminder", 1),
        ("CQUI_AutoRepeatTechCivic", 0), -- Automatically repeat techs and civics if repeatable (Only Future Tech/Civic in base game)
        ("CQUI_ShowLuxuries", 1), -- Luxury resources will show in the top-bar next to strategic resources
        ("CQUI_ShowUnitPaths", 1), -- Shows unit paths on hover and selection
        ("CQUI_ShowYieldsOnCityHover", 1), -- Shows city management info like citizens, tile yields, and tile growth on hover
        ("CQUI_Smartbanner", 1), -- Additional informations such as districts will show in the city banner
        ("CQUI_Smartbanner_UnlockedCitizen", 0), -- Shows if city have Unmanaged citizens in the banner
        ("CQUI_Smartbanner_Districts", 1), -- Shows city districts in the banner
        ("CQUI_Smartbanner_Population", 1), -- Shows turns to city population growth in the banner
        ("CQUI_Smartbanner_Cultural", 1), -- Shows turns to city cultural growth in the banner
        ("CQUI_Smartbanner_DistrictsAvailable", 1), -- Shows that districts are available to be built
        ("CQUI_SmartWorkIcon", 1), -- Applies a different size/transparency to citizen icons if they're currently being worked
        ("CQUI_ToggleYieldsOnLoad", 1), -- Toggles yields immediately on load
        ('CQUI_ShowCitizenIconsOnCityHover', 0), -- Shows citizen icons when hovering over city banner
        ('CQUI_ShowCityManageAreaOnCityHover', 1), -- Shows citizen management area when hovering over city banner
        ('CQUI_ShowCityManageOverLenses', 0), -- Shows citizen management over other lenses applied in city view (religion, loyalty, and power)
        ('CQUI_TraderAddDivider', 1), -- Adds a divider between groups in TradeOverview panel
        ('CQUI_TraderShowSortOrder', 0), -- Adds a divider between groups in TradeOverview panel
        ('CQUI_ShowProductionRecommendations', 0), -- Shows the advisor recommendation in the city produciton panel
        ('CQUI_ShowTechCivicRecommendations', 1), -- Shows the advisor recommendation in the techs/civics tree/panel
        ('CQUI_ShowSuzerainLabelInCityStateBanner', 1), -- Show the Icon of the Suzerain Civilization in the CityState Banner
        ('CQUI_ShowWarIconInCityStateBanner', 1), -- When at war with a City State, show the War Icon in the banner of that City State
        ('CQUI_ShowImprovementsRecommendations', 0), -- Shows the advisor recommendation for the builder improvements
        ('CQUI_InlineCityStateQuest', 1), -- Show city state quest below city state name instead of a tooltip
        ('CQUI_ShowCityDetailAdvisor', 0), -- Shows the advisor recommendation in the city detail panel
        ('CQUI_ReligionLensUnitFlagStyle', 1), -- When Religion Lens is on, update Flags of non-religious units.  Values of 0 (Solid, unmodified gae), 1 (Transparent), or 2 (Hidden) are acceptable
        ('CQUI_BuilderLensDisableNothingPlot', 1), -- When enabled, do not show the "nothing to do here" plot with the Builder Lens
        ('CQUI_BuilderLensDisableDangerousPlot', 1), -- When enabled, do not show "dangerous / enemy near" plot with the Builder Lens
        ('CQUI_AutoapplyScoutLensExtra', 1), -- When enabled, auto-apply the Scout lens for every military unit
        ('CQUI_AutoapplyEngineerLens', 1), -- When enabled, auto-apply the Routes lens when the Military Engineer is selected
        ('CQUI_AutoapplyReligionLensInCity', 1), -- When enabled, auto-apply the Religion lens when the Religion tab is selected in the city view
        ('CQUI_AutoapplyLoyaltyLensInCity', 1), -- When enabled, auto-apply the Loyalty lens when the Loyalty tab is selected in the city view
        ('CQUI_AutoapplyPowerLensInCity', 1), -- When enabled, auto-apply the Power lens when the Power tab is selected in the city view
        ('CQUI_ShowDebugPrint', 0); -- Shows print in the console

/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Combobox settings                                       │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the default state of the CQUI configuration comboboxes.              │
    │Different values can be used depending on individual settings.                              │
    │Don't change the names of the settings or the first line!                                   │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Settings -- Don't touch this line!
    VALUES  ("CQUI_BindingsMode", 1), -- Set of keybindings used │ 0=Civ6 default │ 1=keybinds from Civ5 |
        ("CQUI_ResourceDimmingStyle", 1), -- Affects the way resource icons look when they have been improved  | 0=No Change | 1=Transparent | 2=Hidden |
        ('CQUI_ShowSuzerainInCityStateBanner', 1); -- Show the Icon of the Suzerain Civilization in the CityState Banner | 0 = No Suzerain | 1 = Civ Icon | 2 = Leader Icon

/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Slider settings                                         │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the default value of the CQUI configuration sliders.                 │
    │Different values can be used depending on individual settings.                              │
    │Don't change the names of the settings or the first line!                                   │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Settings -- Don't touch this line!
    VALUES  ("CQUI_SmartWorkIconSize", 64), -- Size used for "smart" work icons. This size is applied to work icons that are currently locked if the smart work icon option is enabled. Recommended values fall between 48 and 128, though any positive multiple of 8 could work (non-multiples are rounded down)
        ("CQUI_SmartWorkIconAlpha", 40), -- Transparency percent used for "smart" work icons. This alpha is applied to work icons that are currently locked if the smart work icon option is enabled. Recommended values fall between 10 and 100, though any value between 0 and 100 could work
        ("CQUI_WorkIconSize", 64), -- Size used for work icons. Applies to all icons that aren't flagged using the "smart" work icon feature. Recommended values fall between 48 and 128, though any positive multiple of 8 could work (non-multiples are rounded down)
        ("CQUI_WorkIconAlpha", 80), -- Size used for work icons. Applies to all icons that aren't flagged using the "smart" work icon feature. Recommended values fall between 10 and 100, though any value between 0 and 100 could work
        ('CQUI_InlineCityStateQuestFontSize', 10); -- Font size of the inline City State Quest font

/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Popup settings                                          │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the default state of the popup visuals / audio checkboxes.           │
    │Valid values are 0 (disabled) or 1 (enabled). Don't change the names or the first line!     │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Settings -- Don't touch this line!
    VALUES  ("CQUI_MultiplayerPopups", 0), -- Allow popups and popup movies to be displayed in multiplayer
        ("CQUI_BoostUnlockedPopupVisual", 1), -- Popups will be displayed when you boost a tech or civic (this is the normal behavior for the unmoded game)
        ("CQUI_EraCompletePopupVisual", 1), -- Popups will be displayed when entering a new era (this is the normal behavior for the unmoded game)
        ("CQUI_HeroDiscoveredPopupVisual", 1), -- Popups will be displayed when discovering a Hero (this is the normal behavior for the unmoded game)
        ("CQUI_HeroExpiredPopupVisual", 1), -- Popups will be displayed when a Hero expires (this is the normal behavior for the unmoded game)
        ("CQUI_HistoricMomentsPopupVisual", 1), -- Popups will be displayed when completing a historic moment (this is the normal behavior for the unmoded game)
        ("CQUI_NaturalDisasterPopupVisual", 1), -- Diaster movies will be played when a disaster occurs (this is the normal behavior for the unmoded game)
        ("CQUI_NaturalWonderPopupVisual", 1), -- Wonder movies will be displayed when you discover a natural wonder (this is the normal behavior for the unmoded game)
        ("CQUI_NaturalWonderPopupAudio", 1), -- Wonder quote audio will be played when you discover a natural wonder (this is the normal behavior for the unmoded game)
        ("CQUI_ProjectBuiltPopupVisual", 1), -- Popup movies will be displayed when you complete a space race project (this is the normal behavior for the unmoded game)
        ("CQUI_RockBandMoviePopupVisual", 1), -- Popup movies will be displayed during a rock band performance (this is the normal behavior for the unmoded game)
        ("CQUI_SecretSocietyDiscoveredPopupVisual", 1), -- Popups will be displayed when discovering a Secret Society (this is the normal behavior for the unmoded game)
        ("CQUI_SecretSocietyJoinedPopupVisual", 1), -- Popups will be displayed when joining a Secret Society (this is the normal behavior for the unmoded game)
        ("CQUI_TechCivicCompletedPopupVisual", 1), -- Popups will be displayed when you discover a new tech or civic (this is the normal behavior for the unmoded game)
        ("CQUI_TechCivicCompletedPopupAudio", 1), -- Automatically play the voiceovers when you discover a new tech or civic (this is the normal behavior for the unmoded game)
        ("CQUI_UnitCapturedPopupVisual", 1), -- Popups will be displayed when you capture a unit or your unit is captured (this is the normal behavior for the unmoded game)
        ("CQUI_WonderBuiltPopupVisual", 1), -- Wonder movies will be displayed when you complete a wonder (this is the normal behavior for the unmoded game)
        ("CQUI_WonderBuiltPopupAudio", 1); -- Wonder quote audio will be played when you complete a wonder (this is the normal behavior for the unmoded game)

/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Gossip settings                                         │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the default state of the Gossip message checkboxes                   │
    │Valid values are 0 (disabled) or 1 (enabled). Don't change the names or the first line!     │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Settings -- Don't touch this line!
    VALUES  ("CQUI_TrimGossip", 1), --Trims the source from the start of gossip messages
        --Values controlling individual gossip messages
        ("CQUI_LOC_GOSSIP_AGENDA_KUDOS", 0),
        ("CQUI_LOC_GOSSIP_AGENDA_WARNING", 1),
        ("CQUI_LOC_GOSSIP_ALLIED", 1),
        ("CQUI_LOC_GOSSIP_ANARCHY_BEGINS", 1),
        ("CQUI_LOC_GOSSIP_ARTIFACT_EXTRACTED", 0),
        ("CQUI_LOC_GOSSIP_BARBARIAN_INVASION_STARTED", 1),
        ("CQUI_LOC_GOSSIP_BARBARIAN_RAID_STARTED", 1),
        ("CQUI_LOC_GOSSIP_BEACH_RESORT_CREATED", 0),
        ("CQUI_LOC_GOSSIP_CHANGE_GOVERNMENT", 1),
        ("CQUI_LOC_GOSSIP_CITY_BESIEGED", 1),
        ("CQUI_LOC_GOSSIP_CITY_LIBERATED", 1),
        ("CQUI_LOC_GOSSIP_CITY_RAZED", 1),
        ("CQUI_LOC_GOSSIP_CLEAR_CAMP", 0),
        ("CQUI_LOC_GOSSIP_CITY_STATE_INFLUENCE", 1),
        ("CQUI_LOC_GOSSIP_CONQUER_CITY", 1),
        ("CQUI_LOC_GOSSIP_CONQUER_CAPITAL_CITY", 1),
        ("CQUI_LOC_GOSSIP_CONSTRUCT_BUILDING", 1),
        ("CQUI_LOC_GOSSIP_CONSTRUCT_DISTRICT", 1),
        ("CQUI_LOC_GOSSIP_CREATE_PANTHEON", 1),
        ("CQUI_LOC_GOSSIP_CULTURVATE_CIVIC", 1), --Civic researched
        ("CQUI_LOC_GOSSIP_DECLARED_FRIENDSHIP", 1),
        ("CQUI_LOC_GOSSIP_DELEGATION", 0),
        ("CQUI_LOC_GOSSIP_DENOUNCED", 1),
        ("CQUI_LOC_GOSSIP_EMBASSY", 0),
        ("CQUI_LOC_GOSSIP_ERA_CHANGED", 1),
        ("CQUI_LOC_GOSSIP_FIND_NATURAL_WONDER", 0),
        ("CQUI_LOC_GOSSIP_FOUND_CITY", 1),
        ("CQUI_LOC_GOSSIP_FOUND_RELIGION", 1),
        ("CQUI_LOC_GOSSIP_GREATPERSON_CREATED", 1),
        ("CQUI_LOC_GOSSIP_LAUNCHING_ATTACK", 1),
        ("CQUI_LOC_GOSSIP_WAR_PREPARATION", 1),
        ("CQUI_LOC_GOSSIP_INQUISITION_LAUNCHED", 0),
        ("CQUI_LOC_GOSSIP_LAND_UNIT_LEVEL", 0),
        ("CQUI_LOC_GOSSIP_MAKE_DOW", 1),
        ("CQUI_LOC_GOSSIP_NATIONAL_PARK_CREATED", 0),
        ("CQUI_LOC_GOSSIP_NAVAL_UNIT_LEVEL", 0),
        ("CQUI_LOC_GOSSIP_NEW_RELIGIOUS_MAJORITY", 1),
        ("CQUI_LOC_GOSSIP_PILLAGE", 0),
        ("CQUI_LOC_GOSSIP_POLICY_ENACTED", 1),
        ("CQUI_LOC_GOSSIP_RECEIVE_DOW", 1),
        ("CQUI_LOC_GOSSIP_RELIC_RECEIVED", 0),
        ("CQUI_LOC_GOSSIP_RESEARCH_AGREEMENT", 0),
        ("CQUI_LOC_GOSSIP_RESEARCH_TECH", 1),
        ("CQUI_LOC_GOSSIP_SPY_CAPTURED", 1),
        ("CQUI_LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTED", 0),
        ("CQUI_LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTED", 0),
        ("CQUI_LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_TRADE_DEAL", 0),
        ("CQUI_LOC_GOSSIP_TRADE_RENEGE", 0),
        ("CQUI_LOC_GOSSIP_TRAIN_SETTLER", 1),
        ("CQUI_LOC_GOSSIP_TRAIN_UNIT", 1),
        ("CQUI_LOC_GOSSIP_TRAIN_UNIQUE_UNIT", 1),
        ("CQUI_LOC_GOSSIP_PROJECT_STARTED", 0),
        ("CQUI_LOC_GOSSIP_SPACE_RACE_PROJECT_COMPLETED", 1),
        ("CQUI_LOC_GOSSIP_START_VICTORY_STRATEGY", 1),
        ("CQUI_LOC_GOSSIP_STOP_VICTORY_STRATEGY", 1),
        ("CQUI_LOC_GOSSIP_WMD_BUILT", 1),
        ("CQUI_LOC_GOSSIP_WMD_STRIKE", 1),
        ("CQUI_LOC_GOSSIP_WONDER_STARTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_FOMENT_UNREST_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_FOMENT_UNREST_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_NEUTRALIZE_GOVERNOR_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_DAM_BREACHED_DETECTED", 1),
        ("CQUI_LOC_GOSSIP_SPY_DAM_BREACHED_UNDETECTED", 1),
        ("CQUI_LOC_GOSSIP_ROCK_CONCERT", 1),
        ("CQUI_LOC_GOSSIP_POWERED_CITY", 1),
        ("CQUI_LOC_GOSSIP_RANDOM_EVENT", 1);

/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Key Binding Information                                 │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the key bindings used when CQUI_BindingsMode is not 0                │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Bindings -- Don't touch this line!
    VALUES
        ("CANCEL_COMMAND", "VK_BACK", "LOC_CQUI_CANCEL_COMMAND"),
        ("REMOVE_HARVEST", "Alt+C", "LOC_CQUI_REMOVE_HARVEST"),
        ("BUILD_FISHING", "F", "LOC_CQUI_BUILD_FISHING"),
        ("BUILD_FORT", "F", "LOC_CQUI_BUILD_FORT"),
        ("BUILD_CAMP", "H", "LOC_CQUI_BUILD_CAMP"),
        ("BUILD_FARM", "I", "LOC_CQUI_BUILD_FARM"),
        ("BUILD_MILL", "L", "LOC_CQUI_BUILD_MILL"),
        ("BUILD_OIL", "O", "LOC_CQUI_BUILD_OIL"),
        ("BUILD_PASTURE", "P", "LOC_CQUI_BUILD_PASTURE"),
        ("BUILD_PLANTATION", "P", "LOC_CQUI_BUILD_PLANTATION"),
        ("BUILD_QUARRY", "Q", "LOC_CQUI_BUILD_QUARRY"),
        ("BUILD_RAILROAD", "R", "LOC_CQUI_BUILD_RAILROAD"),
        ("BUILD_MINE", "N", "LOC_CQUI_BUILD_MINE"),
        ("NUKE", "N", "LOC_CQUI_NUKE"),
        ("THERMO_NUKE", "Alt+N", "LOC_CQUI_THERMO_NUKE"),
        ("SPREAD_RELIGION", "R", "LOC_CQUI_SPREAD_RELIGION"),
        ("REMOVE_HERESY", "R", "LOC_CQUI_REMOVE_HERESY"),
        ("REST_HEAL", "H", "LOC_CQUI_REST_HEAL"),
        ("REBASE", "Alt+R", "LOC_CQUI_REBASE"),
        ("PLACE_PIN", "Shift+P", "LOC_CQUI_PLACE_PIN");

/*
    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    Notification settings                                   │
    ├────────────────────────────────────────────────────────────────────────────────────────────┤
    │These settings control the default state of the Notification checkboxes                     │
    │Valid values are 0 (disabled) or 1 (enabled). Don't change the names or the first line!     │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
*/

INSERT OR REPLACE INTO CQUI_Settings -- Don't touch this line!
    VALUES  ("CQUI_NotificationGoodyHut", 1), -- Notification - goody hut reward
        --('CQUI_NotificationTradeDeal', 1), -- Notification - trade deal expired (reserved)
        --('CQUI_NotificationPopulation', 0), -- Notification - population growth (reserved)
        --('CQUI_NotificationCityBorder', 0), -- Notification - city border growth (reserved)
        ("CQUI_NOTIFICATION_CITY_LOW_AMENITIES", 1),
        ("CQUI_NOTIFICATION_HOUSING_PREVENTING_GROWTH", 1),
        ("CQUI_NOTIFICATION_CITY_FOOD_FOCUS", 1),
        ("CQUI_NOTIFICATION_CITY_UNPOWERED", 1);