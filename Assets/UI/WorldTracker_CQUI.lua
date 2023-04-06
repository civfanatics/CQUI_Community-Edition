include("ToolTipHelper");
include("CQUICommon.lua");

-- CQUI/Infixo Load a proper base file
-- CivBattleRoyale file could be loaded also here - need to find proper conditions to trigger it
if g_bIsRiseAndFall or g_bIsGatheringStorm then
    include("WorldTracker_Expansion1");
else
    include("WorldTracker");
end

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnCivicCompleted    = OnCivicCompleted;
BASE_CQUI_UpdateCivicsPanel   = UpdateCivicsPanel;
BASE_CQUI_OnResearchCompleted = OnResearchCompleted;
BASE_CQUI_UpdateResearchPanel = UpdateResearchPanel;

-- ===========================================================================
-- Variables
-- ===========================================================================
local m_lastResearchCompletedID :number = -1; -- needed to display a tooltip
local m_lastCivicCompletedID    :number = -1; -- needed to display a tooltip
local CIVIC_PANEL_TEXTURE_NAME    = "CivicPanel_Frame";
local RESEARCH_PANEL_TEXTURE_NAME = "ResearchPanel_Frame";

-- ===========================================================================
-- CQUI Extension Functions
-- ===========================================================================
function OnCivicCompleted( ePlayer:number, eCivic:number )
    if ePlayer == Game.GetLocalPlayer() then
        m_lastCivicCompletedID = eCivic;
    end

    BASE_CQUI_OnCivicCompleted(ePlayer, eCivic);
end

-- ===========================================================================
function UpdateCivicsPanel(hideCivics:boolean)
    --print("UpdateCivicsPanel");
    BASE_CQUI_UpdateCivicsPanel(hideCivics);

    -- CQUI extension to add a tooltip showing the details of the current civic
    local localPlayer :number = Game.GetLocalPlayer();
    if (localPlayer ~= -1 and not hideCivics and not IsCivicsHidden()) then
        local iCivic:number = Players[localPlayer]:GetCulture():GetProgressingCivic();
        if iCivic == -1 then
            iCivic = m_lastCivicCompletedID;
        end
        -- show the tooltip
        if iCivic == -1 then
            -- Nothing yet researched (begin of the game)
            SetMainPanelToolTip(Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_CIVIC"), CIVIC_PANEL_TEXTURE_NAME);
        else
            local mainPanelToolTip:string = ToolTipHelper.GetToolTip( GameInfo.Civics[iCivic].CivicType, localPlayer );
            SetMainPanelToolTip(mainPanelToolTip, CIVIC_PANEL_TEXTURE_NAME);
        end
    end
end

-- ===========================================================================
function OnResearchCompleted( ePlayer:number, eTech:number )
    if ePlayer == Game.GetLocalPlayer() then
        m_lastResearchCompletedID = eTech;
    end

    BASE_CQUI_OnResearchCompleted(ePlayer, eTech);
end

-- ===========================================================================
function UpdateResearchPanel( isHideResearch:boolean )
    --print("UpdateResearchPanel");
    BASE_CQUI_UpdateResearchPanel(isHideResearch);

    -- CQUI extension to add a tooltip showing the details of the current tech
    local localPlayer :number = Game.GetLocalPlayer();
    if (localPlayer ~= -1 and not isHideResearch and not IsResearchHidden()) then
        local iTech:number = Players[localPlayer]:GetTechs():GetResearchingTech();
        if iTech == -1 then
            iTech = m_lastResearchCompletedID;
        end
        -- show the tooltip
        if iTech == -1 then
            -- Nothing yet researched (begin of the game)
            SetMainPanelToolTip(Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_RESEARCH"), RESEARCH_PANEL_TEXTURE_NAME);
        else
            local mainPanelToolTip:string = ToolTipHelper.GetToolTip( GameInfo.Technologies[iTech].TechnologyType, localPlayer );
            SetMainPanelToolTip(mainPanelToolTip, RESEARCH_PANEL_TEXTURE_NAME);
        end
    end
end

-- ===========================================================================
-- CQUI Custom Functions
-- ===========================================================================
function SetMainPanelToolTip(toolTip:string, panelTextureName:string)
    --print("SetMainPanelToolTip", toolTip, panelTextureName);
    -- Get either the MainPanel from the CivicInstance or ResearchInstance
    for _,ctrl in pairs(Controls.WorldTrackerVerticalContainer:GetChildren()) do
        if (ctrl:GetID() == "MainPanel" and ctrl:GetTexture() == panelTextureName) then
            ctrl:LocalizeAndSetToolTip(toolTip);
        end
    end
end
