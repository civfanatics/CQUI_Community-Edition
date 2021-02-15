print("*** CQUI: DiplomacyDealView_CQUI loaded");
-- ===========================================================================
-- Base File
-- ===========================================================================
include("CitySupport");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_UpdateOtherPlayerText = UpdateOtherPlayerText;

-- ===========================================================================
-- Constants
-- ===========================================================================
local CQUI_SIZE_SLOT_TYPE_ICON = 20;

-- ===========================================================================
-- Members
-- ===========================================================================
-- The *_IconOnlyIM and *_IconAndTextIM are now a global variables in the Expansion2 version of DiplomacyDealView; it is still declared locally in the Vanilla/Exp1 version.
-- CQUI will use g_IconOnlyIM and g_IconAndTextIM in any case; if those start as nil, then they are instantiated like their local-only counterparts from Vanilla/XP1 (in the Initialize function)
local CQUI_IconAndTextForCitiesIM = nil;
local CQUI_IconAndTextForGreatWorkIM = nil;
-- This is a local instance of ms_MinimizedSectionIM, which appears in the unmodified file, also declared as local
local ms_MinimizedSectionIM = InstanceManager:new( "MinimizedSection", "MinimizedSectionContainer" );

-- ===========================================================================
--  CQUI PopulateSignatureArea function
--  Populate the icon and leader name for the given player
-- ===========================================================================
function PopulateSignatureArea(player:table, iconControl, leaderControl, civControl)
    if (player == nil) then
        return;
    end

    local playerIconController = CivilizationIcon:AttachInstance(iconControl);
    playerIconController:UpdateIconFromPlayerID(player:GetID());

    local m_primaryColor, m_secondaryColor = UI.GetPlayerColors(player:GetID());

    local playerConfig = PlayerConfigurations[player:GetID()];
    local leaderName = Locale.ToUpper(Locale.Lookup(playerConfig:GetLeaderName()))
    local playerName = PlayerConfigurations[player:GetID()]:GetPlayerName();
    local civTypeName = playerConfig:GetCivilizationTypeName();
    if GameConfiguration.IsAnyMultiplayer() and player:IsHuman() then
        leaderName = leaderName .. " ("..Locale.ToUpper(playerName)..")";
    end

    if (civTypeName == nil) then
        UI.DataError("Invalid type name returned by GetCivilizationTypeName");
        return;
    end

    --Create a tooltip which shows a list of this Civ's cities
    local civTooltip = Locale.Lookup(GameInfo.Civilizations[civTypeName].Name);
    local pPlayerConfig = PlayerConfigurations[player:GetID()];
    local playerName = pPlayerConfig:GetPlayerName();
    local playerCities = player:GetCities();
    if (playerCities ~= nil) then
        civTooltip = civTooltip .. " "..Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGEGROUP_CITIES_NAME").. ":[NEWLINE]----------";
        for i,city in playerCities:Members() do
            civTooltip = civTooltip.. "[NEWLINE]".. Locale.Lookup(city:GetName());
        end
    end

    civControl:SetText(Locale.ToUpper(Locale.Lookup(GameInfo.Civilizations[civTypeName].Name)));
    civControl:SetColor(m_primaryColor);
    leaderControl:SetText(leaderName);
    leaderControl:SetColor(UI.GetColorValue("COLOR_WHITE"));
    playerIconController.Controls.CivIcon:SetToolTipString(Locale.Lookup(civTooltip));
end

