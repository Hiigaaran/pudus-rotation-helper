local _, ns = ...

-- Editor de rotación pensado para el mando. Se abre con un atajo (una combinación del mando)
-- o con /prh editar. Mientras está abierto, la cruceta y los botones A, B, X, Y, Menú y Vista
-- manejan el editor y no lanzan habilidades (SetOverrideBindingClick). Al cerrarlo, los
-- botones vuelven a lo de siempre. No se abre en combate y se cierra solo al entrar en él,
-- porque el juego no permite cambiar atajos en combate.
local EditorUI = { open = false }
local ROWS, ROW_H, COL_W = 10, 30, 330
local PREFIX = "|cffffd100Pudu's Rotation Helper:|r "

local A = "|cff60d060A|r"
local B = "|cffe05050B|r"
local X = "|cff5090ffX|r"
local Y = "|cffe0c040Y|r"

local owner = CreateFrame("Frame")
local frame -- se construye al abrir por primera vez

-- Habilidades de las barras del jugador (teclado y mando), sin repetir el mismo hechizo.
local function scanPalette()
  local list, seen = {}, {}
  for slot = 1, 300 do
    local kind, id = GetActionInfo(slot)
    if kind == "spell" and id and id ~= 6603 then -- 6603: Ataque automático
      local key = ns.SpellName(id) or id
      if not seen[key] then
        seen[key] = true
        list[#list + 1] = id
      end
    end
  end
  return list
end

---------------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------------
local function makeColumn(parent, x, title)
  local col = CreateFrame("Frame", nil, parent)
  col:SetSize(COL_W, 28 + ROWS * ROW_H)
  col:SetPoint("TOPLEFT", x, -52)
  col.title = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  col.title:SetPoint("TOPLEFT", 4, 0)
  col.title:SetText(title)
  col.rows = {}
  for i = 1, ROWS do
    local row = CreateFrame("Button", nil, col)
    row:SetSize(COL_W, ROW_H - 2)
    row:SetPoint("TOPLEFT", 0, -22 - (i - 1) * ROW_H)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_H - 6, ROW_H - 6)
    row.icon:SetPoint("LEFT", 4, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.text:SetPoint("RIGHT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    col.rows[i] = row
  end
  col.more = col:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  col.more:SetPoint("TOPRIGHT", -4, 0)
  return col
end

local function build()
  local f = CreateFrame("Frame", "PudusRotationHelperEditor", UIParent, "BackdropTemplate")
  f:SetSize(COL_W * 2 + 60, 52 + 28 + ROWS * ROW_H + 110)
  f:SetPoint("CENTER", 0, 60)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
  })
  f:EnableMouse(true)
  tinsert(UISpecialFrames, f:GetName()) -- Escape cierra (y guarda)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", 0, -18)

  f.left = makeColumn(f, 20, "Tu rotación")
  f.right = makeColumn(f, 40 + COL_W, "Habilidades en tus barras")

  f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.status:SetPoint("TOPLEFT", f.left, "BOTTOMLEFT", 4, -10)
  f.status:SetWidth(COL_W * 2 + 10)
  f.status:SetJustifyH("LEFT")

  f.legend = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.legend:SetPoint("TOPLEFT", f.status, "BOTTOMLEFT", 0, -10)
  f.legend:SetWidth(COL_W * 2 + 10)
  f.legend:SetJustifyH("LEFT")
  f.legend:SetSpacing(4)

  -- Botones para ratón (con mando se usan B y Vista).
  local save = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  save:SetSize(140, 24)
  save:SetPoint("BOTTOMRIGHT", -16, 14)
  save:SetText("Guardar y salir")
  save:SetScript("OnClick", function() EditorUI:Close(true) end)
  local discard = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  discard:SetSize(140, 24)
  discard:SetPoint("RIGHT", save, "LEFT", -8, 0)
  discard:SetText("Descartar")
  discard:SetScript("OnClick", function() EditorUI:Close(false) end)

  -- Clic en una fila: seleccionarla.
  for colName, col in pairs({ rotation = f.left, palette = f.right }) do
    for i, row in ipairs(col.rows) do
      row:SetScript("OnClick", function()
        local m = EditorUI.model
        if not m or m.grabbed then return end
        local idx = (col.offset or 0) + i
        if idx <= #m:List(colName) then
          m.column = colName
          m.cursor[colName] = idx
          EditorUI:Render()
        end
      end)
    end
  end

  -- Escape (o cualquier otra forma de ocultar la ventana) guarda y cierra.
  f:SetScript("OnHide", function()
    if EditorUI.open then EditorUI:Close(true) end
  end)
  f:Hide()
  return f
end

