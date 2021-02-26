print("*** CQUI: PlotToolTip_CQUI_Expansion2.lua loaded");
-- ===========================================================================
-- Base File
-- ===========================================================================
include("PlotToolTip");
include("CQUICommon.lua");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_CQUI_FetchData = FetchData;
BASE_CQUI_View = View;

--CQUI Use this table to set up a better order of listing the yields... ie Food before Production
local cquiYieldsOrder:table = { "YIELD_FOOD", "YIELD_PRODUCTION", "YIELD_GOLD", "YIELD_SCIENCE", "YIELD_CULTURE", "YIELD_FAITH" };

-- ===========================================================================
-- Unmodified from the Firaxis PlotToolTip_Expansion2.lua file, save for the name of the Base version of the function
function FetchData( pPlot:table )
    local data :table = BASE_CQUI_FetchData(pPlot);

    data.IsVolcano = MapFeatureManager.IsVolcano(pPlot);
    data.RiverNames	= RiverManager.GetRiverName(pPlot);
    data.VolcanoName = MapFeatureManager.GetVolcanoName(pPlot);
    data.Active = MapFeatureManager.IsActiveVolcano(pPlot);
    data.Erupting = MapFeatureManager.IsVolcanoErupting(pPlot);
    data.Storm = GameClimate.GetActiveStormTypeAtPlot(pPlot);
    data.Drought = GameClimate.GetActiveDroughtTypeAtPlot(pPlot);
    data.DroughtTurns = GameClimate.GetDroughtTurnsAtPlot(pPlot);
    data.CoastalLowland = TerrainManager.GetCoastalLowlandType(pPlot);
    local territory = Territories.GetTerritoryAt(pPlot:GetIndex());
    if (territory) then
        data.TerritoryName = territory:GetName();
    else
        data.TerritoryName = nil;
    end
    if (data.CoastalLowland ~= -1) then
        data.Flooded = TerrainManager.IsFlooded(pPlot);
        data.Submerged = TerrainManager.IsSubmerged(pPlot);
    else
        data.Flooded = false;
        data.Submerged = false;
    end

    return data;
end

