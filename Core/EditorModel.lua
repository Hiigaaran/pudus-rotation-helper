-- Modelo del editor de rotación: Lua puro, testeable fuera del juego.
--
-- Dos columnas: a la izquierda la rotación, a la derecha las habilidades disponibles
-- (las que el jugador tiene en sus barras). Todo se maneja con la cruceta y cuatro botones:
--
--   Cruceta arriba/abajo   mover el cursor (o el paso tomado, al reordenar)
--   Cruceta izq./der.      cambiar de columna
--   A   en Habilidades: agregar después del paso seleccionado
--       en Rotación: tomar / soltar el paso para reordenarlo
--   X   quitar el paso seleccionado
--   Y   deshacer
local _, ns = ...
ns = ns or {}

local Editor = {}
Editor.__index = Editor

local HISTORY_MAX = 50

local function copy(t)
  local c = {}
  for i, v in ipairs(t) do c[i] = v end
  return c
end

-- steps: rotación actual; palette: spellIDs disponibles para agregar.
function Editor.new(steps, palette)
  local e = setmetatable({
    steps = copy(steps or {}),
    palette = copy(palette or {}),
    cursor = { rotation = 1, palette = 1 },
    history = {},
    grabbed = nil, -- índice del paso tomado para reordenar
  }, Editor)
  -- Con la rotación vacía lo natural es empezar eligiendo habilidades.
  e.column = #e.steps == 0 and #e.palette > 0 and "palette" or "rotation"
  e.cursor.rotation = math.max(1, #e.steps)
  return e
end

function Editor:List(column)
  return column == "palette" and self.palette or self.steps
end

function Editor:Selected(column)
  column = column or self.column
  return self:List(column)[self.cursor[column]]
end

function Editor:Snapshot()
  self.history[#self.history + 1] = copy(self.steps)
  if #self.history > HISTORY_MAX then table.remove(self.history, 1) end
end

local function clamp(i, n) return math.max(1, math.min(i, math.max(1, n))) end

-- dy: -1 arriba, 1 abajo. Devuelve un texto corto para mostrar como aviso (o nil).
function Editor:Move(dy)
  if self.grabbed then
    local i, j = self.grabbed, self.grabbed + dy
    if j < 1 or j > #self.steps then return nil end
    self.steps[i], self.steps[j] = self.steps[j], self.steps[i]
    self.grabbed, self.cursor.rotation = j, j
    return nil
  end
  local n = #self:List(self.column)
  if n == 0 then return nil end
  self.cursor[self.column] = ((self.cursor[self.column] - 1 + dy) % n) + 1
  return nil
end

-- dx: -1 izquierda (Rotación), 1 derecha (Habilidades).
function Editor:Switch(dx)
  if self.grabbed then return "Suelta el paso con A antes de cambiar de columna" end
  self.column = dx < 0 and "rotation" or "palette"
  return nil
end

function Editor:Accept()
  if self.column == "palette" then
    local spell = self:Selected("palette")
    if not spell then return nil end
    self:Snapshot()
    local at = #self.steps == 0 and 1 or self.cursor.rotation + 1
    table.insert(self.steps, at, spell)
    self.cursor.rotation = at
    return "added", spell, at
  end
  if #self.steps == 0 then return nil end
  if self.grabbed then
    self.grabbed = nil
    return "dropped"
  end
  self:Snapshot()
  self.grabbed = self.cursor.rotation
  return "grabbed"
end

function Editor:Remove()
  if self.column ~= "rotation" or #self.steps == 0 then return nil end
  self:Snapshot()
  local i = self.cursor.rotation
  local spell = table.remove(self.steps, i)
  self.grabbed = nil
  self.cursor.rotation = clamp(i, #self.steps)
  return "removed", spell
end

function Editor:Undo()
  local prev = table.remove(self.history)
  if not prev then return nil end
  self.steps = prev
  self.grabbed = nil
  self.cursor.rotation = clamp(self.cursor.rotation, #self.steps)
  return "undone"
end

ns.EditorModel = Editor
return Editor