-- ===========================================================================
--  CQUI GetImportedResources function
--  from the Improved Deal Screen by Mironos
-- ===========================================================================
function CQUI_GetImportedResources(playerID)
    local importedResources :table = {};
    local kPlayers          :table = PlayerManager.GetAliveMajors();

    for _, pOtherPlayer in ipairs(kPlayers) do
        local otherID:number = pOtherPlayer:GetID();
        if ( otherID ~= playerID ) then
            local pPlayerConfig :table = PlayerConfigurations[otherID];
            local pDeals        :table = DealManager.GetPlayerDeals(playerID, otherID); -- ARISTOS: double filter Resources!
            local isNotCheat  :boolean = (playerID == Game.GetLocalPlayer()) or (otherID == Game.GetLocalPlayer()); -- ARISTOS: non-cheat CQUI policy

            if ( pDeals ~= nil and isNotCheat) then --ARISTOS: show only if local player is the importer or the exporter!!!
                for i,pDeal in ipairs(pDeals) do
                    --if ( pDeal:IsValid() ) then --!! ARISTOS: Bug??? deal:IsValid() not always returns true even if the deal IS valid!!!
                    -- Add incoming resource deals
                    local pDealResources = pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, otherID);
                    if ( pDealResources ~= nil ) then
                        for j,pDealResource in ipairs(pDealResources) do
                            local pClassType = GameInfo.Resources[pDealResource:GetValueType()].ResourceClassType;
                            local ending:number = pDealResource:GetEndTurn() - Game.GetCurrentGameTurn();
                            local convertedResources = {
                                Name = tostring(pDealResource:GetValueType());
                                ForType = pDealResource:GetValueType();
                                MaxAmount = pDealResource:GetAmount();
                                ClassType = pClassType;
                                -- ARISTOS: Show the deal's other civ's identity only if it is the local player.
                                ImportString = Locale.Lookup("LOC_IDS_DEAL_TRADE") .. " " .. ((otherID == Game.GetLocalPlayer() or playerID == Game.GetLocalPlayer())
                                and Locale.Lookup(PlayerConfigurations[otherID]:GetPlayerName()) or "another civ") .. " (" .. ending .. "[ICON_Turn])" .. " : " .. pDealResource:GetAmount();
                            };
                            -- !!ARISTOS: To group resources imported from different sources into a single icon!!!
                            local isIncluded:boolean = false;
                            local isIndex:number = 0;
                            for k,impResource in ipairs(importedResources) do
                                if (impResource.Name == convertedResources.Name) then
                                isIncluded = true;
                                isIndex = k;
                                break;
                                end
                            end
                            if (isIncluded) then
                                local existingResource = importedResources[isIndex];
                                local newResource = {
                                Name = existingResource.Name;
                                ForType = existingResource.ForType;
                                MaxAmount  = existingResource.MaxAmount + convertedResources.MaxAmount;
                                ClassType = existingResource.ClassType;
                                ImportString = existingResource.ImportString .. "[NEWLINE]" .. convertedResources.ImportString;
                                };
                                importedResources[isIndex] = newResource;
                            else
                                table.insert(importedResources, convertedResources);
                            end
                            -- END ARISTOS grouping of imported resources
                        end
                    end
                end
            end
        end
    end

    -- Add resources provided by city states
    for i, pMinorPlayer in ipairs(PlayerManager.GetAliveMinors()) do
        local pMinorPlayerInfluence:table = pMinorPlayer:GetInfluence();
        local hasMetLocalPlayer: boolean = Players[Game.GetLocalPlayer()]:GetDiplomacy():HasMet( pMinorPlayer:GetID() ); --ARISTOS: CQUI anti-cheat policy
        if (pMinorPlayerInfluence ~= nil and hasMetLocalPlayer) then --ARISTOS: show only if local player has met the City State!!!
            local suzerainID:number = pMinorPlayerInfluence:GetSuzerain();
            if suzerainID == playerID then
                for row in GameInfo.Resources() do

                    -- AZURENCY : fix by adding pMinorPlayer:GetResources():GetResourceAmount(row.Index)
                    local resourceAmount:number =  pMinorPlayer:GetResources():GetResourceAmount(row.Index) + pMinorPlayer:GetResources():GetExportedResourceAmount(row.Index);

                    if resourceAmount > 0 then
                        local kResource :table = GameInfo.Resources[row.Index];
                        local cityStateResources = {
                            Name = tostring(row.Index);--kResource.ResourceType);
                            ForType = kResource.ResourceType;
                            MaxAmount = resourceAmount;
                            ClassType = kResource.ResourceClassType;
                            ImportString = Locale.Lookup("LOC_IDS_DEAL_SUZERAIN").." " .. Locale.Lookup(PlayerConfigurations[pMinorPlayer:GetID()]:GetPlayerName()) .. " : " .. resourceAmount;
                            };
                        -- !!ARISTOS: To group resources imported from different sources into a single icon!!!
                        local isIncluded:boolean = false;
                        local isIndex:number = 0;
                        for k,impResource in ipairs(importedResources) do
                            if (impResource.Name == cityStateResources.Name) then
                                isIncluded = true;
                                isIndex = k;
                                break;
                            end
                        end
                        if isIncluded then
                            local existingResource = importedResources[isIndex];
                            local newResource = {
                                Name = existingResource.Name;
                                ForType = existingResource.ForType;
                                MaxAmount  = existingResource.MaxAmount + cityStateResources.MaxAmount;
                                ClassType = existingResource.ClassType;
                                ImportString = existingResource.ImportString .. "[NEWLINE]" .. cityStateResources.ImportString;
                            };
                            importedResources[isIndex] = newResource;
                        else
                            table.insert(importedResources, cityStateResources);
                        end
                        -- END ARISTOS grouping of imported resources
                    end
                end
            end
        end
    end

    return importedResources;
end

-- ===========================================================================
--  CQUI MatchesPartnerResource function
--  from the Improved Deal Screen by Mironos
-- ===========================================================================
function MatchesPartnerResource(partnerResourceTable, targetResourceType)
    for j, partnerEntry in ipairs(partnerResourceTable) do
        local partnerResourceDesc =  GameInfo.Resources[partnerEntry.ForType];
        if (partnerResourceDesc.ResourceType == targetResourceType) then
            return j;
        end
    end

    return -1;
end

