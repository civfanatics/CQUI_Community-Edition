------------------------------------------------------------------------------
-- Additional CQUI Common LUA support functions specific to Civilization 6
-- Contains:
-- * Expansions check
-- * Debug support
-- * CQUI_TrimGossipMessage
-- * CQUI_GetRealHousingFromImprovements
-- * CQUI_SmartWrap
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
        print("[CQUI]", ...);
    end
end

-- ===========================================================================
function CQUI_OnSettingsUpdate()
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
    -- print_debug("ENTRY: CQUICommon - CQUI_TrimGossipMessage - string: "..tostring(str));
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

-- ===========================================================================
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
-- Wraps a string according to the provided length, but, unlike the built in wrapping, will ignore the limit if a single continuous word exceeds the length of the wrap width
function CQUI_SmartWrap( textString, wrapWidth )
    local lines = {""}; --Table that holds each individual line as it's build
    function append(w) --Appends a new word to the end of the currently processed line along with proper spacing
        if (lines[#lines] ~= "") then
            w = lines[#lines] .. " " .. w;
        end

        return w;
    end

    for i, word in ipairs(Split(textString, " ")) do --Takes each word and builds it into lines that respect the wrapWidth param, except for long individual words
        if (i ~= 1 and string.len(append(word)) > wrapWidth) then
            lines[#lines] = lines[#lines] .. "[NEWLINE]";
            lines[#lines + 1] = "";
        end

        lines[#lines] = append(word);
    end

    local out = ""; --The output variable
    for _,line in ipairs(lines) do --Flattens the table back into a single string
        out = out .. line;
    end

    return out;
end

-- ===========================================================================
local m_CQUI_GreatPeoplePopupCalculations = {};

local function CQUI_GreatPeoplePopupSizeCalculations()
    local _, CQUI_screenHeight = UIManager:GetScreenSizeVal();
    -- These values are calculated as part of the "AddRecruit" function, which is a function separated out from "ViewCurrent" by Firaxis.
    -- Previously CQUI left the "AddRecruit" logic inline the ViewCurrent function, however given the changes for the Babylon Patch by Firaxis,
    -- it makes sense to move the logic out to that separate function, in case a future update makes use of it.
    -- Notes on Pixel sizes:
    -- 63px from top of container "RecruitProgressBox" to top of scrollpanel "RecruitScroll"
    -- 84px from bottom of scrollpanel "RecruitScroll" to bottom of the container "PopupContainer"
    local CQUI_lowerPanelAdditionalHeight = 147;
    -- When fit to a full screen, the Great Person panel instance is 122px shorter than the "PopupContainer"
    local CQUI_instanceMargin = 127;
    -- each individual Recruit Row instance has a height of 22, with 3 padding in between each
    local majorCivs = Game.GetPlayers{Major = true};
    local recruitScrollCivsCount = #majorCivs - 1;
    local CQUI_preferredRecruitScrollSize = (recruitScrollCivsCount * 22) + ((recruitScrollCivsCount - 2) * 3);
    local CQUI_preferredEffectsScrollSize = 240; -- Value defined in the XML
    local CQUI_preferredInstanceSize = 0;

        -- This if clause will only run for the first instance, each subsequent will use the values calculated here
    --CQUI_preferredRecruitScrollSize = 1000;  -- for quick testing
    if (CQUI_preferredRecruitScrollSize > (CQUI_screenHeight / 4)) then
        CQUI_preferredRecruitScrollSize = (CQUI_screenHeight / 4);
    end

    -- 670 is the default Instance size in the XML... 86 is a number that represents some undocumented thing
    CQUI_preferredInstanceSize =  670 - 86 + CQUI_preferredRecruitScrollSize;
    -- CQUI_preferredInstanceSize = 3000 -- for quick testing
    if (CQUI_preferredInstanceSize > (CQUI_screenHeight - CQUI_instanceMargin)) then
        -- The instance area cannot be bigger than the screen height minus CQUI_instanceMargin:
        -- When the Gold/Faith (or Recruit/Pass) buttons are 5px above the PeopleScroller horizontal scroll, 
        -- the PanelInstance is CQUI_instanceMargin pixels less in height than the PeopleContainer, which is defined as 768 in the XML.
        -- These adjustments are necessary to properly fit the screen
        local prevPreferredInstanceSize = CQUI_preferredInstanceSize;
        CQUI_preferredInstanceSize = CQUI_screenHeight - CQUI_instanceMargin;

        -- Instead of shrinking the recruit scroll size, instead shrink the EffectsStackScroller, as there's typically room to spare in that section
        -- 240 is the value defined in the XML.  We cannot do a GetSizeY here because subsequent calls to this function
        -- would update the smaller value, eventually shrinking the control to less than zero.
        local effectStackScrollerAdjustment = prevPreferredInstanceSize - CQUI_preferredInstanceSize;
        CQUI_preferredEffectsScrollSize = 240 - effectStackScrollerAdjustment;
    end

    m_CQUI_GreatPeoplePopupCalculations["InstanceContentSizeY"] = CQUI_preferredInstanceSize;
    m_CQUI_GreatPeoplePopupCalculations["EffectsScrollSizeY"] = CQUI_preferredEffectsScrollSize;
    m_CQUI_GreatPeoplePopupCalculations["RecruitScrollSizeY"] = CQUI_preferredRecruitScrollSize;
    m_CQUI_GreatPeoplePopupCalculations["RecruitWoodPanelingY"] = CQUI_preferredRecruitScrollSize + CQUI_lowerPanelAdditionalHeight;
    m_CQUI_GreatPeoplePopupCalculations["ModalFrameSizeY"] = CQUI_preferredInstanceSize + CQUI_instanceMargin -6; -- CQUI: 6px less for the 3px outer border
    m_CQUI_GreatPeoplePopupCalculations["PopupContainerSizeY"] = CQUI_preferredInstanceSize + CQUI_instanceMargin;
end

local function CQUI_GreatPeoplePanel_GetControlSizeY( controlName )
    if m_CQUI_GreatPeoplePopupCalculations[controlName] == nil then
        CQUI_GreatPeoplePopupSizeCalculations();
    end

    return m_CQUI_GreatPeoplePopupCalculations[controlName];
end

function CQUI_GreatPeoplePanel_GetInstanceContentSizeY()
    return CQUI_GreatPeoplePanel_GetControlSizeY("InstanceContentSizeY");
end

function CQUI_GreatPeoplePanel_GetEffectsScrollSizeY()
    return CQUI_GreatPeoplePanel_GetControlSizeY("EffectsScrollSizeY");
end

function CQUI_GreatPeoplePanel_GetRecruitScrollSizeY()
    return CQUI_GreatPeoplePanel_GetControlSizeY("RecruitScrollSizeY");
end

function CQUI_GreatPeoplePanel_GetRecruitWoodPanelingSizeY()
    return CQUI_GreatPeoplePanel_GetControlSizeY("RecruitWoodPanelingY");
end

function CQUI_GreatPeoplePanel_GetModalFrameSizeY()
    return CQUI_GreatPeoplePanel_GetControlSizeY("ModalFrameSizeY");
end

function CQUI_GreatPeoplePanel_GetPopupContainerSizeY()
    return CQUI_GreatPeoplePanel_GetControlSizeY("PopupContainerSizeY");
end

-- ===========================================================================
function Initialize()
    -- print_debug("INITIALIZE: CQUICommon.lua");
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize();
