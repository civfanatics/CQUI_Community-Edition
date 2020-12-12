print("*** citystates_CQUI.lua start")
-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_AddCityStateRow = AddCityStateRow;

-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
local COLOR_ICON_BONUS_OFF:number = UI.GetColorValueFromHexLiteral(0xff606060);

-- ===========================================================================
--  CQUI Function Extensions
-- ===========================================================================
function AddCityStateRow( kCityState:table )
    local kInst = BASE_CQUI_AddCityStateRow(kCityState);

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
print("*** citystates_CQUI.lua end")