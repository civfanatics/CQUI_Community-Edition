-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_AddCityStateRow = AddCityStateRow;

-- ===========================================================================
function AddCityStateRow( kCityState:table )
    local kInst = BASE_AddCityStateRow(kCityState);

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

    return kInst;
end