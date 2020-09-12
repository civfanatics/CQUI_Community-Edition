include("BuilderLens_Support")

-- ===========================================================================
-- Helpers
-- ===========================================================================

local builderGovernorIndex = nil
local builderAquacultureHash = nil
local builderParksRecHash = nil

if GameInfo.Governors ~= nil then
    for row in GameInfo.Governors() do
        if row.GovernorType == "GOVERNOR_THE_BUILDER" then
            builderGovernorIndex = row.Index
            print("Governor Builder Index = " .. builderGovernorIndex)
            break
        end
    end

    for row in GameInfo.GovernorPromotions() do
        if row.GovernorPromotionType == "GOVERNOR_PROMOTION_AQUACULTURE" then
            builderAquacultureHash = row.Hash
            print("Governor Builder Aquaculture hash = " .. builderAquacultureHash)
            break
        end
    end

    for row in GameInfo.GovernorPromotions() do
        if row.GovernorPromotionType == "GOVERNOR_PROMOTION_PARKS_RECREATION" then
            builderParksRecHash = row.Hash
            print("Governor Builder Parks Rec hash = " .. builderParksRecHash)
            break
        end
    end
end

-- From GovernorSupport.lua
function GetAppointedGovernor(playerID:number, governorTypeIndex:number)
    -- Make sure we're looking for a valid governor
    if playerID < 0 or governorTypeIndex < 0 then
        return nil;
    end

    -- Get the player governor list
    local pGovernorDef = GameInfo.Governors[governorTypeIndex];
    local pPlayer:table = Players[playerID];
    local pPlayerGovernors:table = pPlayer:GetGovernors();
    local bHasGovernors, tGovernorList = pPlayerGovernors:GetGovernorList();

    -- Find and return the governor from the governor list
    if pPlayerGovernors:HasGovernor(pGovernorDef.Hash) then
        for i,governor in ipairs(tGovernorList) do
            if governor:GetType() == governorTypeIndex then
                return governor;
            end
        end
    end

    -- Return nil if this player has not appointed that governor
    return nil;
end

-- ===========================================================================
-- Add rules for builder lens
-- ===========================================================================

local m_BuilderLens_PN  = UI.GetColorValue("COLOR_BUILDER_LENS_PN")
local m_BuilderLens_PD  = UI.GetColorValue("COLOR_BUILDER_LENS_PD")
local m_BuilderLens_P1  = UI.GetColorValue("COLOR_BUILDER_LENS_P1")
local m_BuilderLens_P1N = UI.GetColorValue("COLOR_BUILDER_LENS_P1N")
local m_BuilderLens_P2  = UI.GetColorValue("COLOR_BUILDER_LENS_P2")
local m_BuilderLens_P3  = UI.GetColorValue("COLOR_BUILDER_LENS_P3")
local m_BuilderLens_P4  = UI.GetColorValue("COLOR_BUILDER_LENS_P4")
local m_BuilderLens_P5  = UI.GetColorValue("COLOR_BUILDER_LENS_P5")
local m_BuilderLens_P6  = UI.GetColorValue("COLOR_BUILDER_LENS_P6")
local m_BuilderLens_P7  = UI.GetColorValue("COLOR_BUILDER_LENS_P7")


-- NATIONAL PARK
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_PN],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        if pPlot:GetOwner() == localPlayer then
            if pPlot:IsNationalPark() then
                return m_BuilderLens_PN
            end
        end
        return -1
    end)


-- RESOURCE
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P1],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) then
            if playerHasDiscoveredResource(pPlayer, pPlot) then
                if plotHasImprovement(pPlot) then
                    if plotHasCorrectImprovement(pPlot) then
                        return m_BuilderLens_PN
                    end
                end

                if plotResourceImprovable(pPlayer, pPlot) then
                    -- If the plot is within working range go ahead with correct highlight
                    if plotWithinWorkingRange(pPlayer, pPlot) then
                        return m_BuilderLens_P1
                    else
                        -- If the plot is outside working range, it is less important
                        -- We still might want to suggest it because of vital strategic resource / luxury, or a unique wonder
                        -- that can provide bonuses to it example (Temple of Artemis)
                        return m_BuilderLens_P1N
                    end
                else
                    return m_BuilderLens_PN
                end
            end
        end
        return -1
    end)


-- GEOTHERMAL PLANTS (Only add if exists)
--------------------------------------
if GameInfo.Improvements["IMPROVEMENT_GEOTHERMAL_PLANT"] ~= nil then
    table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P2],
        function(pPlot)
            local localPlayer = Game.GetLocalPlayer()
            local pPlayer:table = Players[localPlayer]
            if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and not plotHasImprovement(pPlot)
                    and plotHasFeature(pPlot) then

                local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
                if featureInfo.FeatureType == "FEATURE_GEOTHERMAL_FISSURE" then
                    local plantImprovInfo = GameInfo.Improvements["IMPROVEMENT_GEOTHERMAL_PLANT"]
                    if playerCanHave(pPlayer, plantImprovInfo) then
                        return m_BuilderLens_P2
                    end
                end
            end
        end)
end


