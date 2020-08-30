------------------------------------------------------------------------------
-- Additional CQUI Common LUA support functions specific to Civilization 6
-- Contains:
-- * Expansions check
-- * Debug support
-- * CQUI_TrimGossipMessage
-- * CQUI_GetRealHousingFromImprovements
------------------------------------------------------------------------------

-- ===========================================================================
-- Expansions check
-- ===========================================================================

-- these are global variables, will be visible in the entire context
-- please note that Modding object is only available in the UI context
-- in the Gameplay context a different method must be used as those variables will be nil
g_bIsRiseAndFall    = Modding and Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
g_bIsGatheringStorm = Modding and Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm


-- ===========================================================================
-- Debug support
-- ===========================================================================

CQUI_ShowDebugPrint = false;

function print_debug(...)
    if CQUI_ShowDebugPrint then
        print(...);
    end
end

function CQUI_OnSettingsUpdate()
    print_debug("ENTRY: CQUICommon - CQUI_OnSettingsUpdate");
    if (GameInfo.CQUI_Settings ~= nil and GameInfo.CQUI_Settings["CQUI_ShowDebugPrint"] ~= nil) then
        CQUI_ShowDebugPrint = ( GameInfo.CQUI_Settings["CQUI_ShowDebugPrint"].Value == 1 );
    else
        CQUI_ShowDebugPrint = GameConfiguration.GetValue("CQUI_ShowDebugPrint");
    end
end


-- ===========================================================================
-- Trims source information from gossip messages. Returns nil if the message couldn't be trimmed (this usually means the provided string wasn't a gossip message at all)
-- ===========================================================================

function CQUI_TrimGossipMessage(str:string)
    print_debug("ENTRY: CQUICommon - CQUI_TrimGossipMessage - string: "..tostring(str));
    -- Get a sample of a gossip source string
    local sourceSample = Locale.Lookup("LOC_GOSSIP_SOURCE_DELEGATE", "XX", "Y", "Z");

    -- Get last word that occurs in the gossip source string. "that" in English.
    -- Assumes the last word is always the same, which it is in English, unsure if this holds true in other languages
    -- AZURENCY : the patterns means : any character 0 or +, XX exactly, any character 0 or +, space, any character other than space 1 or + at the end of the sentence.
    -- AZURENCY : in some languages, there is no space, in that case, take the last character (often it's a ":")
    local last = string.match(sourceSample, ".-XX.-(%s%S+)$"); 
    if last == nil then
        last = string.match(sourceSample, ".-(.)$");
    end

    -- AZURENCY : if last is still nill, it's not normal, print an error but still allow the code to run
    if last == nil then
        print_debug("ERROR : LOC_GOSSIP_SOURCE_DELEGATE seems to be empty as last was still nil after the second pattern matching.")
        last = ""
    end

 -- Return the rest of the string after the last word from the gossip source string
    return Split(str, last .. " " , 2)[2];
end


-- ===========================================================================
-- Calculate real housing from improvements
-- Author: Infixo, code from Better Report Screen
-- 2020-06-09 new idea for calculations - calculate only a correction and apply to the game function
-- please note that another condition was added - a tile must be within workable distance - this is how the game's engine works
-- ===========================================================================

local iCityMaxBuyPlotRange:number = tonumber(GlobalParameters.CITY_MAX_BUY_PLOT_RANGE);

function CQUI_GetRealHousingFromImprovements(pCity:table)
    local cityX:number, cityY:number = pCity:GetX(), pCity:GetY();
    --local centerIndex:number = Map.GetPlotIndex(pCity:GetLocation());
    local iNumHousing:number = 0; -- we'll add data from Housing field in Improvements divided by TilesRequired which is usually 2
    -- check all plots in the city
    for _,plotIndex in ipairs(Map.GetCityPlots():GetPurchasedPlots(pCity)) do
        local pPlot:table = Map.GetPlotByIndex(plotIndex);
        --print(centerIndex, plotIndex, Map.GetPlotDistance(cityX,cityY, pPlot:GetX(), pPlot:GetY()));
        if pPlot and pPlot:GetImprovementType() > -1 and not pPlot:IsImprovementPillaged() and Map.GetPlotDistance(cityX, cityY, pPlot:GetX(), pPlot:GetY()) <= iCityMaxBuyPlotRange then
            local imprInfo:table = GameInfo.Improvements[ pPlot:GetImprovementType() ];
            iNumHousing = iNumHousing + imprInfo.Housing / imprInfo.TilesRequired; -- well, we can always add 0, right?
        end
    end

    return pCity:GetGrowth():GetHousingFromImprovements() + Round(iNumHousing-math.floor(iNumHousing),1);
end


-- ===========================================================================
function Initialize()
    print_debug("INITIALIZE: CQUICommon.lua");
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize();
