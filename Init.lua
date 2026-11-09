local addonName, ns = ...

local events = CreateFrame("Frame")
local rotation
local recorder -- no nil mientras se graba una secuencia

local PREFIX = "|cffffd100Pudu's Rotation Helper:|r "

local function refresh()
  if recorder then
    -- Mientras se graba, la barra muestra lo grabado (los últimos 8) y no hay resaltado.
    local steps, shown = recorder.steps, {}
    for i = math.max(1, #steps - 7), #steps do shown[#shown + 1] = steps[i] end
    ns.Bar:Refresh(shown, "Grabando: " .. #steps .. " pasos", true)
    ns.Highlight:Show(nil)
    return
  end
  if not rotation then return end
  ns.Bar:Refresh(rotation:Peek(ns.db.barSize))
  ns.Highlight:Show(rotation:Current())
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

function ns.LoadRotation()
  local steps, mode = ns.GetActiveProfile()
  rotation = ns.Rotation.new(steps, mode, isReady, ns.SameSpell)
  ns.Highlight:Rebuild()
  refresh()
end

-- Grabación: el jugador pulsa sus habilidades en el orden de la rotación (teclado o mando).
-- Se registra cada intento, aunque falle por falta de objetivo, rango o recurso.
local function startRecording()
  recorder = ns.Recorder.new()
  print(PREFIX .. "grabando. Pulsa tus habilidades en orden y vuelve a pulsar el atajo (o /prh fin) para guardar.")
  refresh()
end

local function stopRecording(save)
  local steps = recorder:Steps()
  recorder = nil
  if save and #steps > 0 then
    ns.SetProfile(steps, "sequence")
    print(PREFIX .. #steps .. " pasos guardados.")
  else
    print(PREFIX .. "grabación cancelada.")
  end
  ns.LoadRotation()
end

ns.Refresh = refresh

function PudusRotationHelper_ToggleRecord()
  if recorder then stopRecording(true) else startRecording() end
end

function PudusRotationHelper_Undo()
  if recorder then recorder:Undo() refresh() end
end

BINDING_HEADER_PUDUSROTATIONHELPER = "Pudu's Rotation Helper"
BINDING_NAME_PUDUSROTATIONHELPER_TOGGLERECORD = "Grabar / guardar secuencia"
BINDING_NAME_PUDUSROTATIONHELPER_UNDO = "Deshacer último paso grabado"

local RECORD_EVENTS = {
  UNIT_SPELLCAST_SENT = true,          -- unit, target, castGUID, spellID
  UNIT_SPELLCAST_FAILED = true,        -- unit, castGUID, spellID
  UNIT_SPELLCAST_FAILED_QUIET = true,  -- unit, castGUID, spellID
}

events:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... == addonName then
      ns.InitDB()
      ns.Bar:ApplyScale()
      ns.Options:Register()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    ns.LoadRotation()
  elseif RECORD_EVENTS[event] then
    if recorder then
      local castGUID, spellID
      if event == "UNIT_SPELLCAST_SENT" then
        castGUID, spellID = select(3, ...)
      else
        castGUID, spellID = select(2, ...)
      end
      if recorder:Add(spellID, GetTime(), castGUID) then refresh() end
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local _, castGUID, spellID = ...
    if recorder then
      if recorder:Add(spellID, GetTime(), castGUID) then refresh() end
    elseif rotation and rotation:OnCast(spellID) then
      refresh()
    end
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
for e in pairs(RECORD_EVENTS) do events:RegisterUnitEvent(e, "player") end

-- /prh                   -> abre el panel de opciones
-- /prh grabar            -> empieza a grabar la secuencia pulsando habilidades
-- /prh fin               -> guarda la grabación      /prh cancelar  -> la descarta
-- /prh deshacer          -> quita el último paso grabado
-- /prh set 133 116 133   -> secuencia fija escribiendo IDs de hechizo
-- /prh prio 23922 6572   -> lista de prioridades
-- /prh reset             -> vuelve al primer paso
SLASH_PUDUSROTATIONHELPER1 = "/prh"
SlashCmdList.PUDUSROTATIONHELPER = function(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = cmd:lower()
  if cmd == "grabar" or cmd == "record" then
    if not recorder then startRecording() end
  elseif (cmd == "fin" or cmd == "stop") and recorder then
    stopRecording(true)
  elseif cmd == "cancelar" and recorder then
    stopRecording(false)
  elseif cmd == "deshacer" then
    PudusRotationHelper_Undo()
  elseif cmd == "set" or cmd == "prio" then
    local steps = {}
    for id in rest:gmatch("%d+") do steps[#steps + 1] = tonumber(id) end
    local mode = cmd == "prio" and "priority" or "sequence"
    ns.SetProfile(steps, mode)
    ns.LoadRotation()
    print(PREFIX .. #steps .. " pasos guardados (" .. mode .. ").")
  elseif cmd == "opciones" or cmd == "options" or cmd == "" then
    ns.Options:Open()
  elseif cmd == "reset" and rotation then
    rotation:Reset()
    refresh()
  else
    print(PREFIX .. "/prh (opciones) | grabar | fin | cancelar | deshacer | reset | set <IDs> | prio <IDs>")
  end
end
