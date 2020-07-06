include("GameCapabilities");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_VIEW = View;
BASE_CQUI_Refresh = Refresh;
BASE_CQUI_GetUnitActionsTable = GetUnitActionsTable;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_ShowImprovementsRecommendations :boolean = false;
function CQUI_OnSettingsUpdate()
    CQUI_ShowImprovementsRecommendations = GameConfiguration.GetValue("CQUI_ShowImprovementsRecommendations") == 1
end
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);

-- ===========================================================================
--  CQUI modified View functiton : check if we should show the recommanded action
-- ===========================================================================
function View(data)
    BASE_CQUI_VIEW(data);

    if ( data.Actions["BUILD"] ~= nil and #data.Actions["BUILD"] > 0 ) then
        local BUILD_PANEL_ART_PADDING_Y = 20;
        local buildStackHeight :number = Controls.BuildActionsStack:GetSizeY();

        if not CQUI_ShowImprovementsRecommendations then
            Controls.RecommendedActionButton:SetHide(true);
            Controls.BuildActionsPanel:SetSizeY( buildStackHeight + BUILD_PANEL_ART_PADDING_Y);
            Controls.BuildActionsStack:SetOffsetY(0);
        end
    end

    -- CQUI (Azurency) : instead of changing the xml, it's easier to do it in code here (bigger XP bar)
    Controls.XPArea:SetSizeY(15);
    Controls.XPBar:SetSizeY(10);
    Controls.XPLabel:SetFontSize(12);
end

-- ===========================================================================
--  CQUI modified Refresh functiton : AutoExpand
-- ===========================================================================
function Refresh(player, unitId)
    BASE_CQUI_Refresh(player, unitId);

    if (player ~= nil and player ~= -1 and unitId ~= nil and unitId ~= -1) then
        local units = Players[player]:GetUnits();
        local unit = units:FindID(unitId);
        if (unit ~= nil) then
            --CQUI auto-expando
            if (GameConfiguration.GetValue("CQUI_AutoExpandUnitActions")) then
                local isHidden:boolean = Controls.SecondaryActionsStack:IsHidden();
                if isHidden then
                    Controls.SecondaryActionsStack:SetHide(false);
                    Controls.ExpandSecondaryActionsButton:SetTextureOffsetVal(0,29);
                    OnSecondaryActionStackMouseEnter();
                    Controls.ExpandSecondaryActionStack:CalculateSize();
                    Controls.ExpandSecondaryActionStack:ReprocessAnchoring();
                end

                -- AZURENCY : fix for the size not updating correcly (fall 2017), we calculate the size manually, 4 is the StackPadding
                Controls.ExpandSecondaryActionStack:SetSizeX(Controls.ExpandSecondaryActionsButton:GetSizeX() + Controls.SecondaryActionsStack:GetSizeX() + 4);
                ResizeUnitPanelToFitActionButtons();
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified Refresh functiton : GetUnitActionsTable
--  Update the Housing tool tip to show Farm Provides 1.5 Housing when Player is Maya
--  This is fixing a bug in the unmodified game, as it still shows 0.5 Housing on the tool tip
-- ===========================================================================
function GetUnitActionsTable( pUnit )
    local actionsTable = BASE_CQUI_GetUnitActionsTable(pUnit);

    -- Update the Farm Tool Tip to show 1.5 Housing if the player is Maya
    if HasTrait("TRAIT_CIVILIZATION_MAYAB", Game.GetLocalPlayer()) then
        local iconCount = #actionsTable["BUILD"];
        for i = 1, iconCount do
            if (actionsTable["BUILD"][i]["IconId"] == "ICON_IMPROVEMENT_FARM") then
                if housingStr ~= "" then
                    local housingStrBefore = Locale.Lookup("LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING", 0.5);
                    -- print_debug isn't working in this file, so for now just comment out the print statements
                    -- print("housingStrBefore is (before adding escape chars): "..housingStrBefore);
                    -- Lua parses characters that are found in regex ([],+, etc) so we need to escape those in our string we're looking to replace
                    -- Using gsub("%p", "%%%1") will replace all of the punctuation characters (which includes [], +, )
                    -- See https://www.lua.org/pil/20.2.html
                    housingStrBefore = housingStrBefore:gsub("%p", "%%%1")
                    local housingStrAfter = Locale.Lookup("LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING", 1.5);
                    local updatedHelpString, replacedCount = actionsTable["BUILD"][i]["helpString"]:gsub(housingStrBefore, housingStrAfter);

                    -- print("housingStrBefore is (after adding escape chars): "..housingStrBefore);
                    -- print("housingStrAfter is: "..housingStrAfter);
                    -- print("updatedHelpString is: "..updatedHelpString);
                    -- print("replacedCount is: "..tostring(replacedCount));

                    if replacedCount == 1 then
                        actionsTable["BUILD"][i]["helpString"] = updatedHelpString;
                    end
                end

                break -- Only the farm icon needs updating, break from the for loop
            end
        end
    end

    return actionsTable;
end