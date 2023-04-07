-- Given the issues observed with including this file, print out a confirmation that has loaded to make for easier debugging
print("NotificationPanel_CQUI.lua: File loaded");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnTechBoostActivateNotification = OnTechBoostActivateNotification;
BASE_CQUI_OnCivicBoostActivateNotification = OnCivicBoostActivateNotification;
BASE_CQUI_OnNotificationAdded = OnNotificationAdded;
BASE_CQUI_LateInitialize = LateInitialize;
BASE_CQUI_RegisterHandlers = RegisterHandlers;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_NotificationGoodyHut:boolean = true;
local m_eRewardMeteorHash:number = DB.MakeHash("METEOR_GOODIES"); -- the only entry in GameInfo.GoodyHuts with no .Hash value

-- =======================================================================================
function CQUI_OnSettingsUpdate()
    CQUI_NotificationGoodyHut = GameConfiguration.GetValue("CQUI_NotificationGoodyHut");
end

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
                if GameInfo.Technologies["TECH_SANITATION"] and techIndex == GameInfo.Technologies["TECH_SANITATION"].Index then        -- Sanitation
                    if PlayerConfigurations[notificationEntry.m_PlayerID]:GetCivilizationTypeName() == "CIVILIZATION_INDIA" then
                        if Players[notificationEntry.m_PlayerID]:GetTechs():HasTech(techIndex) then
                            LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost(notificationEntry.m_PlayerID);
                        end
                    end
                -- CQUI update all cities real housing when play as Indonesia and boosted and researched Mass Production
                elseif GameInfo.Technologies["TECH_MASS_PRODUCTION"] and techIndex == GameInfo.Technologies["TECH_MASS_PRODUCTION"].Index then        -- Mass Production
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
                if GameInfo.Civics["CIVIC_CIVIL_SERVICE"] and civicIndex == GameInfo.Civics["CIVIC_CIVIL_SERVICE"].Index then -- Civil Service
                    if PlayerConfigurations[notificationEntry.m_PlayerID]:GetCivilizationTypeName() == "CIVILIZATION_CREE" then
                        if Players[notificationEntry.m_PlayerID]:GetCulture():HasCivic(civicIndex) then
                            LuaEvents.CQUI_AllCitiesInfoUpdatedOnTechCivicBoost(notificationEntry.m_PlayerID);
                        end
                    end
                -- CQUI update all cities real housing when play as Scotland and boosted and researched Globalization
                elseif GameInfo.Civics["CIVIC_GLOBALIZATION"] and civicIndex == GameInfo.Civics["CIVIC_GLOBALIZATION"].Index then -- Globalization
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
        if pNotification ~= nil then
            if pNotification:GetType() == GameInfo.Notifications["NOTIFICATION_TILE_LOST_CULTURE_BOMB"].Hash then
                local x, y = pNotification:GetLocation();
                LuaEvents.CQUI_CityLostTileToCultureBomb(playerID, x, y);
            end
            
            -- CQUI: Stop if the notification is meant to be hidden
            if (CQUI_IsNotificationIgnored(pNotification)) then
                return;
            end
        end
    end

    BASE_CQUI_OnNotificationAdded(playerID, notificationID);
end

-- ===========================================================================
function RegisterHandlers()
    BASE_CQUI_RegisterHandlers();
    
    g_notificationHandlers[NotificationTypes.CIVIC_BOOST].Activate = OnCivicBoostActivateNotification;
    g_notificationHandlers[NotificationTypes.TECH_BOOST].Activate = OnTechBoostActivateNotification;
end

-- ===========================================================================
function CQUI_IsNotificationIgnored(pNotification:table)
    -- Sanity checks
    -- These should never be nil at this point, but let's be safe
    -- If somehow nil, just return false to attempt using default behavior
    if (pNotification == nil) then
        return false;
    end
    
    local typeName:string = pNotification:GetTypeName();
    if (typeName == nil) then
        return false;
    end
    
    -- The name of the setting for each notification should be the typeName with the "CQUI_" prefix
    local settingName = "CQUI_"..typeName;

    -- Check if the notification is supposed to be ignored
    -- If it doesn't exist, it will return nil, which does not equal false
    if (GameConfiguration.GetValue(settingName) == false) then
        return true;
    end

    return false;
