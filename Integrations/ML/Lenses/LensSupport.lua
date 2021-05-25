include( "Civ6Common.lua" ) -- GetCivilizationUniqueTraits, GetLeaderUniqueTraits
include( "SupportFunctions" ) -- Split

CITY_WORK_RANGE = GlobalParameters.CITY_MIN_RANGE

function plotWithinWorkingRange(pPlayer:table, pPlot:table)
    local localPlayerCities = pPlayer:GetCities()
    local plotX = pPlot:GetX()
    local plotY = pPlot:GetY()

    for _, pCity in localPlayerCities:Members() do
        if Map.GetPlotDistance(plotX, plotY, pCity:GetX(), pCity:GetY()) <= CITY_WORK_RANGE then
            return true
        end
    end
    return false
end

function plotHasImprovement(pPlot:table)
    return pPlot:GetImprovementType() ~= -1
end

function plotHasResource(pPlot:table)
    return pPlot:GetResourceType() ~= -1
end

function plotHasFeature(pPlot:table)
    return pPlot:GetFeatureType() ~= -1
end

function plotHasWonder(pPlot:table)
    return pPlot:GetWonderType() ~= -1
end

function plotHasDistrict(pPlot:table)
    return pPlot:GetDistrictType() ~= -1
end

function plotHasNaturalWonder(pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil and featureInfo.NaturalWonder then
        return true
    end
    return false
end

-- General function to check if the player has xmlEntry.PrereqTech and xmlEntry.PrereqTech
-- Also handles unique traits, and bonuses received from city states
function playerCanHave(pPlayer:table, xmlEntry:table)
    if xmlEntry == nil then return false end

    local playerID = pPlayer:GetID()
    if xmlEntry.PrereqTech ~= nil then
        local playerTech:table = pPlayer:GetTechs()
        local tech = GameInfo.Technologies[xmlEntry.PrereqTech]
        if tech ~= nil and (not playerTech:HasTech(tech.Index)) then
            -- print("Player does not have " .. tech.TechnologyType)
            return false
        end
    end

    -- Does the player have the prereq civic if one exists
    if xmlEntry.PrereqCivic ~= nil then
        local playerCulture = pPlayer:GetCulture()
        local civic = GameInfo.Civics[xmlEntry.PrereqCivic]
        if civic ~= nil and (not playerCulture:HasCivic(civic.Index)) then
            -- print("Player does not have " .. civic.CivicType)
            return false
        end
    end

    -- Is it a Unique thing to a player/civ
    if xmlEntry.TraitType ~= nil then
        -- print(xmlEntry.TraitType)
        local civilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
        local leaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()
        local isSuzerain:boolean = false

        -- Special handler for city state traits.
        local spitResult = Split(xmlEntry.TraitType, "_")
        if spitResult[1] == "MINOR" then
            local traitLeaderType = nil
            for traitInfo in GameInfo.LeaderTraits() do
                if traitInfo.TraitType == xmlEntry.TraitType then
                    traitLeaderType = traitInfo.LeaderType
                    break
                end
            end

            if traitLeaderType ~= nil then
                -- print("traitLeaderType " .. traitLeaderType)
                local traitLeaderID

                -- See if this city state is present in the game
                for minorID in ipairs(PlayerManager.GetAliveMinorIDs()) do
                    local minorLeaderType = PlayerConfigurations[minorID]:GetLeaderTypeName()
                    if minorLeaderType == traitLeaderType then
                        traitLeaderID = minorID
                        break
                    end
                end

                if traitLeaderID ~= nil then
                    -- Found the player in the game. Is the suzerain the player
                    if playerID ~= Players[traitLeaderID]:GetInfluence():GetSuzerain() then
                        -- print("Player is not the suzerain of " .. minorLeaderType)
                        return false
                    else
                        return true
                    end
                else
                    -- print(traitLeaderType .. " is not in this game")
                    return false
                end
            end
        end

        for traitInfo in GameInfo.CivilizationTraits() do
            if traitInfo.TraitType == xmlEntry.TraitType and
                    traitInfo.CivilizationType ~= nil and
                    civilizationType ~= traitInfo.CivilizationType then
                -- print(civilizationType .. " ~= " .. traitInfo.CivilizationType)
                return false
            end
        end

        for traitInfo in GameInfo.LeaderTraits() do
            if traitInfo.TraitType == xmlEntry.TraitType and
                    traitInfo.LeaderType ~= nil and
                    leaderType ~= traitInfo.LeaderType then
                -- print(civilizationType .. " ~= " .. traitInfo.LeaderType)
                return false
            end
        end

    end
    return true
end

function playerHasModifier(pPlayer:table, modifierType:string)
    -- Get civ, and leader
    local playerID = pPlayer:GetID()
    local civTypeName = PlayerConfigurations[playerID]:GetCivilizationTypeName()
    local leaderTypeName = PlayerConfigurations[playerID]:GetLeaderTypeName()

    local civUA = GetCivilizationUniqueTraits(civTypeName)
    local leaderUA = GetLeaderUniqueTraits(leaderTypeName)

    for _, item in ipairs(civUA) do
        local traitType = civUA[1].TraitType
        -- print("Trait type: " .. traitType)

        -- Find the modifier ID
        local modifierID
        for row in GameInfo.TraitModifiers() do
            if row.TraitType == traitType then
                local modifierID = row.ModifierId

                -- Find the matching modifier type
                if modifierID ~= nil then
                    -- print("Modifier ID: " .. modifierID)
                    for row in GameInfo.Modifiers() do
                        if row.ModifierId == modifierID and row.ModifierType == modifierType then
                            -- print("Player has a modifier for district")
                            return true
                        end
                    end
                end
            end
        end
    end

    for _, item in ipairs(leaderUA) do
        local traitType = leaderUA[1].TraitType
        -- print("Trait type: " .. traitType)

        -- Find the modifier ID
        local modifierID
        for row in GameInfo.TraitModifiers() do
            if row.TraitType == traitType then
                local modifierID = row.ModifierId

                -- Find the matching modifier type
                if modifierID ~= nil then
                    -- print("Modifier ID: " .. modifierID)
                    for row in GameInfo.Modifiers() do
                        if row.ModifierId == modifierID and row.ModifierType == modifierType then
                            -- print("Player has a modifier for district")
                            return true
                        end
                    end
                end
            end
        end
    end
end

-- Uses same logic as the icon manager (returns true, if the resource icon is being displayed on the map)
function playerHasDiscoveredResource(pPlayer:table, pPlot:table)
    if plotHasResource(pPlot) then
        local eObserverID = Game.GetLocalObserver();
        local pLocalPlayerVis = PlayerVisibilityManager.GetPlayerVisibility(eObserverID);
        local xmlEntry = GameInfo.Resources[pPlot:GetResourceType()]

        -- Have a Resource?
        local eResource = pLocalPlayerVis:GetLayerValue(VisibilityLayerTypes.RESOURCES, pPlot:GetIndex());
        local bHideResource = ( pPlot ~= nil and ( pPlot:GetDistrictType() > 0 or pPlot:IsCity() ) )
        if (eResource ~= nil and eResource ~= -1 and not bHideResource ) then
            -- print(pPlot:GetIndex() .. " has " .. xmlEntry.ResourceType)
            return true
        end
    end
    return false
end

-- Tells if the district on this plot is complete or not
function districtComplete(pPlayer:table, pPlot:table)
    local districtID = pPlot:GetDistrictID()
    if districtID ~= nil and districtID >= 0 then
        local pDistrict = pPlayer:GetDistricts():FindID(districtID)
        if pDistrict ~= nil then
            return pDistrict:IsComplete()
        end
    end
    return false
end

function GetUnitTypeFromIDs( playerID: number, unitID : number )
    if( playerID == Game.GetLocalPlayer() ) then
        local pPlayer   :table = Players[playerID];
        local pUnit     :table = pPlayer:GetUnits():FindID(unitID);
        if pUnit ~= nil then
            return GameInfo.Units[pUnit:GetUnitType()].UnitType;
        end
    end
    return nil
end

function getUnitType(pUnit:table)
    local info = GameInfo.Units[pUnit:GetUnitType()]
    if info ~= nil then
        return info.UnitType
    end
    return nil
end

function has_value(tab, val)
    for _, value in ipairs (tab) do
        if value == val then
            return true
        end
    end
    return false
end

function has_rInfo(tab, val)
    for _, value in ipairs (tab) do
        if value.ResourceType == val then
            return true
        end
    end
    return false
end

function find_and_remove(tab, val)
    for i, item in ipairs(tab) do
        if item == val then
            table.remove(tab, i)
            return
        end
    end
end

function ndup_insert(tab, val)
    if not has_value(tab, val) then
        table.insert(tab, val)
    end
end

function get_common_values(tab1, tab2)
    local common_table = {}
    for _, value1 in ipairs (tab1) do
        for _, value2 in ipairs (tab2) do
            if value1 == value2 then
                table.insert(common_table, value1)
            end
        end
    end
    return common_table
end

--------------------------------------------
-- Plot Iterator, Author: whoward69; URL: https://forums.civfanatics.com/threads/border-and-area-plot-iterators.474634/
    -- convert funcs odd-r offset to axial. URL: http://www.redblobgames.com/grids/hexagons/
    -- here grid == offset; hex == axial
    function ToHexFromGrid(grid)
        local hex = {
            x = grid.x - (grid.y - (grid.y % 2)) / 2;
            y = grid.y;
        }
        return hex
    end
    function ToGridFromHex(hex_x, hex_y)
        local grid = {
            x = hex_x + (hex_y - (hex_y % 2)) / 2;
            y = hex_y;
        }
        return grid.x, grid.y
    end

    SECTOR_NONE = nil
    SECTOR_NORTH = 1
    SECTOR_NORTHEAST = 2
    SECTOR_SOUTHEAST = 3
    SECTOR_SOUTH = 4
    SECTOR_SOUTHWEST = 5
    SECTOR_NORTHWEST = 6

    DIRECTION_CLOCKWISE = false
    DIRECTION_ANTICLOCKWISE = true

    DIRECTION_OUTWARDS = false
    DIRECTION_INWARDS = true

    CENTRE_INCLUDE = true
    CENTRE_EXCLUDE = false

    function PlotRingIterator(pPlot, r, sector, anticlock)
        -- print(string.format("PlotRingIterator((%i, %i), r=%i, s=%i, d=%s)", pPlot:GetX(), pPlot:GetY(), r, (sector or SECTOR_NORTH), (anticlock and "rev" or "fwd")))
        -- The important thing to remember with hex-coordinates is that x+y+z = 0
        -- so we never actually need to store z as we can always calculate it as -(x+y)
        -- See http://keekerdc.com/2011/03/hexagon-grids-coordinate-systems-and-distance-calculations/

        if (pPlot ~= nil and r > 0) then
            local hex = ToHexFromGrid({x=pPlot:GetX(), y=pPlot:GetY()})
            local x, y = hex.x, hex.y

            -- Along the North edge of the hex (x-r, y+r, z) to (x, y+r, z-r)
            local function north(x, y, r, i) return {x=x-r+i, y=y+r} end
            -- Along the North-East edge (x, y+r, z-r) to (x+r, y, z-r)
            local function northeast(x, y, r, i) return {x=x+i, y=y+r-i} end
            -- Along the South-East edge (x+r, y, z-r) to (x+r, y-r, z)
            local function southeast(x, y, r, i) return {x=x+r, y=y-i} end
            -- Along the South edge (x+r, y-r, z) to (x, y-r, z+r)
            local function south(x, y, r, i) return {x=x+r-i, y=y-r} end
            -- Along the South-West edge (x, y-r, z+r) to (x-r, y, z+r)
            local function southwest(x, y, r, i) return {x=x-i, y=y-r+i} end
            -- Along the North-West edge (x-r, y, z+r) to (x-r, y+r, z)
            local function northwest(x, y, r, i) return {x=x-r, y=y+i} end

            local side = {north, northeast, southeast, south, southwest, northwest}
            if (sector) then
                for i=(anticlock and 1 or 2), sector, 1 do
                    table.insert(side, table.remove(side, 1))
                end
            end

            -- This coroutine walks the edges of the hex centered on pPlot at radius r
            local next = coroutine.create(function ()
                if (anticlock) then
                    for s=6, 1, -1 do
                        for i=r, 1, -1 do
                            coroutine.yield(side[s](x, y, r, i))
                        end
                    end
                else
                    for s=1, 6, 1 do
                        for i=0, r-1, 1 do
                            coroutine.yield(side[s](x, y, r, i))
                        end
                    end
                end

                return nil
            end)

            -- This function returns the next edge plot in the sequence, ignoring those that fall off the edges of the map
            return function ()
                local pEdgePlot = nil
                local success, hex = coroutine.resume(next)
                -- if (hex ~= nil) then print(string.format("hex(%i, %i, %i)", hex.x, hex.y, -1 * (hex.x+hex.y))) else print("hex(nil)") end

                while (success and hex ~= nil and pEdgePlot == nil) do
                    pEdgePlot = Map.GetPlot(ToGridFromHex(hex.x, hex.y))
                    if (pEdgePlot == nil) then success, hex = coroutine.resume(next) end
                end

                return success and pEdgePlot or nil
            end
        else
            -- Iterators have to return a function, so return a function that returns nil
            return function () return nil end
        end
    end


    function PlotAreaSpiralIterator(pPlot, r, sector, anticlock, inwards, centre)
        -- print(string.format("PlotAreaSpiralIterator((%i, %i), r=%i, s=%i, d=%s, w=%s, c=%s)", pPlot:GetX(), pPlot:GetY(), r, (sector or SECTOR_NORTH), (anticlock and "rev" or "fwd"), (inwards and "in" or "out"), (centre and "yes" or "no")))
        -- This coroutine walks each ring in sequence
        local next = coroutine.create(function ()
            if (centre and not inwards) then
                coroutine.yield(pPlot)
            end

            if (inwards) then
                for i=r, 1, -1 do
                    for pEdgePlot in PlotRingIterator(pPlot, i, sector, anticlock) do
                        coroutine.yield(pEdgePlot)
                    end
                end
            else
                for i=1, r, 1 do
                    for pEdgePlot in PlotRingIterator(pPlot, i, sector, anticlock) do
                        coroutine.yield(pEdgePlot)
                    end
                end
            end

            if (centre and inwards) then
                coroutine.yield(pPlot)
            end

            return nil
        end)

        -- This function returns the next plot in the sequence
        return function ()
            local success, pAreaPlot = coroutine.resume(next)
            return success and pAreaPlot or nil
        end
    end
-- End of iterator code --------------------

function GetLensColorFromSettings(lensName)
    -- A lens color can be set by the CQUI Settings elements
    local lensData = GameConfiguration.GetValue(lensName);
    if (lensData == nil) then
        lensData = GameInfo.Colors[lensName];
        if (lensData == nil) then
            lensData = {}
            lensData["Red"] = 0;
            lensData["Blue"] = 0;
            lensData["Green"] = 0;
        end

        GameConfiguration.SetValue(lensName, lensData);
    end

    return UI.GetColorValue(lensData["Red"], lensData["Green"], lensData["Blue"]);
end

-- lensEntitiesTable is a table structured like what is seen in ModLens_Builder or CQUI_CitizenManagement - the list of Lens Entities (Colors) for that Particular Lens
-- modLensModalPanelTable is the table used by modalpanel.lua to construct the Key table for any lens
-- lens_name is the LENS_NAME value from that lens
function UpdateLensConfiguredColors(lensEntitiesTable, modLensModalPanelTable, lens_name)
    -- Called whenever we want to force the Lens Colors to be refreshed
    -- GetLensColorFromSettings will get the value if stored by GameConfiguration.SetValue,
    -- otherwise it will load the value from the GameInfo.Colors table that was updated by the MoreLenses SQL file
    for lensKey, lensConfig in pairs(lensEntitiesTable) do
        lensColor = GetLensColorFromSettings(lensKey);
        lensEntitiesTable[lensKey].ConfiguredColor = lensColor;
        -- Not sure there's a better way to do this and also keep the structure of g_ModLensModalPanel?
        -- defined only by modellenspanel.lua, so only gets called when in the modellenspanel context
        if modLensModalPanelTable ~= nil then
            lensLegend = modLensModalPanelTable[lens_name].Legend;
            for idx, entry in ipairs(modLensModalPanelTable[lens_name].Legend) do
                locVal, colorVal = unpack(entry);
                if locVal == lensEntitiesTable[lensKey].KeyLabel then
                    modLensModalPanelTable[lens_name].Legend[idx] = {lensEntitiesTable[lensKey].KeyLabel, lensColor};
                    break;
                end
            end
        end
    end
end
