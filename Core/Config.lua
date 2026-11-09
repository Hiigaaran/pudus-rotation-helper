local _, ns = ...

-- Forever no tiene GetSpecialization (comprobado): guardamos por clase + perfil.
-- La clase es el token en inglés que devuelve UnitClass ("WARRIOR", "DRUID", ...), así que
-- funciona igual para las nueve clases de Forever sin listas por clase.
local defaults = {
  profiles = {}, active = {}, lastByClass = {}, barSize = 4, iconSize = 40,
  scale = 1, locked = false, showSplash = true, position = nil, color = { r = 1, g = 0.85, b = 0.1, a = 1 },
}

function ns.InitDB()
  PudusRotationHelperDB = PudusRotationHelperDB or {}
  for k, v in pairs(defaults) do
    if PudusRotationHelperDB[k] == nil then PudusRotationHelperDB[k] = v end
  end
  ns.db = PudusRotationHelperDB
end

local function charKey()
  return UnitName("player") .. "-" .. GetRealmName()
end

local function playerClass()
  local _, class = UnitClass("player")
  return class
end

-- Perfil activo del personaje; si no eligió ninguno, el último guardado o importado para su clase.
function ns.ActiveProfileName()
  return ns.db.active[charKey()] or ns.db.lastByClass[playerClass()] or "default"
end

-- Devuelve steps, mode. Acepta perfiles antiguos guardados como lista simple.
function ns.GetActiveProfile()
  local profile = (ns.db.profiles[playerClass()] or {})[ns.ActiveProfileName()]
  if not profile then return {}, "sequence" end
  if profile.steps then return profile.steps, profile.mode end
  return profile, "sequence"
end

-- Guarda un perfil. Si es de la clase del personaje, pasa a ser el activo.
function ns.SetProfile(steps, mode, profileName, class)
  class = class or playerClass()
  profileName = profileName or ns.ActiveProfileName()
  ns.db.profiles[class] = ns.db.profiles[class] or {}
  ns.db.profiles[class][profileName] = { steps = steps, mode = mode }
  ns.db.lastByClass[class] = profileName
  if class == playerClass() then ns.db.active[charKey()] = profileName end
end

function ns.ActiveProfileForExport()
  local steps, mode = ns.GetActiveProfile()
  return { name = ns.ActiveProfileName(), class = playerClass(), mode = mode, steps = steps }
end

-- Mismo hechizo aunque sea otro rango: en Forever cada rango tiene su propio ID
-- (p. ej. Golpe heroico rango 1 = 284), así que comparamos también por nombre.
local nameCache = {}
local function spellName(id)
  if not id then return nil end
  local n = nameCache[id]
  if n == nil then
    n = C_Spell.GetSpellName(id) or false
    nameCache[id] = n
  end
  return n or nil
end
ns.SpellName = spellName

function ns.SameSpell(a, b)
  if a == b then return true end
  local na = spellName(a)
  return na ~= nil and na == spellName(b)
end

-- Nombre -> ID, para importar listas escritas con nombres. Solo funciona con hechizos
-- que el personaje conoce (y en el idioma del cliente).
function ns.ResolveSpell(name)
  local info = C_Spell.GetSpellInfo(name)
  return info and info.spellID
end