-- ===========================================================================
--  CQUI CQUI_RenderResourceButton function
--  Render the correct resource button
-- ===========================================================================
function CQUI_RenderResourceButton(resource, resourceCategory, iconList, howAcquired)
    resourceDesc = GameInfo.Resources[resource.ForType];
    local icon = g_IconOnlyIM:GetInstance(iconList.ListStack);
    local tooltipAddedText = '';
    local buttonDisabled = false;

    icon.Icon:SetAlpha(1);
    icon.SelectButton:SetAlpha(1);
    icon.AmountText:SetAlpha(1);
    icon.AmountText:SetColor(UI.GetColorValue(194/255,194/255,204/255)); -- Color : BodyTextCool
    icon.SelectButton:SetTexture("Controls_DraggableButton");
    icon.SelectButton:SetTextureOffsetVal(0, 0);

    if (resourceCategory == 'scarce') then
        icon.AmountText:SetColor(UI.GetColorValue(224/255,124/255,124/255,230/255));
    elseif (resourceCategory == 'duplicate') then
        icon.SelectButton:SetAlpha(.8);
        icon.AmountText:SetColor(UI.GetColorValue(124/255,154/255,224/255,230/255));
        tooltipAddedText = ' [COLOR:GoldMetalDark](' .. Locale.Lookup("LOC_IDS_DEAL_DUPLICATE") .. ')[ENDCOLOR]';
    elseif (resourceCategory == 'none' or resourceCategory == 'imported') then
        icon.SelectButton:SetTexture("");
        icon.AmountText:SetAlpha(.3);
        tooltipAddedText = ' [COLOR:GoldMetalDark](' .. Locale.Lookup("LOC_IDS_DEAL_UNTRADEABLE") .. ')[ENDCOLOR]';
        buttonDisabled = true;
    else
        icon.SelectButton:SetTextureOffsetVal(0, 50);
    end

    SetIconToSize(icon.Icon, "ICON_" .. resourceDesc.ResourceType);
    icon.AmountText:SetText(tostring(resource.MaxAmount));
    icon.AmountText:SetHide(false);
    icon.SelectButton:SetDisabled( buttonDisabled );

    -- Set a tooltip
    local tooltipString = Locale.Lookup(resourceDesc.Name) .. tooltipAddedText;
    if (howAcquired ~= nil) then
        tooltipString = tooltipString .. '[NEWLINE]' .. howAcquired;
    end
    if resource.IsValid then
        icon.SelectButton:SetToolTipString(tooltipString);
        icon.SelectButton:SetDisabled(false);
        icon.Icon:SetColor(1, 1, 1);
    else
        local tempstr = tooltipString .. "[NEWLINE][COLOR_RED]";
        if player ~= g_LocalPlayer then
            tempstr = tempstr .. Locale.Lookup("LOC_DEAL_PLAYER_HAS_NO_CAP_ROOM");
            icon.SelectButton:SetToolTipString(tempstr);
        else
            tempstr = tempstr .. Locale.Lookup("LOC_DEAL_AI_HAS_NO_CAP_ROOM");
            icon.SelectButton:SetToolTipString(tempstr);
        end
        icon.SelectButton:SetDisabled(true);
        icon.Icon:SetColor(0.5, 0.5, 0.5);
    end
    icon.SelectButton:SetToolTipString(tooltipString);
    icon.SelectButton:ReprocessAnchoring();

    return icon;
end

-- ===========================================================================
--  CQUI CQUI_RenderCityButton function
--  Render the city button with all the details
-- ===========================================================================
function CQUI_RenderCityButton(pCity : table, player : table, targetContainer : table)
    local isCQUIXmlLoaded = CQUI_IsCQUIXmlLoaded();
    local button = nil; 
    local cityData = GetCityData(pCity);
    local otherPlayer = GetOtherPlayer(player);

    if (isCQUIXmlLoaded) then
        button = CQUI_IconAndTextForCitiesIM:GetInstance(targetContainer);
    else
        -- CQUI XML wasn't loaded, so use the basegame "IconAndText" button
        button = g_IconAndTextIM:GetInstance(targetContainer);
    end

    SetIconToSize(button.Icon, "ICON_BUILDINGS", 45);
    button.IconText:SetText(CQUI_GenerateCityNameForDisplay(pCity, player, true));
    if pCity:IsOccupied() then
        button.SelectButton:SetTextureOffsetVal(0, 50);
    else
        button.SelectButton:SetTextureOffsetVal(0, 0);
    end

    if (isCQUIXmlLoaded) then
        button.PopulationLabel:SetText(tostring(cityData.Population));
        --ARISTOS: only show detailed info for cities owned or occupied by local player! CQUI non-cheat policy
        if pCity:GetOwner() == Game.GetLocalPlayer() then
            button.FoodLabel:SetText("[ICON_FOOD]" .. toPlusMinusString(cityData.FoodPerTurn));
            button.ProductionLabel:SetText("[ICON_PRODUCTION]" .. toPlusMinusString(cityData.ProductionPerTurn));
            button.ScienceLabel:SetText("[ICON_SCIENCE]" .. toPlusMinusString(cityData.SciencePerTurn));
        else
            button.FoodLabel:SetText("");
            button.ProductionLabel:SetText("");
            button.ScienceLabel:SetText("");
        end
    else
        -- CQUI DiplomacyDealView XML was not loaded (note these IDs do not exist in the CQUI XML version)
        button.AmountText:SetHide(true);
        button.RemoveButton:SetHide(true);
        button.StopAskingButton:SetHide(true);
    end

    button.SelectButton:SetToolTipString( CQUI_MakeCityToolTip(pCity, player) );
    button.UnacceptableIcon:SetHide(true); -- AZURENCY : Sometime the icon is shown so always hide it
    button.ValueText:SetHide(true);
    button.Icon:SetColor(1, 1, 1);

    return button;
