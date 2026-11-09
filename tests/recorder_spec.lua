local Recorder = loadfile("Core/Recorder.lua")("PudusRotationHelper", {})

describe("Recorder", function()
  it("guarda los hechizos en el orden pulsado", function()
    local r = Recorder.new()
    r:Add(10, 1); r:Add(20, 2); r:Add(10, 3)
    assert.same({ 10, 20, 10 }, r:Steps())
  end)

  it("cuenta una sola vez los eventos de un mismo intento", function()
    local r = Recorder.new()
    r:Add(10, 1.0, "guid-a") -- enviado
    r:Add(10, 1.5, "guid-a") -- completado
    assert.same({ 10 }, r:Steps())
  end)

  it("agrupa repeticiones muy seguidas sin castGUID", function()
    local r = Recorder.new()
    r:Add(10, 1.0); r:Add(10, 1.2)
    r:Add(10, 2.0)
    assert.same({ 10, 10 }, r:Steps())
  end)

  it("ignora el ataque automático y permite deshacer", function()
    local r = Recorder.new()
    r:Add(6603, 1); r:Add(10, 2); r:Add(20, 3)
    r:Undo()
    assert.same({ 10 }, r:Steps())
  end)
end)
