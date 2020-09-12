include("LensSupport")

function isAncientClassicalWonder(wonderTypeID:number)
    for row in GameInfo.Buildings() do
        if row.Index == wonderTypeID then
            -- Make hash, and get era
            if row.PrereqTech ~= nil then
                prereqTechHash = DB.MakeHash(row.PrereqTech)
                eraType = GameInfo.Technologies[prereqTechHash].EraType
            elseif row.PrereqCivic ~= nil then
                prereqCivicHash = DB.MakeHash(row.PrereqCivic)
                eraType = GameInfo.Civics[prereqCivicHash].EraType
            else
                -- Wonder has no prereq
                return true
            end

            if eraType == nil then
                return true
            elseif eraType == "ERA_ANCIENT" or eraType == "ERA_CLASSICAL" then
                return true
            end
        end
    end
    return false
end

function BuilderCanConstruct(improvementInfo)
    for improvementBuildUnits in GameInfo.Improvement_ValidBuildUnits() do
        if improvementBuildUnits ~= nil and improvementBuildUnits.ImprovementType == improvementInfo.ImprovementType and
            improvementBuildUnits.UnitType == "UNIT_BUILDER" then
                return true
        end
    end
    return false
end

function playerCanRemoveFeature(pPlayer:table, pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil then
        if not featureInfo.Removable then return false end

        -- Check for remove tech
        if featureInfo.RemoveTech ~= nil then
            local tech = GameInfo.Technologies[featureInfo.RemoveTech]
            local playerTech:table = pPlayer:GetTechs()
            if tech ~= nil  then
                return playerTech:HasTech(tech.Index)
            else
                return false
            end
        else
            return true
        end
    end
    return false
end

function playerCanImproveFeature(pPlayer:table, pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil then
        for validFeatureInfo in GameInfo.Improvement_ValidFeatures() do
            if validFeatureInfo ~= nil and validFeatureInfo.FeatureType == featureInfo.FeatureType then
                improvementType = validFeatureInfo.ImprovementType
                improvementInfo = GameInfo.Improvements[improvementType]
                if improvementInfo ~= nil and BuilderCanConstruct(improvementInfo) and playerCanHave(pPlayer, improvementInfo) then
                    -- print("can have " .. improvementType)
                    return true
                end
            end
        end
    end
    return false
end

function plotHasYieldExtractingFeature(pPlayer:table, pPlot:table)
    if plotHasFeature(pPlot) and playerCanRemoveFeature(pPlayer, pPlot) then
        local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
        for kRow in GameInfo.Feature_Removes() do
            if kRow.FeatureType == featureInfo.FeatureType and kRow.Yield ~= nil then
                return kRow.Yield > 0
            end
        end
    end
    return false
end

function plotCountAdjSeaResource(pPlayer:table, pPlot:table)
    local cnt = 0
    for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        if pAdjPlot:IsWater() and plotHasResource(pAdjPlot) and playerHasDiscoveredResource(pPlayer, pAdjPlot) then
            cnt = cnt + 1
        end
    end
    return cnt
end

function plotHasAdjImprovement(pPlot:table, sImprvType:string)
    for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        if plotHasImprovement(pAdjPlot) then
            if sImprvType == nil then
                return true
            else
                local kImprvRow = GameInfo.Improvements[pAdjPlot:GetImprovementType()]
                if kImprvRow ~= nil and kImprvRow.ImprovementType == sImprvType then
                    return true
                end
            end
        end
    end
    return false
end

function plotHasAdjBonusOrLuxury(pPlayer:table, pPlot:table)
    for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        if plotHasResource(pAdjPlot) and playerHasDiscoveredResource(pPlayer, pAdjPlot) then
            -- Check if the resource is luxury or strategic
            resInfo = GameInfo.Resources[pAdjPlot:GetResourceType()]
            if resInfo ~= nil and (resInfo.ResourceClassType == "RESOURCECLASS_BONUS" or
                    resInfo.ResourceClassType == "RESOURCECLASS_LUXURY") then

                return true
            end
        end
    end
    return false
end

function plotCountAdjTerrain(pPlayer:table, pPlot:table)
    local playerVis:table = PlayersVisibility[pPlayer:GetID()]
    local cnt:number = 0
    for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        if playerVis.IsRevealed(pAdjPlot:GetX(), pAdjPlot:GetY()) and not pAdjPlot:IsWater() then
            cnt = cnt + 1
        end
    end
    return cnt
end

-- Incomplete handler to check if that plot has a buildable improvement
-- FIXME: Does not check requirements properly so some improvements pass through, example: fishery
function plotCanHaveImprovement(pPlayer:table, pPlot:table, kImprvRow:table)
    if kImprvRow ~= nil and kImprvRow.Buildable then

        -- Do the simple checks first
        -- Domain checks
        if kImprvRow.Coast and not pPlot:IsCoastalLand() then
            return false
        end
        if kImprvRow.Domain == "DOMAIN_LAND" and pPlot:IsWater() then
            return false
        end
        if kImprvRow.Domain == "DOMAIN_SEA" and not pPlot:IsWater() then
            return false
        end
        -- NOTE: Firaxis for some reason made RequiresRiver an integer rather than boolean. Lua defaults 0 to true (don't ask)
        -- So if they patch their original SQL file, I will need to update this again
        if kImprvRow.RequiresRiver == 1 and not pPlot:IsRiver() then
            return false
        end

        -- If the builder cannot consturct it, ignore it
        if not BuilderCanConstruct(kImprvRow) then
            return false
        end

        -- Does the player the prereq tech and civic, or city state
        if not playerCanHave(pPlayer, kImprvRow) then
            return false
        end

        -- Check for improvement validity
        -- How this works is the improvement needs either a valid terrain, feature, or resource to build
        -- Any one of them makes it valid
        local improvementValid:boolean = false

        -- Check for valid terrain
        for kRow in GameInfo.Improvement_ValidTerrains() do
            if kRow ~= nil and kRow.ImprovementType == kImprvRow.ImprovementType then
                -- Does this plot have this terrain?
                local terrainInfo = GameInfo.Terrains[kRow.TerrainType]
                if terrainInfo ~= nil and pPlot:GetTerrainType() == terrainInfo.Index then
                    if playerCanHave(pPlayer, kRow)  then
                        -- print("(terrain) Plot " .. pPlot:GetIndex() .. " can have " .. kImprvRow.ImprovementType)
                        improvementValid = true
                        break
                    end
                end
            end
        end

        -- If the plot has a feature, improvement needs to be valid from this plot's feature unless the player can remove this feature
        if plotHasFeature(pPlot) and not playerCanRemoveFeature(pPlayer, pPlot) then
            improvementValid = false
        end

        -- Check for valid feature
        if not improvementValid and plotHasFeature(pPlot) then
            for kRow in GameInfo.Improvement_ValidFeatures() do
                if kRow ~= nil and kRow.ImprovementType == kImprvRow.ImprovementType then
                    -- Does this plot have this feature?
                    local featureInfo = GameInfo.Features[kRow.FeatureType]
                    if featureInfo ~= nil and pPlot:GetFeatureType() == featureInfo.Index then
                        if playerCanHave(pPlayer, kRow) then
                            -- print("(feature) Plot " .. pPlot:GetIndex() .. " can have " .. kImprvRow.ImprovementType)
                            improvementValid = true
                            break
                        end
                    end
                end
            end
        end

        -- Check for valid resource
        -- Skipping this since if an improvement required a resource to be valid, we won't be handling it here anyways
        --[[
            if not improvementValid then
                for kRow in GameInfo.Improvement_ValidResources() do
                    if kRow ~= nil and kRow.ImprovementType == kImprvRow.ImprovementType then
                        -- Does this plot have this terrain?
                        local resourceInfo = GameInfo.Resources[kRow.ResourceType]
                        if resourceInfo ~= nil and pPlot:GetResourceType() == resourceInfo.Index then
                            if playerCanHave(pPlayer, resourceInfo) and playerCanHave(pPlayer, kRow)  then
                                -- print("(resource) Plot " .. pPlot:GetIndex() .. " can have " .. kImprvRow.ImprovementType)
                                improvementValid = true
                                break
                            end
                        end
                    end
                end
            end
        ]]

        if not improvementValid then
            return false
        end

        -- astog: Disabled for performance reasons. Some plots will get incorrectly highlited as buildable but the trade-off with speed is significant in bigger maps
        --[[
            -- Adjacent Bonus or luxury (example mekewap)
            if improvementValid and kImprvRow.RequiresAdjacentBonusOrLuxury and
                    not plotHasAdjBonusOrLuxury(pPlayer, pPlot) then
                improvementValid = false
                -- print("failed adjacent bonus or luxury")
            end

            -- Adjacent terrain requirement (example polder)
            if improvementValid and kImprvRow.ValidAdjacentTerrainAmount ~= nil and kImprvRow.ValidAdjacentTerrainAmount > 0 then
                cnt = plotCountAdjTerrain(pPlayer, pPlot)
                if cnt < kImprvRow.ValidAdjacentTerrainAmount then
                    improvementValid = false
                    -- print("failed adjacent terrain")
                end
            end

            -- Same adjacent
            if improvementValid and not kImprvRow.SameAdjacentValid then
                for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
                    if pAdjPlot:GetOwner() == pPlayer:GetID() and kImprvRow.Index == pAdjPlot:GetImprovementType() then
                        -- print("failed same adjacent")
                        improvementValid = false
                        break
                    end
                end
            end
        ]]

        -- special handling for city park and fishery
        -- check if the builder governor has the required promotion
        if GameInfo.Governors ~= nil and
                (kImprvRow.ImprovementType == "IMPROVEMENT_FISHERY" or kImprvRow.ImprovementType == "IMPROVEMENT_CITY_PARK") then

            local pGovernor = GetAppointedGovernor(pPlayer:GetID(), builderGovernorIndex)
            if pGovernor ~= nil then
                if kImprvRow.ImprovementType == "IMPROVEMENT_FISHERY" then
                    if not pGovernor:HasPromotion(builderAquacultureHash) then
                        -- print("Aquaculture promotion not present")
                        return false
                    end
                elseif kImprvRow.ImprovementType == "IMPROVEMENT_CITY_PARK" then
                    if not pGovernor:HasPromotion(builderParksRecHash) then
                        -- print("Parks and Recreation promotion not present")
                        return false
                    end
                end
            else
                -- print("Builder Governor not present")
                return false
            end
        end

        -- print(pPlot:GetIndex() .. " can have " .. kImprvRow.ImprovementType)
        return true
    end
    return false
end

function plotCanHaveSomeImprovement(pPlayer:table, pPlot:table)
    for kImprvRow in GameInfo.Improvements() do
        if plotCanHaveImprovement(pPlayer, pPlot, kImprvRow) then
            return true
        end
    end
    return false
end

function plotHasRemovableFeature(pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil and featureInfo.Removable then
        return true
    end
    return false
end

function IsAdjYieldWonder(featureInfo)
    -- List any wonders here that provide yield bonuses, but not mentioned in Features.xml
    local specialWonderList = {
        "FEATURE_TORRES_DEL_PAINE"
    }

    if featureInfo ~= nil and featureInfo.NaturalWonder then
        for adjYieldInfo in GameInfo.Feature_AdjacentYields() do
            if adjYieldInfo ~= nil and adjYieldInfo.FeatureType == featureInfo.FeatureType
                    and adjYieldInfo.YieldChange > 0 then
                return true
            end
        end

        for i, featureType in ipairs(specialWonderList) do
            if featureType == featureInfo.FeatureType then
                return true
            end
        end
    end
    return false
end

function plotNextToBuffingWonder(pPlot:table)
    for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        local featureInfo = GameInfo.Features[pAdjPlot:GetFeatureType()]
        if IsAdjYieldWonder(featureInfo) then
            return true
        end
    end
    return false
end

-- Checks if the resource at this plot has an improvment for it, and the player has tech/civic to build it
function plotResourceImprovable(pPlayer:table, pPlot:table)
    local resourceInfo = GameInfo.Resources[pPlot:GetResourceType()]
    if resourceInfo ~= nil then
        local improvementType = nil
        for validResourceInfo in GameInfo.Improvement_ValidResources() do
            if validResourceInfo ~= nil and validResourceInfo.ResourceType == resourceInfo.ResourceType then
                improvementType = validResourceInfo.ImprovementType
                if improvementType ~= nil then
                    local improvementInfo = GameInfo.Improvements[improvementType]
                    if playerCanHave(pPlayer, improvementInfo) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function plotHasCorrectImprovement(pPlot:table)
    local resourceInfo = GameInfo.Resources[pPlot:GetResourceType()]
    if resourceInfo ~= nil then
        for validResourceInfo in GameInfo.Improvement_ValidResources() do
            if validResourceInfo ~= nil and validResourceInfo.ResourceType == resourceInfo.ResourceType then
                local improvementType = validResourceInfo.ImprovementType
                if improvementType ~= nil and GameInfo.Improvements[improvementType] ~= nil then
                    local improvementID = GameInfo.Improvements[improvementType].RowId - 1
                    if pPlot:GetImprovementType() == improvementID then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function plotWorkedByCitizen(pPlot:table)
    print("Checking worked by for " .. pPlot:GetIndex())
    return pPlot:GetWorkerCount() > 0
end

function playerHasBuilderWonderModifier(playerID)
    return playerHasModifier(playerID, "MODIFIER_PLAYER_ADJUST_UNIT_WONDER_PERCENT")
end

function playerHasBuilderDistrictModifier(playerID)
    return playerHasModifier(playerID, "MODIFIER_PLAYER_ADJUST_UNIT_DISTRICT_PERCENT")
end
