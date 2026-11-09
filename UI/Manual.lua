local _, ns = ...

-- Manual de uso: un solo texto que comparten la pantalla de bienvenida y la sección
-- "Manual de uso" del panel de opciones, para que nunca digan cosas distintas.
local Manual = {}

local H = "|cffffd100%s|r"
local K = "|cffffffff%s|r"

Manual.SECTIONS = {
  {
    key = "start",
    title = "Cómo empezar",
    lines = {
      "1. En Opciones > Atajos de teclado > AddOns, asigna " .. K:format("\"Grabar / guardar secuencia\"") .. " a una tecla o botón del mando.",
      "2. Pulsa el atajo, usa tus habilidades en el orden de tu rotación (mejor contra un muñeco) y vuelve a pulsarlo para guardar. También " .. K:format("/prh grabar") .. " y " .. K:format("/prh fin") .. ".",
      "3. La lista muestra las siguientes habilidades con su nombre y el botón de la próxima se resalta en tus barras, también en las de mando. Avanza cada vez que usas la habilidad que toca.",
    },
  },
  {
    key = "list",
    title = "Mover y bloquear la lista",
    lines = {
      "- Desbloqueada (fondo azul): arrástrala con el ratón o el cursor del mando, o usa los atajos " .. K:format("\"Mover lista arriba/abajo/izquierda/derecha\"") .. ". La posición se guarda.",
      "- Bloquéala o desbloquéala con el candado sobre la lista, el atajo " .. K:format("\"Bloquear / desbloquear lista\"") .. ", la casilla de este panel o " .. K:format("/prh bloquear") .. ". Bloqueada, deja pasar los clics.",
    },
  },
  {
    key = "focus",
    title = "Modo foco con el mando",
    lines = {
      "Asigna " .. K:format("\"Foco en la lista\"") .. " a una combinación del mando (p. ej. LB+RB+Back) o escribe " .. K:format("/prh foco") .. ". Mientras dura el foco:",
      "- " .. K:format("Cruceta") .. ": con la lista bloqueada, arriba/abajo eligen un paso (marcado en azul); desbloqueada, mueve la lista.",
      "- " .. K:format("A") .. ": bloquear o desbloquear la lista.",
      "- " .. K:format("X") .. ": sacar el paso elegido. Grabando, saca un paso de lo grabado en vez de agregar uno.",
      "- " .. K:format("B") .. ": salir del foco.",
      "- Teclado: flechas, Enter, Supr y Retroceso hacen lo mismo.",
      "|cffff8040Botones reservados:|r la combinación del foco es del addon y no lanza habilidades; si se la asignas a una habilidad, el juego se la quita al foco. Durante el foco, la cruceta, A, X y B tampoco lanzan habilidades. El foco no se abre en combate y se cierra solo al entrar en combate.",
    },
  },
  {
    key = "options",
    title = "Opciones e importación",
    lines = {
      "- " .. K:format("/prh") .. " abre las opciones: escala de la lista, color del resaltado y bloqueo.",
      "- Importar: prepara un .md fuera del juego, cópialo y pégalo en el cuadro de " .. K:format("Importar / exportar") .. ". Formato: un título " .. K:format("# Nombre") .. ", opcionalmente " .. K:format("clase:") .. " y " .. K:format("modo: secuencia | prioridad") .. ", y una lista numerada con el nombre y/o el ID de cada habilidad, p. ej. " .. K:format("1. Revancha (6572)") .. ".",
      "- Exportar copia tu rotación actual en ese mismo formato para guardarla o compartirla.",
      "- Funciona con todas las clases: las rotaciones se guardan por clase y cualquier rango de una habilidad cuenta como la misma.",
    },
  },
  {
    key = "commands",
    title = "Comandos",
    lines = {
      K:format("/prh") .. " opciones   " .. K:format("/prh ayuda") .. " bienvenida   " .. K:format("/prh foco") .. "   " .. K:format("/prh bloquear"),
      K:format("/prh grabar") .. " · " .. K:format("fin") .. " · " .. K:format("cancelar") .. " · " .. K:format("deshacer") .. "   " .. K:format("/prh reset") .. " vuelve al primer paso",
    },
  },
}

-- keys: lista de secciones a incluir (nil = todas).
function Manual.Text(keys)
  local wanted
  if keys then wanted = {} for _, k in ipairs(keys) do wanted[k] = true end end
  local out = {}
  for _, s in ipairs(Manual.SECTIONS) do
    if not wanted or wanted[s.key] then
      if #out > 0 then out[#out + 1] = "" end
      out[#out + 1] = H:format(s.title)
      for _, l in ipairs(s.lines) do out[#out + 1] = l end
    end
  end
  return table.concat(out, "\n")
end

-- Subsección "Manual de uso" bajo el panel del addon en Opciones > AddOns.
function Manual:RegisterPanel(parentCategory)
  local panel = CreateFrame("Frame")
  panel.name = "Manual de uso"
  panel:SetScript("OnShow", function(self)
    if self.built then return end
    self.built = true
    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Pudu's Rotation Helper: manual de uso")

    local scroll = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    scroll:SetPoint("BOTTOMRIGHT", -32, 16)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(600, 10)
    scroll:SetScrollChild(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT")
    text:SetWidth(600)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    text:SetText(Manual.Text())
    content:SetHeight(text:GetStringHeight() + 20)
    scroll:SetScript("OnSizeChanged", function(_, w)
      if w and w > 50 then content:SetWidth(w) text:SetWidth(w - 8) content:SetHeight(text:GetStringHeight() + 20) end
    end)
  end)
  if Settings and Settings.RegisterCanvasLayoutSubcategory and parentCategory then
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
  elseif InterfaceOptions_AddCategory then
    panel.parent = "Pudu's Rotation Helper"
    InterfaceOptions_AddCategory(panel)
  end
end

ns.Manual = Manual