end
-- ===========================================================================
function CQUI_GenerateCityNameForDisplay(pCity, player, useColor)
    local retStr = "";
    local cityData = GetCityData(pCity);
    local otherPlayer = GetOtherPlayer(player);

    if pCity:IsOccupied() then
        if pCity:GetOwner() == otherPlayer:GetID() then -- Cede
            if useColor then retStr = "[COLOR_Civ6Green]" end;
            retStr = retStr .. Locale.Lookup("LOC_DIPLOMACY_DEAL_CEDE_CITY", cityData.CityName);
            if useColor then retStr = retStr .. "[ENDCOLOR]" end; 
        else -- Return
            if pCity:GetOriginalOwner() == otherPlayer:GetID() then
                if useColor then retStr = "[COLOR_Civ6Red]" end
                retStr = retStr .. Locale.Lookup("LOC_DIPLOMACY_DEAL_RETURN_CITY", cityData.CityName); 
                if useColor then retStr = retStr .. '[ENDCOLOR]' end; 
            end
        end
    else
        retStr = Locale.Lookup(cityData.CityName);
    end

    return retStr;
end

-- ===========================================================================
function CQUI_MakeCityToolTip(pCity:table, player:table)
    local cityData = GetCityData(pCity);
    local isLocalPlayerCity = pCity:GetOwner() == Game.GetLocalPlayer();

    if (pCity ~= nil) then
        local szToolTip = Locale.ToUpper(CQUI_GenerateCityNameForDisplay(pCity, player)) .. "[NEWLINE]";
        szToolTip = szToolTip .. Locale.Lookup("LOC_DEAL_CITY_POPULATION_TOOLTIP", pCity:GetPopulation());
        if isLocalPlayerCity then --ARISTOS: only show detailed info for cities owned or occupied by local player! CQUI non-cheat policy
            szToolTip = szToolTip .. "[NEWLINE]";
            szToolTip = szToolTip .. "[ICON_Food]" .. toPlusMinusString(cityData.FoodPerTurn) .. " ";
            szToolTip = szToolTip .. "[ICON_Production]" .. toPlusMinusString(cityData.ProductionPerTurn) .. " ";
            szToolTip = szToolTip .. "[ICON_Science]" .. toPlusMinusString(cityData.SciencePerTurn) .. " ";
            szToolTip = szToolTip .. "[ICON_Culture]" .. toPlusMinusString(cityData.CulturePerTurn) .. " ";
            szToolTip = szToolTip .. "[ICON_Faith]" .. toPlusMinusString(cityData.FaithPerTurn) .. " ";
            szToolTip = szToolTip .. "[ICON_Gold]" .. toPlusMinusString(cityData.GoldPerTurn);
        end
        local districtNames = {};
        local pCityDistricts = pCity:GetDistricts();
        if (pCityDistricts ~= nil) then

            for i, pDistrict in pCityDistricts:Members() do
                local pDistrictDef = GameInfo.Districts[ pDistrict:GetType() ];
                if (pDistrictDef ~= nil) then
                    local districtType:string = pDistrictDef.DistrictType;
                    -- Skip the city center and any wonder districts
                    if (districtType ~= "DISTRICT_CITY_CENTER" and districtType ~= "DISTRICT_WONDER") then
                        table.insert(districtNames, pDistrictDef.Name);
                    end
                end
            end
        end

        if (#districtNames > 0) then
            szToolTip = szToolTip .. "[NEWLINE]" .. Locale.Lookup("LOC_DEAL_CITY_DISTRICTS_TOOLTIP");
            for i, name in ipairs(districtNames) do
                szToolTip = szToolTip .. "[NEWLINE] • " .. Locale.Lookup(name);
            end
        end

        local cityOwner = Players[pCity:GetOwner()];
        local cityID = pCity:GetID();

        -- Add Resources
        local extractedResources = cityOwner:GetResources():GetResourcesExtractedByCity( cityID, ResultFormat.SUMMARY );
        if extractedResources ~= nil and #extractedResources > 0 then
            szToolTip = szToolTip .. "[NEWLINE]" .. Locale.Lookup("LOC_DEAL_CITY_RESOURCES_TOOLTIP");
            for i, entry in ipairs(extractedResources) do
                local resourceDesc = GameInfo.Resources[entry.ResourceType];
                if resourceDesc ~= nil then
                    szToolTip = szToolTip .. "[NEWLINE] • [ICON_"..resourceDesc.ResourceType.. "]" .. Locale.Lookup(resourceDesc.Name) .. " : " .. tostring(entry.Amount);
                end
            end
        end

        -- Add Great Works
        local cityGreatWorks = cityOwner:GetCulture():GetGreatWorksInCity( cityID );
        if cityGreatWorks ~= nil and #cityGreatWorks > 0 then
            szToolTip = szToolTip .. "[NEWLINE]" .. Locale.Lookup("LOC_DEAL_CITY_GREAT_WORKS_TOOLTIP");
            for i, entry in ipairs(cityGreatWorks) do
                local greatWorksDesc = GameInfo.GreatWorks[entry.GreatWorksType];
                if greatWorksDesc ~= nil then
                    szToolTip = szToolTip .. "[NEWLINE]" .. Locale.Lookup(greatWorksDesc.Name);
                end
            end
        end

        return szToolTip;
    end -- if (pCity ~= nil)

    return "";
end

-- ===========================================================================
--  CQUI modified UpdateOtherPlayerText function
--  Small Hack, because modifing OnShow is not called, this function is called first after player variable are set and only in the original OnShow()
--  Populate the signature of each civilization in the trade screen
-- ===========================================================================
function UpdateOtherPlayerText(otherPlayerSays)
    BASE_CQUI_UpdateOtherPlayerText(otherPlayerSays);

    -- This doesn't need to be called for the Expansion2 games as it's already been done prior to calling this function.
    -- However, for Vanilla and EXP1, it does because we declared this as a global and the instances require resetting
    -- Calling this (rather than including CQUICommon and checking which mod is loaded) doesn't hurt anything with XP2, so just allow it to be called...
    g_IconOnlyIM:ResetInstances();
    ms_MinimizedSectionIM:ResetInstances();

    if (CQUI_IsCQUIXmlLoaded()) then
        CQUI_IconAndTextForCitiesIM:ResetInstances();
        CQUI_IconAndTextForGreatWorkIM:ResetInstances();

        PopulateSignatureArea(g_LocalPlayer, Controls.PlayerCivIcon, Controls.PlayerLeaderName, Controls.PlayerCivName);  -- Expansion 2 added global variable for local and other player
        PopulateSignatureArea(g_OtherPlayer, Controls.OtherPlayerCivIcon, Controls.OtherPlayerLeaderName, Controls.OtherPlayerCivName);
    end
end

-- ===========================================================================
--  CQUI modified PopulateAvailableResources function
--  Resources are sorted by quantity
-- ===========================================================================
function PopulateAvailableResources(player : table, iconList : table, className : string)
    local iAvailableItemCount = 0;
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID());
    local possibleResources = DealManager.GetPossibleDealItems(player:GetID(), GetOtherPlayer(player):GetID(), DealItemTypes.RESOURCES, pForDeal);

    local playerDuplicateResources = {};
    local playerUntradeableResources = {};
    local playerImportedResources = CQUI_GetImportedResources(player:GetID());
    local otherPlayerResources = DealManager.GetPossibleDealItems(GetOtherPlayer(player):GetID(), player:GetID(), DealItemTypes.RESOURCES);
    local otherPlayerImportedResources = CQUI_GetImportedResources(GetOtherPlayer(player):GetID());

    if (pDeal ~= nil) then
        g_IconOnlyIM:ReleaseInstanceByParent(iconList);
    end

    if (possibleResources ~= nil) then
        -- CQUI :Sort the resources
        local sort_func = function( a,b ) return tonumber(a.MaxAmount) > tonumber(b.MaxAmount) end;
        table.sort( possibleResources, sort_func );

        for i, entry in ipairs(possibleResources) do
            local resourceDesc = GameInfo.Resources[entry.ForType];
            local resourceType = entry.ForType;
            if (resourceDesc ~= nil and resourceDesc.ResourceClassType == className) then  -- correct resource class
                if (entry.MaxAmount == 0) then
                    -- All copies have been traded away
                    table.insert(playerUntradeableResources, possibleResources[i]);
                elseif (MatchesPartnerResource(otherPlayerResources, resourceDesc.ResourceType) > -1
                        or MatchesPartnerResource(otherPlayerImportedResources, resourceDesc.ResourceType) > -1) then
                    -- Other player already has the resource
                    table.insert(playerDuplicateResources, possibleResources[i]);
                else
                    -- It's a tradeable resource
                    local tradeableType;
                    if (entry.MaxAmount == 1) then
                        tradeableType = 'scarce';
                    else
                        tradeableType = 'default';
                    end

                    icon = CQUI_RenderResourceButton(entry, tradeableType, iconList);

                    -- What to do when double clicked/tapped.
                    icon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableResource(player, resourceType); end );

                    iAvailableItemCount = iAvailableItemCount + 1;
                end
            end
        end
    end

    if (playerDuplicateResources ~= nil) then
        for z, entry in ipairs(playerDuplicateResources) do
            tradeableType = 'duplicate';
            icon = CQUI_RenderResourceButton(entry, tradeableType, iconList);
            icon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableResource(player, entry.ForType); end );
            iAvailableItemCount = iAvailableItemCount + 1;
        end
    end

    if (playerUntradeableResources ~= nil) then
        for x, entry in ipairs(playerUntradeableResources) do
            tradeableType = 'none';
            icon = CQUI_RenderResourceButton(entry, tradeableType, iconList, entry.ImportString);
            icon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableResource(player, entry.ForType); end );
            iAvailableItemCount = iAvailableItemCount + 1;
        end
    end

    if (playerImportedResources ~= nil) then
        for y, entry in ipairs(playerImportedResources) do
            if (entry.ClassType == className) then
                tradeableType = 'imported';
                icon = CQUI_RenderResourceButton(entry, tradeableType, iconList, entry.ImportString);
                icon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableResource(player, entry.ForType); end );
                iAvailableItemCount = iAvailableItemCount + 1;
            end
        end
    end

    iconList.ListStack:CalculateSize();
    iconList.List:ReprocessAnchoring();

    -- Hide if empty
    iconList.GetTopControl():SetHide( iconList.ListStack:GetSizeX()==0 );

    return iAvailableItemCount;
