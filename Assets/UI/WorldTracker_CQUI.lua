include("ToolTipHelper");
include("CQUICommon.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_ToggleAll                 = ToggleAll;
BASE_CQUI_OnCivicCompleted          = OnCivicCompleted;
BASE_CQUI_OnCivicChanged            = OnCivicChanged;
BASE_CQUI_UpdateCivicsPanel         = UpdateCivicsPanel;
BASE_CQUI_OnResearchCompleted       = OnResearchCompleted;
BASE_CQUI_ShouldUpdateResearchPanel = ShouldUpdateResearchPanel;
BASE_CQUI_UpdateResearchPanel       = UpdateResearchPanel;
BASE_CQUI_Refresh                   = Refresh;

-- ===========================================================================
-- Variables
-- ===========================================================================

local m_hideAll                 :boolean = false;
local m_hideResearch            :boolean = false;
local m_hideCivics              :boolean = false;
local m_lastResearchCompletedID :number = -1;
local m_lastCivicCompletedID    :number = -1;
local CIVIC_PANEL_TEXTURE_NAME    = "CivicPanel_Frame";
local RESEARCH_PANEL_TEXTURE_NAME = "ResearchPanel_Frame";

-- ===========================================================================
-- CQUI Extension Functions
-- ===========================================================================
function ToggleAll(hideAll:boolean)
    -- The m_hideAll variable declared in the unmodified version is only set in the ToggleAll function
    m_hideAll = hideAll;
    BASE_CQUI_ToggleAll(hideAll);
end

-- ===========================================================================
function OnCivicCompleted( ePlayer:number, eCivic:number )
    local localPlayer = Game.GetLocalPlayer();
    if (localPlayer ~= -1 and localPlayer == ePlayer) then
        m_lastCivicCompletedID = eCivic;
    end

    BASE_CQUI_OnCivicCompleted(ePlayer, eCivic);
end

-- ===========================================================================
function OnCivicChanged( ePlayer:number, eCivic:number )
    local localPlayer = Game.GetLocalPlayer();
    if localPlayer ~= -1 and localPlayer == ePlayer then
        m_lastCivicCompletedID = -1;
    end

    BASE_CQUI_OnCivicChanged(ePlayer, eCivic);
end

-- ===========================================================================
function UpdateCivicsPanel(hideCivics:boolean)
    BASE_CQUI_UpdateCivicsPanel(hideCivics);

    if hideCivics ~= nil then
        m_hideCivics = hideCivics;
    end

    local localPlayer :number = Game.GetLocalPlayer();
    if (localPlayer ~= -1 and not m_hideCulture and not m_hideAll) then
        local playerCulture :table  = Players[localPlayer]:GetCulture();
        local iCivic        :number = playerCulture:GetProgressingCivic();
        if iCivic == -1 then
            iCivic = m_lastCivicCompletedID;
        end

        local mainPanelToolTip :string = nil;
        local kCivic :table  = (iCivic ~= -1) and GameInfo.Civics[ iCivic ] or nil;
        if (kCivic ~= nil) then
            mainPanelToolTip = ToolTipHelper.GetToolTip( kCivic.CivicType, localPlayer )
        end

        SetMainPanelToolTip(mainPanelToolTip, CIVIC_PANEL_TEXTURE_NAME);
    end
end

-- ===========================================================================
function OnResearchCompleted( ePlayer:number, eTech:number )
    local localPlayer = Game.GetLocalPlayer();
    if (localPlayer ~= -1 and localPlayer == ePlayer) then
        m_lastResearchCompletedID = eTech;
    end

    BASE_CQUI_OnResearchCompleted(ePlayer, eTech);
end

-- ===========================================================================
function ShouldUpdateResearchPanel( ePlayer:number, eTech:number )
    if (BASE_CQUI_ShouldUpdateResearchPanel(ePlayer, eTech) == true) then
        m_lastResearchCompletedID = -1;
    end
end

-- ===========================================================================
function UpdateResearchPanel( isHideResearch:boolean )
    BASE_CQUI_UpdateResearchPanel(isHideResearch);

    if (isHideResearch ~= nil) then
        m_hideResearch = isHideResearch;
    end

    local localPlayer :number = Game.GetLocalPlayer();
    if (localPlayer ~= -1 and not m_hideResearch and not m_hideAll) then
        local playerTechs :table  = Players[localPlayer]:GetTechs();
        local iTech       :number = playerTechs:GetResearchingTech();
        if iTech == -1 then
            iTech = m_lastResearchCompletedID;
        end

        local mainPanelToolTip :string = nil;
        local kTech :table  = (iTech ~= -1) and GameInfo.Technologies[iTech] or nil;
        if (kTech ~= nil) then
            mainPanelToolTip = ToolTipHelper.GetToolTip( kTech.TechnologyType, localPlayer )
        end

        SetMainPanelToolTip(mainPanelToolTip, RESEARCH_PANEL_TEXTURE_NAME);
    end
end

-- ===========================================================================
function Refresh()
    local localPlayer :number = Game.GetLocalPlayer();
    if localPlayer >= 0 then
        -- Fix for the Checkbox bug by ARISTOS
        ToggleAll(m_hideAll);
    end

    BASE_CQUI_Refresh();
end

-- ===========================================================================
-- CQUI Replacement Functions
-- ===========================================================================
function RealizeEmptyMessage()
    -- Do nothing, base game refers to an Empty Panel that is not defined by CQUI
end

-- ===========================================================================
-- CQUI Custom Functions
-- ===========================================================================
function SetMainPanelToolTip(toolTip:string, panelTextureName:string)
-- Get either the MainPanel from the CivicInstance or ResearchInstance
    for _,ctrl in pairs(Controls.PanelStack:GetChildren()) do
        if (ctrl:GetID() == "MainPanel" and ctrl:GetTexture() == panelTextureName) then
            ctrl:LocalizeAndSetToolTip(toolTip);
        end
    end
end