local _, ns = ...

-- Lista vertical de las próximas habilidades: icono + nombre por fila.
-- Se mueve arrastrándola con el ratón (o el cursor del mando) cuando está desbloqueada,
-- o con los atajos "Mover lista" asignables a botones del mando.
local ROW_GAP = 4
local NAME_WIDTH = 160
local NUDGE = 10 -- píxeles por pulsación de los atajos de mover

local Bar = CreateFrame("Frame", "PudusRotationHelperBar", UIParent, "BackdropTemplate")
Bar:SetPoint("CENTER", 0, -180)
Bar:SetMovable(true)
Bar:SetClampedToScreen(true)
Bar:RegisterForDrag("LeftButton")
if Bar.SetDontSavePosition then Bar:SetDontSavePosition(true) end -- la posición la guardamos nosotros
Bar.rows = {}
Bar.lastSpellIDs = {}

Bar.label = Bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Bar.label:SetPoint("BOTTOMLEFT", Bar, "TOPLEFT", 0, 4)

-- Botón de candado: siempre visible y clicable, aunque la lista esté bloqueada.
local lock = CreateFrame("Button", nil, Bar)
lock:SetSize(20, 20)
lock:SetPoint("BOTTOMRIGHT", Bar, "TOPRIGHT", 0, 2)
lock:SetAlpha(0.7)
lock:SetScript("OnClick", function() Bar:ToggleLock() end)
lock:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(ns.db.locked and "Lista bloqueada: clic para mover" or "Lista desbloqueada: arrástrala y haz clic para bloquear")
  GameTooltip:Show()
end)
lock:SetScript("OnLeave", function() GameTooltip:Hide() end)
Bar.lock = lock

local function savePosition()
  local point, _, relPoint, x, y = Bar:GetPoint()
  ns.db.position = { point = point, relPoint = relPoint, x = x, y = y }
end

Bar:SetScript("OnDragStart", function(self) if not ns.db.locked then self:StartMoving() end end)
Bar:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)

local function getRow(i)
  local row = Bar.rows[i]
  if not row then
    row = CreateFrame("Frame", nil, Bar)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT")
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWidth(NAME_WIDTH)
    row.name:SetWordWrap(false)
    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetPoint("TOPLEFT", -2, 2)
    row.selected:SetPoint("BOTTOMRIGHT", 2, -2)
    row.selected:SetColorTexture(0.25, 0.75, 1, 0.35)
    if i == 1 then
      -- Borde que parpadea alrededor del icono del paso actual (mismo color que el resaltado).
      row.glow = ns.CreateBorder(row, row.icon, 2)
    end
    Bar.rows[i] = row
  end
  local size = ns.db.iconSize
  row:SetSize(size + 6 + NAME_WIDTH, size)
  row.icon:SetSize(size, size)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", Bar, "TOPLEFT", 4, -4 - (i - 1) * (size + ROW_GAP))
  return row
end

function Bar:ApplyStyle()
  local first = self.rows[1]
  if first and first.glow then first.glow:ApplyStyle() end
end

function Bar:ApplyScale()
  self:SetScale(ns.db.scale or 1)
end

function Bar:ApplyLock()
  local locked = ns.db.locked
  -- Bloqueada: la lista no captura el ratón (los clics pasan al mundo), solo el candado.
  self:EnableMouse(not locked)
  if locked then
    self.lock:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
    self:SetBackdrop(nil)
  else
    self.lock:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
    self:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    self:SetBackdropColor(0, 0.4, 0.8, 0.35)
  end
  if ns.Refresh then ns.Refresh() else self:Refresh(self.lastSpellIDs, self.lastLabel, self.lastAllBright) end
end

function Bar:ApplySettings()
  local p = ns.db.position
  if p then
    self:ClearAllPoints()
    self:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
  end
  self:ApplyScale()
  self:ApplyLock()
end

function Bar:ToggleLock()
  ns.db.locked = not ns.db.locked
  self:ApplyLock()
  print("|cffffd100Pudu's Rotation Helper:|r lista " .. (ns.db.locked and "bloqueada." or "desbloqueada: arrástrala o usa los atajos de mover."))
  if ns.Options and ns.Options.Refresh then ns.Options:Refresh() end
end

function Bar:Nudge(dx, dy)
  if ns.db.locked then return end
  local point, _, relPoint, x, y = self:GetPoint()
  self:ClearAllPoints()
  self:SetPoint(point, UIParent, relPoint, x + dx * NUDGE, y + dy * NUDGE)
  savePosition()
end

-- label: texto opcional encima de la lista; allBright: todas las filas sin atenuar (grabación);
-- selected: fila marcada en el modo foco.
function Bar:Refresh(spellIDs, label, allBright, selected)
  self.lastSpellIDs, self.lastLabel, self.lastAllBright = spellIDs, label, allBright
  local size = ns.db.iconSize
  local shown = #spellIDs
  if shown == 0 and not ns.db.locked then
    -- Desbloqueada y sin rotación: un marcador para poder colocar la lista.
    label = label or "Pudu's Rotation Helper (sin rotación)"
  end
  self.label:SetText(label or "")
  for i, spellID in ipairs(spellIDs) do
    local row = getRow(i)
    row.icon:SetTexture(C_Spell.GetSpellTexture(spellID))
    row.name:SetText(ns.SpellName(spellID) or tostring(spellID))
    -- La primera fila (la siguiente a lanzar) se ve entera; el resto, atenuadas.
    row:SetAlpha((allBright or i == 1) and 1 or 0.55)
    if row.glow then row.glow:SetShown(not allBright) end
    row.selected:SetShown(i == selected)
    row:Show()
  end
  for i = shown + 1, #self.rows do self.rows[i]:Hide() end
  local rows = math.max(1, shown)
  self:SetSize(size + 6 + NAME_WIDTH + 8, rows * size + (rows - 1) * ROW_GAP + 8)
  self:SetShown(shown > 0 or not ns.db.locked or (ns.EditorUI and ns.EditorUI.open))
end

ns.Bar = Bar

-- Atajos (Bindings.xml): asignables a botones o combinaciones del mando.
function PudusRotationHelper_ToggleLock() Bar:ToggleLock() end
function PudusRotationHelper_MoveUp() Bar:Nudge(0, 1) end
function PudusRotationHelper_MoveDown() Bar:Nudge(0, -1) end
function PudusRotationHelper_MoveLeft() Bar:Nudge(-1, 0) end
function PudusRotationHelper_MoveRight() Bar:Nudge(1, 0) end
BINDING_NAME_PUDUSROTATIONHELPER_TOGGLELOCK = "Bloquear / desbloquear lista"
BINDING_NAME_PUDUSROTATIONHELPER_MOVEUP = "Mover lista arriba"
BINDING_NAME_PUDUSROTATIONHELPER_MOVEDOWN = "Mover lista abajo"
BINDING_NAME_PUDUSROTATIONHELPER_MOVELEFT = "Mover lista a la izquierda"
BINDING_NAME_PUDUSROTATIONHELPER_MOVERIGHT = "Mover lista a la derecha"