end

-- ===========================================================================
--  CQUI modified PopulateAvailableCities function
-- ===========================================================================
function PopulateAvailableCities(player : table, iconList : table)
    local iAvailableItemCount = 0;
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID());
    -- Note: damanged cities do not appear in this list
    local possibleItems = DealManager.GetPossibleDealItems(player:GetID(), GetOtherPlayer(player):GetID(), DealItemTypes.CITIES, pForDeal);

    if (pForDeal ~= nil) then
        ms_MinimizedSectionIM:ReleaseInstanceByParent(iconList.List);
        if (CQUI_IsCQUIXmlLoaded()) then
            CQUI_IconAndTextForCitiesIM:ReleaseInstanceByParent(iconList.ListStack);
        end
    end

    local uiMinimizedSection:table = ms_MinimizedSectionIM:GetInstance(iconList.List);

    -- Todo: Possible to show the untradable (damaged) cities?
    if (possibleItems ~= nil) then
        local otherPlayer = GetOtherPlayer(player);

        -- CQUI : Sort the cities
        -- the-m4a CHANGE: Previous logic here (from Azurency) would remove occupied cities from the list and put nil at that spot in the table
        --                 With Expansion2 (Gathering Storm) a nil entry in this array causes the UI to stop displaying anything from that list
        --                 Instead of removing items from the list, we will instead just prefix the names of each with many spaces before sorting
        --                 so those occupied and cede cities are listed before the others.
        --                 The altered name is not passed to the CQUI_RenderCityButton method, so this will not affect what is displayed on the screen
        for i, entry in ipairs(possibleItems) do
            local type = entry.ForType;
            local pCity = player:GetCities():FindID( type );
            if pCity == nil then
                pCity = otherPlayer:GetCities():FindID( type );
            end

            if player:GetDiplomacy():IsAtWarWith(otherPlayer) or otherPlayer:GetDiplomacy():IsAtWarWith(player) then
                -- "Cede" cities do not show as occupied (IsOccupied is false), but do take the form of "CITYNAME, cede" in English
                local isCedeCity = (string.match(entry.ForTypeName, Locale.Lookup("LOC_DIPLOMACY_DEAL_CEDE_CITY", pCity:GetName())) ~= nil);
                if pCity:IsOccupied() or isCedeCity then
                    -- Add a series of spaces so that it sorts first, we do not pass this altered name to renderCityButton
                    -- so this change is just for sorting only, ensuring the occupied or "cede" cities are listed first
                    local tempName = "       " .. entry.ForTypeName;
                    entry.ForTypeName = tempName;
                end
            end
        end

        local sort_func = function( a,b ) return a.ForTypeName < b.ForTypeName end;
        table.sort(possibleItems, sort_func);

        -- Cycle through the possibleItems again in order to render the city buttons for the diplomacy UI
        for i, entry in ipairs(possibleItems) do
            local type = entry.ForType;
            local subType = entry.SubType;
            local pCity = player:GetCities():FindID( type );

            -- Handle occupied cities
            -- Aristos from CivFanatics originally fixed this for Expansion1, changes with Expansion2 made part of that fix logic no longer functional
            -- If at war and occupying one of their cities, it will show as "CityName, return" or "CityName, cede"
            -- The ", cede" is a special case -- it exists only for civs that have occupancy penalties (basically all except Persia)
            local isCedeCity = (pCity ~= nil and (string.match(entry.ForTypeName, Locale.Lookup("LOC_DIPLOMACY_DEAL_CEDE_CITY", pCity:GetName())) ~= nil));
            if pCity == nil or (isCedeCity and not pCity:IsOccupied()) then
                -- shows Occupied as false for the cedeing party
                -- pull the data for this city from the otherPlayer data, as otherPlayer owns it
                pCity = otherPlayer:GetCities():FindID( type ); 
            end

            -- pCity should never be nil here, if it is print a warning so the scenario can be reproduced
            if pCity ~= nil then
                local icon = CQUI_RenderCityButton(pCity, player, iconList.ListStack);
                local uiMinimizedIcon = g_IconOnlyIM:GetInstance(uiMinimizedSection.MinimizedSectionStack);
                SetIconToSize(uiMinimizedIcon.Icon, "ICON_BUILDINGS", 45);
                uiMinimizedIcon.AmountText:SetHide(true);
                uiMinimizedIcon.SelectButton:SetDisabled( not entry.IsValid and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY );	-- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
                uiMinimizedIcon.RemoveButton:SetHide(true);
                uiMinimizedIcon.StopAskingButton:SetHide(true);
                uiMinimizedIcon.SelectButton:SetToolTipString( CQUI_MakeCityToolTip(pCity, player) );

                -- What to do when double clicked/tapped.
                icon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableCity(player, type, subType); end );
                uiMinimizedIcon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableCity(player, type, subType); end );

                iAvailableItemCount = iAvailableItemCount + 1;
            else
                print("ERROR: diplomacydealview_CQUI.lua / PopulateAvailableCities: pCity is nil, could not find match in either player data!");
            end
        end

        iconList.ListStack:CalculateSize();
    end

    uiMinimizedSection.MinimizedSectionContainer:SetHide(iconList.ListStack:IsVisible());
    iconList.HeaderExpandButton:RegisterCallback(Mouse.eLClick, function() OnDealsHeaderCollapseButton(iconList.ListStack, uiMinimizedSection.MinimizedSectionContainer, iconList.HeaderExpandButton); end);
    iconList.HeaderExpandButton:SetHide(table.count(iconList.ListStack:GetChildren()) == 1);

    -- Hide if empty
    iconList.GetTopControl():SetHide( iconList.ListStack:GetSizeX()==0 );

    return iAvailableItemCount;
