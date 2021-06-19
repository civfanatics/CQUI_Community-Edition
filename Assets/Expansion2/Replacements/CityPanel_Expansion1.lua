-- NOTE: This is the correct file name.  Firaxis has a CityPanel_Expansion1.lua located in the Expansion2 folder.
--       This file updates the actions found in CityPanel_Expansion1.lua.

include("CityPanel");
BASE_CQUI_ViewMain = ViewMain;

-- ===========================================================================
function ViewMain( kData:table )
    BASE_CQUI_ViewMain( kData );
    
    -- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
    -- swarsele: change religious citizens to loyalty
    local pCity = UI.GetHeadSelectedCity()
    if pCity ~= nil then
        local pCulturalIdentity = pCity:GetCulturalIdentity();
        local currentLoyalty = pCulturalIdentity:GetLoyalty();
        local loyaltyPerTurn:number = pCulturalIdentity:GetLoyaltyPerTurn();

        Controls.ReligionIcon:SetIcon("ICON_STAT_CULTURAL_FLAG");
        Controls.ReligionLabel:SetText(Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_SUBSECTION"));
        if Controls.CQUI_Loyalty ~= nil then
            local loyaltyValueSign = "";
            if loyaltyPerTurn >= 0 then
                loyaltyValueSign = "+";
            end
    
            Controls.CQUI_Loyalty:SetText(Round(currentLoyalty, 1));
            Controls.CQUI_LoyaltyPerTurn:SetText(" (" .. loyaltyValueSign .. Round(loyaltyPerTurn,1) .. ")");
        end

        -- m4a: Move the Religion tool tip to the City Size icon
        local religionTooltip = Controls.ReligionGrid:GetToolTipString();
        Controls.ReligionGrid:SetToolTipString("");
        Controls.CitizensGrowthButton:SetToolTipString(religionTooltip);
    end
    -- ==== CQUI CUSTOMIZATION END ======================================================================================== --
end

-- ===========================================================================
function OnCityLoyaltyChanged( ownerPlayerID:number, cityID:number )
    if UI.IsCityIDSelected(ownerPlayerID, cityID) then
        UI.DeselectCityID(ownerPlayerID, cityID);
    end
end

-- ===========================================================================
function LateInitialize()
    Events.CityLoyaltyChanged.Add(OnCityLoyaltyChanged);
end