local function renderColumn(col, list, cursor, active, grabbed, numbered)
  local n = #list
  -- Desplazar para que el cursor siempre se vea.
  col.offset = col.offset or 0
  if cursor > col.offset + ROWS then col.offset = cursor - ROWS end
  if cursor <= col.offset then col.offset = cursor - 1 end
  col.offset = math.max(0, math.min(col.offset, math.max(0, n - ROWS)))
  for i, row in ipairs(col.rows) do
    local idx = col.offset + i
    local id = list[idx]
    if id then
      row.icon:SetTexture(C_Spell.GetSpellTexture(id))
      local spellName = ns.SpellName(id) or tostring(id)
      row.text:SetText(numbered and (idx .. ". " .. spellName) or spellName)
      if idx == grabbed then
        row.bg:SetColorTexture(0.2, 0.8, 0.3, 0.45)
      elseif idx == cursor then
        if active then row.bg:SetColorTexture(1, 0.82, 0.1, 0.4) else row.bg:SetColorTexture(1, 1, 1, 0.12) end
      else
        row.bg:SetColorTexture(0, 0, 0, 0)
      end
      row:Show()
    else
      row:Hide()
    end
  end
  col.more:SetText(n > ROWS and ("%d-%d de %d"):format(col.offset + 1, math.min(n, col.offset + ROWS), n) or "")
  if n == 0 then
    local row = col.rows[1]
    row.icon:SetTexture(nil)
    row.text:SetText(numbered and "Vacía: ve a la derecha y agrega con A" or "No hay habilidades en tus barras")
    row.bg:SetColorTexture(0, 0, 0, 0)
    row:Show()
  end
end

local function setTitleColor(fs, active)
  if active then fs:SetTextColor(1, 0.82, 0) else fs:SetTextColor(0.6, 0.6, 0.6) end
end

