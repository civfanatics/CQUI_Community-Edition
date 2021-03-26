
-- CQUI/Infixo choose a proper base file to load
include("CQUICommon");
if g_bIsGatheringStorm or g_bIsRiseAndFall then
    include("ResearchChooser_Expansion1"); -- XP2 reuses XP1 file
else
    include("ResearchChooser");
end

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================

-- CQUI/Infixo
-- Unfortunately some trick is needed here because Firaxis' version from XP1 does NOT return kControlInstance as Base version does.
-- It means that we have to call the version from Base file first and perform XP1 things here. We cannot go back to XP1 as it would call the base version again.
-- Shame on you, Firaxis, for not following your own rules!

BASE_CQUI_AddAvailableResearch = AddAvailableResearch;

if g_bIsGatheringStorm or g_bIsRiseAndFall then
    BASE_CQUI_AddAvailableResearch = BASE_AddAvailableResearch;
end

BASE_CQUI_RealizeCurrentResearch = RealizeCurrentResearch; -- this function is in TechAndCivicSupport.lua, also extended in XP1 file
BASE_CQUI_OnOpenPanel = OnOpenPanel;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_AlwaysOpenTechTrees = false; --Ignores events calling for this to open when true
local CQUI_ShowTechCivicRecommendations = true; -- default is 1

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- CQUI_AlwaysOpenTechTrees is a checkbox, so it has a value of true or false
    CQUI_AlwaysOpenTechTrees = GameConfiguration.GetValue("CQUI_AlwaysOpenTechTrees");
    -- CQUI_ShowTechCivicRecommendations is a ComboBox, so it has a value of 0 or 1
    CQUI_ShowTechCivicRecommendations = GameConfiguration.GetValue("CQUI_ShowTechCivicRecommendations") == 1;
end

-- ===========================================================================
-- CQUI Function Extensions
-- ===========================================================================

function AddAvailableResearch( playerID:number, kData:table )
    -- unlike the CivicsChooser, ResearchChooser returns the control instance, which is nice
    local kControlInstance = BASE_CQUI_AddAvailableResearch(playerID, kData);

    -- CQUI/Infixo this part is copied from XP1 replacement file
    if g_bIsGatheringStorm or g_bIsRiseAndFall then
        if kData then
            local techID = GameInfo.Technologies[kData.TechType].Index;
            if AllyHasOrIsResearchingTech(techID) then
                kControlInstance.AllianceIcon:SetToolTipString(GetAllianceIconToolTip());
                kControlInstance.AllianceIcon:SetColor(GetAllianceIconColor());
                kControlInstance.Alliance:SetHide(false);
            else
                kControlInstance.Alliance:SetHide(true);
            end
        end
    end

    -- If the user wants to hide the Civic and/or Tech recommendations, then find the RecommendedIcon and hide it
    if not CQUI_ShowTechCivicRecommendations then
        kControlInstance.RecommendedIcon:SetHide(true);
    end
end

-- ===========================================================================
function RealizeCurrentResearch( playerID:number, kData:table, kControl:table )
    BASE_CQUI_RealizeCurrentResearch(playerID, kData, kControl);
    
    if kControl == nil then
        kControl = Controls;
    end

    if kData ~= nil then
        -- Show/Hide Recommended Icon
        -- CQUI : only if show tech civ enabled in settings
        if kControl.RecommendedIcon and not CQUI_ShowTechCivicRecommendations then
            kControl.RecommendedIcon:SetHide(true);
        end
    end
end

-- ===========================================================================
function OnOpenPanel()
    --CQUI: ignores command and opens the tech tree instead if AlwaysShowTechTrees is true
    if CQUI_AlwaysOpenTechTrees then
        LuaEvents.ResearchChooser_RaiseTechTree()
    else
        BASE_CQUI_OnOpenPanel();
    end
end

-- ===========================================================================
--  CQUI Functions
-- ===========================================================================
function Initialize_ResearchChooser_CQUI()
    -- CQUI events
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );

    -- Map the LuaEvent to our instance of OnOpenPanel
    LuaEvents.ActionPanel_OpenChooseResearch.Remove(BASE_CQUI_OnOpenPanel);
    LuaEvents.ActionPanel_OpenChooseResearch.Add(OnOpenPanel);
    LuaEvents.WorldTracker_OpenChooseResearch.Remove(BASE_CQUI_OnOpenPanel);
    LuaEvents.WorldTracker_OpenChooseResearch.Add(OnOpenPanel);
end
Initialize_ResearchChooser_CQUI();
