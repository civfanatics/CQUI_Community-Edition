include("StatusMessagePanel");
include( "supportfunctions.lua" );
include( "CQUICommon.lua" );

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnStatusMessage = OnStatusMessage;


-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_trimGossip = true;
local CQUI_ignoredMessages = {};

-- temp
m4atemp = nil;

function CQUI_OnSettingsUpdate()
    CQUI_trimGossip = GameConfiguration.GetValue("CQUI_TrimGossip");
    CQUI_ignoredMessages = CQUI_GetIgnoredGossipMessages();
end

LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );

-- ===========================================================================
-- CQUI Function Extensions
-- ===========================================================================
function OnStatusMessage( message:string, displayTime:number, type:number, subType:number )
-- If gossip, trim or ignore and then send on to base game for handling
-- temp
print("**** OnStatusMessage Entry, message: "..tostring(message));
-- if (type == ReportingStatusTypes.GOSSIP) then
--         local trimmed = CQUI_TrimGossipMessage(message);
--         print("***** trimmed: "..tostring(trimmed));
--         if (trimmed ~= nil) then
--             if (CQUI_IsGossipMessageIgnored(trimmed)) then
--                 return; --If the message is supposed to be ignored, give up!
--             elseif (CQUI_trimGossip) then
--                 message = trimmed
--             end
--         end
--     end

if (type == ReportingStatusTypes.GOSSIP) then
    if (CQUI_IsGossipMessageIgnored(message)) then
        -- temp print
        print("************** ignoring message: "..message);
        return; --If the message is supposed to be ignored, give up!
    end
end


    BASE_CQUI_OnStatusMessage(message, displayTime, type, subType);
end

-- ===========================================================================
function CQUI_IsGossipMessageIgnored(str)
-- Returns true if the given message is disabled in settings

--temp print
print("****** CQUI_IsGossipMessageIgnored ENTRY, str = "..tostring(str));
    if (str == nil) then
        -- str will be nil if the last word from the gossip source string can't be found in message.
        -- Generally means the incoming message wasn't gossip at all
        return false;
    end
print ("22222222222222222");
    str = string.gsub(str, "%s", "") -- remove spaces to normalize the string
print("3333333333333 str = "..tostring(str));
    for _, message in ipairs(CQUI_ignoredMessages) do
        --temp print
        print("********* cqui_ignoredmessage: "..message)
        message = string.gsub(message, "%s", "") -- remove spaces to normalize the ignored message
        partsToMatch = Split(message, "%[%]") -- Split the ignored messages into its different parts
        local stringToMatch = "^" -- We'll build a string to match with the differents parts
        for _, part in ipairs(partsToMatch) do
            part = string.gsub(part, "%p", "%%%1") -- Escape all the magic character that each part can contain (to avoid being considered as part of the pattern)
            stringToMatch = stringToMatch .. part .. ".*"
        end

        stringToMatch = stringToMatch .. "$"

        -- temp
        print("************ stringToMatch: "..stringToMatch)
        if string.find(str, stringToMatch) then -- If the str match the strToMatch, return true
            return true
        end
    end

    return false
end

