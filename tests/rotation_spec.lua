-- Ejecutar con: busted tests/   (desde la carpeta del addon, Lua 5.1)
local Rotation = loadfile("Core/Rotation.lua")("PudusRotationHelper", {})

describe("Rotation en modo secuencia", function()
  it("muestra los próximos pasos y da la vuelta", function()
    local r = Rotation.new({ 1, 2, 3 })
    r:OnCast(1); r:OnCast(2)
    assert.same({ 3, 1, 2 }, r:Peek(3))
  end)

  it("ignora hechizos fuera de la rotación", function()
    local r = Rotation.new({ 1, 2 })
    assert.is_false(r:OnCast(99))
    assert.equal(1, r:Current())
  end)

  it("salta si el jugador se adelanta un paso", function()
    local r = Rotation.new({ 1, 2, 3 })
    r:OnCast(2)
    assert.equal(3, r:Current())
  end)
end)

describe("Rotation en modo prioridad", function()
  it("sugiere la primera habilidad lista", function()
    local ready = { [1] = false, [2] = true, [3] = true }
    local r = Rotation.new({ 1, 2, 3 }, "priority", function(id) return ready[id] end)
    assert.equal(2, r:Current())
    ready[1] = true
    assert.equal(1, r:Current())
  end)

  it("pone al final las que no están listas", function()
    local r = Rotation.new({ 1, 2, 3 }, "priority", function(id) return id ~= 1 end)
    assert.same({ 2, 3, 1 }, r:Peek(3))
    assert.same({ 2, 3 }, r:Peek(2))
  end)

  it("pide refrescar solo con hechizos de la lista", function()
    local r = Rotation.new({ 1, 2 }, "priority")
    assert.is_true(r:OnCast(2))
    assert.is_false(r:OnCast(99))
  end)
end)

describe("Rotation con otro rango del mismo hechizo", function()
  it("avanza si el lanzado es otro rango", function()
    local names = { [284] = "Golpe heroico", [285] = "Golpe heroico", [72] = "Golpe de escudo" }
    local same = function(a, b) return a == b or names[a] == names[b] end
    local r = Rotation.new({ 284, 72 }, "sequence", nil, same)
    r:OnCast(285)
    assert.equal(72, r:Current())
  end)
end)