end

-- ===========================================================================
-- CUSTOM NOTIFICATIONS, 2020-09-11 Infixo
-- Usage:
-- NotificationManager.SendNotification(iNotifyPlayer, notificationData.Type, msgString, sumString, pPlot:GetX(), pPlot:GetY());
-- Potential notifications to be added:
-- city border expands
-- populations grows
-- trade deal expired
-- goody hut reward [there is already NOTIFICATION_DISCOVER_GOODY_HUT]
-- Note: if PlotX/Y are not specified, the location-based notifications will not stack (only 1 will show at a time).

--[[
USER_DEFINED_1 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_2 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_3 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_4 - used by BlackDeathScenario and CivRoyaleScenario
USER_DEFINED_5 - used in CivRoyaleScenario
USER_DEFINED_6 - used in CivRoyaleScenario
USER_DEFINED_7 - free => City Border Expands
USER_DEFINED_8 - free => Population Grows
USER_DEFINED_9 - free => Trade Deal Expired
--]]

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
    GOODYHUT_GRANT_EXPERIENCE = "exp",  -- experience
    GOODYHUT_HEAL             = "desc",
    GOODYHUT_GRANT_BUILDER    = "unit", -- unit granted
    GOODYHUT_GRANT_TRADER     = "unit",
    GOODYHUT_GRANT_SETTLER    = "unit",
    -- xp2
    GOODYHUT_GOVERNOR_TITLE   = "desc",
    GOODYHUT_RESOURCES        = "res",  -- resources <Text>[COLOR_FLOAT_MILITARY]+{1_Num} [ICON_{2_Icon}] {3_Resources}[ENDCOLOR]</Text>
    -- gran colombia maya
    METEOR_GRANT_GOODIES      = "desc",
}

g_RewardDescriptions = {}; -- this is a global variable, so other mods can add its own rewards and hook descriptions in here

function Initialize_RewardDescriptions()
    -- print("CQUI -- Initialize_RewardDescriptions");
    -- helper to get arguments from modifiers
    local function GetModifierParam(sModifierID:string, sName:string)
        for row in GameInfo.ModifierArguments() do
            if row.ModifierId == sModifierID and row.Name == sName then
                return row.Value;
            end
        end

        print("Warning! No argument '"..sName.."' in modifier '"..sModifierID.."'");
        return "0";
    end

    -- decode a single reward
    local function DecodeRewardDescription(sSubType:string, sDescription:string, sModifierID:string)
        -- print("DecodeRewardDescription",sSubType,sDescription,sModifierID);
        if sDescription == nil or sDescription == "" then
            return "Warning! Unkown description for goody sub type".. tostring(sSubType);
        end

        local returnStr = "";
        if g_RewardExceptions[sSubType] then
            -- unique decode
            if g_RewardExceptions[sSubType] == "desc" then
                returnStr = Locale.Lookup(sDescription);
            elseif g_RewardExceptions[sSubType] == "exp" then
                returnStr =  string.format("+%d%s %s",
                                           tonumber(GetModifierParam(sModifierID, "Amount")),
                                           Locale.Lookup("LOC_HUD_UNIT_PANEL_XP"),
                                           Locale.Lookup(sDescription));
            elseif g_RewardExceptions[sSubType] == "unit" then
                local iNum:number  = tonumber(GetModifierParam(sModifierID, "Amount"));
                local sType:string = GetModifierParam(sModifierID, "UnitType");
                local infoUnit:table = GameInfo.Units[sType];
                if infoUnit == nil then
                    returnStr = "Warning! Cannot decode"..sSubType;
                else
                    returnStr = Locale.Lookup(sDescription, iNum, Locale.Lookup(infoUnit.Name));
                end
            elseif g_RewardExceptions[sSubType] == "res" then
                local iNum:number = tonumber(GetModifierParam(sModifierID, "Amount"));
                returnStr = Locale.Lookup("LOC_GOODYHUT_STRATEGIC_RESOURCES_DESCRIPTION", iNum);
            end
        else
            -- default decode
            local iNum:number = tonumber(GetModifierParam(sModifierID, "Amount"));
            returnStr = Locale.Lookup(sDescription, iNum);
        end

        return returnStr;
    end

    -- decode all rewards
    for row in GameInfo.GoodyHutSubTypes() do
        local eRewardSubType:number = DB.MakeHash(row.SubTypeGoodyHut);
        local sRewardDescription:string = DecodeRewardDescription(row.SubTypeGoodyHut, row.Description, row.ModifierID);
        sRewardDescription = string.gsub(sRewardDescription, "%[ENDCOLOR%]", "");
        sRewardDescription = string.gsub(sRewardDescription, "%[COLOR[%l%u_]+%]", "");
        -- print("DECODED", row.SubTypeGoodyHut, sRewardDescription);
        g_RewardDescriptions[ eRewardSubType ] = sRewardDescription;
    end
