include("CQUICommon.lua");
-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_AddCityStateRow = AddCityStateRow;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
local COLOR_ICON_BONUS_OFF:number = UI.GetColorValueFromHexLiteral(0xff606060);
local ICON_NAMES = {"%[ICON_TechBoosted%] ", "%[ICON_CivicBoosted%] ", "%[ICON_TradeRoute%] ", "%[ICON_Barbarian%] "};
local CITYSTATEBASE_DEFAULT_SIZEY :number = 48;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_InlineCityStateQuest         = true;
local CQUI_InlineCityStateQuestFontSize = 10;

-- ===========================================================================
function CQUI_OnSettingsInitialized()
    -- print_debug("CityStates_CQUI: CQUI_OnSettingsInitialized ENTRY")
    CQUI_InlineCityStateQuest         = GameConfiguration.GetValue("CQUI_InlineCityStateQuest");
    CQUI_InlineCityStateQuestFontSize = GameConfiguration.GetValue("CQUI_InlineCityStateQuestFontSize");
end

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- print_debug("CityStates_CQUI: CQUI_OnSettingsUpdate ENTRY")
    CQUI_OnSettingsInitialized();
    Refresh();
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

    for _,kQuest in pairs( kCityState.Quests ) do
        anyQuests = true;
        questString = kQuest.Name;
    end

    -- get city state quest, ensure the CQUI-added QuestRow is valid (in case another mod loads its XML but does not replace this lua)
    if (IsCQUI_InlineCityStateQuestEnabled() and kInst.QuestRow ~= nil) then
        kInst.QuestIcon:SetHide(true);

        if (anyQuests) then
            -- Adjust the size of the container based on the font size of the Inline City State Quest
            kInst.CityStateBase:SetSizeY(CITYSTATEBASE_DEFAULT_SIZEY + CQUI_InlineCityStateQuestFontSize - 2);
            kInst.QuestRow:SetHide(false);
            kInst.CityStateQuest:SetFontSize(CQUI_InlineCityStateQuestFontSize);
            kInst.CityStateQuest:SetString(CQUI_RemoveQuestIconsFromString(questString));
            kInst.CityStateQuest:SetColor(kCityState.ColorSecondary);
        else
            kInst.CityStateBase:SetSizeY(CITYSTATEBASE_DEFAULT_SIZEY);
            kInst.QuestRow:SetHide(true);
        end
    else
        kInst.CityStateBase:SetSizeY(CITYSTATEBASE_DEFAULT_SIZEY);
        if (kInst.QuestRow ~= nil) then
            -- Reference only if valid (another mod may have replaced the XML but not the lua)
            kInst.QuestRow:SetHide(true);
        end

        -- SetHide is TRUE if anyQuests is FALSE
        kInst.QuestIcon:SetHide(not anyQuests);
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

        if (#envoyTable > 1 and kInst.SecondHighestName ~= nil) then
            -- Show 2nd place if there is one (recall Lua tables/arrays start at index 1)
            -- The check on kInst.SecondHighestName is for cases where another mod replaces the XML, but not the citystates lua file
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
function Initialize_CityStates_CQUI()
    print_debug("citystates_CQUI: Initialize_CQUI CQUI CityStates (Common File)")
    -- CQUI related events
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsInitialized);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
end
Initialize_CityStates_CQUI();