end

-- ===========================================================================
--  CQUI modified PopulateAvailableGreatWorks function
-- ===========================================================================
function PopulateAvailableGreatWorks(player : table, iconList : table)
    local iAvailableItemCount = 0;
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID());
    local possibleItems = DealManager.GetPossibleDealItems(player:GetID(), GetOtherPlayer(player):GetID(), DealItemTypes.GREATWORK, pForDeal);

    if (pForDeal ~= nil) then
        ms_MinimizedSectionIM:ReleaseInstanceByParent(iconList.List);
        if (CQUI_IsCQUIXmlLoaded()) then
            CQUI_IconAndTextForGreatWorkIM:ReleaseInstanceByParent(iconList.ListStack);
        end
    end

    local uiMinimizedSection:table = ms_MinimizedSectionIM:GetInstance(iconList.List);

    -- CQUI : Sort by great work type
    local sort_func = function( a,b ) return a.ForTypeDescriptionID < b.ForTypeDescriptionID end;
    table.sort( possibleItems, sort_func );

    if (possibleItems ~= nil) then
        for i, entry in ipairs(possibleItems) do
            local greatWorkDesc = GameInfo.GreatWorks[entry.ForTypeDescriptionID];
            if (greatWorkDesc ~= nil) then
                local type = entry.ForType;
                local isCQUIXmlLoaded = CQUI_IsCQUIXmlLoaded();
                local icon = nil;
                local uiMinimizedIcon = g_IconOnlyIM:GetInstance(uiMinimizedSection.MinimizedSectionStack);

                if (isCQUIXmlLoaded) then
                    icon = CQUI_IconAndTextForGreatWorkIM:GetInstance(iconList.ListStack);
                else
                    -- CQUI DiplomacyDealView XML is not loaded, use the standard GreatWork button
                    icon = g_IconAndTextIM:GetInstance(iconList.ListStack);
                end

                SetIconToSize(icon.Icon, "ICON_" .. greatWorkDesc.GreatWorkType, 45);
                SetIconToSize(uiMinimizedIcon.Icon, "ICON_" .. greatWorkDesc.GreatWorkType, 45);

                icon.AmountText:SetHide(true);
                icon.IconText:LocalizeAndSetText(entry.ForTypeName);
                icon.SelectButton:SetDisabled( not entry.IsValid and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY ); -- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
                --icon.ValueText:SetHide(true);
                icon.Icon:SetColor(1, 1, 1);

                uiMinimizedIcon.AmountText:SetHide(true);
                uiMinimizedIcon.SelectButton:SetDisabled( not entry.IsValid and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY );	-- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
                uiMinimizedIcon.RemoveButton:SetHide(true);
                uiMinimizedIcon.StopAskingButton:SetHide(true);

                -- CQUI (Azurency) : add the type icon
                if (isCQUIXmlLoaded) then
                    local objectType = greatWorkDesc.GreatWorkObjectType;
                    local slotTypeIcon = "ICON_" .. objectType;
                    if objectType == "GREATWORKOBJECT_ARTIFACT" then
                        slotTypeIcon = slotTypeIcon .. "_" .. greatWorkDesc.EraType;
                    end
                    local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(slotTypeIcon, CQUI_SIZE_SLOT_TYPE_ICON);
                    if (textureSheet == nil or textureSheet == "") then
                        UI.DataError("Could not find slot type icon in PopulateAvailableGreatWorks: icon=\""..slotTypeIcon.."\", iconSize="..tostring(CQUI_SIZE_SLOT_TYPE_ICON));
                    else
                        icon.TypeIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
                    end
                else
                    -- The RemoveButton and StopAskingButton objects are not defined in the CQUI IconAndTextForGreatWork Control
                    icon.RemoveButton:SetHide(true);
                    icon.StopAskingButton:SetHide(true);
                end

                -- CQUI (Azurency) : add creator to the IconText
                local tInstInfo:table = Game.GetGreatWorkDataFromIndex(entry.ForType);
                local strCreator:string = Locale.Lookup(tInstInfo.CreatorName);
                icon.ValueText:SetText(strCreator);
                icon.ValueText:SetColorByName("GrayMedium");

                -- What to do when double clicked/tapped.
                icon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableGreatWork(player, type); end );
                uiMinimizedIcon.SelectButton:RegisterCallback( Mouse.eLClick, function() OnClickAvailableGreatWork(player, type); end );

                -- Set a tool tip
                local strGreatWorkTooltip = GreatWorksSupport_GetBasicTooltip(entry.ForType, false);
                icon.SelectButton:SetToolTipString(strGreatWorkTooltip);
                uiMinimizedIcon.SelectButton:SetToolTipString(strGreatWorkTooltip);

                icon.SelectButton:ReprocessAnchoring();

                iAvailableItemCount = iAvailableItemCount + 1;
            end
        end

        iconList.ListStack:CalculateSize();
        iconList.List:ReprocessAnchoring();
    end

    uiMinimizedSection.MinimizedSectionContainer:SetHide(iconList.ListStack:IsVisible());
    iconList.HeaderExpandButton:RegisterCallback(Mouse.eLClick, function() OnDealsHeaderCollapseButton(iconList.ListStack, uiMinimizedSection.MinimizedSectionContainer, iconList.HeaderExpandButton); end);
    iconList.HeaderExpandButton:SetHide( table.count(iconList.ListStack:GetChildren()) == 1 );

    -- Hide if empty
    iconList.GetTopControl():SetHide( iconList.ListStack:GetSizeX()==0 );

    return iAvailableItemCount;
