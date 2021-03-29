include("CivicsChooser");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_AddAvailableCivic = AddAvailableCivic;
BASE_CQUI_RealizeCurrentCivic = RealizeCurrentCivic; -- this function is in TechAndCivicSupport.lua
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

function AddAvailableCivic( playerID:number, kData:table )
    BASE_CQUI_AddAvailableCivic(playerID, kData);

    -- If the user wants to hide the Civic and/or Tech recommendations, then find the RecommendedIcon and hide it
    if not CQUI_ShowTechCivicRecommendations then
        
        -- CivicsChooser does not return an item instance from AddAvailableCivic,
        -- so we go and find the controls manually and hide the RecommendedIcon if necessary
        -- The Control lives at <Instance>/TopContainer/Top/<UnNamedStack>/RecommendedIcon
        -- Also, is there really no better way to do this?  I could not find a way to get an existing Instance Manager that is "Local" to the CivicsChooser.lua
        for _, civicStackChild in pairs(Controls.CivicStack:GetChildren()) do
            -- each civicStackChild is a Container with ID "TopContainer", which has 1 child, a GridButton with ID "Top"
            gridButton = civicStackChild:GetChildren()[1];
            for _, gridButtonChild in pairs(gridButton:GetChildren()) do
                -- The RecommendedIcon is in a Stack control without an ID, which will be a child of the GridButton
                if ((getmetatable(gridButtonChild).CTypeName == "StackControl") and (gridButtonChild:GetID() == "")) then
                    for _, ctrl in pairs(gridButtonChild:GetChildren()) do
                        -- Now locate the RecommendedIcon and hide it
                        if (ctrl:GetID() == "RecommendedIcon") then
                            ctrl:SetHide(true);
                            break
                        end
                    end
                    break -- no need to walk the gridButton child controls any further
                end
            end -- gridButton:GetChildren for loop
        end -- civicStack:GetChildren for loop
        
    end -- not CQUI_ShowTechCivicRecommendations
end

-- ===========================================================================
function RealizeCurrentCivic( playerID:number, kData:table, kControl:table, cachedModifiers:table )
    BASE_CQUI_RealizeCurrentCivic(playerID, kData, kControl, cachedModifiers);
    
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
        LuaEvents.CivicsChooser_RaiseCivicsTree()
    else
        BASE_CQUI_OnOpenPanel();
    end
end

-- ===========================================================================
--  CQUI Functions
-- ===========================================================================
function Initialize_CivicsChooser_CQUI()
    -- CQUI events
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);

    -- Map the LuaEvent to our instance of OnOpenPanel
    LuaEvents.ActionPanel_OpenChooseCivic.Remove(BASE_CQUI_OnOpenPanel);
    LuaEvents.ActionPanel_OpenChooseCivic.Add(OnOpenPanel);
    LuaEvents.WorldTracker_OpenChooseCivic.Remove(BASE_CQUI_OnOpenPanel);
    LuaEvents.WorldTracker_OpenChooseCivic.Add(OnOpenPanel);
end
Initialize_CivicsChooser_CQUI();
