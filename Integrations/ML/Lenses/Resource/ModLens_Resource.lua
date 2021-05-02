include("LensSupport")

local PANEL_OFFSET_Y:number = 32
local PANEL_OFFSET_X:number = -5

local LENS_NAME = "ML_RESOURCE"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

-- ===========================================================================
--  Member Variables
-- ===========================================================================

local m_isOpen:boolean = false
local m_bonusResourcesToShow:table = {}
local m_luxuryResourcesToShow:table = {}
local m_strategicResourcesToShow:table = {}

local m_showBonusResource:boolean = true
local m_showLuxuryResource:boolean = true
local m_showStrategicResource:boolean = true

local m_resetBonusResourceList:boolean = true
local m_resetLuxuryResourceList:boolean = true
local m_resetStrategicResourceList:boolean = true

local m_resourceExclusionList:table = {
    "RESOURCE_ANTIQUITY_SITE",
    "RESOURCE_SHIPWRECK"
}

-- ===========================================================================
--  Resource Support functions
-- ===========================================================================

local function ShowResourceLens()
    print("Showing " .. LENS_NAME)
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearResourceLens()
    print("Clearing " .. LENS_NAME)
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    else
        print("Nothing to clear")
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end

local function clamp(val, min, max)
    if val < min then
        return min
    elseif val > max then
        return max
    end
    return val
end