end

-- ===========================================================================
    -- We need to reset the text color as it does not get reset if an instance is next used for gold or diplomatic favor
    -- Note: Calling ResetInstances just puts the already-allocated instances into an available list and does NOT reset these properties changed by CQUI
function CQUI_CleanAllocatedInstances()
    for i=1, #g_IconOnlyIM.m_AllocatedInstances, 1 do
        local inst = g_IconOnlyIM.m_AllocatedInstances[i];
        -- Reset the text color, in case it was set to red or blue because this instances was last used for a scarce or duplicate resource
        inst.AmountText:SetColor(UI.GetColorValue(194/255,194/255,204/255))
        -- Reset these as well, because it appears it is not always cleared as it should be if that instance ends up as the diplomatic favor or gold button
        inst.UnacceptableIcon:SetHide(true);
        inst.RemoveButton:SetHide(true);
    end
end

-- ===========================================================================
--  CQUI OnShowMakeDeal to set the g_LocalPlayer and g_OtherPlayer
-- ===========================================================================
function CQUI_OnShowMakeDeal(otherPlayerID)
    g_LocalPlayer = Players[Game.GetLocalPlayer()];
    g_OtherPlayer = Players[otherPlayerID];
    CQUI_CleanAllocatedInstances();
    OnShowMakeDeal(otherPlayerID);
