package.loaded["config.project_context"] = dofile("lua/config/project_context.lua")
package.loaded["config.project_runner"] = dofile("lua/config/project_runner.lua")
package.loaded["config.local_actions"] = dofile("lua/config/local_actions.lua")
package.loaded["config.local_actions.project"] = dofile("lua/config/local_actions/project.lua")
package.loaded["config.local_actions.salesforce"] = dofile("lua/config/local_actions/salesforce.lua")
package.loaded["config.local_actions.soql"] = dofile("lua/config/local_actions/soql.lua")

local local_actions = package.loaded["config.local_actions"]
local runner = package.loaded["config.project_runner"]

local created_buffers = {}
local created_roots = {}

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines or { "" }, path)
end

local function project(files)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  created_roots[#created_roots + 1] = root
  for path, lines in pairs(files) do
    if lines == "directory" then
      vim.fn.mkdir(vim.fs.joinpath(root, path), "p")
    else
      write(vim.fs.joinpath(root, path), lines)
    end
  end
  return root
end

local function buffer(path, filetype)
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)
  vim.bo[bufnr].filetype = filetype or ""
  created_buffers[#created_buffers + 1] = bufnr
  return bufnr
end

local function mapping(bufnr, lhs)
  for _, item in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
    if item.lhs == lhs then
      return item
    end
  end
end

local function clear_providers()
  for id in pairs(local_actions._test.providers) do
    local_actions._test.providers[id] = nil
  end
end

describe("context-aware localleader", function()
  before_each(function()
    vim.g.maplocalleader = "\\"
    clear_providers()
  end)

  after_each(function()
    for _, bufnr in ipairs(created_buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        local_actions._test.clear_owned(bufnr)
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
      end
    end
    for _, root in ipairs(created_roots) do
      vim.fn.delete(root, "rf")
    end
    created_buffers = {}
    created_roots = {}
    clear_providers()
  end)

  describe("project runner capabilities", function()
    it("provides run, build, and test for every supported ecosystem", function()
      local cases = {
        {
          name = "rust",
          file = "src/main.rs",
          files = {
            ["Cargo.toml"] = { "[package]", 'name = "demo"' },
            ["src/main.rs"] = { "fn main() {}" },
          },
        },
        {
          name = "node",
          file = "src/index.ts",
          files = {
            ["package.json"] = { '{"scripts":{"dev":"tsx src/index.ts","build":"tsc","test":"vitest"}}' },
            ["src/index.ts"] = { "console.log('ok')" },
          },
        },
        {
          name = "python",
          file = "src/demo.py",
          files = {
            ["pyproject.toml"] = {
              "[project.scripts]",
              'demo = "demo:main"',
              "[build-system]",
              'requires = ["hatchling"]',
            },
            ["src/demo.py"] = { "print('ok')" },
            ["tests"] = "directory",
          },
        },
        {
          name = "go",
          file = "main.go",
          files = {
            ["go.mod"] = { "module example.test/demo" },
            ["main.go"] = { "package main", "func main() {}" },
          },
        },
        {
          name = "maven",
          file = "src/main/java/App.java",
          files = {
            ["pom.xml"] = { "<project></project>" },
            ["src/main/java/App.java"] = { "class App {}" },
          },
        },
        {
          name = "flutter",
          file = "lib/main.dart",
          files = {
            ["pubspec.yaml"] = { "name: demo" },
            ["lib/main.dart"] = { "void main() {}" },
            ["android"] = "directory",
          },
        },
        {
          name = "cmake",
          file = "src/main.cpp",
          files = {
            ["CMakeLists.txt"] = { "add_custom_target(run_exe)" },
            ["src/main.cpp"] = { "int main() {}" },
          },
        },
      }

      for _, case in ipairs(cases) do
        local root = project(case.files)
        local actions = runner.get_actions(buffer(vim.fs.joinpath(root, case.file)))
        local kinds = {}
        for _, action in ipairs(actions) do
          kinds[action.kind] = true
        end
        assert.is_true(kinds.run, case.name .. " run")
        assert.is_true(kinds.build, case.name .. " build")
        assert.is_true(kinds.test, case.name .. " test")
      end
    end)

    it("uses nearest roots and retains same-root ecosystems", function()
      local outer = project({
        ["package.json"] = { '{"scripts":{"build":"tsc"}}' },
        ["nested/Cargo.toml"] = { "[package]", 'name = "nested"' },
        ["nested/src/main.rs"] = { "fn main() {}" },
      })
      local nested = buffer(vim.fs.joinpath(outer, "nested/src/main.rs"))
      local detected = runner.detect(nested)
      assert.are.equal(1, #detected)
      assert.are.equal("rust", detected[1].id)

      local shared = project({
        ["Cargo.toml"] = { "[package]", 'name = "shared"' },
        ["package.json"] = { '{"scripts":{"build":"tsc"}}' },
        ["src/main.rs"] = { "fn main() {}" },
      })
      local shared_buf = buffer(vim.fs.joinpath(shared, "src/main.rs"))
      local ids = {}
      for _, item in ipairs(runner.detect(shared_buf)) do
        ids[item.id] = true
      end
      assert.is_true(ids.rust)
      assert.is_true(ids.node)
    end)

    it("detects projects for named files before their first write", function()
      local root = project({
        ["Cargo.toml"] = { "[package]", 'name = "new-file"' },
        ["src"] = "directory",
      })
      local bufnr = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(bufnr, vim.fs.joinpath(root, "src/new.rs"))
      vim.bo[bufnr].filetype = "rust"
      created_buffers[#created_buffers + 1] = bufnr
      local detected = runner.detect(bufnr)
      assert.are.equal(1, #detected)
      assert.are.equal("rust", detected[1].id)
    end)
  end)

  describe("local action reconciliation", function()
    it("merges menus while higher-priority providers own direct slots", function()
      local root = project({
        ["sfdx-project.json"] = { '{"packageDirectories":[{"path":"force-app","default":true}]}' },
        ["package.json"] = { '{"scripts":{"dev":"vite","build":"vite build","test":"vitest"}}' },
        ["force-app/main/default/lwc/demo/demo.ts"] = { "export {}" },
        ["scripts/setup.ts"] = { "export {}" },
        ["scripts/lwc/helper.ts"] = { "export {}" },
        ["scripts/Test.cls"] = { "class Test {}" },
      })
      local bufnr = buffer(vim.fs.joinpath(root, "force-app/main/default/lwc/demo/demo.ts"), "typescript")

      local_actions.register(require("config.local_actions.project"))
      local_actions.register(require("config.local_actions.salesforce").new({
        salesforce_root = function()
          return root
        end,
        guarded_load = function() end,
        sf_action = function()
          return function() end
        end,
        cancel = function() end,
      }))

      local collected = local_actions.collect(bufnr)
      assert.are.equal("Salesforce + Node / TypeScript", collected.context)
      assert.are.equal("salesforce", collected.direct["\\b"][1].provider)
      assert.are.equal("project", collected.direct["\\r"][1].provider)
      assert.are.equal("project", collected.direct["\\t"][1].provider)

      local_actions.reconcile(bufnr)
      assert.is_truthy(mapping(bufnr, "\\p"))
      assert.is_truthy(mapping(bufnr, "\\r"))
      assert.is_truthy(mapping(bufnr, "\\b"))
      assert.is_truthy(mapping(bufnr, "\\t"))

      local script_buf = buffer(vim.fs.joinpath(root, "scripts/setup.ts"), "typescript")
      local script_actions = local_actions.collect(script_buf)
      assert.are.equal("project", script_actions.direct["\\b"][1].provider)
      assert.is_true(require("config.local_actions.salesforce")._test.is_metadata_buffer({
        filetype = "typescript",
        path = vim.fs.joinpath(root, "force-app/main/default/lwc/demo/demo.ts"),
      }, root))
      assert.is_false(require("config.local_actions.salesforce")._test.is_metadata_buffer({
        filetype = "typescript",
        path = vim.fs.joinpath(root, "scripts/setup.ts"),
      }, root))
      assert.is_false(require("config.local_actions.salesforce")._test.is_metadata_buffer({
        filetype = "typescript",
        path = vim.fs.joinpath(root, "scripts/lwc/helper.ts"),
      }, root))
      assert.is_false(require("config.local_actions.salesforce")._test.is_metadata_buffer({
        filetype = "apex",
        path = vim.fs.joinpath(root, "scripts/Test.cls"),
      }, root))
    end)

    it("preserves foreign mappings and removes only owned stale actions", function()
      local root = project({
        ["Cargo.toml"] = { "[package]", 'name = "demo"' },
        ["src/main.rs"] = { "fn main() {}" },
      })
      local plain_root = project({ ["plain.txt"] = { "plain" } })
      local bufnr = buffer(vim.fs.joinpath(root, "src/main.rs"), "rust")
      vim.keymap.set("n", "<localleader>b", "<cmd>echo 'foreign'<cr>", {
        buffer = bufnr,
        desc = "Local: Foreign build",
      })
      local_actions.register(require("config.local_actions.project"))
      local_actions.reconcile(bufnr)
      assert.are.equal("Local: Foreign build", mapping(bufnr, "\\b").desc)
      assert.is_truthy(mapping(bufnr, "\\p"))
      assert.is_truthy(mapping(bufnr, "\\r"))

      vim.api.nvim_buf_set_name(bufnr, vim.fs.joinpath(plain_root, "plain.txt"))
      local_actions.reconcile(bufnr)
      assert.are.equal("Local: Foreign build", mapping(bufnr, "\\b").desc)
      assert.is_nil(mapping(bufnr, "\\p"))
      assert.is_nil(mapping(bufnr, "\\r"))
    end)

    it("omits direct keys for capabilities the project does not provide", function()
      local root = project({
        ["package.json"] = { '{"scripts":{"build":"vite build"}}' },
        ["src/app.ts"] = { "export {}" },
      })
      local bufnr = buffer(vim.fs.joinpath(root, "src/app.ts"), "typescript")
      local_actions.register(require("config.local_actions.project"))
      local_actions.reconcile(bufnr)
      assert.is_truthy(mapping(bufnr, "\\p"))
      assert.is_truthy(mapping(bufnr, "\\b"))
      assert.is_nil(mapping(bufnr, "\\r"))
      assert.is_nil(mapping(bufnr, "\\t"))
    end)

    it("does not install mappings in unnamed or special buffers", function()
      local unnamed = vim.api.nvim_create_buf(true, false)
      created_buffers[#created_buffers + 1] = unnamed
      local_actions.register({
        id = "always",
        priority = 1,
        resolve = function()
          return {
            label = "Always",
            actions = {
              { id = "run", label = "Run", slot = "run", run = function() end },
            },
          }
        end,
      })
      local_actions.reconcile(unnamed)
      assert.is_nil(mapping(unnamed, "\\r"))

      local special = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_name(special, "local-actions://special")
      vim.bo[special].buftype = "nofile"
      created_buffers[#created_buffers + 1] = special
      local_actions.reconcile(special)
      assert.is_nil(mapping(special, "\\r"))
    end)

    it("re-resolves actions before invocation instead of running stale callbacks", function()
      local root = project({ ["file.txt"] = { "text" } })
      local bufnr = buffer(vim.fs.joinpath(root, "file.txt"), "text")
      local active = true
      local runs = 0
      local_actions.register({
        id = "changing",
        priority = 10,
        resolve = function()
          if not active then
            return nil
          end
          return {
            label = "Changing",
            actions = {
              {
                id = "run",
                label = "Run",
                slot = "run",
                run = function()
                  runs = runs + 1
                end,
              },
            },
          }
        end,
      })
      local_actions.reconcile(bufnr)
      local_actions.invoke(bufnr, "<localleader>r")
      assert.are.equal(1, runs)

      active = false
      local_actions.invoke(bufnr, "<localleader>r")
      assert.are.equal(1, runs)
      assert.is_nil(mapping(bufnr, "\\r"))
    end)

    it("rejects a picker selection after its project root changes", function()
      local first_root = project({ ["file.txt"] = { "first" } })
      local second_root = project({ ["file.txt"] = { "second" } })
      local bufnr = buffer(vim.fs.joinpath(first_root, "file.txt"), "text")
      local current_root = first_root
      local runs = 0
      local_actions.register({
        id = "moving",
        priority = 10,
        resolve = function()
          return {
            label = "Moving",
            root = current_root,
            actions = {
              {
                id = "one",
                label = "Run one",
                slot = "run",
                run = function()
                  runs = runs + 1
                end,
              },
              {
                id = "two",
                label = "Run two",
                slot = "run",
                run = function()
                  runs = runs + 1
                end,
              },
            },
          }
        end,
      })

      local original_select = vim.ui.select
      local selected_items
      local selected_callback
      vim.ui.select = function(items, _, callback)
        selected_items = items
        selected_callback = callback
      end
      local_actions.invoke(bufnr, "<localleader>r")
      current_root = second_root
      selected_callback(selected_items[1])
      vim.ui.select = original_select
      assert.are.equal(0, runs)
    end)
  end)

  describe("domain providers", function()
    it("recognizes metadata below a symlinked package directory", function()
      local root = project({
        ["sfdx-project.json"] = { '{"packageDirectories":[{"path":"force-app","default":true}]}' },
        ["actual/main/default/lwc/demo/demo.ts"] = { "export {}" },
      })
      assert(vim.uv.fs_symlink(vim.fs.joinpath(root, "actual"), vim.fs.joinpath(root, "force-app")))
      assert.is_true(require("config.local_actions.salesforce")._test.is_metadata_buffer({
        filetype = "typescript",
        path = vim.fs.joinpath(root, "force-app/main/default/lwc/demo/demo.ts"),
      }, root))
    end)

    it("maps a standalone SOQL buffer before sf.nvim has loaded", function()
      local root = project({ ["query.soql"] = { "SELECT Id FROM Account" } })
      local bufnr = buffer(vim.fs.joinpath(root, "query.soql"), "soql")
      local_actions.register(require("config.local_actions.soql"))
      local_actions.reconcile(bufnr)
      assert.are.equal("SOQL", vim.b[bufnr].local_actions_context)
      for _, lhs in ipairs({ "\\p", "\\f", "\\o", "\\r", "\\t" }) do
        assert.is_truthy(mapping(bufnr, lhs), lhs)
      end
    end)

    it("gives SOQL explicit mappings priority over project test slots", function()
      local root = project({
        ["package.json"] = { '{"scripts":{"test":"vitest"}}' },
        ["query/demo.soql"] = { "SELECT Id FROM Account" },
      })
      local bufnr = buffer(vim.fs.joinpath(root, "query/demo.soql"), "soql")
      vim.b[bufnr].soql_root = root
      vim.b[bufnr].soql_org = "unit-org"
      vim.b[bufnr].soql_cache_browser = vim.fs.joinpath(root, "sf_cache")

      local context_calls = 0
      package.loaded["config.salesforce.metadata"] = {
        get_context = function()
          context_calls = context_calls + 1
          return { root = root, org = "unit-org", paths = { browser = vim.fs.joinpath(root, "sf_cache") } }
        end,
      }
      package.loaded["config.salesforce.process"] = { run_in_term = function() end }
      package.loaded["config.salesforce.schema"] = {}
      package.loaded["config.salesforce.query"] = dofile("lua/config/salesforce/query.lua")

      local_actions.register(require("config.local_actions.project"))
      local query = package.loaded["config.salesforce.query"]
      query.setup()
      local collected = local_actions.collect(bufnr)
      assert.are.equal("soql", collected.direct["\\t"][1].provider)
      assert.are.equal("soql", collected.direct["\\r"][1].provider)
      local_actions.reconcile(bufnr)
      assert.is_truthy(mapping(bufnr, "\\f"))
      assert.is_truthy(mapping(bufnr, "\\o"))
      assert.is_truthy(mapping(bufnr, "\\r"))
      assert.is_truthy(mapping(bufnr, "\\t"))

      local loose = project({ ["loose.soql"] = { "SELECT Id FROM Contact" } })
      local loose_buf = buffer(vim.fs.joinpath(loose, "loose.soql"), "soql")
      assert.is_truthy(local_actions.collect(loose_buf).direct["\\r"])
      assert.are.equal(0, context_calls)

      query._test.open_draft({
        root = root,
        org = "unit-org",
        paths = { browser = vim.fs.joinpath(root, "sf_cache") },
      }, "Contact", { "Id" }, true)
      local draft_buf = vim.api.nvim_get_current_buf()
      created_buffers[#created_buffers + 1] = draft_buf
      assert.are.equal("soql", vim.bo[draft_buf].filetype)
      assert.is_truthy(mapping(draft_buf, "\\f"))
      assert.is_truthy(mapping(draft_buf, "\\r"))
      assert.is_nil(local_actions._test.owned[0])
      assert.is_not_nil(local_actions._test.owned[draft_buf])

      vim.bo[draft_buf].filetype = "text"
      local_actions.reconcile(draft_buf)
      assert.is_nil(mapping(draft_buf, "\\f"))
      assert.is_nil(mapping(draft_buf, "\\o"))
      assert.is_nil(mapping(draft_buf, "\\r"))

      package.loaded["config.salesforce.query"] = nil
      package.loaded["config.salesforce.metadata"] = nil
      package.loaded["config.salesforce.process"] = nil
      package.loaded["config.salesforce.schema"] = nil
    end)

    it("keeps a dynamically labelled which-key group registered", function()
      local spec = dofile("lua/plugins/which-key.lua")[1]
      local local_group
      for _, entry in ipairs(spec.opts.spec) do
        if entry[1] == "<localleader>" then
          local_group = entry
          break
        end
      end
      assert.is_not_nil(local_group)
      assert.is_nil(local_group.cond)
      vim.b.local_actions_context = "Java — Maven"
      assert.are.equal("Local · Java — Maven", local_group.group())
      vim.b.local_actions_context = nil
      assert.are.equal("Local", local_group.group())
    end)
  end)
end)
