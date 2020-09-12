-- Given the issues observed with including this file, print out a confirmation that has loaded to make for easier debugging
print("NotificationPanel_CQUI.lua: File loaded");

local LL = Locale.Lookup;

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnTechBoostActivateNotification = OnTechBoostActivateNotification;
BASE_CQUI_OnCivicBoostActivateNotification = OnCivicBoostActivateNotification;
BASE_CQUI_OnNotificationAdded = OnNotificationAdded;
BASE_CQUI_LateInitialize = LateInitialize;
BASE_CQUI_RegisterHandlers = RegisterHandlers;

-- =======================================================================================
function OnCityRangeAttack( notificationEntry : NotificationType )
    if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then
        local pPlayer = Players[notificationEntry.m_PlayerID];
        if pPlayer ~= nil then
            local attackCity = pPlayer:GetCities():GetFirstRangedAttackCity();
            if (attackCity ~= nil) then
                LuaEvents.CQUI_Strike_Enter();
                LuaEvents.CQUI_CityRangeStrike(Game.GetLocalPlayer(), attackCity:GetID());
            else
                error( "Unable to find selectable attack city while in OnCityRangeAttack()" );
            end
        end
    end
end

-- =======================================================================================
function OnTechBoostActivateNotification( notificationEntry : NotificationType, notificationID : number )
    if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then
        local pNotification :table = GetActiveNotificationFromEntry(notificationEntry, notificationID);
        if pNotification ~= nil then
            local techIndex = pNotification:GetValue("TechIndex");
            local techProgress = pNotification:GetValue("TechProgress");
            local techSource = pNotification:GetValue("TechSource");
            if (techIndex ~= nil and techProgress ~= nil and techSource ~= nil) then
                -- CQUI update all cities real housing when play as India and boosted and researched Sanitation
                if techIndex == GameInfo.Technologies["TECH_SANITATION"].Index then        -- Sanitation
                    if PlayerConfigurations[notificationEntry.m_PlayerID]:GetCivilizationTypeName() == "CIVILIZATION_INDIA" then
                        if Players[notificationEntry.m_PlayerID]:GetTechs():HasTech(techIndex) then
                            LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost(notificationEntry.m_PlayerID);
                        end
                    end
                -- CQUI update all cities real housing when play as Indonesia and boosted and researched Mass Production
                elseif techIndex == GameInfo.Technologies["TECH_MASS_PRODUCTION"].Index then        -- Mass Production
                    if PlayerConfigurations[notificationEntry.m_PlayerID]:GetCivilizationTypeName() == "CIVILIZATION_INDONESIA" then
                        if Players[notificationEntry.m_PlayerID]:GetTechs():HasTech(techIndex) then
                            LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost(notificationEntry.m_PlayerID);
                        end
                    end
                end
            end
        end
    end

    BASE_CQUI_OnTechBoostActivateNotification(notificationEntry, notificationID);
end

-- =======================================================================================
function OnCivicBoostActivateNotification( notificationEntry : NotificationType, notificationID : number )
    if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then
        local pNotification :table = GetActiveNotificationFromEntry(notificationEntry, notificationID);
        if pNotification ~= nil then
            local civicIndex = pNotification:GetValue("CivicIndex");
            local civicProgress = pNotification:GetValue("CivicProgress");
            local civicSource = pNotification:GetValue("CivicSource");
            if (civicIndex ~= nil and civicProgress ~= nil and civicSource ~= nil) then
                -- CQUI update all cities real housing when play as Cree and boosted and researched Civil Service
                if civicIndex == GameInfo.Civics["CIVIC_CIVIL_SERVICE"].Index then -- Civil Service
                    if PlayerConfigurations[notificationEntry.m_PlayerID]:GetCivilizationTypeName() == "CIVILIZATION_CREE" then
                        if Players[notificationEntry.m_PlayerID]:GetCulture():HasCivic(civicIndex) then
                            LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost(notificationEntry.m_PlayerID);
                        end
                    end
                -- CQUI update all cities real housing when play as Scotland and boosted and researched Globalization
                elseif civicIndex == GameInfo.Civics["CIVIC_GLOBALIZATION"].Index then -- Globalization
                    if PlayerConfigurations[notificationEntry.m_PlayerID]:GetCivilizationTypeName() == "CIVILIZATION_SCOTLAND" then
                        if Players[notificationEntry.m_PlayerID]:GetCulture():HasCivic(civicIndex) then
                            LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost(notificationEntry.m_PlayerID);
                        end
                    end
                end
            end
        end
    end

    BASE_CQUI_OnCivicBoostActivateNotification(notificationEntry, notificationID);
