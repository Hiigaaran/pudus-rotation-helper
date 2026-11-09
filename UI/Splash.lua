local addonName, ns = ...

-- Pantalla de bienvenida con la imagen del addon y las instrucciones básicas.
-- Se muestra al iniciar sesión con un personaje, salvo que el jugador desmarque la casilla.
local Splash = {}
local IMAGE = "Interface\\AddOns\\" .. addonName .. "\\Media\\splash" -- splash.tga, 1024x512
local WIDTH = 640

local INSTRUCTIONS = table.concat({
  "|cffffd100Cómo empezar|r",
  "1. En Opciones > Atajos de teclado > AddOns, asigna |cffffffff\"Grabar / guardar secuencia\"|r a una tecla o botón del mando.",
  "2. Pulsa el atajo, usa tus habilidades en el orden de tu rotación (mejor contra un muñeco) y vuelve a pulsarlo para guardar.",
  "3. La lista muestra las siguientes habilidades y el botón de la próxima se resalta en tus barras, también las de mando.",
  "4. Coloca la lista donde quieras y bloquéala con el candado o el atajo |cffffffff\"Bloquear / desbloquear lista\"|r.",
  "5. Con el mando, asigna |cffffffff\"Foco en la lista\"|r a una combinación (p. ej. LB+RB+Back). En foco, la cruceta elige o mueve, A bloquea, X saca el paso elegido y B sale. Esa combinación y esos botones, mientras dura el foco, quedan reservados y no lanzan habilidades.",
  "",
  "|cffffd100/prh|r abre las opciones: escala, color del resaltado e importar o exportar listas en markdown.",
}, "\n")

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
  image:SetSize(WIDTH, WIDTH / 2)
  image:SetPoint("TOP", 0, -12)

  local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("TOPLEFT", image, "BOTTOMLEFT", 8, -12)
  text:SetWidth(WIDTH - 16)
  text:SetJustifyH("LEFT")
  text:SetSpacing(3)
  text:SetText(INSTRUCTIONS)

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
    self:SetHeight(12 + WIDTH / 2 + 12 + text:GetStringHeight() + 56)
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
