-- Copyright 2017-2019, Firaxis Games

include("CityPanel");
BASE_ViewMain = ViewMain;

-- ===========================================================================
function ViewMain( kData:table )
	BASE_ViewMain( kData );
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
