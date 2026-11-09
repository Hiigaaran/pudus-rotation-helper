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
      "1. En Opciones > Atajos de teclado > AddOns, asigna " .. K:format("\"Abrir / cerrar editor de rotación\"") .. " a una combinación del mando (p. ej. LB+RB+Back). También " .. K:format("/prh editar") .. ".",
      "2. En el editor, a la derecha están las habilidades de tus barras. Elige una con la cruceta y agrégala con " .. K:format("A") .. ". Se agrega después del paso marcado a la izquierda, así que puedes armar la rotación en orden sin lanzar nada.",
      "3. Pulsa " .. K:format("B") .. " para guardar y salir. La lista muestra las siguientes habilidades con su nombre, el botón de la próxima se resalta en tus barras (también las de mando) y avanza cada vez que usas la habilidad que toca. Al salir de combate vuelve al primer paso (se puede desactivar en las opciones).",
    },
  },
  {
    key = "list",
    title = "Mover y bloquear la lista",
    lines = {
      "- Desbloqueada (fondo azul): arrástrala con el ratón o el cursor del mando, o usa los atajos " .. K:format("\"Mover lista arriba/abajo/izquierda/derecha\"") .. ". La posición se guarda.",
      "- En el editor, " .. K:format("Menú") .. " desbloquea la lista para moverla con la cruceta y la vuelve a bloquear.",
      "- Bloquéala o desbloquéala con el candado sobre la lista, el atajo " .. K:format("\"Bloquear / desbloquear lista\"") .. ", la casilla de este panel o " .. K:format("/prh bloquear") .. ". Bloqueada, deja pasar los clics.",
    },
  },
  {
    key = "editor",
    title = "Editor de rotación con el mando",
    lines = {
      "- " .. K:format("Cruceta") .. ": arriba/abajo eligen; izquierda/derecha cambian entre " .. K:format("Tu rotación") .. " y " .. K:format("Habilidades en tus barras") .. ".",
      "- " .. K:format("A") .. ": en Habilidades, agrega la elegida después del paso marcado. En Tu rotación, toma el paso para reordenarlo (muévelo con la cruceta y suéltalo con A).",
      "- " .. K:format("X") .. ": quita el paso marcado.   " .. K:format("Y") .. ": deshace el último cambio.",
      "- " .. K:format("B") .. ": guarda y sale.   " .. K:format("Vista") .. ": descarta los cambios.   " .. K:format("Menú") .. ": mover la lista con la cruceta y bloquearla.",
      "- Teclado y ratón: flechas, Enter, Supr y Retroceso, clic en las filas y los botones Guardar y Descartar.",
      "|cffff8040Botones reservados:|r la combinación que abre el editor es del addon y no lanza habilidades; si se la asignas a una habilidad, el juego se la quita al editor. Mientras el editor está abierto, la cruceta y A, B, X, Y, Menú y Vista tampoco lanzan habilidades. El editor no se abre en combate y se cierra (guardando) al entrar en combate.",
      "- Alternativa: el atajo " .. K:format("\"Grabar secuencia\"") .. " graba lo que lanzas de verdad; al terminar se abre el editor para quitar lo que pulsaste por error.",
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
      K:format("/prh") .. " opciones   " .. K:format("/prh editar") .. " editor   " .. K:format("/prh ayuda") .. " bienvenida   " .. K:format("/prh bloquear"),
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
-- Se construye en el momento (no al mostrarse) y con tamaños fijos: el contenedor de
-- Opciones puede tener tamaño 0 cuando se crean los hijos, y así el texto no depende de eso.
local TEXT_W, VIEW_W, VIEW_H = 560, 590, 470

function Manual:RegisterPanel(parentCategory)
  local panel = CreateFrame("Frame")
  panel.name = "Manual de uso"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Pudu's Rotation Helper: manual de uso")

  local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  local content
  if ok and scroll then
    scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    scroll:SetSize(VIEW_W, VIEW_H)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(TEXT_W, VIEW_H)
    scroll:SetScrollChild(content)
  else
    -- Sin plantilla de desplazamiento: texto directo en el panel.
    content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    content:SetSize(TEXT_W, VIEW_H)
  end

  local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", 0, 0)
  text:SetWidth(TEXT_W)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  text:SetSpacing(3)
  text:SetText(Manual.Text())

  local function fit()
    content:SetHeight(math.max(VIEW_H, text:GetStringHeight() + 20))
  end
  fit()
  panel:SetScript("OnShow", fit)

  if Settings and Settings.RegisterCanvasLayoutSubcategory and parentCategory then
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
  elseif InterfaceOptions_AddCategory then
    panel.parent = "Pudu's Rotation Helper"
    InterfaceOptions_AddCategory(panel)
  end
end

ns.Manual = Manual
