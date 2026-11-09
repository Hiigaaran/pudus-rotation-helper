local Editor = loadfile("Core/EditorModel.lua")("PudusRotationHelper", {})

describe("Editor", function()
  it("empieza en Habilidades si la rotación está vacía", function()
    local e = Editor.new({}, { 10, 20 })
    assert.equal("palette", e.column)
  end)

  it("agrega después del paso seleccionado y avanza el cursor", function()
    local e = Editor.new({}, { 10, 20, 30 })
    e:Accept()             -- 10
    e:Move(1); e:Accept()  -- 20
    e:Move(1); e:Accept()  -- 30
    assert.same({ 10, 20, 30 }, e.steps)
    e:Switch(-1); e:Move(-1); e:Move(-1) -- cursor en el paso 1
    e:Switch(1); e:Accept()              -- agrega 30 detrás del paso 1
    assert.same({ 10, 30, 20, 30 }, e.steps)
    assert.equal(2, e.cursor.rotation)
  end)

  it("quita el paso seleccionado y deshace", function()
    local e = Editor.new({ 1, 2, 3 }, {})
    e:Move(-1)             -- del 3 al 2
    e:Remove()
    assert.same({ 1, 3 }, e.steps)
    assert.equal(2, e.cursor.rotation)
    e:Undo()
    assert.same({ 1, 2, 3 }, e.steps)
  end)

  it("reordena tomando y soltando con A", function()
    local e = Editor.new({ 1, 2, 3 }, {})
    e:Move(1)              -- el cursor empieza en el último; da la vuelta al 1
    e:Accept()             -- toma el 1
    e:Move(1); e:Move(1)   -- lo baja dos posiciones
    e:Accept()             -- lo suelta
    assert.same({ 2, 3, 1 }, e.steps)
    assert.is_nil(e.grabbed)
  end)

  it("no cambia de columna con un paso tomado", function()
    local e = Editor.new({ 1, 2 }, { 9 })
    e:Accept()
    assert.is_string(e:Switch(1))
    assert.equal("rotation", e.column)
  end)

  it("X en la columna de habilidades no quita nada", function()
    local e = Editor.new({ 1 }, { 9 })
    e:Switch(1)
    assert.is_nil(e:Remove())
    assert.same({ 1 }, e.steps)
  end)
end)
