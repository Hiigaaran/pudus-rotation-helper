local Import = loadfile("Core/Import.lua")("PudusRotationHelper", {})

describe("Import", function()
  local known = { ["Revancha"] = 6572 }
  local resolve = function(name) return known[name] end

  it("lee nombre, clase, modo y pasos", function()
    local r = Import.Parse([[
# Protección básica
clase: Guerrero
modo: prioridad

1. Embate con escudo (23922)
2. Revancha
- 7386
]], resolve)
    assert.equal("Protección básica", r.name)
    assert.equal("WARRIOR", r.class)
    assert.equal("priority", r.mode)
    assert.same({ 23922, 6572, 7386 }, r.steps)
    assert.same({}, r.errors)
  end)

  it("acepta clases en inglés y modo por defecto secuencia", function()
    local r = Import.Parse("class: Druid\n* 5176", resolve)
    assert.equal("DRUID", r.class)
    assert.equal("sequence", r.mode)
  end)

  it("informa de líneas que no reconoce", function()
    local r = Import.Parse("1. Hechizo inventado\n2. 100", resolve)
    assert.same({ 100 }, r.steps)
    assert.equal(1, #r.errors)
  end)

  it("exporta en el mismo formato que importa", function()
    local md = Import.Export({ name = "P", class = "WARRIOR", mode = "sequence", steps = { 23922, 6572 } },
      function(id) return id == 6572 and "Revancha" or nil end)
    local r = Import.Parse(md, resolve)
    assert.same({ 23922, 6572 }, r.steps)
    assert.equal("WARRIOR", r.class)
  end)
end)
