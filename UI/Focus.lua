local _, ns = ...

-- Modo foco: el jugador "entra" en la lista con un atajo (p. ej. una combinación del mando)
-- y, mientras dura, algunos botones dejan de lanzar habilidades y pasan a editar la lista:
--
--   Cruceta arriba/abajo  elegir paso       (lista bloqueada)
--   Cruceta               mover la lista    (lista desbloqueada)
--   A                     bloquear / desbloquear
--   X                     sacar el paso elegido
--   B                     salir del foco
--
-- Se hace con SetOverrideBindingClick: los atajos normales del jugador no se tocan y vuelven
-- en cuanto se sale del foco. Las anulaciones no se pueden cambiar en combate, así que el foco
-- no se abre en combate y se cierra solo al entrar en él.
local Focus = { active = false, index = 1 }
local owner = CreateFrame("Frame")

local ACTIONS = {
  up    = { keys = { "PADDUP", "UP" },       run = function() Focus:Step(-1, 0, 1) end },
  down  = { keys = { "PADDDOWN", "DOWN" },   run = function() Focus:Step(1, 0, -1) end },
  left  = { keys = { "PADDLEFT", "LEFT" },   run = function() Focus:Step(0, -1, 0) end },
  right = { keys = { "PADDRIGHT", "RIGHT" }, run = function() Focus:Step(0, 1, 0) end },
  lock  = { keys = { "PAD1", "ENTER" },      run = function() ns.Bar:ToggleLock() Focus:Update() end },
  remove = { keys = { "PAD3", "DELETE" },    run = function() Focus:RemoveSelected() end },
  exit  = { keys = { "PAD2", "BACKSPACE" },  run = function() Focus:Exit() end },
}

-- Un botón oculto por acción, para poder dirigir las teclas a él.
for name, action in pairs(ACTIONS) do
  local b = CreateFrame("Button", "PudusRotationHelperFocus_" .. name, UIParent)
  b:Hide()
  b:SetScript("OnClick", action.run)
  action.button = b:GetName()
end

local PREFIX = "|cffffd100Pudu's Rotation Helper:|r "

function Focus:HintText()
  local count = #(ns.GetEditableList())
  local lines = { "|cff40c0ffMODO FOCO|r  (estos botones no lanzan habilidades mientras dure)" }
  if ns.db.locked then
    lines[#lines + 1] = ("Cruceta: elegir paso %d/%d   A: desbloquear   X: sacar paso   B: salir"):format(math.min(self.index, count), count)
  else
    lines[#lines + 1] = "Cruceta: mover la lista   A: bloquear   X: sacar paso   B: salir"
  end
  return table.concat(lines, "\n")
end

function Focus:Enter()
  if self.active then return end
  if InCombatLockdown() then
    print(PREFIX .. "el foco en la lista no se puede abrir en combate.")
    return
  end
  for _, action in pairs(ACTIONS) do
    for _, key in ipairs(action.keys) do
      SetOverrideBindingClick(owner, true, key, action.button)
    end
  end
  self.active, self.index = true, 1
  print(PREFIX .. "foco en la lista. Los botones de la cruceta, A, X y B editan la lista hasta que pulses B.")
  self:Update()
end

function Focus:Exit()
  if not self.active then return end
  ClearOverrideBindings(owner)
  self.active = false
  self:Update()
end

function Focus:Toggle()
  if self.active then self:Exit() else self:Enter() end
end

-- dy: cambio de paso elegido; mx, my: movimiento de la lista (solo desbloqueada).
function Focus:Step(dy, mx, my)
  if not ns.db.locked then
    ns.Bar:Nudge(mx, my)
    return
  end
  local count = #(ns.GetEditableList())
  if count == 0 or dy == 0 then return end
  self.index = ((self.index - 1 + dy) % count) + 1
  self:Update()
end

function Focus:RemoveSelected()
  local steps, commit = ns.GetEditableList()
  if #steps == 0 then return end
  local i = math.min(self.index, #steps)
  local removed = table.remove(steps, i)
  commit(steps)
  self.index = math.max(1, math.min(i, #steps))
  print(PREFIX .. "paso sacado: " .. (ns.SpellName(removed) or removed) .. ".")
  self:Update()
end

function Focus:Update()
  if ns.Refresh then ns.Refresh() end
end

-- Las anulaciones hay que quitarlas antes de que empiece el bloqueo de combate.
owner:RegisterEvent("PLAYER_REGEN_DISABLED")
owner:SetScript("OnEvent", function()
  if Focus.active then
    Focus:Exit()
    print(PREFIX .. "foco cerrado al entrar en combate.")
  end
end)

function PudusRotationHelper_ToggleFocus() Focus:Toggle() end
BINDING_NAME_PUDUSROTATIONHELPER_TOGGLEFOCUS = "Foco en la lista (combinación reservada: no lanza habilidades)"

ns.Focus = Focus