end

-- ===========================================================================
function OnGoodyHutReward(ePlayer:number, iUnitID:number, eRewardType:number, eRewardSubType:number)
    if not CQUI_NotificationGoodyHut then
        return;
    end

    local pUnit :object = UnitManager.GetUnit(ePlayer, iUnitID);
    if (pUnit == nil) then
        print("Could not retrieve unit!  ePlayer:"..tostring(ePlayer).."  iUnitID:"..tostring(iUnitID));
        return;
    end

    -- eRewardType    - use .Hash on GameInfo.GoodyHuts
    -- eRewardSubType - use DB.MakeHash() on GameInfo.GoodyHutSubTypes.SubTypeGoodyHut
    -- print("OnGoodyHutReward",ePlayer,iUnitID,eRewardType,eRewardSubType);
    -- get a reward description
    local sReward:string = g_RewardDescriptions[eRewardSubType];
    if sReward == nil then
        sReward = "Warning! Unknown reward type!";
    end
    -- print("reward", sReward);

    -- compose a notification and send it
    if eRewardType == m_eRewardMeteorHash then
        NotificationManager.SendNotification(
            ePlayer,
            GameInfo.Notifications.NOTIFICATION_DISCOVER_GOODY_HUT.Hash,
            Locale.Lookup("LOC_IMPROVEMENT_METEOR_GOODY_NAME"),
            sReward,
            pUnit:GetX(),
            pUnit:GetY());
    else
        -- standard goody hut
        -- "LOC_NOTIFICATION_DISCOVER_GOODY_HUT_MESSAGE" <Text>Tribal Village Discovered</Text>
        -- "LOC_NOTIFICATION_DISCOVER_GOODY_HUT_SUMMARY" <Text>You have found a village inhabited by a friendly tribe.</Text>
        NotificationManager.SendNotification(
            ePlayer,
            GameInfo.Notifications.NOTIFICATION_DISCOVER_GOODY_HUT.Hash,
            Locale.Lookup("LOC_NOTIFICATION_DISCOVER_GOODY_HUT_MESSAGE"),
            Locale.Lookup("LOC_NOTIFICATION_DISCOVER_GOODY_HUT_SUMMARY").."[NEWLINE]"..sReward,
            pUnit:GetX(),
            pUnit:GetY());
    end
end

-- ===========================================================================
function LateInitialize()
    BASE_CQUI_LateInitialize();

    Initialize_RewardDescriptions();
    -- dshowtable(g_RewardExceptions); -- debug
    -- dshowtable(g_RewardDescriptions); -- debug

    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    
    Events.NotificationAdded.Remove(BASE_CQUI_OnNotificationAdded);
    Events.NotificationAdded.Add(OnNotificationAdded);
    
    -- custom notifications
    Events.GoodyHutReward.Add( OnGoodyHutReward );
end
