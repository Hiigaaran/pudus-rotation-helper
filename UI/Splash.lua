local addonName, ns = ...

-- Pantalla de bienvenida con la imagen del addon y las instrucciones básicas.
-- Se muestra al iniciar sesión con un personaje, salvo que el jugador desmarque la casilla.
local Splash = {}
local IMAGE = "Interface\\AddOns\\" .. addonName .. "\\Media\\splash" -- splash.tga, 1024x512
local WIDTH = 680 -- ancho del texto; la imagen va a 480x240 centrada
local IMG_W, IMG_H = 480, 240

-- Lo esencial del manual; el manual completo está en Opciones > AddOns > Manual de uso.
local function instructions()
  return ns.Manual.Text({ "start", "editor" })
    .. "\n\n|cffffd100/prh|r abre las opciones y el |cffffffffManual de uso|r completo (importar listas, comandos)."
end

local function build()
  local f = CreateFrame("Frame", "PudusRotationHelperSplash", UIParent, "BackdropTemplate")
  f:SetSize(WIDTH + 24, 0)
  f:SetPoint("CENTER", 0, 40)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
  })
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  tinsert(UISpecialFrames, f:GetName()) -- se cierra con Escape

  local image = f:CreateTexture(nil, "ARTWORK")
  image:SetTexture(IMAGE)
  image:SetSize(IMG_W, IMG_H)
  image:SetPoint("TOP", 0, -12)

  local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOP", image, "BOTTOM", 0, -12)
  text:SetWidth(WIDTH - 16)
  text:SetJustifyH("LEFT")
  text:SetSpacing(2)
  text:SetText(instructions())

  local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  check:SetPoint("BOTTOMLEFT", 12, 10)
  check:SetScript("OnClick", function(self) ns.db.showSplash = self:GetChecked() and true or false end)
  local checkLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  checkLabel:SetPoint("LEFT", check, "RIGHT", 4, 0)
  checkLabel:SetText("Mostrar al iniciar sesión con un personaje")
  f.check = check

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetSize(120, 24)
  close:SetPoint("BOTTOMRIGHT", -14, 14)
  close:SetText("Empezar")
  close:SetScript("OnClick", function() f:Hide() end)

  local x = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  x:SetPoint("TOPRIGHT", 2, 2)

  -- Alto según el texto: imagen + texto + fila de la casilla.
  f:SetScript("OnShow", function(self)
    self.check:SetChecked(ns.db.showSplash ~= false)
    self:SetHeight(12 + IMG_H + 12 + text:GetStringHeight() + 56)
  end)
  f:Hide()
  return f
end

function Splash:Show()
  self.frame = self.frame or build()
  self.frame:Show()
end

function Splash:OnLogin()
  if ns.db.showSplash ~= false then self:Show() end
end

ns.Splash = Splash
