local _, ns = ...

-- Forever no tiene GetSpecialization (comprobado): guardamos por clase + perfil.
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

-- Devuelve steps, mode. Acepta perfiles antiguos guardados como lista simple.
function ns.GetActiveProfile()
  local profileName = ns.db.active[charKey()] or "default"
  local _, class = UnitClass("player")
  local profile = (ns.db.profiles[class] or {})[profileName]
  if not profile then return {}, "sequence" end
  if profile.steps then return profile.steps, profile.mode end
  return profile, "sequence"
end

function ns.SetProfile(steps, mode, profileName)
  local _, class = UnitClass("player")
  profileName = profileName or "default"
  ns.db.profiles[class] = ns.db.profiles[class] or {}
  ns.db.profiles[class][profileName] = { steps = steps, mode = mode }
  ns.db.active[charKey()] = profileName
end
