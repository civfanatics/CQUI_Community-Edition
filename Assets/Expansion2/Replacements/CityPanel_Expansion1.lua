-- Copyright 2017-2019, Firaxis Games

include("CityPanel");
BASE_ViewMain = ViewMain;

-- ===========================================================================
function ViewMain( kData:table )
	BASE_ViewMain( kData );
	
	-- ==== CQUI CUSTOMIZATION BEGIN ====================================================================================== --
	--swarsele: change religious citizens to loyalty
    local pCity = UI.GetHeadSelectedCity()
    if pCity ~= nil then
		local pCulturalIdentity = pCity:GetCulturalIdentity();
		local currentLoyalty = pCulturalIdentity:GetLoyalty();
		local loyaltyPerTurn:number = pCulturalIdentity:GetLoyaltyPerTurn();

		Controls.ReligionIcon:SetIcon("ICON_STAT_CULTURAL_FLAG");
		Controls.ReligionLabel:SetText(Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_SUBSECTION"));
		Controls.ReligionNum:SetText(Round(currentLoyalty, 1) .. "/" .. Round(loyaltyPerTurn,1));

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