-- ===========================================================================
function CQUI_GetIgnoredGossipMessages()
    -- Gets a list of ignored gossip messages based on current settings
    -- Yeah... as far as I can tell there's no way to get these programatically, so I just made a script that grepped these from the LOC files
    local ignored :table = {};
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_AGENDA_KUDOS") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_AGENDA_KUDOS", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_AGENDA_WARNING") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_AGENDA_WARNING", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_ALLIED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_ALLIED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_ANARCHY_BEGINS") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_ANARCHY_BEGINS", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_ARTIFACT_EXTRACTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_ARTIFACT_EXTRACTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_BARBARIAN_INVASION_STARTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_BARBARIAN_INVASION_STARTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_BARBARIAN_RAID_STARTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_BARBARIAN_RAID_STARTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_BEACH_RESORT_CREATED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_BEACH_RESORT_CREATED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CHANGE_GOVERNMENT") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CHANGE_GOVERNMENT", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CITY_BESIEGED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CITY_BESIEGED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CITY_LIBERATED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CITY_LIBERATED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CITY_RAZED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CITY_RAZED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CLEAR_CAMP") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CLEAR_CAMP", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CITY_STATE_INFLUENCE") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CITY_STATE_INFLUENCE", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CONQUER_CITY") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CONQUER_CITY", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CONSTRUCT_BUILDING") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CONSTRUCT_BUILDING", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CONSTRUCT_DISTRICT") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CONSTRUCT_DISTRICT", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CREATE_PANTHEON") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CREATE_PANTHEON", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_CULTURVATE_CIVIC") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_CULTURVATE_CIVIC", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_DECLARED_FRIENDSHIP") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_DECLARED_FRIENDSHIP", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_DELEGATION") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_DELEGATION", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_DENOUNCED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_DENOUNCED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_EMBASSY") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_EMBASSY", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_ERA_CHANGED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_ERA_CHANGED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_FIND_NATURAL_WONDER") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_FIND_NATURAL_WONDER", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_FOUND_CITY") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_FOUND_CITY", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_FOUND_RELIGION") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_FOUND_RELIGION", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_GREATPERSON_CREATED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_GREATPERSON_CREATED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_LAUNCHING_ATTACK") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_LAUNCHING_ATTACK", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_WAR_PREPARATION") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_WAR_PREPARATION", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_INQUISITION_LAUNCHED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_INQUISITION_LAUNCHED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_LAND_UNIT_LEVEL") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_LAND_UNIT_LEVEL", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_MAKE_DOW") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_MAKE_DOW", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_NATIONAL_PARK_CREATED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_NATIONAL_PARK_CREATED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_NEW_RELIGIOUS_MAJORITY") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_NEW_RELIGIOUS_MAJORITY", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_PILLAGE") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_PILLAGE", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_POLICY_ENACTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_POLICY_ENACTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_RECEIVE_DOW") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_RECEIVE_DOW", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_RELIC_RECEIVED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_RELIC_RECEIVED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_RESEARCH_AGREEMENT") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_RESEARCH_AGREEMENT", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_RESEARCH_TECH") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_RESEARCH_TECH", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_DETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_DISRUPT_ROCKETRY_UNDETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_GREAT_WORK_HEIST_DETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_GREAT_WORK_HEIST_UNDETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_RECRUIT_PARTISANS_DETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_RECRUIT_PARTISANS_UNDETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_DETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_SABOTAGE_PRODUCTION_UNDETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_SIPHON_FUNDS_DETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_SIPHON_FUNDS_UNDETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_STEAL_TECH_BOOST_DETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_SPY_STEAL_TECH_BOOST_UNDETECTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_TRADE_DEAL") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_TRADE_DEAL", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_TRADE_RENEGE") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_TRADE_RENEGE", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_TRAIN_SETTLER") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_TRAIN_SETTLER", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_TRAIN_UNIT") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_TRAIN_UNIT", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_TRAIN_UNIQUE_UNIT") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_TRAIN_UNIQUE_UNIT", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_PROJECT_STARTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_PROJECT_STARTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_START_VICTORY_STRATEGY") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_START_VICTORY_STRATEGY", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_STOP_VICTORY_STRATEGY") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_STOP_VICTORY_STRATEGY", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_WMD_BUILT") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_WMD_BUILT", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_WMD_STRIKE") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_WMD_STRIKE", "[]", "[]", "[]", "[]", "[]", "[]");
    end
    if (GameConfiguration.GetValue("CQUI_LOC_GOSSIP_WONDER_STARTED") == false) then
        ignored[#ignored+1] = Locale.Lookup("LOC_GOSSIP_WONDER_STARTED", "[]", "[]", "[]", "[]", "[]", "[]");
    end

    -- temp
    m4atemp = ignored;

    return ignored;
end

function CQUI_DebugTest()
-- LOC_GOSSIP_EMBASSY disabled by default
-- LOC_GOSSIP_EMBASSY not trimmed = A new building has appeared in the capital of X: a permanent embassy from Y.
-- LOC_GOSSIP_EMBASSY trimmed = New embassy established in X from Y.
-- LOC_GOSSIP_DENOUNCED enabled by default
-- LOC_GOSSIP_DENOUNCED not trimmed = X has/have deounced the evil deeds of Y
-- LOC_GOSSIP_DENOUNCED trimmed = X denounced Y
    OnStatusMessage("Use 'F' to attempt to generate the CQUI-disabled-by-default message regarding an Embassy.", 10, ReportingStatusTypes.DEFAULT );
    OnStatusMessage("Use 'G' to attempt to generate the CQUI-enabled-by-default message regarding a player being denounced.", 10, ReportingStatusTypes.DEFAULT );
    ContextPtr:SetInputHandler( 
        function( pInputStruct ) 
            local uiMsg = pInputStruct:GetMessageType();
            if uiMsg == KeyEvents.KeyUp then 
                local key = pInputStruct:GetKey();
                local type = pInputStruct:IsShiftDown() and ReportingStatusTypes.DEFAULT or ReportingStatusTypes.GOSSIP ;
                local subType = DB.MakeHash("GOSSIP_MAKE_DOW");
                if key == Keys.F then
                    OnStatusMessage(Locale.Lookup("LOC_GOSSIP_EMBASSY", "AAA", "BBB", "CCC", "DDD", "EEE", "FFF"), 10, type, subType);
                    return true;
                end

                if key == Keys.G then
                    OnStatusMessage(Locale.Lookup("LOC_GOSSIP_DENOUNCED", "AAA", "BBB", "CCC", "DDD", "EEE", "FFF"), 10, type, subType );
                    return true;
                end
            end	
            return false;
        end, true);
end
