include( "CQUICommon.lua" );
include( "CityStates" );
-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_AddCityStateRow = AddCityStateRow;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
local COLOR_ICON_BONUS_OFF:number = UI.GetColorValueFromHexLiteral(0xff606060);
local ICON_NAMES = {"%[ICON_TechBoosted%] ", "%[ICON_CivicBoosted%] ", "%[ICON_TradeRoute%] ", "%[ICON_Barbarian%] "};
local OFFSET_0 :number = 0;
local NEW_ROW_OFFSET_Y :number = -2;
local BONUS_IMAGE_ORIGINAL_SIZE_X :number = 29;
local BONUS_IMAGE_ORIGINAL_SIZE_Y :number = 42;
local BONUS_IMAGE_NEW_SIZE_X :number = 37;
local BONUS_IMAGE_NEW_SIZE_Y :number = 50;
local SUZERAIN_STATUS_ORIGINAL_SIZE_X :number = 110;
local SUZERAIN_STATUS_ORIGINAL_SIZE_Y :number = 42;
local SUZERAIN_STATUS_NEW_SIZE_X :number = 113;
local SUZERAIN_STATUS_NEW_SIZE_Y :number = 50;
local SUZERAIN_STATUS_EXTRA_OFFSET_X :number = 26;
local BONUS_IMAGE_1_ORIGINAL_OFFSET_X :number = 256;
local BONUS_IMAGE_1_ORIGINAL_OFFSET_STEP_X :number = 30;
local BONUS_IMAGE_1_NEW_OFFSET_STEP_X :number = 38;
local ORIGINAL_DIPLOMACY_PIP_OFFSET_Y :number = -6;
local NEW_DIPLOMACY_PIP_OFFSET_Y :number = -2;
local ORIGINAL_NAME_BUTTON_OFFSET_Y :number = 9;
local NEW_NAME_BUTTON_OFFSET_Y :number = 11;
local ORIGINAL_CITY_STATE_BASE_SIZE_Y :number = 48;
local NEW_CITY_STATE_BASE_SIZE_Y :number = 56;
local ORIGINAL_AMBASSADOR_OFFSET_X :number = 4;
local NEW_AMBASSADOR_OFFSET_X :number = 8;
local ORIGINAL_AMBASSADOR_ICON_SIZE :number = 32;
local NEW_AMBASSADOR_ICON_SIZE :number = 30;
local NORMAL_ENVOY_LABEL_OFFSET_X :number = 4;
local NEW_ENVOY_LABEL_OFFSET_X :number = 28;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_InlineCityStateQuest         = true;

-- ===========================================================================
function CQUI_OnSettingsInitialized()
    -- print_debug("CityStates_CQUI: CQUI_OnSettingsInitialized ENTRY")
    CQUI_InlineCityStateQuest      = GameConfiguration.GetValue("CQUI_InlineCityStateQuest");
end

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- print_debug("CityStates_CQUI: CQUI_OnSettingsUpdate ENTRY")
    CQUI_OnSettingsInitialized();
    Refresh();
end

-- ===========================================================================
function CQUI_RestoreOriginalPanel( kInst:table )
    -- revert all changes done to the xml
    kInst.CityStateBase:SetSizeY(ORIGINAL_CITY_STATE_BASE_SIZE_Y);
    kInst.DiplomacyPip:SetOffsetY(ORIGINAL_DIPLOMACY_PIP_OFFSET_Y);
    kInst.Icon:SetOffsetY(OFFSET_0);
    kInst.NameButton:SetOffsetY(ORIGINAL_NAME_BUTTON_OFFSET_Y);
    kInst.Envoy:SetOffsetY(OFFSET_0);
    kInst.BonusImage1:SetSizeVal(BONUS_IMAGE_ORIGINAL_SIZE_X, BONUS_IMAGE_ORIGINAL_SIZE_Y);
    kInst.BonusImage3:SetOffsetX(BONUS_IMAGE_1_ORIGINAL_OFFSET_X + BONUS_IMAGE_1_ORIGINAL_OFFSET_STEP_X);
    kInst.BonusImage3:SetSizeVal(BONUS_IMAGE_ORIGINAL_SIZE_X, BONUS_IMAGE_ORIGINAL_SIZE_Y);
    kInst.BonusImage6:SetOffsetX(BONUS_IMAGE_1_ORIGINAL_OFFSET_X + BONUS_IMAGE_1_ORIGINAL_OFFSET_STEP_X * 2);
    kInst.BonusImage6:SetSizeVal(BONUS_IMAGE_ORIGINAL_SIZE_X, BONUS_IMAGE_ORIGINAL_SIZE_Y);
    kInst.SuzerainStatus:SetOffsetX(BONUS_IMAGE_1_ORIGINAL_OFFSET_X + BONUS_IMAGE_1_ORIGINAL_OFFSET_STEP_X * 3);
    kInst.SuzerainStatus:SetSizeVal(SUZERAIN_STATUS_ORIGINAL_SIZE_X, SUZERAIN_STATUS_ORIGINAL_SIZE_Y);
    kInst.BonusTextSuzerain:SetOffsetX(NORMAL_ENVOY_LABEL_OFFSET_X);
    kInst.SecondHighestEnvoys:SetOffsetX(NORMAL_ENVOY_LABEL_OFFSET_X);
    kInst.AmbassadorButton:SetOffsetX(ORIGINAL_AMBASSADOR_OFFSET_X);
    kInst.AmbassadorButton:SetSizeVal(ORIGINAL_AMBASSADOR_ICON_SIZE, ORIGINAL_AMBASSADOR_ICON_SIZE);
    kInst.QuestRow:SetHide(true);
