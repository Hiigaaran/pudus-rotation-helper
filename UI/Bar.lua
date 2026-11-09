local _, ns = ...

local Bar = CreateFrame("Frame", "PudusRotationHelperBar", UIParent)
Bar:SetPoint("CENTER", 0, -180)
Bar:SetMovable(true)
Bar:EnableMouse(true)
Bar:RegisterForDrag("LeftButton")
Bar:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
Bar:SetScript("OnDragStop", Bar.StopMovingOrSizing)
Bar.icons = {}
Bar.label = Bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Bar.label:SetPoint("BOTTOMLEFT", Bar, "TOPLEFT", 0, 4)

local function getIcon(i, size, allBright)
  local tex = Bar.icons[i]
  if not tex then
    tex = Bar:CreateTexture(nil, "ARTWORK")
    Bar.icons[i] = tex
  end
  tex:SetSize(size, size)
  tex:ClearAllPoints()
  tex:SetPoint("LEFT", Bar, "LEFT", (i - 1) * (size + 4), 0)
  -- El primer icono (el siguiente a lanzar) se ve entero; el resto, atenuado.
  tex:SetAlpha((allBright or i == 1) and 1 or 0.6)
  return tex
end

function Bar:ApplyScale()
  self:SetScale(ns.db.scale or 1)
end

-- label: texto opcional encima de la barra; allBright: todos los iconos sin atenuar (grabación).
function Bar:Refresh(spellIDs, label, allBright)
  self.label:SetText(label or "")
  local size = ns.db.iconSize
  self:SetSize(math.max(1, #spellIDs) * (size + 4), size)
  for i, spellID in ipairs(spellIDs) do
    local tex = getIcon(i, size, allBright)
    tex:SetTexture(C_Spell.GetSpellTexture(spellID))
    tex:Show()
  end
  for i = #spellIDs + 1, #self.icons do self.icons[i]:Hide() end
end

ns.Bar = Bar