end

-- ===========================================================================
function OnNotificationAdded( playerID:number, notificationID:number )
    if (playerID == Game.GetLocalPlayer()) then -- Was it for us?
        local pNotification = NotificationManager.Find( playerID, notificationID );
        -- CQUI: Notification when a City lost tile to a Culture Bomb. We use it to update real housing.
        if pNotification ~= nil and pNotification:GetType() == GameInfo.Notifications["NOTIFICATION_TILE_LOST_CULTURE_BOMB"].Hash then
            local x, y = pNotification:GetLocation();
            LuaEvents.CQUI_CityLostTileToCultureBomb(playerID, x, y);
        end
    end

    BASE_CQUI_OnNotificationAdded(playerID, notificationID);
end

-- ===========================================================================
function LateInitialize()
    BASE_CQUI_LateInitialize();

    Events.NotificationAdded.Remove(BASE_CQUI_OnNotificationAdded);
    Events.NotificationAdded.Add(OnNotificationAdded);
end

-- ===========================================================================
function RegisterHandlers()
    BASE_CQUI_RegisterHandlers();
    
    g_notificationHandlers[NotificationTypes.CIVIC_BOOST].Activate = OnCivicBoostActivateNotification;
    g_notificationHandlers[NotificationTypes.TECH_BOOST].Activate = OnTechBoostActivateNotification;
end


-- CUSTOM NOTIFICATIONS
-- 2020-09-11 Infixo
-- Potential notifications to be added:
-- city border expands
-- populations grows
-- trade deal expired
-- goody hut reward
--[[
USER_DEFINED_1 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_2 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_3 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_4 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_5 - used in CivRoyaleScenario
USER_DEFINED_6 - used in CivRoyaleScenario => Goody Hut
USER_DEFINED_7 - free => City Border Expands
USER_DEFINED_8 - free => Population Grows
USER_DEFINED_9 - free => Trade Deal Expired
--]]


-- NotificationManager.SendNotification(iNotifyPlayer, notificationData.Type, msgString, sumString, pPlot:GetX(), pPlot:GetY());

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	if tTable == nil then print("dshowtable: table is nil"); return; end
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- ===========================================================================

-- prepare reward descriptions in advance, to simplify the process later
-- default behavior - read Description and fill it with Amount param from the Modifier
g_RewardExceptions = {
    -- base
    GOODYHUT_GRANT_SCOUT      = "desc", -- direct description
    GOODYHUT_GRANT_UPGRADE    = "desc",
    GOODYHUT_GRANT_EXPERIENCE = "exp", -- experience
    GOODYHUT_HEAL             = "desc",
    GOODYHUT_GRANT_BUILDER    = "unit", -- unit granted
    GOODYHUT_GRANT_TRADER     = "unit",
    GOODYHUT_GRANT_SETTLER    = "unit",
    -- xp2
    GOODYHUT_GOVERNOR_TITLE   = "desc",
    GOODYHUT_RESOURCES        = "res", -- resources <Text>[COLOR_FLOAT_MILITARY]+{1_Num} [ICON_{2_Icon}] {3_Resources}[ENDCOLOR]</Text>
    -- gran colombia maya
    METEOR_GRANT_GOODIES      = "desc",
}
--dshowtable(g_RewardExceptions);

g_RewardDescriptions = {}; -- this is a global variable, so other mods can add its own rewards and hook descriptions in here

