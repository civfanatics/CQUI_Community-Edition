include("PortraitSupport");
include("ToolTipHelper");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_GetCityData = GetCityData;

-- ===========================================================================
-- CQUI Extension Functions
-- These functions extend the unmodifed versions
-- ===========================================================================
function GetCityData( pCity:table )
  -- call the base function, extend the return data we give back
  local data = BASE_CQUI_GetCityData(pCity);

  -- Extend the table returned by the base function and return that
  local productionInfo :table = GetCurrentProductionInfoOfCity( pCity, SIZE_PRODUCTION_ICON );
  data["ProductionProgress"] = productionInfo.Progress;
  data["ProductionCost"] = productionInfo.Cost;

  local pCityGrowth :table = pCity:GetGrowth();
  local foodSurplus :number = pCityGrowth:GetFoodSurplus();

  data.["CurrentFood"] =  pCityGrowth:GetFood();
  data.["RequiredFood"] = pCityGrowth:GetGrowthThreshold();
  data.["FoodGainNextTurn"] = foodSurplus * pCityGrowth:GetOverallGrowthModifier();

  return data;
end
