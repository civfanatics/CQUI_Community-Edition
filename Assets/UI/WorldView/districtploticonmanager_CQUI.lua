-- ===========================================================================
-- Base File
-- ===========================================================================
include("DistrictPlotIconManager");
include("GameCapabilities");

-- ===========================================================================
-- Everything except the Initialize function at the end is copied from
-- the KublaiKhan / Vietnam file DistrictPlotIconManager_KublaiKhan_Vietnam.lua.
-- Firaxis implemented their own ReplaceUIScript for DistrictPlotIconManager
-- ===========================================================================
-- ===========================================================================
-- CACHED BASE FUNCTIONS
-- ===========================================================================
BASE_Realize2dArtForCityDistricts = Realize2dArtForCityDistricts;

-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
local PADDING_X :number = 18;
local PADDING_Y :number = 16;

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================

function Realize2dArtForCityDistricts( pCity:table )
    local districtHash:number   = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
    local district:table        = GameInfo.Districts[districtHash];

    --Is vietnam trying to place a district?
    if(HasTrait("TRAIT_CIVILIZATION_VIETNAM") and district ~= nil)then
        -- Show information for a district about to be placed
        local plots			:table = GetCityRelatedPlotIndexesDistrictsAlternative( pCity, districtHash );		
        for i,plotID in pairs(plots) do
            local kPlot:table =  Map.GetPlotByIndex(plotID);
            if kPlot == nil then
                UI.DataError("Bad plot index; could not get plot #"..tostring(plotID));
            else
                -- All plots that are valid for this district
                if kPlot:CanHaveDistrict(district.Index, pCity:GetOwner(), pCity:GetID()) then
                    local yieldBonus:string, yieldTooltip:string, requirementText:string = GetAdjacentYieldBonusString( district.Index, pCity, kPlot );
                    local showIfPurchaseable:boolean = IsShownIfPlotPurchaseable(district.Index, pCity, kPlot);
                    if showIfPurchaseable then
                        local instance:table = GetInstanceAt( plotID );
                        instance.PlotBonus:SetHide( yieldBonus == "" );
                        instance.BonusText:SetText(yieldBonus);
                        instance.BonusText:SetToolTipString(yieldTooltip);

                        --Hide the PrereqIcon since Vietnam does not have to remove features to build districts
                        instance.PrereqIcon:SetHide( true );

                        local x:number,y:number = instance.BonusText:GetSizeVal();
                        instance.PlotBonus:SetSizeVal( x+PADDING_X, y+PADDING_Y );
                        RealizeIconStack(instance);
                    end					
                end
            end
        end
    else
        BASE_Realize2dArtForCityDistricts(pCity);
    end
end

-- ===========================================================================
function Initialize_DistrictPlotIconManager_CQUI()
    LuaEvents.CQUI_DistrictPlotIconManager_ClearEverything.Add(ClearEveything);
    LuaEvents.CQUI_Realize2dArtForDistrictPlacement.Add(Realize2dArtForDistrictPlacement);
end
Initialize_DistrictPlotIconManager_CQUI();