-- ========== START OF DataDumper.lua =================
--[[ DataDumper.lua
  Copyright (c) 2007 Olivetti-Engineering SA

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation
  files (the "Software"), to deal in the Software without
  restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.
  ]]

  local dumplua_closure = [[
  local closures = {}
  local function closure(t)
    closures[#closures+1] = t
    t[1] = assert(loadstring(t[1]))
    return t[1]
  end

  for _,t in pairs(closures) do
    for i = 2,#t do
      debug.setupvalue(t[1], i-1, t[i])
    end
  end
  ]]

  local lua_reserved_keywords = {
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
    'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
    'return', 'then', 'true', 'until', 'while' }

  local function keys(t)
    local res = {}
    local oktypes = { stringstring = true, numbernumber = true }
    local function cmpfct(a,b)
      if oktypes[type(a)..type(b)] then
        return a < b
      else
        return type(a) < type(b)
      end
    end
    for k in pairs(t) do
      res[#res+1] = k
    end
    table.sort(res, cmpfct)
    return res
  end

  local c_functions = {}
  for _,lib in pairs{'_G', 'string', 'table', 'math',
      'io', 'os', 'coroutine', 'package', 'debug'} do
    local t = {}
    lib = lib .. "."
    if lib == "_G." then lib = "" end
    for k,v in pairs(t) do
      if type(v) == 'function' and not pcall(string.dump, v) then
        c_functions[v] = lib..k
      end
    end
  end

  local function DataDumper(value, varname, fastmode, ident)
    local defined, dumplua = {}
    -- Local variables for speed optimization
    local string_format, type, string_dump, string_rep =
          string.format, type, string.dump, string.rep
    local tostring, pairs, table_concat =
          tostring, pairs, table.concat
    local keycache, strvalcache, out, closure_cnt = {}, {}, {}, 0
    setmetatable(strvalcache, {__index = function(t,value)
      local res = string_format('%q', value)
      t[value] = res
      return res
    end})
    local fcts = {
      string = function(value) return strvalcache[value] end,
      number = function(value) return value end,
      boolean = function(value) return tostring(value) end,
      ['nil'] = function(value) return 'nil' end,
      ['function'] = function(value)
        return string_format("loadstring(%q)", string_dump(value))
      end,
      userdata = function() error("Cannot dump userdata") end,
      thread = function() error("Cannot dump threads") end,
    }
    local function test_defined(value, path)
      if defined[value] then
        if path:match("^getmetatable.*%)$") then
          out[#out+1] = string_format("s%s, %s)\n", path:sub(2,-2), defined[value])
        else
          out[#out+1] = path .. " = " .. defined[value] .. "\n"
        end
        return true
      end
      defined[value] = path
    end
    local function make_key(t, key)
      local s
      if type(key) == 'string' and key:match('^[_%a][_%w]*$') then
        s = key .. "="
      else
        s = "[" .. dumplua(key, 0) .. "]="
      end
      t[key] = s
      return s
    end
    for _,k in ipairs(lua_reserved_keywords) do
      keycache[k] = '["'..k..'"] = '
    end
    if fastmode then
      fcts.table = function (value)
        -- Table value
        local numidx = 1
        out[#out+1] = "{"
        for key,val in pairs(value) do
          if key == numidx then
            numidx = numidx + 1
          else
            out[#out+1] = keycache[key]
          end
          local str = dumplua(val)
          out[#out+1] = str..","
        end
        if string.sub(out[#out], -1) == "," then
          out[#out] = string.sub(out[#out], 1, -2);
        end
        out[#out+1] = "}"
        return ""
      end
    else
      fcts.table = function (value, ident, path)
        if test_defined(value, path) then return "nil" end
        -- Table value
        local sep, str, numidx, totallen = " ", {}, 1, 0
        local meta, metastr = getmetatable(value)
        if meta then
          ident = ident + 1
          metastr = dumplua(meta, ident, "getmetatable("..path..")")
          totallen = totallen + #metastr + 16
        end
        for _,key in pairs(keys(value)) do
          local val = value[key]
          local s = ""
          local subpath = path or ""
          if key == numidx then
            subpath = subpath .. "[" .. numidx .. "]"
            numidx = numidx + 1
          else
            s = keycache[key]
            if not s:match "^%[" then subpath = subpath .. "." end
            subpath = subpath .. s:gsub("%s*=%s*$","")
          end
          s = s .. dumplua(val, ident+1, subpath)
          str[#str+1] = s
          totallen = totallen + #s + 2
        end
        if totallen > 80 then
          sep = "\n" .. string_rep("  ", ident+1)
        end
        str = "{"..sep..table_concat(str, ","..sep).." "..sep:sub(1,-3).."}"
        if meta then
          sep = sep:sub(1,-3)
          return "setmetatable("..sep..str..","..sep..metastr..sep:sub(1,-3)..")"
        end
        return str
      end
      fcts['function'] = function (value, ident, path)
        if test_defined(value, path) then return "nil" end
        if c_functions[value] then
          return c_functions[value]
        elseif debug == nil or debug.getupvalue(value, 1) == nil then
          return string_format("loadstring(%q)", string_dump(value))
        end
        closure_cnt = closure_cnt + 1
        local res = {string.dump(value)}
        for i = 1,math.huge do
          local name, v = debug.getupvalue(value,i)
          if name == nil then break end
          res[i+1] = v
        end
        return "closure " .. dumplua(res, ident, "closures["..closure_cnt.."]")
      end
    end
    function dumplua(value, ident, path)
      return fcts[type(value)](value, ident, path)
    end
    if varname == nil then
      varname = ""
    elseif varname:match("^[%a_][%w_]*$") then
      varname = varname .. " = "
    end
    if fastmode then
      setmetatable(keycache, {__index = make_key })
      out[1] = varname
      table.insert(out,dumplua(value, 0))
      return table.concat(out)
    else
      setmetatable(keycache, {__index = make_key })
      local items = {}
      for i=1,10 do items[i] = '' end
      items[3] = dumplua(value, ident or 0, "t")
      if closure_cnt > 0 then
        items[1], items[6] = dumplua_closure:match("(.*\n)\n(.*)")
        out[#out+1] = ""
      end
      if #out > 0 then
        items[2], items[4] = "local t = ", "\n"
        items[5] = table.concat(out)
        items[7] = varname .. "t"
      else
        items[2] = varname
      end
      return table.concat(items)
    end
  end
-- ========== END OF DataDumper.lua =================

local function SaveBonusResourcesToShow()
    -- print("Saving bonus")
    local localPlayerID = Game.GetLocalPlayer()
    local dataDump = DataDumper(m_bonusResourcesToShow, "bonusResourcesToShow", true);
    -- print(dataDump)
    PlayerConfigurations[localPlayerID]:SetValue("ML_ModLens_Resource_bonusResourcesToShow", dataDump)
end

local function LoadBonusResourcesToShow()
    -- print("Loading bonus")
    local localPlayerID = Game.GetLocalPlayer()
    if(PlayerConfigurations[localPlayerID]:GetValue("ML_ModLens_Resource_bonusResourcesToShow") ~= nil) then
        local dataDump = PlayerConfigurations[localPlayerID]:GetValue("ML_ModLens_Resource_bonusResourcesToShow")
        -- print(dataDump)
        loadstring(dataDump)()
        if bonusResourcesToShow ~= nil and #bonusResourcesToShow > 0 then
            for i, resourceType in ipairs(bonusResourcesToShow) do
                ndup_insert(m_bonusResourcesToShow, resourceType)
            end
        end
        return true
    end

    -- print("No previous bonusResourcesToShow data was available")
    return false
end

local function SaveLuxuryResourcesToShow()
    -- print("Saving luxury")
    local localPlayerID = Game.GetLocalPlayer()
    local dataDump = DataDumper(m_luxuryResourcesToShow, "luxuryResourcesToShow", true);
    PlayerConfigurations[localPlayerID]:SetValue("ML_ModLens_Resource_luxuryResourcesToShow", dataDump)
    -- print(dataDump)
end

local function LoadLuxuryResourcesToShow()
    -- print("Loading luxury")
    local localPlayerID = Game.GetLocalPlayer()
    if(PlayerConfigurations[localPlayerID]:GetValue("ML_ModLens_Resource_luxuryResourcesToShow") ~= nil) then
        local dataDump = PlayerConfigurations[localPlayerID]:GetValue("ML_ModLens_Resource_luxuryResourcesToShow")
        -- print(dataDump)
        loadstring(dataDump)()
        if luxuryResourcesToShow ~= nil and #luxuryResourcesToShow > 0 then
            for i, resourceType in ipairs(luxuryResourcesToShow) do
                ndup_insert(m_luxuryResourcesToShow, resourceType)
            end
        end
        return true
    end

    -- print("No previous luxuryResourcesToShow data was available")
    return false
end

local function SaveStrategicResourcesToShow()
    -- print("Saving strategic")
    local localPlayerID = Game.GetLocalPlayer()
    local dataDump = DataDumper(m_strategicResourcesToShow, "strategicResourcesToShow", true);
    PlayerConfigurations[localPlayerID]:SetValue("ML_ModLens_Resource_strategicResourcesToShow", dataDump)
    -- print(dataDump)
end

local function LoadStrategicResourcesToShow()
    -- print("Loading strategic")
    local localPlayerID = Game.GetLocalPlayer()
    if(PlayerConfigurations[localPlayerID]:GetValue("ML_ModLens_Resource_strategicResourcesToShow") ~= nil) then
        local dataDump = PlayerConfigurations[localPlayerID]:GetValue("ML_ModLens_Resource_strategicResourcesToShow")
        -- print(dataDump)
        loadstring(dataDump)()
        if strategicResourcesToShow ~= nil and #strategicResourcesToShow > 0 then
            for i, resourceType in ipairs(strategicResourcesToShow) do
                ndup_insert(m_strategicResourcesToShow, resourceType)
            end
        end
        return true
    end

    -- print("No previous strategicResourcesToShow data was available")
    return false
end

-- ===========================================================================
--  Exported functions
-- ===========================================================================

function RefreshResourceLens()
    -- Assuming city overlap lens is already applied
    UILens.ClearLayerHexes(ML_LENS_LAYER)
    SetResourceLens()
end

function SetResourceLens()
    -- print("Show Resource lens")
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer:number = Game.GetLocalPlayer()
    local pPlayer:table = Players[localPlayer]
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local LuxConnectedColor   :number = UI.GetColorValue("COLOR_LUXCONNECTED_RES_LENS")
    local StratConnectedColor :number = UI.GetColorValue("COLOR_STRATCONNECTED_RES_LENS")
    local BonusConnectedColor :number = UI.GetColorValue("COLOR_BONUSCONNECTED_RES_LENS")
    local LuxNConnectedColor  :number = UI.GetColorValue("COLOR_LUXNCONNECTED_RES_LENS")
    local StratNConnectedColor  :number = UI.GetColorValue("COLOR_STRATNCONNECTED_RES_LENS")
    local BonusNConnectedColor  :number = UI.GetColorValue("COLOR_BONUSNCONNECTED_RES_LENS")
    local IgnoreColor         :number = UI.GetColorValue("COLOR_MORELENSES_GREY")

    local ConnectedLuxury       = {}
    local ConnectedStrategic    = {}
    local ConnectedBonus        = {}
    local NotConnectedLuxury    = {}
    local NotConnectedStrategic = {}
    local NotConnectedBonus     = {}
    local IgnorePlots           = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        local bAdded:boolean = false

        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if playerHasDiscoveredResource(pPlayer, pPlot) then
                local resourceType = pPlot:GetResourceType()
                if resourceType ~= nil and resourceType >= 0 then
                    local resourceInfo = GameInfo.Resources[resourceType]
                    if resourceInfo ~= nil then
                        -- Check if resource is not in exclusion list
                        if not has_value(m_resourceExclusionList, resourceInfo.ResourceType) then
                            if resourceInfo.ResourceClassType == "RESOURCECLASS_BONUS" and
                                    has_value(m_bonusResourcesToShow, resourceInfo.ResourceType) then
                                if plotHasImprovement(pPlot) and not pPlot:IsImprovementPillaged() then
                                    table.insert(ConnectedBonus, i)
                                else
                                    table.insert(NotConnectedBonus, i)
                                end
                                bAdded = true
                            elseif resourceInfo.ResourceClassType == "RESOURCECLASS_LUXURY" and
                                    has_value(m_luxuryResourcesToShow, resourceInfo.ResourceType) then
                                if plotHasImprovement(pPlot) and not pPlot:IsImprovementPillaged() then
                                    table.insert(ConnectedLuxury, i)
                                else
                                    table.insert(NotConnectedLuxury, i)
                                end
                                bAdded = true
                            elseif resourceInfo.ResourceClassType == "RESOURCECLASS_STRATEGIC" and
                                    has_value(m_strategicResourcesToShow, resourceInfo.ResourceType) then
                                if plotHasImprovement(pPlot) and not pPlot:IsImprovementPillaged() then
                                    table.insert(ConnectedStrategic, i)
                                else
                                    table.insert(NotConnectedStrategic, i)
                                end
                                bAdded = true
                            end
                        end
                    end
                end
            end

            if not bAdded then
                table.insert(IgnorePlots, i)
            end
        end
    end

    if table.count(ConnectedLuxury) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, ConnectedLuxury, LuxConnectedColor )
    end
    if table.count(ConnectedStrategic) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, ConnectedStrategic, StratConnectedColor )
    end
    if table.count(ConnectedBonus) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, ConnectedBonus, BonusConnectedColor )
    end
    if table.count(NotConnectedLuxury) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, NotConnectedLuxury, LuxNConnectedColor )
    end
    if table.count(NotConnectedStrategic) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, NotConnectedStrategic, StratNConnectedColor )
    end
    if table.count(NotConnectedBonus) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, NotConnectedBonus, BonusNConnectedColor )
    end
    if table.count(IgnorePlots) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, IgnorePlots, IgnoreColor )
    end
end

function RefreshResourcePicker()
    print("Show Resource Picker")
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer:number = Game.GetLocalPlayer()
    local pPlayer:table = Players[localPlayer]
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local BonusResources:table = {}
    local LuxuryResources:table = {}
    local StrategicResources:table = {}
    local resourceCounts:table = {}
    local playerResourceCounts:table = {}
    local playerImprovedResourceCounts:table = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) and playerHasDiscoveredResource(pPlayer, pPlot) then
            local resourceType = pPlot:GetResourceType()
            if resourceType ~= nil and resourceType >= 0 then
                local resourceInfo = GameInfo.Resources[resourceType]
                if resourceInfo ~= nil then
                    -- Check if resource is not in exclusion list
                    if not has_value(m_resourceExclusionList, resourceInfo.ResourceType) then
                        -- Add entry if it doesn't exist
                        if resourceCounts[resourceInfo.ResourceType] == nil then
                            resourceCounts[resourceInfo.ResourceType] = 0
                        end
                        if playerResourceCounts[resourceInfo.ResourceType] == nil then
                            playerResourceCounts[resourceInfo.ResourceType] = 0
                        end
                        if playerImprovedResourceCounts[resourceInfo.ResourceType] == nil then
                            playerImprovedResourceCounts[resourceInfo.ResourceType] = 0
                        end

                        -- Count resources
                        resourceCounts[resourceInfo.ResourceType] = resourceCounts[resourceInfo.ResourceType] + 1
                        if pPlot:GetOwner() == Game.GetLocalPlayer() then
                            playerResourceCounts[resourceInfo.ResourceType] = playerResourceCounts[resourceInfo.ResourceType] + 1
                            if pPlot:GetImprovementType() ~= -1 then
                                playerImprovedResourceCounts[resourceInfo.ResourceType] = playerImprovedResourceCounts[resourceInfo.ResourceType] + 1
                            end
                        end

                        -- Add resource to specific group
                        if resourceInfo.ResourceClassType == "RESOURCECLASS_BONUS" then
                            if not has_rInfo(BonusResources, resourceInfo.ResourceType) then
                                table.insert(BonusResources, resourceInfo)
                                if m_showBonusResource and m_resetBonusResourceList then
                                    table.insert(m_bonusResourcesToShow, resourceInfo.ResourceType)
                                end
                            end
                        elseif resourceInfo.ResourceClassType == "RESOURCECLASS_LUXURY" then
                            if not has_rInfo(LuxuryResources, resourceInfo.ResourceType) then
                                table.insert(LuxuryResources, resourceInfo)
                                if m_showLuxuryResource and m_resetLuxuryResourceList then
                                    table.insert(m_luxuryResourcesToShow, resourceInfo.ResourceType)
                                end
                            end
                        elseif resourceInfo.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
                            if not has_rInfo(StrategicResources, resourceInfo.ResourceType) then
                                table.insert(StrategicResources, resourceInfo)
                                if m_showStrategicResource and m_resetStrategicResourceList then
                                    table.insert(m_strategicResourcesToShow, resourceInfo.ResourceType)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Save the resourcesToShow if we were doing a reset
    if m_resetBonusResourceList then
        SaveBonusResourcesToShow()
    end
    if m_resetLuxuryResourceList then
        SaveLuxuryResourcesToShow()
    end
    if m_resetStrategicResourceList then
        SaveStrategicResourcesToShow()
    end

    -- Done with reset
    m_resetBonusResourceList = false
    m_resetLuxuryResourceList = false
    m_resetStrategicResourceList = false

    Controls.BonusResourcePickStack:DestroyAllChildren()
    Controls.LuxuryResourcePickStack:DestroyAllChildren()
    Controls.StrategicResourcePickStack:DestroyAllChildren()

    -- Bonus Resources
    if table.count(BonusResources) > 0 then
        for i, resourceInfo in ipairs(BonusResources) do
            -- print(Locale.Lookup(resourceInfo.Name))
            local resourcePickInstance:table = {}
            ContextPtr:BuildInstanceForControl( "ResourcePickEntry", resourcePickInstance, Controls.BonusResourcePickStack )

            local nameLabel:string = "[ICON_" .. resourceInfo.ResourceType .. "]" .. Locale.Lookup(resourceInfo.Name)
            local countLabel:string = playerResourceCounts[resourceInfo.ResourceType] .. "/" .. resourceCounts[resourceInfo.ResourceType]
            local tooltipLabel:string = Locale.Lookup("LOC_HUD_RESOURCE_LENS_COUNT_TOOLTIP", playerResourceCounts[resourceInfo.ResourceType],
                    playerImprovedResourceCounts[resourceInfo.ResourceType], resourceCounts[resourceInfo.ResourceType], nameLabel)
            resourcePickInstance.ResourceLabel:SetText(nameLabel)
            resourcePickInstance.ResourceCount:SetText(countLabel)
            resourcePickInstance.ResourceCount:SetToolTipString(tooltipLabel)

            local bShowResource:boolean = has_value(m_bonusResourcesToShow, resourceInfo.ResourceType)
            resourcePickInstance.ResourceCheckbox:SetCheck(bShowResource)
            resourcePickInstance.ResourceCheckbox:RegisterCallback(
                Mouse.eLClick,
                function()
                    HandleBonusResourceCheckbox(resourcePickInstance, resourceInfo.ResourceType)
                end)
        end
    end

    -- Luxury Resources
    if table.count(LuxuryResources) > 0 then
        for i, resourceInfo in ipairs(LuxuryResources) do
            -- print(Locale.Lookup(resourceInfo.Name))
            local resourcePickInstance:table = {}
            ContextPtr:BuildInstanceForControl( "ResourcePickEntry", resourcePickInstance, Controls.LuxuryResourcePickStack )

            local nameLabel:string = "[ICON_" .. resourceInfo.ResourceType .. "]" .. Locale.Lookup(resourceInfo.Name)
            local countLabel:string = playerResourceCounts[resourceInfo.ResourceType] .. "/" .. resourceCounts[resourceInfo.ResourceType]
            local tooltipLabel:string = Locale.Lookup("LOC_HUD_RESOURCE_LENS_COUNT_TOOLTIP", playerResourceCounts[resourceInfo.ResourceType],
                    playerImprovedResourceCounts[resourceInfo.ResourceType], resourceCounts[resourceInfo.ResourceType], nameLabel)
            resourcePickInstance.ResourceLabel:SetText(nameLabel)
            resourcePickInstance.ResourceCount:SetText(countLabel)
            resourcePickInstance.ResourceCount:SetToolTipString(tooltipLabel)

            local bShowResource:boolean = has_value(m_luxuryResourcesToShow, resourceInfo.ResourceType)
            resourcePickInstance.ResourceCheckbox:SetCheck(bShowResource)
            resourcePickInstance.ResourceCheckbox:RegisterCallback(
                Mouse.eLClick,
                function()
                    HandleLuxuryResourceCheckbox(resourcePickInstance, resourceInfo.ResourceType)
                end)
        end
    end

    -- Strategic Resources
    if table.count(StrategicResources) > 0 then
        for i, resourceInfo in ipairs(StrategicResources) do
            -- print(Locale.Lookup(resourceInfo.Name))
            local resourcePickInstance:table = {}
            ContextPtr:BuildInstanceForControl( "ResourcePickEntry", resourcePickInstance, Controls.StrategicResourcePickStack )

            local nameLabel:string = "[ICON_" .. resourceInfo.ResourceType .. "]" .. Locale.Lookup(resourceInfo.Name)
            local countLabel:string = playerResourceCounts[resourceInfo.ResourceType] .. "/" .. resourceCounts[resourceInfo.ResourceType]
            local tooltipLabel:string = Locale.Lookup("LOC_HUD_RESOURCE_LENS_COUNT_TOOLTIP", playerResourceCounts[resourceInfo.ResourceType],
                    playerImprovedResourceCounts[resourceInfo.ResourceType], resourceCounts[resourceInfo.ResourceType], nameLabel)
            resourcePickInstance.ResourceLabel:SetText(nameLabel)
            resourcePickInstance.ResourceCount:SetText(countLabel)
            resourcePickInstance.ResourceCount:SetToolTipString(tooltipLabel)

            local bShowResource:boolean = has_value(m_strategicResourcesToShow, resourceInfo.ResourceType)
            resourcePickInstance.ResourceCheckbox:SetCheck(bShowResource)
            resourcePickInstance.ResourceCheckbox:RegisterCallback(
                Mouse.eLClick,
                function()
                    HandleStrategicResourceCheckbox(resourcePickInstance, resourceInfo.ResourceType)
                end)
        end
    end

    -- Cleanup
    Controls.BonusResourcePickStack:CalculateSize()
    Controls.LuxuryResourcePickStack:CalculateSize()
    Controls.StrategicResourcePickStack:CalculateSize()
    Controls.ResourcePickList:CalculateSize()
end

function ToggleResourceLens_Bonus()
    m_showBonusResource = Controls.ShowBonusResource:IsChecked()
    m_resetBonusResourceList = true
    m_bonusResourcesToShow = {}

    -- Assuming resource lens is already applied
    RefreshResourcePicker()
    RefreshResourceLens()
end

function ToggleResourceLens_Luxury()
    m_showLuxuryResource = Controls.ShowLuxuryResource:IsChecked()
    m_resetLuxuryResourceList = true
    m_luxuryResourcesToShow = {}

    -- Assuming resource lens is already applied
    RefreshResourcePicker()
    RefreshResourceLens()
end

function ToggleResourceLens_Strategic()
    m_showStrategicResource = Controls.ShowStrategicResource:IsChecked()
    m_resetStrategicResourceList = true
    m_strategicResourcesToShow = {}

    -- Assuming resource lens is already applied
    RefreshResourcePicker()
    RefreshResourceLens()
end

function HandleBonusResourceCheckbox(pControl, resourceType)
    if not pControl.ResourceCheckbox:IsChecked() then
        -- Don't show this resource
        find_and_remove(m_bonusResourcesToShow, resourceType)
    else
        -- Ensure the bonus resource category is checked
        Controls.ShowBonusResource:SetCheck(true)
        m_showBonusResource = true

        -- Show this resource
        ndup_insert(m_bonusResourcesToShow, resourceType)
    end
    SaveBonusResourcesToShow()

    -- Assuming resource lens is already applied
    RefreshResourceLens()
end

function HandleLuxuryResourceCheckbox(pControl, resourceType)
    if not pControl.ResourceCheckbox:IsChecked() then
        -- Don't show this resource
        find_and_remove(m_luxuryResourcesToShow, resourceType)
    else
        -- Ensure the bonus resource category is checked
        Controls.ShowLuxuryResource:SetCheck(true)
        m_showLuxuryResource = true

        -- Show this resource
        ndup_insert(m_luxuryResourcesToShow, resourceType)
    end
    SaveLuxuryResourcesToShow()

    -- Assuming resource lens is already applied
    RefreshResourceLens()
end

function HandleStrategicResourceCheckbox(pControl, resourceType)
    if not pControl.ResourceCheckbox:IsChecked() then
        -- Don't show this resource
        find_and_remove(m_strategicResourcesToShow, resourceType)
    else
        -- Ensure the bonus resource category is checked
        Controls.ShowStrategicResource:SetCheck(true)
        m_showStrategicResource = true

        -- Show this resource
        ndup_insert(m_strategicResourcesToShow, resourceType)
    end
    SaveStrategicResourcesToShow()

    -- Assuming resource lens is already applied
    RefreshResourceLens()
end

-- ===========================================================================
--  UI Controls
-- ===========================================================================

local function Open()
    Controls.ResourceLensOptionsPanel:SetHide(false)
    m_isOpen = true

    -- Load our saved settings, but if no settings exits, ensure a reset
    if not LoadBonusResourcesToShow() then
        m_resetBonusResourceList = true
    end
    if not LoadLuxuryResourcesToShow() then
        m_resetLuxuryResourceList = true
    end
    if not LoadStrategicResourcesToShow() then
        m_resetStrategicResourceList = true
    end

    RefreshResourcePicker()  -- Recall this to apply options properly
end

local function Close()
    Controls.ResourceLensOptionsPanel:SetHide(true)
    m_isOpen = false
end

local function TogglePanel()
    if m_isOpen then
        Close()
    else
        Open()
    end
end

local function OnReoffsetPanel()
    -- Get size and offsets for minimap panel
    local offsets = {}
    LuaEvents.MinimapPanel_GetLensPanelOffsets(offsets)
    Controls.ResourceLensOptionsPanel:SetOffsetY(offsets.Y + PANEL_OFFSET_Y)
    Controls.ResourceLensOptionsPanel:SetOffsetX(offsets.X + PANEL_OFFSET_X)
end

-- ===========================================================================
--  Game Engine Events
-- ===========================================================================

local function OnLensLayerOn(layerNum:number)
    if layerNum == ML_LENS_LAYER then
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            SetResourceLens()
        end
    end
end

local function ChangeContainer()
    -- Change the parent to /InGame/HUD container so that it hides correcty during diplomacy, etc
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    Controls.ResourceLensOptionsPanel:ChangeParent(hudContainer)
end

local function OnInit(isReload:boolean)
    if isReload then
        ChangeContainer()
    end
end

local function OnShutdown()
    -- Destroy the container manually
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    if hudContainer ~= nil then
        hudContainer:DestroyChild(Controls.ResourceLensOptionsPanel)
    end
end

-- ===========================================================================
--  Init
-- ===========================================================================

-- minimappanel.lua
local ResourceLensEntry = {
    LensButtonText = "LOC_HUD_RESOURCE_LENS",
    LensButtonTooltip = "LOC_HUD_RESOURCE_LENS_TOOLTIP",
    Initialize = nil,
    OnToggle = TogglePanel,
    GetColorPlotTable = nil  -- Don't pass a function here since we will have our own trigger
}

-- modallenspanel.lua
local ResourceLensModalPanelEntry = {}
ResourceLensModalPanelEntry.LensTextKey = "LOC_HUD_RESOURCE_LENS"
ResourceLensModalPanelEntry.Legend = {
    {"LOC_TOOLTIP_RESOURCE_LENS_LUXURY",        UI.GetColorValue("COLOR_LUXCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_NLUXURY",       UI.GetColorValue("COLOR_LUXNCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_BONUS",         UI.GetColorValue("COLOR_BONUSCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_NBONUS",        UI.GetColorValue("COLOR_BONUSNCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_STRATEGIC",     UI.GetColorValue("COLOR_STRATCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_NSTRATEGIC",    UI.GetColorValue("COLOR_STRATNCONNECTED_RES_LENS")}
}

-- Don't import this into g_ModLenses, since this for the UI (ie not lens)
local function Initialize()
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("           Resource Panel")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    Close()
    OnReoffsetPanel()

    ContextPtr:SetInitHandler( OnInit )
    ContextPtr:SetShutdown( OnShutdown )
    ContextPtr:SetInputHandler( OnInputHandler, true )

    Events.LoadScreenClose.Add(
        function()
            ChangeContainer()
            LuaEvents.MinimapPanel_AddLensEntry(LENS_NAME, ResourceLensEntry)
            LuaEvents.ModalLensPanel_AddLensEntry(LENS_NAME, ResourceLensModalPanelEntry)
        end
    )
    Events.LensLayerOn.Add( OnLensLayerOn )

    -- Resource Lens Setting
    Controls.ShowBonusResource:RegisterCallback( Mouse.eLClick, ToggleResourceLens_Bonus )
    Controls.ShowLuxuryResource:RegisterCallback( Mouse.eLClick, ToggleResourceLens_Luxury )
    Controls.ShowStrategicResource:RegisterCallback( Mouse.eLClick, ToggleResourceLens_Strategic )

    LuaEvents.ML_ReoffsetPanels.Add( OnReoffsetPanel )
    LuaEvents.ML_CloseLensPanels.Add( Close )
end

Initialize()
