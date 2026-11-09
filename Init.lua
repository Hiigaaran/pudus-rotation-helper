local addonName, ns = ...

local events = CreateFrame("Frame")
local rotation

local function refresh()
  if not rotation then return end
  ns.Bar:Refresh(rotation:Peek(ns.db.barSize))
  local nextSpell = rotation:Current()
  if nextSpell then ns.Highlight:Show(nextSpell) end
end

local function loadRotation()
  rotation = ns.Rotation.new(ns.GetActiveSteps())
  ns.Highlight:Rebuild()
  refresh()
end

events:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" and ... == addonName then
    ns.InitDB()
  elseif event == "PLAYER_ENTERING_WORLD" then
    loadRotation()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local _, _, spellID = ...
    if rotation and rotation:OnCast(spellID) then refresh() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if ns.Highlight.dirty then ns.Highlight:Rebuild() end
    refresh()
  else
    -- Cambio de casilla, de página o de set de barras de mando. Fuera de combate volvemos a
    -- buscar botones (la UI de mando puede crearlos al activarla); en combate basta con refrescar.
    if not InCombatLockdown() then ns.Highlight:Rebuild() end
    refresh()
  end
end)
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
events:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

-- /prh set 133 116 133   -> guarda la rotación (IDs de hechizo)
-- /prh reset             -> vuelve al primer paso
SLASH_PUDUSROTATIONHELPER1 = "/prh"
SlashCmdList.PUDUSROTATIONHELPER = function(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  if cmd == "set" then
    local steps = {}
    for id in rest:gmatch("%d+") do steps[#steps + 1] = tonumber(id) end
    ns.SetSteps(steps)
    loadRotation()
    print("Pudu's Rotation Helper: " .. #steps .. " pasos guardados.")
  elseif cmd == "reset" and rotation then
    rotation:Reset()
    refresh()
  else
    print("Uso: /prh set <spellID> <spellID> ...  |  /prh reset")
  end
end
