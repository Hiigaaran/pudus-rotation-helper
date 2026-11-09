local addonName, ns = ...

local events = CreateFrame("Frame")
local rotation

local function refresh()
  if not rotation then return end
  ns.Bar:Refresh(rotation:Peek(ns.db.barSize))
  local nextSpell = rotation:Current()
  if nextSpell then ns.Highlight:Show(nextSpell) end
end

-- Lista para usar: usable (recurso, Revancha activa) y sin reutilización pendiente.
-- En combate estos valores pueden ser secretos; si lo son, no podemos saberlo y la damos por lista.
local function isReady(spellID)
  local usable = C_Spell.IsSpellUsable(spellID)
  if issecretvalue and issecretvalue(usable) then usable = true end
  if not usable then return false end
  local cd = C_Spell.GetSpellCooldown(spellID)
  if cd then
    local active, onGCD = cd.isActive, cd.isOnGCD
    if issecretvalue and (issecretvalue(active) or issecretvalue(onGCD)) then return true end
    if active and not onGCD then return false end
  end
  return true
end

local function loadRotation()
  local steps, mode = ns.GetActiveProfile()
  rotation = ns.Rotation.new(steps, mode, isReady)
  ns.Highlight:Rebuild()
  refresh()
end

events:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... == addonName then ns.InitDB() end
  elseif event == "PLAYER_ENTERING_WORLD" then
    loadRotation()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local _, _, spellID = ...
    if rotation and rotation:OnCast(spellID) then refresh() end
  elseif event == "SPELL_UPDATE_USABLE" or event == "SPELL_UPDATE_COOLDOWN" then
    if rotation and rotation.mode == "priority" then refresh() end
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
events:RegisterEvent("SPELL_UPDATE_USABLE")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

-- /prh set 133 116 133   -> secuencia fija (IDs de hechizo)
-- /prh prio 23922 6572   -> lista de prioridades
-- /prh reset             -> vuelve al primer paso
SLASH_PUDUSROTATIONHELPER1 = "/prh"
SlashCmdList.PUDUSROTATIONHELPER = function(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  if cmd == "set" or cmd == "prio" then
    local steps = {}
    for id in rest:gmatch("%d+") do steps[#steps + 1] = tonumber(id) end
    local mode = cmd == "prio" and "priority" or "sequence"
    ns.SetProfile(steps, mode)
    loadRotation()
    print("Pudu's Rotation Helper: " .. #steps .. " pasos guardados (" .. mode .. ").")
  elseif cmd == "reset" and rotation then
    rotation:Reset()
    refresh()
  else
    print("Uso: /prh set <spellIDs> (secuencia)  |  /prh prio <spellIDs> (prioridad)  |  /prh reset")
  end
end
