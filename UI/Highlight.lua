local _, ns = ...

-- Resaltado propio encima del botón de acción. Nunca modificamos el botón de Blizzard
-- (evita taint y "Acción bloqueada" en la interfaz de mando).
--
-- Comprobado en WoW: Forever (Interface 16001): las barras de mando son botones con
-- campo .action, p. ej. GamepadMainActionBarFramePageUnitLeftCenteredAnchorLeftBarActionButton1
-- (casilla 185). Al cambiar de set de barras, de postura (guerrero) o de forma (druida) la
-- casilla del botón puede cambiar, así que guardamos la lista de botones y resolvemos el
-- hechizo de cada uno al mostrar.
local Highlight = { buttons = {}, overlays = {} }
local THICKNESS = 3

local function slotOf(button)
  local slot = button.action
  if type(slot) ~= "number" and button.GetAttribute then slot = button:GetAttribute("action") end
  if type(slot) == "number" and slot > 0 then return slot end
end

-- Borde de cuatro lados con texturas de color sólido: no depende de atlas que podrían
-- no existir en Forever y se puede pintar de cualquier color.
local function overlayFor(button)
  local o = Highlight.overlays[button]
  if not o then
    o = CreateFrame("Frame", nil, UIParent)
    o:SetFrameStrata("HIGH")
    o.edges = {}
    for i = 1, 4 do o.edges[i] = o:CreateTexture(nil, "OVERLAY") end
    local top, bottom, left, right = unpack(o.edges)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(THICKNESS)
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(THICKNESS)
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(THICKNESS)
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(THICKNESS)
    o:SetPoint("TOPLEFT", button, "TOPLEFT", -THICKNESS, THICKNESS)
    o:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", THICKNESS, -THICKNESS)
    o:Hide()
    Highlight.overlays[button] = o
  end
  local c = ns.db.color
  for _, edge in ipairs(o.edges) do edge:SetColorTexture(c.r, c.g, c.b, c.a or 1) end
  return o
end

function Highlight:ApplyColor()
  for button in pairs(self.overlays) do overlayFor(button) end
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
    if slot and spellID then kind, id = GetActionInfo(slot) end
    o:SetShown(kind == "spell" and ns.SameSpell(id, spellID) and button:IsVisible())
  end
end

ns.Highlight = Highlight
