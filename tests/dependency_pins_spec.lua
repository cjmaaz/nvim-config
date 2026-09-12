describe("reproducible dependency inputs", function()
  it("uses exact Mason startup specifications", function()
    local versions = dofile("lua/config/tool_versions.lua")
    assert.are.same({ "lua-language-server", version = "3.19.1" }, versions.mason_spec("lua-language-server"))
    assert.are.same({ "stylua", version = "v2.5.2" }, versions.mason_spec("stylua"))
    assert.are.same({ "prettierd", version = "0.29.0" }, versions.mason_spec("prettierd"))
  end)

  it("pins Node and Vite scaffold packages exactly", function()
    package.loaded["config.tool_versions"] = dofile("lua/config/tool_versions.lua")
    local generators = dofile("lua/config/project_scaffold.lua")._test.generators
    local by_id = {}
    for _, generator in ipairs(generators) do
      by_id[generator.id] = generator
    end

    local node_steps = by_id["node-ts"].steps({ target = "/tmp/node" })
    assert.is_true(vim.tbl_contains(node_steps[2].args, "--save-exact"))
    assert.is_true(vim.tbl_contains(node_steps[2].args, "typescript@6.0.3"))
    assert.is_true(vim.tbl_contains(node_steps[2].args, "tsx@4.23.13"))
    assert.is_true(vim.tbl_contains(node_steps[2].args, "@types/node@24.13.3"))

    local vite_steps = by_id["vite-ts"].steps({
      name = "demo",
      parent = "/tmp",
      target = "/tmp/demo",
    })
    assert.is_true(vim.tbl_contains(vite_steps[1].args, "vite@9.2.0"))
    assert.is_true(vim.tbl_contains(vite_steps[2].args, "--save-exact"))
    assert.is_true(vim.tbl_contains(vite_steps[2].args, "typescript@6.0.3"))
    assert.is_true(vim.tbl_contains(vite_steps[2].args, "vite@8.2.2"))
  end)
end)
