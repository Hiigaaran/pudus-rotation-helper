-- Importar y exportar rotaciones en markdown. Lua puro, testeable fuera del juego.
--
-- Los addons no pueden leer archivos del disco: el .md se prepara fuera del juego
-- y se pega en el cuadro de texto del panel de opciones. Formato:
--
--   # Protección básica          <- nombre del perfil
--   clase: Guerrero              <- opcional (español o inglés); por defecto, la del personaje
--   modo: secuencia              <- opcional: secuencia | prioridad
--
--   1. Embate con escudo (23922) <- ID entre paréntesis
--   2. Revancha                  <- o solo el nombre, si el personaje conoce el hechizo
--   - 7386                       <- o solo el ID
local _, ns = ...
ns = ns or {}

local Import = {}

local CLASSES = {
  WARRIOR = { "warrior", "guerrero" },
  PALADIN = { "paladin", "paladín" },
  HUNTER = { "hunter", "cazador" },
  ROGUE = { "rogue", "pícaro", "picaro" },
  PRIEST = { "priest", "sacerdote" },
  SHAMAN = { "shaman", "chamán", "chaman" },
  MAGE = { "mage", "mago" },
  WARLOCK = { "warlock", "brujo" },
  DRUID = { "druid", "druida" },
}
Import.CLASSES = CLASSES

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

function Import.ClassToken(text)
  local t = trim(text):lower()
  for token, names in pairs(CLASSES) do
    if t == token:lower() then return token end
    for _, n in ipairs(names) do if t == n then return token end end
  end
end

-- resolve: función(nombre) -> spellID o nil (en el juego usa C_Spell.GetSpellInfo).
-- Devuelve { name, class, mode, steps, errors }.
function Import.Parse(text, resolve)
  local result = { steps = {}, errors = {}, mode = "sequence" }
  local lineNo = 0
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    lineNo = lineNo + 1
    local l = trim(line)
    local title = l:match("^#+%s*(.+)$")
    local key, value = l:match("^(%a+)%s*:%s*(.+)$")
    local item = l:match("^[-*+]%s+(.+)$") or l:match("^%d+[.)]%s+(.+)$")
    if title then
      result.name = result.name or trim(title)
    elseif item then
      item = trim(item)
      local id = tonumber(item:match("%((%d+)%)%s*$") or item:match("^(%d+)$"))
      if not id and resolve then id = resolve(item) end
      if id then
        result.steps[#result.steps + 1] = id
      else
        result.errors[#result.errors + 1] = "línea " .. lineNo .. ": no se reconoce \"" .. item .. "\""
      end
    elseif key then
      key = key:lower()
      if key == "clase" or key == "class" then
        result.class = Import.ClassToken(value)
        if not result.class then
          result.errors[#result.errors + 1] = "línea " .. lineNo .. ": clase desconocida \"" .. trim(value) .. "\""
        end
      elseif key == "modo" or key == "mode" then
        local v = trim(value):lower()
        result.mode = (v == "prioridad" or v == "priority") and "priority" or "sequence"
      end
    end
  end
  if #result.steps == 0 then
    result.errors[#result.errors + 1] = "la lista no tiene pasos"
  end
  return result
end

-- nameOf: función(spellID) -> nombre o nil.
function Import.Export(profile, nameOf)
  local lines = {
    "# " .. (profile.name or "default"),
    "clase: " .. (profile.class or ""),
    "modo: " .. (profile.mode == "priority" and "prioridad" or "secuencia"),
    "",
  }
  for i, id in ipairs(profile.steps or {}) do
    local name = nameOf and nameOf(id)
    lines[#lines + 1] = i .. ". " .. (name and (name .. " (" .. id .. ")") or tostring(id))
  end
  return table.concat(lines, "\n")
end

ns.Import = Import
return Import
