-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnOpenCivilopedia = OnOpenCivilopedia;

-- ===========================================================================
--  CQUI Functions
-- ===========================================================================
function OnOpenCivilopedia(sectionId_or_search, pageId)
    BASE_CQUI_OnOpenCivilopedia(sectionId_or_search, pageId);
    Controls.SearchEditBox:TakeFocus();
end
