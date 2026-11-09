-- Grabador de secuencias: Lua puro, testeable fuera del juego.
-- El jugador pulsa sus habilidades en orden (teclado o mando) y cada intento de
-- lanzamiento se añade a la lista. Un mismo intento genera varios eventos
-- (enviado, completado, fallido), así que se agrupan por castGUID o por tiempo.
local _, ns = ...
ns = ns or {}

local IGNORED = { [6603] = true } -- Ataque automático: se activa solo y ensucia la lista
local WINDOW = 0.4 -- segundos: el mismo hechizo repetido dentro de esta ventana es un solo intento

local Recorder = {}
Recorder.__index = Recorder

function Recorder.new()
  return setmetatable({ steps = {}, seenGUID = {}, lastID = nil, lastTime = -math.huge }, Recorder)
end

-- Devuelve true si el hechizo se añadió.
function Recorder:Add(spellID, now, castGUID)
  if not spellID or IGNORED[spellID] then return false end
  if castGUID then
    if self.seenGUID[castGUID] then return false end
    self.seenGUID[castGUID] = true
  end
  if spellID == self.lastID and now - self.lastTime < WINDOW then
    self.lastTime = now
    return false
  end
  self.steps[#self.steps + 1] = spellID
  self.lastID, self.lastTime = spellID, now
  return true
end

function Recorder:Undo()
  self.steps[#self.steps] = nil
  self.lastID, self.lastTime = self.steps[#self.steps], -math.huge
end

function Recorder:Steps()
  local copy = {}
  for i, id in ipairs(self.steps) do copy[i] = id end
  return copy
end

ns.Recorder = Recorder
return Recorder