-- ===========================================================================
--  CQUI modified GetDetails functiton
--  Re-arrrange the tooltip informations (https://github.com/CQUI-Org/cqui/issues/232)
--  Complete override for Expansion2 to integrate new landscape feature and climate related changes
--  This builds the tool-tip using table.insert as the mechanism for each line
-- ===========================================================================
function GetDetails(data)
    --for k,v in pairs(data) do print(k,v); end -- debug
    local details:table = {};
    local localPlayerID:number = Game.GetLocalPlayer();
    local localPlayer:table = Players[localPlayerID];
    local iTourism:number = 0; -- #75
    
    ------------------------------------------------------------------------------
    -- Civilization, city ownership line and player related data

    if (data.Owner ~= nil) then

        local szOwnerString;

        local pPlayerConfig = PlayerConfigurations[data.Owner];
        if (pPlayerConfig ~= nil) then
            szOwnerString = Locale.Lookup(pPlayerConfig:GetCivilizationShortDescription());
        end

        if (szOwnerString == nil or string.len(szOwnerString) == 0) then
            szOwnerString = Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", data.Owner);
        end

        local pPlayer = Players[data.Owner];
        if (GameConfiguration:IsAnyMultiplayer() and pPlayer:IsHuman()) then
            szOwnerString = szOwnerString .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. ")";
        end

        if pPlayer:IsMajor() then
            szOwnerString = Locale.Lookup("LOC_TOOLTIP_CITY_OWNER", szOwnerString, data.OwningCityName); -- vanilla game
        else
            -- CQUI Remove City Owner if it's a city state as civ name is the same as city owner name
            szOwnerString = Locale.Lookup("LOC_HUD_CITY_OWNER", szOwnerString);
        end
        table.insert(details, szOwnerString);
        
        -- #75 Infixo tourism
        iTourism = pPlayer:GetCulture():GetTourismAt(data.Index);
        --print("..plot tourism at", data.Index, iTourism); -- debug
    end

    ------------------------------------------------------------------------------
    -- TERRAIN AND FEATURE
    
    local szTerrainString;

    if (data.IsLake) then
        szTerrainString = Locale.Lookup("LOC_TOOLTIP_LAKE");
    else
        szTerrainString = Locale.Lookup(data.TerrainTypeName);
    end

    if (data.FeatureType ~= nil) then
        local szFeatureString = Locale.Lookup(GameInfo.Features[data.FeatureType].Name);
        local addCivicName = GameInfo.Features[data.FeatureType].AddCivic;
        
        if (localPlayer ~= nil and addCivicName ~= nil) then
            local civicIndex = GameInfo.Civics[addCivicName].Index;
            if (localPlayer:GetCulture():HasCivic(civicIndex)) then
                    local szAdditionalString;
                if (not data.FeatureAdded) then
                    szAdditionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_OLD_GROWTH");
                else
                    szAdditionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_SECONDARY");
                end
                szFeatureString = szFeatureString .. " " .. szAdditionalString;
            end
        end
        szTerrainString = szTerrainString.."/ ".. szFeatureString;
    end

    -- If there's a river on this plot, add that info as well
    if (data.IsRiver and data.RiverNames) then
        szTerrainString = szTerrainString.."/ "..Locale.Lookup("LOC_RIVER_TOOLTIP_STRING", data.RiverNames);
    end

    -- Insert the line about the terrain
    table.insert(details, szTerrainString);

    -- Next sets of data are short checks, should be obvious what's happening
    if (data.IsVolcano == true) then
        local szVolcanoString = Locale.Lookup("LOC_VOLCANO_TOOLTIP_STRING", data.VolcanoName);
        if (data.Erupting) then
            szVolcanoString = szVolcanoString .. " " .. Locale.Lookup("LOC_VOLCANO_ERUPTING_STRING");
        elseif (data.Active) then
            szVolcanoString = szVolcanoString .. " " .. Locale.Lookup("LOC_VOLCANO_ACTIVE_STRING");
        end
        table.insert(details, szVolcanoString);
    end

    if (data.TerritoryName ~= nil) then
        table.insert(details, Locale.Lookup(data.TerritoryName));
    end

    if (data.Storm ~= -1) then
        table.insert(details, Locale.Lookup(GameInfo.RandomEvents[data.Storm].Name));
    end

    if (data.Drought ~= -1) then
        table.insert(details, Locale.Lookup("LOC_DROUGHT_TOOLTIP_STRING", GameInfo.RandomEvents[data.Drought].Name, data.DroughtTurns));
    end

    if (data.NationalPark ~= "") then
        table.insert(details, data.NationalPark);
    end

    ------------------------------------------------------------------------------
    -- RESOURCE
    -- Add Resource Information if there exists one
    if (data.ResourceType ~= nil) then
        --if it's a resource that requires a tech to improve, let the player know that in the tooltip
        local resourceType = data.ResourceType;
        local resource = GameInfo.Resources[resourceType];
        local resourceHash = GameInfo.Resources[resourceType].Hash;
        
        local resourceColor;
        if (resource.ResourceClassType == "RESOURCECLASS_BONUS") then
            resourceColor = "GoldDark";
        elseif (resource.ResourceClassType == "RESOURCECLASS_LUXURY") then
            resourceColor = "Civ6Purple";
        elseif (resource.ResourceClassType == "RESOURCECLASS_STRATEGIC") then
            resourceColor = "Civ6Red";
        end

        --Color code the resource text if they have a color. For example, antiquity sites don't have a color
        local resourceString;
        if (resourceColor ~= nil) then
            resourceString = "[ICON_"..resourceType.. "] " .. "[COLOR:"..resourceColor.."]"..Locale.Lookup(resource.Name).."[ENDCOLOR]";
        else
            resourceString = "[ICON_"..resourceType.. "] " .. Locale.Lookup(resource.Name);
        end

        local resourceTechType;
        local terrainType = data.TerrainType;
        local featureType = data.FeatureType;
        local valid_feature = false;
        local valid_terrain = false;

        -- Are there any improvements that specifically require this resource?
        for row in GameInfo.Improvement_ValidResources() do
            if (row.ResourceType == resourceType) then
                -- Found one!  Now...can it be constructed on this terrain/feature
                local improvementType = row.ImprovementType;
                local has_feature = false;
                for inner_row in GameInfo.Improvement_ValidFeatures() do
                    if (inner_row.ImprovementType == improvementType) then
                        has_feature = true;
                        if (inner_row.FeatureType == featureType) then
                            valid_feature = true;
                        end
                    end
                end
                valid_feature = not has_feature or valid_feature;
                
                local has_terrain = false;
                for inner_row in GameInfo.Improvement_ValidTerrains() do
                    if (inner_row.ImprovementType == improvementType) then
                        has_terrain = true;
                        if (inner_row.TerrainType == terrainType) then
                            valid_terrain = true;
                        end
                    end
                end
                valid_terrain = not has_terrain or valid_terrain;

                -- If terrain is coast, then only sea-things are valid... otherwise only land
                if ( GameInfo.Terrains[terrainType].TerrainType  == "TERRAIN_COAST") then
                    if ("DOMAIN_SEA" == GameInfo.Improvements[improvementType].Domain) then
                        valid_terrain = true;
                    elseif ("DOMAIN_LAND" == GameInfo.Improvements[improvementType].Domain) then
                        valid_terrain = false;
                    end
                else
                    if ("DOMAIN_SEA" == GameInfo.Improvements[improvementType].Domain) then
                        valid_terrain = false;
                    elseif ("DOMAIN_LAND" == GameInfo.Improvements[improvementType].Domain) then
                        valid_terrain = true;
                    end
                end

                if (valid_feature == true and valid_terrain == true) then
                    resourceTechType = GameInfo.Improvements[improvementType].PrereqTech;
                    break; -- for loop
                end
            end -- if
        end -- for loop

        -- Only show the resource if the player has acquired the tech to make it visible
        if (localPlayer ~= nil) then
            local playerResources = localPlayer:GetResources();
            if (playerResources:IsResourceVisible(resourceHash)) then
                if (resourceTechType ~= nil and valid_feature == true and valid_terrain == true) then
                    local playerTechs  = localPlayer:GetTechs();
                    local techType = GameInfo.Technologies[resourceTechType];
                    if (techType ~= nil and not playerTechs:HasTech(techType.Index)) then
                        resourceString = resourceString .. "[COLOR:Civ6Red]  ( " .. Locale.Lookup("LOC_TOOLTIP_REQUIRES") .. " " .. Locale.Lookup(techType.Name) .. ")[ENDCOLOR]";
                    end
                end

                table.insert(details, resourceString);
            end
		elseif m_isWorldBuilder then
			if (resourceTechType ~= nil and valid_feature == true and valid_terrain == true) then
				local techType = GameInfo.Technologies[resourceTechType];
				if (techType ~= nil) then
					resourceString = resourceString .. "( " .. Locale.Lookup("LOC_TOOLTIP_REQUIRES") .. " " .. Locale.Lookup(techType.Name) .. ")[ENDCOLOR]";
				end
			end
			table.insert(details, resourceString);
        end
        
        -- info about the resource being extracted
        local function ValidImprovement(imprType:string, resourceType:string)
            for row in GameInfo.Improvement_ValidResources() do
                if row.ResourceType == resourceType and row.ImprovementType == imprType then return true; end
            end
            return false;
        end
        if (localPlayer ~= nil) then
            local playerResources = localPlayer:GetResources();
            if(playerResources:IsResourceVisible(resourceHash)) then
                local resourceTechType = resource.PrereqTech;
                if (resourceTechType ~= nil) then
                    local playerTechs = localPlayer:GetTechs();
                    local techType = GameInfo.Technologies[resourceTechType];
                    if (techType ~= nil and playerTechs:HasTech(techType.Index)) then
                        -- check if improved
                        if (data.DistrictType ~= nil and not data.DistrictPillaged) or (data.ImprovementType ~= nil and not data.ImprovementPillaged and ValidImprovement(data.ImprovementType, resourceType)) then 
                            local kConsumption:table = GameInfo.Resource_Consumption[data.ResourceType];    
                            if (kConsumption ~= nil and kConsumption.Accumulate) then
                                local iExtraction = kConsumption.ImprovedExtractionRate; -- TODO: there is also BaseExtractionRate but not used currently
                                if (iExtraction > 0) then
                                    local resourceIcon:string = "[ICON_" .. data.ResourceType .. "]";
                                    table.insert(details, Locale.Lookup("LOC_RESOURCE_ACCUMULATION_BUILD_IMPROVEMENT", iExtraction, resourceIcon, "[COLOR:Civ6Red]"..Locale.Lookup(resource.Name).."[ENDCOLOR]")); -- {1_Amount} {2_Icon} {3_ResourceName} per turn
                                end
                            end
                        else
                            if data.Owner == localPlayerID then
                                table.insert(details, Locale.Lookup("LOC_CQUI_TOOLTIP_PLOT_IMPROVE_RESOURCE"));
                            end
                        end -- if improved
                    end -- has tech
                end
            end -- visible
        end
        
    end -- if ResourceType is not nil

    table.insert(details, "------------------");

    ------------------------------------------------------------------------------
    -- ROUTE TILE - CQUI Modified Doesn't display movement cost if route movement exists
    local szMoveString;
    if (data.IsRoute and not data.Impassable) then
        local routeInfo = GameInfo.Routes[data.RouteType];
        if (routeInfo ~= nil and routeInfo.MovementCost ~= nil and routeInfo.Name ~= nil) then
            if (data.RoutePillaged) then
                szMoveString = Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT_PILLAGED", routeInfo.MovementCost, routeInfo.Name);
            else
                szMoveString = Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT", routeInfo.MovementCost, routeInfo.Name);
            end
            szMoveString = szMoveString.. "[ICON_Movement]";
        end
    elseif (not data.Impassable and data.MovementCost > 0) then
        szMoveString = Locale.Lookup("LOC_TOOLTIP_MOVEMENT_COST", data.MovementCost).. "[ICON_Movement]";
    end

    if (szMoveString ~=nil) then
        table.insert(details,szMoveString);
    end

    -- Defense modifier
    if (data.DefenseModifier ~= 0) then
        table.insert(details, Locale.Lookup("LOC_TOOLTIP_DEFENSE_MODIFIER", data.DefenseModifier).. "[ICON_STRENGTH]");
    end

    -- Appeal
    local feature = nil;
    if (data.FeatureType ~= nil) then
            feature = GameInfo.Features[data.FeatureType];
    end

    if ((data.FeatureType ~= nil and feature.NaturalWonder) or not data.IsWater) then
        local strAppealDescriptor;
        for row in GameInfo.AppealHousingChanges() do
            local iMinimumValue = row.MinimumValue;
            local szDescription = row.Description;
            if (data.Appeal >= iMinimumValue) then
                strAppealDescriptor = Locale.Lookup(szDescription);
                break;
            end
        end
        if (strAppealDescriptor) then
            table.insert(details, Locale.Lookup("LOC_TOOLTIP_APPEAL", strAppealDescriptor, data.Appeal));
        end
    end

    -- #75 Infixo tourism
    if iTourism > 0 then table.insert(details, string.format("%s: %+d[ICON_Tourism]", Locale.Lookup("LOC_TOP_PANEL_TOURISM"), iTourism)); end

    -- Do not include ('none') continent line unless continent plot. #35955
    if (data.Continent ~= nil) then
        table.insert(details, Locale.Lookup("LOC_TOOLTIP_CONTINENT", GameInfo.Continents[data.Continent].Description));
    end

    -- Conditional display based on tile type

    -- WONDER TILE
    if (data.WonderType ~= nil) then
        table.insert(details, "------------------");
        if (data.WonderComplete == true) then
            table.insert(details, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name));
        else
            table.insert(details, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT"));
        end
    end

    ------------------------------------------------------------------------------
    -- YIELDS
    local function ShowYields(details:table, yields:table)
        --for k,v in pairs(yields) do print(k,v); end -- debug
        for _,yieldType in ipairs(cquiYieldsOrder) do
            if yields[yieldType] ~= nil then
                local yield:table = GameInfo.Yields[yieldType];
                table.insert(details, string.format("%d%s%s", yields[yieldType], yield.IconString, Locale.Lookup(yield.Name)));
            end
        end
    end

    -- Fill in the next set of info based on whether it's a city, district, or other tile
    if (data.IsCity == true and data.DistrictType ~= nil) then
        -- CITY TILE
        table.insert(details, "------------------");
        table.insert(details, Locale.Lookup(GameInfo.Districts[data.DistrictType].Name));
        ShowYields(details, data.Yields);

    elseif(data.DistrictID ~= -1 and data.DistrictType ~= nil and not GameInfo.Districts[data.DistrictType].InternalOnly) then
        -- DISTRICT TILE (ignore 'Wonder' districts)
        -- Plot yields (ie. from Specialists)
        if (data.Yields ~= nil) then
            if (table.count(data.Yields) > 0) then
                table.insert(details, "------------------");
                table.insert(details, Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGE_CITIES_9_CHAPTER_CONTENT_TITLE")); -- "Specialists", text lock :'()
            end
            ShowYields(details, data.Yields);
        end

        -- Inherent district yields
        local sDistrictName :string = Locale.Lookup(GameInfo.Districts[data.DistrictType].Name);
        if (data.DistrictPillaged) then
            sDistrictName = sDistrictName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT");
        elseif (not data.DistrictComplete) then
            sDistrictName = sDistrictName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT");
        end

        table.insert(details, "------------------");
        table.insert(details, sDistrictName);

        -- List the yields from this district tile
        if (data.DistrictYields ~= nil) then
            ShowYields(details, data.DistrictYields);
        end

    else
        -- OTHER TILE (Not city, not district)
        table.insert(details, "------------------");
        if (data.ImprovementType ~= nil) then
            local improvementStr = Locale.Lookup(GameInfo.Improvements[data.ImprovementType].Name);
            if (data.ImprovementPillaged) then
                improvementStr = improvementStr .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT");
            end

            table.insert(details, improvementStr)
            -- ==== CQUI WORKAROUND: Incorporate inforamtion from  the Barbarian Clans Mode to enable CQUI and that mode to work together ====
            -- ==== Firaxis added a ReplaceUIScript for PlotToolTip with the Barbarian Clans mode; incorporating this code allows CQUI to load its PlotToolTip
            if (g_bIsBarbarianClansMode and data.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP") then
                local pBarbManager = Game.GetBarbarianManager();
                local iTribeIndex = pBarbManager:GetTribeIndexAtLocation(data.X, data.Y);
                if (iTribeIndex >= 0) then
                    local eTribeName = pBarbManager:GetTribeNameType(iTribeIndex);
                    if (GameInfo.BarbarianTribeNames[eTribeName] ~= nil) then
                        local tribeNameStr = Locale.Lookup("LOC_TOOLTIP_BARBARIAN_CLAN_NAME", GameInfo.BarbarianTribeNames[eTribeName].TribeDisplayName);
                        table.insert(details, tribeNameStr);
                    end
                end
            end
        end

        ShowYields(details, data.Yields);
    end -- city / district / normal

    -- if tile is impassable, add that line
    if (data.Impassable == true) then
        table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_IMPASSABLE_TEXT"));
    end

    -- NATURAL WONDER TILE
    if (data.FeatureType ~= nil) then
        if (feature.NaturalWonder) then
            table.insert(details, "------------------");
            table.insert(details, Locale.Lookup(feature.Description));
        end
    end

    -- For districts, city center show all building info including Great Works
    -- For wonders, just show Great Work info
    if (data.IsCity or data.WonderType ~= nil or data.DistrictID ~= -1) then
        if (data.BuildingNames ~= nil and table.count(data.BuildingNames) > 0) then
            local cityBuildings = data.OwnerCity:GetBuildings();
            if (data.WonderType == nil) then
                table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_BUILDINGS_TEXT"));
            end

            local greatWorksSection: table = {};
            for i, v in ipairs(data.BuildingNames) do
                if (data.WonderType == nil) then
                    if (data.BuildingsPillaged[i]) then
                        table.insert(details, "- " .. Locale.Lookup(v) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT"));
                    else
                        table.insert(details, "- " .. Locale.Lookup(v));
                    end
                end

                local iSlots = cityBuildings:GetNumGreatWorkSlots(data.BuildingTypes[i]);
                for j = 0, iSlots - 1, 1 do
                    local greatWorkIndex:number = cityBuildings:GetGreatWorkInSlot(data.BuildingTypes[i], j);
                    if (greatWorkIndex ~= -1) then
                        local greatWorkType:number = cityBuildings:GetGreatWorkTypeFromIndex(greatWorkIndex)
                        table.insert(greatWorksSection, "  * " .. Locale.Lookup(GameInfo.GreatWorks[greatWorkType].Name));
                    end
                end
            end

            if #greatWorksSection > 0 then
                for i, v in ipairs(greatWorksSection) do
                    table.insert(details, v);
                end
            end
        end
    end

    -- Show number of civilians working here
    if (data.Owner == localPlayerID and data.Workers > 0) then
        table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_WORKED_TEXT", data.Workers));
    end

    if (data.Fallout > 0) then
        table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", data.Fallout));
    end

    if (data.CoastalLowland ~= -1) then
        local szDetailsText = "";
        if (data.CoastalLowland == 0) then
            szDetailsText = Locale.Lookup("LOC_COASTAL_LOWLAND_1M_NAME");
        elseif (data.CoastalLowland == 1) then
            szDetailsText = Locale.Lookup("LOC_COASTAL_LOWLAND_2M_NAME");
        elseif (data.CoastalLowland == 2) then
            szDetailsText = Locale.Lookup("LOC_COASTAL_LOWLAND_3M_NAME");
        end

        if (data.Submerged) then
            szDetailsText = szDetailsText .. " " .. Locale.Lookup ("LOC_COASTAL_LOWLAND_SUBMERGED");
        elseif (data.Flooded) then
            szDetailsText = szDetailsText .. " " .. Locale.Lookup ("LOC_COASTAL_LOWLAND_FLOODED");
        end

        table.insert(details, szDetailsText);
    end

    return details;
end

-- ===========================================================================
--  CQUI modified View functiton
--  Hide Plotname (https://github.com/CQUI-Org/cqui/issues/232)
-- ===========================================================================
function View(data:table, bIsUpdate:boolean)
    BASE_CQUI_View(data, bIsUpdate);

    Controls.PlotName:SetHide(true)
end

-- ===========================================================================
function Initialize_PlotTooltip_CQUI_Exp2()
    Controls.TooltipMain:SetSpeed(8);  -- CQUI : tooltip spawn faster
end
Initialize_PlotTooltip_CQUI_Exp2();