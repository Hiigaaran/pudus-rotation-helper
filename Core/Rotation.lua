-- Motor de rotación: Lua puro, sin API de WoW, para poder testearlo con busted.
local _, ns = ...
ns = ns or {}

local Rotation = {}
Rotation.__index = Rotation

-- steps: lista de spellIDs en el orden que el jugador configuró, p. ej. {133, 116, 133}
function Rotation.new(steps)
  return setmetatable({ steps = steps or {}, index = 1 }, Rotation)
end

function Rotation:Current()
  return self.steps[self.index]
end

-- Devuelve los próximos n pasos, dando la vuelta al final (rotación cíclica).
function Rotation:Peek(n)
  local out, count = {}, #self.steps
  if count == 0 then return out end
  for i = 0, math.min(n, count) - 1 do
    out[#out + 1] = self.steps[((self.index - 1 + i) % count) + 1]
  end
  return out
end

-- Llamar con cada lanzamiento propio. Si coincide con el paso actual avanza;
-- si coincide con un paso posterior, asume que el jugador se saltó pasos y salta ahí.
function Rotation:OnCast(spellID)
  local count = #self.steps
  if count == 0 then return false end
  for offset = 0, count - 1 do
    local i = ((self.index - 1 + offset) % count) + 1
    if self.steps[i] == spellID then
      self.index = (i % count) + 1
      return true
    end
  end
  return false -- hechizo que no está en la rotación: no cambia nada
end

function Rotation:Reset()
  self.index = 1
end

ns.Rotation = Rotation
return Rotation
