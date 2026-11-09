local _, ns = ...

-- Panel propio en Opciones > AddOns. Todo son frames propios no seguros.
local Options = {}
local panel = CreateFrame("Frame")
panel.name = "Pudu's Rotation Helper"

local function label(parent, text, font)
  local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
  fs:SetText(text)
  fs:SetJustifyH("LEFT")
  return fs
end

local function button(parent, text, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 24)
  b:SetText(text)
  b:SetScript("OnClick", onClick)
  return b
end

local function build()
  local title = label(panel, "Pudu's Rotation Helper", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)

  -- Escala de la lista -------------------------------------------------------
  local scaleLabel = label(panel, "")
  scaleLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)

  local slider = CreateFrame("Slider", nil, panel, "BackdropTemplate")
  slider:SetOrientation("HORIZONTAL")
  slider:SetSize(220, 16)
  slider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -8)
  slider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 },
  })
  slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  slider:SetMinMaxValues(0.5, 2)
  slider:SetValueStep(0.05)
  slider:SetObeyStepOnDrag(true)
  slider:SetScript("OnValueChanged", function(_, value)
    value = math.floor(value * 20 + 0.5) / 20
    ns.db.scale = value
    scaleLabel:SetText(("Escala de la lista: %d%%"):format(value * 100))
    ns.Bar:ApplyScale()
  end)
  panel.slider = slider

  -- Color del resaltado --------------------------------------------------------
  local colorLabel = label(panel, "Color del resaltado")
  colorLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -24)

  local swatch = CreateFrame("Button", nil, panel, "BackdropTemplate")
  swatch:SetSize(24, 24)
  swatch:SetPoint("LEFT", colorLabel, "RIGHT", 12, 0)
  swatch:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
  swatch.tex = swatch:CreateTexture(nil, "ARTWORK")
  swatch.tex:SetPoint("TOPLEFT", 3, -3)
  swatch.tex:SetPoint("BOTTOMRIGHT", -3, 3)
  panel.swatch = swatch

  local function setColor(r, g, b)
    ns.db.color = { r = r, g = g, b = b, a = 1 }
    swatch.tex:SetColorTexture(r, g, b)
    ns.Highlight:ApplyColor()
  end
  swatch:SetScript("OnClick", function()
    local c = ns.db.color
    local prev = { r = c.r, g = c.g, b = c.b }
    local function onChange() setColor(ColorPickerFrame:GetColorRGB()) end
    local function onCancel() setColor(prev.r, prev.g, prev.b) end
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        r = c.r, g = c.g, b = c.b, hasOpacity = false,
        swatchFunc = onChange, cancelFunc = onCancel,
      })
    else -- API antigua del selector de color
      ColorPickerFrame.func, ColorPickerFrame.cancelFunc, ColorPickerFrame.hasOpacity = onChange, onCancel, false
      ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
      ColorPickerFrame:Show()
    end
  end)

  -- Bloquear la lista ----------------------------------------------------------------
  local lockCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  lockCheck:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", -4, -16)
  local lockLabel = label(panel, "Bloquear la posición de la lista")
  lockLabel:SetPoint("LEFT", lockCheck, "RIGHT", 4, 0)
  lockCheck:SetScript("OnClick", function(self)
    if (self:GetChecked() and true or false) ~= (ns.db.locked and true or false) then ns.Bar:ToggleLock() end
  end)
  panel.lockCheck = lockCheck
  local lockHelp = label(panel, "También con el candado sobre la lista, /prh bloquear o el atajo \"Bloquear / desbloquear lista\" (asignable al mando). Desbloqueada, arrástrala o usa los atajos \"Mover lista\".", "GameFontHighlightSmall")
  lockHelp:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 4, -2)
  lockHelp:SetWidth(280)

  -- Reiniciar al salir de combate ------------------------------------------------------
  local resetCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  resetCheck:SetPoint("TOPLEFT", lockHelp, "BOTTOMLEFT", -4, -10)
  local resetLabel = label(panel, "Volver al primer paso al salir de combate")
  resetLabel:SetPoint("LEFT", resetCheck, "RIGHT", 4, 0)
  resetCheck:SetScript("OnClick", function(self) ns.db.resetOnCombatEnd = self:GetChecked() and true or false end)
  panel.resetCheck = resetCheck

  -- Rotación actual ----------------------------------------------------------------
  local rotTitle = label(panel, "Rotación actual")
  rotTitle:SetPoint("TOPLEFT", resetCheck, "BOTTOMLEFT", 4, -16)
  local rotText = label(panel, "", "GameFontHighlightSmall")
  rotText:SetPoint("TOPLEFT", rotTitle, "BOTTOMLEFT", 0, -6)
  rotText:SetWidth(260)
  rotText:SetJustifyV("TOP")
  panel.rotText = rotText

  local record = button(panel, "Abrir editor", 120, function()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    ns.EditorUI:Open()
  end)
  record:SetPoint("LEFT", rotTitle, "RIGHT", 16, 0)

  local manualHint = label(panel, "El manual de uso completo está en la sección \"Manual de uso\", debajo de este panel en la lista de AddOns.", "GameFontHighlightSmall")
  manualHint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

  local help = button(panel, "Pantalla de bienvenida", 180, function()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    ns.Splash:Show()
  end)
  help:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)

  -- Importar / exportar en markdown -------------------------------------------------
  local ioTitle = label(panel, "Importar / exportar (markdown): pega aquí una lista preparada fuera del juego")
  ioTitle:SetPoint("TOPLEFT", 320, -64)
  ioTitle:SetWidth(320)

  local box = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  box:SetPoint("TOPLEFT", ioTitle, "BOTTOMLEFT", 0, -8)
  box:SetSize(320, 260)
  box:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  box:SetBackdropColor(0, 0, 0, 0.6)

  local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 8, -8)
  scroll:SetPoint("BOTTOMRIGHT", -28, 8)
  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(280)
  edit:SetScript("OnEscapePressed", edit.ClearFocus)
  scroll:SetScrollChild(edit)
  box:EnableMouse(true)
  box:SetScript("OnMouseDown", function() edit:SetFocus() end)

  local status = label(panel, "", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -36)
  status:SetWidth(320)
  status:SetJustifyV("TOP")

  local import = button(panel, "Importar", 100, function()
    local r = ns.Import.Parse(edit:GetText(), ns.ResolveSpell)
    if #r.steps == 0 then
      status:SetText("|cffff4040No se importó nada:|r " .. table.concat(r.errors, "; "))
      return
    end
    local _, myClass = UnitClass("player")
    local class = r.class or myClass
    ns.SetProfile(r.steps, r.mode, r.name or "importado", class)
    ns.LoadRotation()
    local msg = ("|cff40ff40%d pasos importados|r en \"%s\" (%s)."):format(#r.steps, r.name or "importado", class)
    if class ~= myClass then msg = msg .. " Se usará al entrar con un personaje de esa clase." end
    if #r.errors > 0 then msg = msg .. "\n|cffffd100Avisos:|r " .. table.concat(r.errors, "; ") end
    status:SetText(msg)
    panel:Refresh()
  end)
  import:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -6)

  local export = button(panel, "Exportar", 100, function()
    edit:SetText(ns.Import.Export(ns.ActiveProfileForExport(), ns.SpellName))
    edit:SetFocus()
    edit:HighlightText()
    status:SetText("Copia el texto con Ctrl+C para guardarlo o compartirlo.")
  end)
  export:SetPoint("LEFT", import, "RIGHT", 8, 0)