function Initialize_RewardDescriptions()
    --print("Initialize_RewardDescriptions");
    -- helper to get arguments from modifiers
    local function GetModifierParam(sModifierID:string, sName:string)
        for row in GameInfo.ModifierArguments() do
            if row.ModifierId == sModifierID and row.Name == sName then
                return row.Value;
            end
        end
        print("Warning! No argument", sName, "in modifier", sModifierID);
        return "0";
    end
    -- decode a single reward
    local function DecodeRewardDescription(sSubType:string, sDescription:string, sModifierID:string)
        --print("DecodeRewardDescription",sSubType,sDescription,sModifierID);
        if sDescription == nil or sDescription == "" then
            return "Warning! Unkown description for goody sub type".. tostring(sSubType);
        end
        if g_RewardExceptions[sSubType] then
            -- unique decode
            if g_RewardExceptions[sSubType] == "desc" then
                return LL(sDescription);
            elseif g_RewardExceptions[sSubType] == "exp" then
                return string.format("+%d%s %s", tonumber(GetModifierParam(sModifierID, "Amount")), LL("LOC_HUD_UNIT_PANEL_XP"), LL(sDescription));
            elseif g_RewardExceptions[sSubType] == "unit" then
                local iNum:number  = tonumber(GetModifierParam(sModifierID, "Amount"));
                local sType:string = GetModifierParam(sModifierID, "UnitType");
                local infoUnit:table = GameInfo.Units[sType];
                if infoUnit == nil then
                    return "Warning! Cannot decode"..sSubType;
                end
                return LL(sDescription, iNum, LL(infoUnit.Name));
            elseif g_RewardExceptions[sSubType] == "res" then
                local iNum:number = tonumber(GetModifierParam(sModifierID, "Amount"));
                return LL("LOC_GOODYHUT_STRATEGIC_RESOURCES_DESCRIPTION", iNum);
            end
        else
            -- default decode
            local iNum:number = tonumber(GetModifierParam(sModifierID, "Amount"));
            return LL(sDescription, iNum);
        end
    end
    -- decode all rewards
    for row in GameInfo.GoodyHutSubTypes() do
        local eRewardSubType:number = DB.MakeHash(row.SubTypeGoodyHut);
        local sRewardDescription:string = DecodeRewardDescription(row.SubTypeGoodyHut, row.Description, row.ModifierID);
        --print("DECODED", row.SubTypeGoodyHut, sRewardDescription);
        g_RewardDescriptions[ eRewardSubType ] = sRewardDescription;
    end
    --dshowtable(g_RewardDescriptions); -- debug
end

function OnGoodyHutReward(ePlayer:number, iUnitID:number, eRewardType:number, eRewardSubType:number)
    -- eRewardType    - use .Hash on GameInfo.GoodyHuts
    -- eRewardSubType - use DB.MakeHash() on GameInfo.GoodyHutSubTypes.SubTypeGoodyHut
    print("OnGoodyHutReward",ePlayer,iUnitID,eRewardType,eRewardSubType);
    -- get a reward description
    local sReward:string = g_RewardDescriptions[eRewardSubType];
    if sReward == nil then
        sReward = "Warning! Unknown reward type!";
    end
    print("reward", sReward);
    -- compose a notification and send it
    -- "LOC_NOTIFICATION_DISCOVER_GOODY_HUT_MESSAGE" <Text>Tribal Village Discovered</Text>
    -- "LOC_NOTIFICATION_DISCOVER_GOODY_HUT_SUMMARY" <Text>You have found a village inhabited by a friendly tribe.</Text>
    NotificationManager.SendNotification(
        ePlayer,
        GameInfo.Notifications.NOTIFICATION_DISCOVER_GOODY_HUT.Hash,
        LL("LOC_NOTIFICATION_DISCOVER_GOODY_HUT_MESSAGE"),
        LL("LOC_NOTIFICATION_DISCOVER_GOODY_HUT_SUMMARY").."[NEWLINE]"..sReward);
end
Events.GoodyHutReward.Add( OnGoodyHutReward );

Initialize_RewardDescriptions();