function EditorUI:Render()
  local m, f = self.model, frame
  if not m or not f then return end
  f.title:SetText(("Editor de rotación: %s (%d pasos)"):format(ns.ActiveProfileName(), #m.steps))
  renderColumn(f.left, m.steps, m.cursor.rotation, m.column == "rotation", m.grabbed, true)
  renderColumn(f.right, m.palette, m.cursor.palette, m.column == "palette", nil, false)
  setTitleColor(f.left.title, m.column == "rotation")
  setTitleColor(f.right.title, m.column == "palette")

  local lines
  if self.moving then
    lines = { "|cff40c0ffMOVIENDO LA LISTA|r   Cruceta: mover   " .. A .. " o Menú: bloquear y volver al editor" }
  elseif m.grabbed then
    lines = { "|cff40ff40REORDENANDO|r   Cruceta arriba/abajo: mover el paso   " .. A .. ": soltar   " .. Y .. ": deshacer" }
  elseif m.column == "palette" then
    lines = { "Cruceta: elegir habilidad   Izquierda: ir a tu rotación   " .. A .. ": agregar después del paso marcado   " .. Y .. ": deshacer" }
  else
    lines = { "Cruceta: elegir paso   Derecha: ir a las habilidades   " .. A .. ": tomar para reordenar   " .. X .. ": quitar   " .. Y .. ": deshacer" }
  end
  lines[#lines + 1] = B .. ": guardar y salir   Vista: descartar cambios   Menú: mover / bloquear la lista"
  lines[#lines + 1] = "|cff999999Mientras el editor está abierto, estos botones no lanzan habilidades.|r"
  f.legend:SetText(table.concat(lines, "\n"))
end

function EditorUI:Status(text)
  if frame then frame.status:SetText(text or "") end
end

---------------------------------------------------------------------------
-- Acciones de los botones
---------------------------------------------------------------------------
local function spellLabel(id) return ns.SpellName(id) or tostring(id) end

local function switch(dx)
  if EditorUI.moving then ns.Bar:Nudge(dx, 0) return end
  local warn = EditorUI.model:Switch(dx)
  if warn then EditorUI:Status("|cffff8040" .. warn .. "|r") end
end

local actions = {
  up = function() if EditorUI.moving then ns.Bar:Nudge(0, 1) else EditorUI.model:Move(-1) end end,
  down = function() if EditorUI.moving then ns.Bar:Nudge(0, -1) else EditorUI.model:Move(1) end end,
  left = function() switch(-1) end,
  right = function() switch(1) end,
  accept = function()
    if EditorUI.moving then EditorUI:ToggleMove() return end
    local what, spell, at = EditorUI.model:Accept()
    if what == "added" then
      EditorUI:Status(("|cff40ff40Agregado:|r %s en el paso %d"):format(spellLabel(spell), at))
    elseif what == "grabbed" then
      EditorUI:Status("Paso tomado: muévelo con la cruceta y suéltalo con " .. A)
    elseif what == "dropped" then
      EditorUI:Status("Paso colocado")
    end
  end,
  remove = function()
    if EditorUI.moving then return end
    local what, spell = EditorUI.model:Remove()
    if what then
      EditorUI:Status(("|cffff6060Quitado:|r %s   (%s para deshacer)"):format(spellLabel(spell), Y))
    elseif EditorUI.model.column == "palette" then
      EditorUI:Status("Para quitar un paso, ve a tu rotación (izquierda) y pulsa " .. X)
    end
  end,
  undo = function()
    if EditorUI.moving then return end
    EditorUI:Status(EditorUI.model:Undo() and "Deshecho" or "No hay nada que deshacer")
  end,
  save = function() EditorUI:Close(true) end,
  discard = function() EditorUI:Close(false) end,
  move = function() EditorUI:ToggleMove() end,
}

-- Botones del mando y su equivalente en teclado.
local KEYS = {
  up = { "PADDUP", "UP" }, down = { "PADDDOWN", "DOWN" },
  left = { "PADDLEFT", "LEFT" }, right = { "PADDRIGHT", "RIGHT" },
  accept = { "PAD1", "ENTER" }, save = { "PAD2" }, remove = { "PAD3", "DELETE" },
  undo = { "PAD4", "BACKSPACE" }, move = { "PADFORWARD" }, discard = { "PADBACK" },
}

for action, run in pairs(actions) do
  -- Botón invisible (1x1, sin textura) pero mostrado: así los clics por atajo llegan seguro.
  local b = CreateFrame("Button", "PudusRotationHelperEditor_" .. action, UIParent)
  b:SetSize(1, 1)
  b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
  b:EnableMouse(false)
  b:SetScript("OnClick", function()
    if not EditorUI.open then return end
    run()
    if EditorUI.open then EditorUI:Render() end
  end)
end

---------------------------------------------------------------------------
-- Abrir y cerrar
---------------------------------------------------------------------------
-- steps opcional: abrir con otra lista (p. ej. recién grabada) en vez de la guardada.
function EditorUI:Open(steps)
  if self.open then return end
  if InCombatLockdown() then
    print(PREFIX .. "el editor no se puede abrir en combate.")
    return
  end
  frame = frame or build()
  local saved, mode = ns.GetActiveProfile()
  self.mode = mode
  self.model = ns.EditorModel.new(steps or saved, scanPalette())
  self.moving = false
  for action, keys in pairs(KEYS) do
    for _, key in ipairs(keys) do
      SetOverrideBindingClick(owner, true, key, "PudusRotationHelperEditor_" .. action)
    end
  end
  self.open = true
  frame:Show()
  self:Status(#self.model.palette == 0 and "|cffff8040Pon habilidades en tus barras para poder agregarlas.|r" or "")
  self:Render()
end

function EditorUI:Close(save)
  if not self.open then return end
  self.open = false
  ClearOverrideBindings(owner)
  if self.moving then
    self.moving = false
    if not ns.db.locked then ns.Bar:ToggleLock() end
  end
  if frame and frame:IsShown() then frame:Hide() end
  if save then
    ns.SetProfile(self.model.steps, self.mode or "sequence")
    print(PREFIX .. ("rotación guardada (%d pasos)."):format(#self.model.steps))
  else
    print(PREFIX .. "cambios descartados.")
  end
  self.model = nil
  ns.LoadRotation()
end

function EditorUI:Toggle()
  if self.open then self:Close(true) else self:Open() end
end

-- Menú: entrar o salir del modo "mover la lista". Al salir, la lista queda bloqueada.
function EditorUI:ToggleMove()
  self.moving = not self.moving
  if self.moving then
    if ns.db.locked then ns.Bar:ToggleLock() end
    self:Status("Mueve la lista con la cruceta")
  else
    if not ns.db.locked then ns.Bar:ToggleLock() end
    self:Status("Lista bloqueada en su sitio")
  end
end

-- Las anulaciones hay que quitarlas antes de que empiece el bloqueo de combate.
owner:RegisterEvent("PLAYER_REGEN_DISABLED")
owner:SetScript("OnEvent", function()
  if EditorUI.open then
    EditorUI:Close(true)
    print(PREFIX .. "editor cerrado al entrar en combate (los cambios se guardaron).")
  end
end)

-- Se mantiene el nombre interno del atajo para no perder lo que el jugador ya asignó al foco.
function PudusRotationHelper_ToggleFocus() EditorUI:Toggle() end
BINDING_NAME_PUDUSROTATIONHELPER_TOGGLEFOCUS = "Abrir / cerrar editor de rotación (combinación reservada)"

ns.EditorUI = EditorUI