end

-- ===========================================================================
--  CQUI OnShowMakeDemand to set the g_LocalPlayer and g_OtherPlayer
-- ===========================================================================
function CQUI_OnShowMakeDemand(otherPlayerID)
    g_LocalPlayer = Players[Game.GetLocalPlayer()];
    g_OtherPlayer = Players[otherPlayerID];
    CQUI_CleanAllocatedInstances();
    OnShowMakeDemand(otherPlayerID);
end

-- ===========================================================================
local CQUI_IssuedMissingXMLWarning = false;
function CQUI_IsCQUIXmlLoaded()
    -- Check and see if the Controls unique to CQUI are not-nil, and if so, the CQUI DiplomacyDealView XML must be loaded
    isCquiXmlActive = true;
    isCquiXmlActive = isCquiXmlActive and (Controls.PlayerCivIcon ~= nil);
    isCquiXmlActive = isCquiXmlActive and (Controls.PlayerLeaderName ~= nil);
    isCquiXmlActive = isCquiXmlActive and (Controls.PlayerCivName ~= nil);
    isCquiXmlActive = isCquiXmlActive and (Controls.OtherPlayerCivIcon ~= nil);
    isCquiXmlActive = isCquiXmlActive and (Controls.OtherPlayerLeaderName ~= nil);
    isCquiXmlActive = isCquiXmlActive and (Controls.OtherPlayerCivName ~= nil);

    if (isCquiXmlActive == false and CQUI_IssuedMissingXMLWarning == false) then
        -- Prints in the log once, so we don't spam the thing
        print("****** CQUI ERROR: It appears the CQUI version of the DiplomacyDealView XML file did not load properly!  CQUI effects cannot be applied!");
        CQUI_IssuedMissingXMLWarning = true;
    end

    return isCquiXmlActive;
end

-- ===========================================================================
function Initialize_DiplomacyDealView_CQUI()
    -- Override the unmodified game for these Lua Events
    LuaEvents.DiploPopup_ShowMakeDeal.Remove(OnShowMakeDeal);
    LuaEvents.DiploPopup_ShowMakeDemand.Remove(OnShowMakeDemand);
    LuaEvents.DiploPopup_ShowMakeDeal.Add(CQUI_OnShowMakeDeal);
    LuaEvents.DiploPopup_ShowMakeDemand.Add(CQUI_OnShowMakeDemand);

    -- CQUI Custom Icons in Trade Screen - only instantiate if the CQUI XML was loaded
    if (CQUI_IsCQUIXmlLoaded()) then
        CQUI_IconAndTextForCitiesIM = InstanceManager:new( "IconAndTextForCities", "SelectButton", Controls.IconOnlyContainer );
        CQUI_IconAndTextForGreatWorkIM = InstanceManager:new( "IconAndTextForGreatWork", "SelectButton", Controls.IconOnlyContainer );
    end

    -- These are declared in the Expansions version of DiplomacyDealView, resetting them here as nil should not hurt things
    g_LocalPlayer = nil;
    g_OtherPlayer = nil;

    -- With the January 2021 update, Firaxis declared this object globally with the Expansion2 files, and kept it as local in the Vanilla and Expansion1.
    -- Declaring this here is therefore necessary as diplomacydealview_CQUI.lua references the g_IconOnlyIM object.
    if (g_IconOnlyIM == nil) then
        g_IconOnlyIM = InstanceManager:new( "IconOnly", "SelectButton", Controls.IconOnlyContainer );
    end

    -- Do the same for the IconAndText object, as it will be used in cases where the CQUI XML did not get loaded
    if (g_IconAndTextIM == nil) then
        g_IconAndTextIM = InstanceManager:new( "IconAndText",  "SelectButton", Controls.IconAndTextContainer );
    end
end
Initialize_DiplomacyDealView_CQUI();