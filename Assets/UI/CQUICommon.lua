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
g_bIsBaseGame       = not g_bIsRiseAndFall and not g_bIsGatheringStorm;
-- Required for Workaround for the Barbarian Clans Mode replacing UnitFlagManager.lua and PlotToolTip.lua via ReplaceUIScript
g_bIsBarbarianClansMode = Modding and Modding.IsModActive("19ED1A36-D744-4A58-8F8B-0376C2BA86E5"); -- Barbarian Clans Mode

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
-- Function to determine the vertical size of the Great People Popup
-- This is located in CQUICommon as the values calculated here are used by both Assets/UI/Popups/GreatPeoplePopup.lua and Assets/Babylon/Additions/GreatPeopleHeroPanel.lua
-- The vertical size of the panel depends on the number of major and alive civilizations, and is calculated once after the first load of the game.
-- NOTE! Values here may refer to objects defined in the XML files (greatpeoplepopup.xml and greatpeopleheropanel.xml), so changes there may require updates here.

local m_CQUI_GreatPeoplePopupCalculations = {};

-- This function is not intended to be called by the other files, it is called when one of
-- those other files attempts to lookup a size of one of the controls and the sizes had not
-- yet been calculated
local function CQUI_GreatPeoplePopupSizeCalculations()
    -- Get the Y-size of the screen, to ensure the panel is built to fit on smaller screens
    local _, screenSizeY = UIManager:GetScreenSizeVal();

    -- Get the number of not-local-player Civs by calculating all alive major civs and subtracting 1
    local majorCivs = Game.GetPlayers{Major = true, Alive = true};
    CQUI_GreatPeoplePopupSizeCalculations_Worker(screenSizeY, (#majorCivs - 1));
end

-- This function exists in order to test different heights of the control and RecruitProgress section from the Live Tuner
function CQUI_GreatPeoplePopupSizeCalculations_Test(screenSizeY, aliveMajorNotLocalCivs)
    CQUI_GreatPeoplePopupSizeCalculations_Worker(screenSizeY, aliveMajorNotLocalCivs)
end 

-- ===========================================================================
function CQUI_GreatPeoplePopupSizeCalculations_Worker(screenSizeY, aliveMajorNotLocalCivs)
    -- The unmodified game sets the total height of the control to 768 pixels.
    -- The 768px includes 240 for the "Great Person Effects" section and 152 for the "Recruit Progress" section.
    -- CQUI will adjust the size of the Recruit Progress and Great Person Effects sections based on the number
    -- of major, alive civilizations.
    -- In order to adjust these values dynamically we need to know the total Y-size of the elements above and below
    -- those that we will change.

    -- The area in the PopupContainer control above the PeopleStack control
    -- PeopleStack is the control that hosts each Great Person and Hero Panel insance
    local popupContainerHeaderSizeY = 78; 
    -- The section of Great Person Panel Instance (gppi) containing the type, name, era, and icon
    -- This is the distance from the top of the instance to the top of the EffectStackScroller (offset 0,224)
    local gppiTopAreaSizeY = 224;
    -- An unnamed small buffer that exists between the EffectStackScroller control and the RecruitProgressBox control
    local gppiMiddleBufferSizeY = 8;
    -- The area in the bottom of the Great Person Panel instance that contains the purchase/recruit/reject buttons
    local gppiBottomAreaSizeY = 46;
    -- The area in the PopupContainer control that exists below the PeopleStack control containing the instance;
    -- This footer area contains the horizontal scroll bar
    local popupContinerFooterSizeY = 20;

    -- The start size of the EffectStackScroller is the unmodified default of 240.
    -- This value may be reduced in order to accomodate a larger Recruit Progress section
    local gppiEffectStackScrollerSizeY = 240;
    -- The Recruit Progress section (RecruitProgressBox) is 152 in the unmodified XML,
    -- which includes allocating 48 for the RecruitScroll control, which shows 2 non-local-player civilizations
    -- Each RecruitInstance item in the RecruitScroll control measures at 24px tall
    local gppiRecruitProgressBoxStaticSizeY = 104;
    local gppiRecruitInstanceItemStaticSizeY = 24;

    -- Determine the size of the RecruitScroll control (inside of the RecruitProgressBox control) based 
    -- on the number of alive, major Civs that are not the local player
    local gppiRecruitScrollSizeY = aliveMajorNotLocalCivs * gppiRecruitInstanceItemStaticSizeY;
    local gppiRecruitProgressBoxSizeY = gppiRecruitProgressBoxStaticSizeY + gppiRecruitScrollSizeY;

    -- Determine the new Y-size of the panel
    -- all of the other elements (calculation below sums items in order of their placement on screen, top to bottom)
    local popupContainerSizeY = popupContainerHeaderSizeY 
                                + gppiTopAreaSizeY
                                + gppiEffectStackScrollerSizeY
                                + gppiMiddleBufferSizeY
                                + gppiRecruitProgressBoxSizeY
                                + gppiBottomAreaSizeY
                                + popupContinerFooterSizeY;

    -- If the height of the panel exceeds the available screen height, adjustments are required
    if (popupContainerSizeY > screenSizeY) then
        popupContainerSizeY = screenSizeY;
        -- Determine the height available to fit the EffectStackScroller and RecruitProgressBox, and split
        -- the difference between the two
        local sizeRemaining = screenSizeY - popupContainerHeaderSizeY - gppiTopAreaSizeY - gppiMiddleBufferSizeY - gppiBottomAreaSizeY - popupContinerFooterSizeY;
        gppiEffectStackScrollerSizeY = sizeRemaining / 2;
        gppiRecruitProgressBoxSizeY = sizeRemaining / 2;
        -- The recruit scroll control is the Y-size of the RecruitProgressBox control minus the Y-size of the elements
        -- in that RecruitProgressBox control that do not change
        gppiRecruitScrollSizeY = gppiRecruitProgressBoxSizeY - gppiRecruitProgressBoxStaticSizeY;
    end

    -- Fill in the table with the new sizes of various items
    m_CQUI_GreatPeoplePopupCalculations["ModalFrame"] = popupContainerSizeY; -- The Modal Frame effectively creates a 3px border around the PopupContainer control, but is same size
    m_CQUI_GreatPeoplePopupCalculations["PopupContainer"] = popupContainerSizeY;

    m_CQUI_GreatPeoplePopupCalculations["Content"] =  gppiTopAreaSizeY + gppiEffectStackScrollerSizeY + gppiMiddleBufferSizeY + gppiRecruitProgressBoxSizeY + gppiBottomAreaSizeY;
    m_CQUI_GreatPeoplePopupCalculations["EffectStackScroller"] = gppiEffectStackScrollerSizeY;
    m_CQUI_GreatPeoplePopupCalculations["RecruitProgressBox"]  = gppiRecruitProgressBoxSizeY;
    m_CQUI_GreatPeoplePopupCalculations["RecruitScroll"] = gppiRecruitScrollSizeY;
    m_CQUI_GreatPeoplePopupCalculations["CQUI_WoodPanelingBottomFiller"] = gppiRecruitProgressBoxSizeY + gppiBottomAreaSizeY + popupContinerFooterSizeY + 3;
end

-- ===========================================================================
function CQUI_GreatPeoplePanel_GetControlSizeY( controlName )
    if m_CQUI_GreatPeoplePopupCalculations[controlName] == nil then
        CQUI_GreatPeoplePopupSizeCalculations();
    end

    return m_CQUI_GreatPeoplePopupCalculations[controlName];
end

-- ===========================================================================
function Initialize_CQUICommon()
    -- print_debug("INITIALIZE: CQUICommon.lua");
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize_CQUICommon();