end

-- ===========================================================================
function CQUI_ChangeOriginalPanel( kInst:table )
    -- enable all changes done to the xml
    kInst.CityStateBase:SetSizeY(NEW_CITY_STATE_BASE_SIZE_Y);
    kInst.DiplomacyPip:SetOffsetY(NEW_DIPLOMACY_PIP_OFFSET_Y);
    kInst.Icon:SetOffsetY(NEW_ROW_OFFSET_Y);
    kInst.NameButton:SetOffsetY(NEW_NAME_BUTTON_OFFSET_Y);
    kInst.Envoy:SetOffsetY(NEW_ROW_OFFSET_Y);
    kInst.BonusImage1:SetSizeVal(BONUS_IMAGE_NEW_SIZE_X, BONUS_IMAGE_NEW_SIZE_Y);
    kInst.BonusImage3:SetOffsetX(BONUS_IMAGE_1_ORIGINAL_OFFSET_X + BONUS_IMAGE_1_NEW_OFFSET_STEP_X);
    kInst.BonusImage3:SetSizeVal(BONUS_IMAGE_NEW_SIZE_X, BONUS_IMAGE_NEW_SIZE_Y);
    kInst.BonusImage6:SetOffsetX(BONUS_IMAGE_1_ORIGINAL_OFFSET_X + BONUS_IMAGE_1_NEW_OFFSET_STEP_X * 2);
    kInst.BonusImage6:SetSizeVal(BONUS_IMAGE_NEW_SIZE_X, BONUS_IMAGE_NEW_SIZE_Y);
    kInst.SuzerainStatus:SetOffsetX(BONUS_IMAGE_1_ORIGINAL_OFFSET_X + BONUS_IMAGE_1_NEW_OFFSET_STEP_X * 3);
    kInst.SuzerainStatus:SetSizeVal(SUZERAIN_STATUS_NEW_SIZE_X, SUZERAIN_STATUS_NEW_SIZE_Y);
    kInst.BonusTextSuzerain:SetOffsetX(NORMAL_ENVOY_LABEL_OFFSET_X);
    kInst.SecondHighestEnvoys:SetOffsetX(NORMAL_ENVOY_LABEL_OFFSET_X);
    kInst.AmbassadorButton:SetOffsetX(NEW_AMBASSADOR_OFFSET_X);
    kInst.AmbassadorButton:SetSizeVal(NEW_AMBASSADOR_ICON_SIZE,NEW_AMBASSADOR_ICON_SIZE);
end

-- ===========================================================================
function CQUI_RemoveQuestIconsFromString( inStr:string )
    local lookupStr :string = inStr;
    local outStr :string = lookupStr;
    for _,iconName in ipairs(ICON_NAMES) do
        if (string.find(lookupStr, iconName)) then
            outStr = string.gsub(lookupStr, iconName, "");
        end
    end
    return outStr;
end

