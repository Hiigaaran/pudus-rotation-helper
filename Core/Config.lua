local _, ns = ...

-- Forever es estilo 2004: puede no existir GetSpecialization. Usamos clase + perfil.
local defaults = { profiles = {}, active = {}, barSize = 4, iconSize = 40 }

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

function ns.GetActiveSteps()
  local profileName = ns.db.active[charKey()] or "default"
  local _, class = UnitClass("player")
  local byClass = ns.db.profiles[class] or {}
  return byClass[profileName] or {}
end

function ns.SetSteps(steps, profileName)
  local _, class = UnitClass("player")
  profileName = profileName or "default"
  ns.db.profiles[class] = ns.db.profiles[class] or {}
  ns.db.profiles[class][profileName] = steps
  ns.db.active[charKey()] = profileName
end
