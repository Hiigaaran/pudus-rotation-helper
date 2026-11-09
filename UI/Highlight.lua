local _, ns = ...

-- Resaltado propio encima del botón de acción. Nunca modificamos el botón de Blizzard
-- (evita taint y "Acción bloqueada" en la interfaz de mando).
--
-- Comprobado en WoW: Forever (Interface 16001): las barras de mando son botones con
-- campo .action, p. ej. GamepadMainActionBarFramePageUnitLeftCenteredAnchorLeftBarActionButton1
-- (casilla 185). Al cambiar de set de barras la casilla del botón puede cambiar, así que
-- guardamos la lista de botones y resolvemos el hechizo de cada uno al mostrar.
local Highlight = { buttons = {}, overlays = {} }

local function slotOf(button)
  local slot = button.action
  if type(slot) ~= "number" and button.GetAttribute then slot = button:GetAttribute("action") end
  if type(slot) == "number" and slot > 0 then return slot end
end

local function overlayFor(button)
  local o = Highlight.overlays[button]
  if not o then
    o = CreateFrame("Frame", nil, UIParent)
    o:SetFrameStrata("HIGH")
    local border = o:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover") -- por verificar en Forever
    border:SetVertexColor(1, 0.85, 0.1)
    o:SetAllPoints(button)
    o:Hide()
    Highlight.overlays[button] = o
  end
  return o
end

-- Recorre todos los frames con un campo de acción (barras de teclado y de mando).
-- Crea los overlays, así que solo se hace fuera de combate.
function Highlight:Rebuild()
  if InCombatLockdown() then self.dirty = true return end
  wipe(self.buttons)
  local f = EnumerateFrames()
  while f do
    if not (f.IsForbidden and f:IsForbidden()) and (f.action ~= nil or (f.GetAttribute and f:GetAttribute("action"))) then
      self.buttons[#self.buttons + 1] = f
      overlayFor(f)
    end
    f = EnumerateFrames(f)
  end
  self.dirty = false
end

-- Leer .action y GetActionInfo y mostrar/ocultar frames propios está permitido en combate.
-- spellID nil oculta todos los resaltados.
function Highlight:Show(spellID)
  for button, o in pairs(self.overlays) do
    local slot = slotOf(button)
    local kind, id
    if slot then kind, id = GetActionInfo(slot) end
    o:SetShown(spellID ~= nil and kind == "spell" and id == spellID and button:IsVisible())
  end
end

ns.Highlight = Highlight
