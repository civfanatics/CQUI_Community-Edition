-- ===========================================================================
-- Base File
-- ===========================================================================
include("UnitPanel_Expansion2.lua");

include("unitpanel_CQUI.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_AddUpgradeResourceCost = AddUpgradeResourceCost;


-- 2020-08-10 Unit Upgrade Maintenance Cost #125
-- Author: Infixo, code taken from Better Report Screen
-- XP2 has a special function that adds upgrade gold and resource cost. However, to add
-- a maintenance cost for the upgraded unit we need to know into what it changes. This
-- info is available in the parent function i.e. GetUnitActionsTable() but it is huge
-- and I don't wanna overwrite it. So, I will use a trick and check the UnitCommand op
-- again to see if this is UPGRADE and get the new unit if so.


-- ===========================================================================
function AddUpgradeResourceCost( pUnit:table )
    local toolTipString:string = BASE_CQUI_AddUpgradeResourceCost( pUnit );
    -- Check again if the operation can occur, this time for real.
    -- we already did that in the parent function, so it should return the same results now
    local _, tResults = UnitManager.CanStartCommand( pUnit, UnitCommandTypes.UPGRADE, false, true);

    -- add the unit it will upgrade to in the tooltip as well as the upgrade cost
    if tResults ~= nil and tResults[UnitCommandResults.UNIT_TYPE] ~= nil then
        local upgradeToUnit:table = GameInfo.Units[tResults[UnitCommandResults.UNIT_TYPE]];
        --print("AURC: proper upgrade-to unit", upgradeToUnit.UnitType, upgradeToUnit.Name);
        -- upgrade to unit name
        local currentUnit = GameInfo.Units[pUnit:GetUnitType()];
        local curUnitToolTipString = Locale.Lookup(currentUnit.Name).." [ICON_GoingTo] ";
        local upgUnitToolTipString = Locale.Lookup(upgradeToUnit.Name).." [ICON_GoingTo] ";
        -- gold
        curUnitToolTipString = curUnitToolTipString..Locale.Lookup("LOC_TOOLTIP_BASE_COST", currentUnit.Maintenance, "[ICON_Gold]", "LOC_YIELD_GOLD_NAME"); -- Base Cost: {1_Amount} {2_YieldIcon} {3_YieldName}
        upgUnitToolTipString = upgUnitToolTipString..Locale.Lookup("LOC_TOOLTIP_BASE_COST", upgradeToUnit.Maintenance, "[ICON_Gold]", "LOC_YIELD_GOLD_NAME"); -- Base Cost: {1_Amount} {2_YieldIcon} {3_YieldName}
        -- resources
        curUnitToolTipString = curUnitToolTipString..(CQUI_GetUnitResourceRequirements(currentUnit));
        upgUnitToolTipString = upgUnitToolTipString..(CQUI_GetUnitResourceRequirements(upgradeToUnit));
        -- combine into the tooltip
        toolTipString = toolTipString.."[NEWLINE]"..curUnitToolTipString.."[NEWLINE]"..upgUnitToolTipString;
    end -- if tResults

    return toolTipString;
end

-- ===========================================================================
function CQUI_GetUnitResourceRequirements ( pUnit:table )
    local retVal = "";
    local unitInfoXP2:table = GameInfo.Units_XP2[ pUnit.UnitType ];
    if unitInfoXP2 ~= nil and unitInfoXP2.ResourceMaintenanceType ~= nil then
        local resourceName:string = Locale.Lookup(GameInfo.Resources[ unitInfoXP2.ResourceMaintenanceType ].Name);
        local resourceIcon = "[ICON_" .. GameInfo.Resources[unitInfoXP2.ResourceMaintenanceType].ResourceType .. "]";
        retVal = " "..Locale.Lookup("LOC_UNIT_PRODUCTION_FUEL_CONSUMPTION", unitInfoXP2.ResourceMaintenanceAmount, resourceIcon, resourceName); -- Consumes: {1_Amount} {2_Icon} {3_FuelName} per turn.
    end -- unit info xp2

    return retVal;
end
