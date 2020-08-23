include("ResearchChooser");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_AddAvailableResearch = AddAvailableResearch;
BASE_CQUI_OnOpenPanel = OnOpenPanel;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_AlwaysOpenTechTrees = false; --Ignores events calling for this to open when true
local CQUI_ShowTechCivicRecommendations = false;

-- ===========================================================================
function CQUI_OnSettingsUpdate()
    -- CQUI_AlwaysOpenTechTrees is a checkbox, so it has a value of true or false
    CQUI_AlwaysOpenTechTrees = GameConfiguration.GetValue("CQUI_AlwaysOpenTechTrees");
    -- CQUI_ShowTechCivicRecommendations is a ComboBox, so it has a vlaue of 0 or 1
    CQUI_ShowTechCivicRecommendations = GameConfiguration.GetValue("CQUI_ShowTechCivicRecommendations") == 1;
end

-- ===========================================================================
-- CQUI Function Extensions
-- ===========================================================================
function AddAvailableResearch( playerID:number, kData:table )
    -- unlike the CivicsChooser, ResearchChooser returns the control instance, which is nice
    local kControlInstance = BASE_CQUI_AddAvailableResearch(playerID, kData);

    -- If the user wants to hide the Civic and/or Tech recommendations, then find the RecommendedIcon and hide it
    if (CQUI_ShowTechCivicRecommendations == false) then
        kControlInstance.RecommendedIcon:SetHide(true);
    end
end

-- ===========================================================================
function OnOpenPanel()
    --CQUI: ignores command and opens the tech tree instead if AlwaysShowTechTrees is true
    if (CQUI_AlwaysOpenTechTrees) then
        LuaEvents.ResearchChooser_RaiseTechTree()
    else
        BASE_CQUI_OnOpenPanel();
    end
end
-- ===========================================================================
--  CQUI Functions
-- ===========================================================================
function Initialize()
    -- CQUI events
    LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );

    -- Map the LuaEvent to our instance of OnOpenPanel
    LuaEvents.ActionPanel_OpenChooseResearch.Remove(BASE_CQUI_OnOpenPanel);
    LuaEvents.ActionPanel_OpenChooseResearch.Add(OnOpenPanel);
    LuaEvents.WorldTracker_OpenChooseResearch.Remove(BASE_CQUI_OnOpenPanel);
    LuaEvents.WorldTracker_OpenChooseResearch.Add(OnOpenPanel);
end
Initialize();