end

function panel:Refresh()
  if not self.built then return end
  self.slider:SetValue(ns.db.scale or 1)
  self.lockCheck:SetChecked(ns.db.locked)
  self.resetCheck:SetChecked(ns.db.resetOnCombatEnd ~= false)
  local c = ns.db.color
  self.swatch.tex:SetColorTexture(c.r, c.g, c.b)
  local steps, mode = ns.GetActiveProfile()
  local lines = { ("Perfil: %s (%s)"):format(ns.ActiveProfileName(), mode == "priority" and "prioridad" or "secuencia") }
  for i, id in ipairs(steps) do lines[#lines + 1] = ("%d. %s"):format(i, ns.SpellName(id) or id) end
  if #steps == 0 then lines[#lines + 1] = "Sin pasos. Usa \"Abrir editor\" o importa una lista." end
  self.rotText:SetText(table.concat(lines, "\n"))
end

panel:SetScript("OnShow", function(self)
  if not self.built then build() self.built = true end
  self:Refresh()
end)

function Options:Refresh() panel:Refresh() end

function Options:Register()
  if Settings and Settings.RegisterCanvasLayoutCategory then
    self.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(self.category)
    ns.Manual:RegisterPanel(self.category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    ns.Manual:RegisterPanel(nil)
  end
end

function Options:Open()
  if self.category then
    Settings.OpenToCategory(self.category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
  end
end

ns.Options = Options
