-- Motor de rotación: Lua puro, sin API de WoW, para poder testearlo con busted.
--
-- Dos modos:
--   "sequence": orden fijo que se repite; avanza con cada lanzamiento propio.
--   "priority": lista de prioridades; se sugiere la primera habilidad lista.
--               Pensado para clases como Guerrero Protección (Revancha solo tras bloquear/esquivar).
local _, ns = ...
ns = ns or {}

local Rotation = {}
Rotation.__index = Rotation

-- steps: lista de spellIDs, p. ej. {23922, 6572, 7386}
-- isReady: función(spellID) -> boolean; solo se usa en modo "priority". Por defecto, todo listo.
function Rotation.new(steps, mode, isReady)
  return setmetatable({
    steps = steps or {},
    mode = mode == "priority" and "priority" or "sequence",
    isReady = isReady or function() return true end,
    index = 1,
  }, Rotation)
end

-- Devuelve los próximos n hechizos a mostrar.
function Rotation:Peek(n)
  local out, count = {}, #self.steps
  if count == 0 then return out end
  n = math.min(n, count)
  if self.mode == "priority" then
    -- Primero los que están listos, en orden de prioridad; luego el resto, atenuados en la barra.
    local waiting = {}
    for _, id in ipairs(self.steps) do
      if self.isReady(id) then out[#out + 1] = id else waiting[#waiting + 1] = id end
    end
    for _, id in ipairs(waiting) do out[#out + 1] = id end
    for i = #out, n + 1, -1 do out[i] = nil end
    return out
  end
  for i = 0, n - 1 do
    out[#out + 1] = self.steps[((self.index - 1 + i) % count) + 1]
  end
  return out
end

function Rotation:Current()
  return self:Peek(1)[1]
end

-- Llamar con cada lanzamiento propio. Devuelve true si la sugerencia puede haber cambiado.
-- En "sequence": si coincide con el paso actual avanza; si coincide con un paso posterior,
-- asume que el jugador se saltó pasos y salta ahí.
function Rotation:OnCast(spellID)
  local count = #self.steps
  if count == 0 then return false end
  if self.mode == "priority" then
    for _, id in ipairs(self.steps) do
      if id == spellID then return true end
    end
    return false
  end
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