-- ===========================================================================
--  CQUI Function Extensions
-- ===========================================================================
function AddCityStateRow( kCityState:table )
    local kInst :table = BASE_CQUI_AddCityStateRow(kCityState);
	local anyQuests :boolean = false;
    local questString :string;
	
    -- get city state quest
    if (IsCQUI_InlineCityStateQuestEnabled()) then
        CQUI_ChangeOriginalPanel(kInst);
        kInst.QuestIcon:SetHide(true);
		
        for _,kQuest in pairs( kCityState.Quests ) do
            anyQuests = true;
            questString = CQUI_RemoveQuestIconsFromString(kQuest.Name);
        end
        if anyQuests then
            kInst.QuestRow:SetHide(false);
            kInst.CityStateQuest:SetString(questString);
            kInst.CityStateQuest:SetColor(kCityState.ColorSecondary);
        else
            CQUI_RestoreOriginalPanel(kInst);      
            kInst.SuzerainStatus:SetSizeVal(SUZERAIN_STATUS_ORIGINAL_SIZE_X + SUZERAIN_STATUS_EXTRA_OFFSET_X, SUZERAIN_STATUS_ORIGINAL_SIZE_Y);
            kInst.BonusTextSuzerain:SetOffsetX(NEW_ENVOY_LABEL_OFFSET_X);
            kInst.SecondHighestEnvoys:SetOffsetX(NEW_ENVOY_LABEL_OFFSET_X);
        end
    else
        CQUI_RestoreOriginalPanel(kInst);
        kInst.QuestIcon:SetHide(false);
    end

    -- Determine the 2nd place (or first-place tie), produce text for Tooltip on the EnvoyCount label
    local envoyTable:table = {};
    -- Iterate through all players that have influenced this city state
    local localPlayerID = Game.GetLocalPlayer();
    for iOtherPlayer,influence in pairs(kCityState.Influence) do
        local pLocalPlayer :table   = Players[localPlayerID];
        local civName      :string  = "LOCAL_CITY_STATES_UNKNOWN";
        local isLocalPlayer:boolean = false;
        if (pLocalPlayer ~= nil) then
            local pPlayerConfig :table = PlayerConfigurations[iOtherPlayer];
            if (localPlayerID == iOtherPlayer) then
                civName = Locale.Lookup("LOC_CITY_STATES_YOU") .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. ")";
                isLocalPlayer = true;
            else
                if (pLocalPlayer:GetDiplomacy():HasMet(iOtherPlayer)) then
                    civName = Locale.Lookup(pPlayerConfig:GetPlayerName());
                else
                    civName = Locale.Lookup("LOCAL_CITY_STATES_UNKNOWN")
                end
            end

            table.insert(envoyTable, {Name = civName, EnvoyCount = influence, IsLocalPlayer = isLocalPlayer});
        end
    end

    if (#envoyTable > 0) then
        -- Sort the table by value descending, alphabetically where tied, favoring local player
        table.sort(envoyTable, 
            function(a,b)
                if (a.EnvoyCount == b.EnvoyCount) then
                    if (a.IsLocalPlayer) then
                        return true;
                    elseif (b.IsLocalPlayer) then
                        return false;
                    else
                        return a.Name < b.Name;
                    end
                else
                    return a.EnvoyCount > b.EnvoyCount
                end
            end);

        local envoysToolTip = Locale.Lookup("LOC_CITY_STATES_ENVOYS_SENT")..":";
        for i=1, #envoyTable do
            envoysToolTip = envoysToolTip .. "[NEWLINE] - " .. envoyTable[i].Name .. ": " .. envoyTable[i].EnvoyCount;
        end

        kInst.EnvoyCount:SetToolTipString(envoysToolTip);

        if (#envoyTable > 1 and kInst.SecondHighestLabel ~= nil) then
            -- Show 2nd place if there is one (recall Lua tables/arrays start at index 1)
            local secondPlaceIdx = 2;

            -- is there a tie for first?
            if (envoyTable[1].EnvoyCount == envoyTable[2].EnvoyCount) then
                -- Already sorted above, so this is either local player or the leader appearing first alphabetically
                secondPlaceIdx = 1;
            end

            local secondHighestIsPlayer = envoyTable[secondPlaceIdx].IsLocalPlayer;
            local secondHighestName = envoyTable[secondPlaceIdx].Name;
            local secondHighestEnvoys = envoyTable[secondPlaceIdx].EnvoyCount;

            if (secondHighestIsPlayer) then
                secondHighestName = Locale.Lookup("LOC_CITY_STATES_YOU");
            end

            -- Add changes to the actual UI object placeholders, which are created in the CityStates.xml file
            kInst.SecondHighestLabel:SetColor(secondHighestIsPlayer and kCityState.ColorSecondary or COLOR_ICON_BONUS_OFF);
            -- -- CQUI Note: SecondHighestLabel needs to be localized, but is hard coded for now
            kInst.SecondHighestLabel:SetText("2nd");
            kInst.SecondHighestName:SetColor(secondHighestIsPlayer and kCityState.ColorSecondary or COLOR_ICON_BONUS_OFF);
            kInst.SecondHighestName:SetText(secondHighestName);
            kInst.SecondHighestEnvoys:SetColor(secondHighestIsPlayer and kCityState.ColorSecondary or COLOR_ICON_BONUS_OFF);
            kInst.SecondHighestEnvoys:SetText(secondHighestEnvoys);
        end
    end

    return kInst;
end

-- ===========================================================================
function IsCQUI_InlineCityStateQuestEnabled()
    return CQUI_InlineCityStateQuest;
end

-- ===========================================================================
--  CQUI Initialize Function
-- ===========================================================================
function Initialize_CQUI()
    print_debug("citystates_CQUI: Initialize_CQUI CQUI CityStates (Common File)")
    -- CQUI related events
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
end
Initialize_CQUI();
