local _, ns = ...

-- Resaltado propio encima del botón de acción. Nunca modificamos el botón de Blizzard
-- (evita taint y "Acción bloqueada" en la interfaz de mando).
local Highlight = { bySpell = {}, overlays = {} }

local function overlayFor(button)
  local o = Highlight.overlays[button]
  if not o then
    o = CreateFrame("Frame", nil, UIParent)
    o:SetFrameStrata("HIGH")
    local border = o:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover") -- por verificar en Forever
    border:SetVertexColor(1, 0.85, 0.1)
    o:Hide()
    Highlight.overlays[button] = o
  end
  o:ClearAllPoints()
  o:SetAllPoints(button)
  return o
end

-- Recorre todos los frames con un slot de acción (barras normales y, si son ActionButton
-- estándar, las de mando). Solo fuera de combate.
function Highlight:Rebuild()
  if InCombatLockdown() then self.dirty = true return end
  wipe(self.bySpell)
  local f = EnumerateFrames()
  while f do
    if f.IsObjectType and f:IsObjectType("CheckButton") then
      local slot = f.action or (f.GetAttribute and f:GetAttribute("action"))
      if type(slot) == "number" then
        local kind, id = GetActionInfo(slot)
        if kind == "spell" and id then
          self.bySpell[id] = self.bySpell[id] or {}
          table.insert(self.bySpell[id], f)
          overlayFor(f)
        end
      end
    end
    f = EnumerateFrames(f)
  end
  self.dirty = false
end

-- Mostrar/ocultar nuestros overlays sí está permitido en combate (no son frames seguros).
function Highlight:Show(spellID)
  for _, o in pairs(self.overlays) do o:Hide() end
  for _, button in ipairs(self.bySpell[spellID] or {}) do
    if button:IsVisible() then self.overlays[button]:Show() end
  end
end

ns.Highlight = Highlight