-- SEASIDE RESORTS
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P2],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        local resortImprovInfo = GameInfo.Improvements["IMPROVEMENT_BEACH_RESORT"]
        local iAppeal = pPlot:GetAppeal()
        if pPlot:GetOwner() == localPlayer and not pPlot:IsMountain() and not plotHasDistrict(pPlot)
                and iAppeal >= resortImprovInfo.MinimumAppeal
                and plotCanHaveImprovement(pPlayer, pPlot, resortImprovInfo) then

            if playerCanHave(pPlayer, resortImprovInfo) then
                return m_BuilderLens_P2
            end
        end
    end)


-- SKI RESORTS (Only add if exists)
--------------------------------------
if GameInfo.Improvements["IMPROVEMENT_SKI_RESORT"] ~= nil then
    table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P2],
        function(pPlot)
            local localPlayer = Game.GetLocalPlayer()
            local pPlayer:table = Players[localPlayer]
            if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and not plotHasImprovement(pPlot)
                    and pPlot:IsMountain() then

                local resortImprovInfo = GameInfo.Improvements["IMPROVEMENT_SKI_RESORT"]
                if playerCanHave(pPlayer, resortImprovInfo)
                        and not plotHasAdjImprovement(pPlot, "IMPROVEMENT_SKI_RESORT") then
                    return m_BuilderLens_P2
                end
            end
        end)
end


-- PILLAGED / UA
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P2],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) then
            if plotHasImprovement(pPlot) and pPlot:IsImprovementPillaged() then
                return m_BuilderLens_P2
            end
        end
        return -1
    end)


-- IGNORE PLOTS (Performance optimizations)
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P3],
    function(pPlot)
        -- Non local player plots
        local localPlayer = Game.GetLocalPlayer()
        if pPlot:GetOwner() ~= localPlayer then
            return -2  -- special flag to completely ignore coloring
        end

        -- Districts. Assume unique abilities are handled earlier (P2 typically)
        if plotHasDistrict(pPlot) then
            return m_BuilderLens_PN
        end

        -- If an improvement is here, assume we are done with this plot
        if plotHasImprovement(pPlot) then
            return m_BuilderLens_PN
        end

        -- Mountains or impassable wonders
        if pPlot:IsImpassable() then
            return m_BuilderLens_PN
        end

        -- Outside of working range can be ignored from here on out
        local pPlayer:table = Players[localPlayer]
        if not plotWithinWorkingRange(pPlayer, pPlot) then
            return m_BuilderLens_PN
        end
    end)


-- RECOMMENDED PLOTS
--------------------------------------
-- These are generic plots, but have some buff on it that can make it desirable to improve
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P3],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]

        if plotHasFeature(pPlot) then
            local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
            if featureInfo.NaturalWonder then
                return m_BuilderLens_PN
            end

            -- 1. Non-hill woods next to river (lumbermill)
            -- Check for modifier existing because a patch removed this bonus
            local lumberImprovInfo = GameInfo.Improvements["IMPROVEMENT_LUMBER_MILL"]
            if GameInfo.Modifiers["LUMBER_MILL_RIVERADJACENCY_PRODUCTION"] ~= nil and (not pPlot:IsHills())
                    and featureInfo.FeatureType == "FEATURE_FOREST" and pPlot:IsRiver()
                    and playerCanHave(pPlayer, lumberImprovInfo) then

                return m_BuilderLens_P3
            end

            -- 2. Floodplains
            --[[
                local farmImprovInfo = GameInfo.Improvements["IMPROVEMENT_FARM"]
                local spitResult = Split(featureInfo.FeatureType, "_")
                if #spitResult > 1 and spitResult[2] == "FLOODPLAINS" and playerCanHave(pPlayer, farmImprovInfo) then
                    return m_BuilderLens_P3
                end
            ]]

            local canHaveImpr:boolean = plotCanHaveSomeImprovement(pPlayer, pPlot)

            -- 3. Volconic soil or tile next to buffing wonder
            if featureInfo.FeatureType == "FEATURE_VOLCANIC_SOIL" and canHaveImpr then
                return m_BuilderLens_P3
            end

            -- 4. Wonder buffed tile
            if plotNextToBuffingWonder(pPlot) and canHaveImpr then
                return m_BuilderLens_P3
            end
        end

        -- 5. Currently worked tile that does not have a improvement but can have one
        if plotWorkedByCitizen(pPlot) and plotCanHaveSomeImprovement(pPlayer, pPlot) then
            return m_BuilderLens_P3
        end
        return -1
    end)


-- HILLS
--------------------------------------
-- Typically hills have a base +1 Production hence any improvement on top of it is desirable
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P4],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        if pPlot:IsHills() and plotCanHaveSomeImprovement(pPlayer, pPlot) then
            return m_BuilderLens_P4
        end
        return -1
    end)


-- EXTRACTABLE FEATURE
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P5],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        if plotHasYieldExtractingFeature(pPlayer, pPlot) then
            return m_BuilderLens_P5
        end
        return -1
    end)


-- GENERIC (Last rule)
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_BuilderLens_P7],
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]

        -- Can we build any improvement add it here
        if plotCanHaveSomeImprovement(pPlayer, pPlot) then
            return m_BuilderLens_P7
        end

        -- Assume at this point we can't do anything
        return m_BuilderLens_PN
    end)
