local uv = vim.uv or vim.loop

describe("Salesforce argv execution", function()
  it("keeps shell metacharacters as literal argv values", function()
    local validate = require("config.salesforce.terminal")._test.validate_argv
    local args = {
      "sf",
      "data",
      "query",
      "--query",
      "SELECT Id FROM Account WHERE Name = '$(touch nope); `id`; \"quoted\"'",
      "--target-org",
      "org;still-one-value",
    }
    local normalized = assert(validate(args))
    assert.are.same(args, normalized)
  end)

  it("passes a list directly to the Salesforce terminal", function()
    local captured
    package.loaded["config.salesforce.terminal"] = {
      run = function(args, opts, callback)
        captured = { args = args, opts = opts, callback = callback }
        return 42
      end,
    }
    package.loaded["config.salesforce.process"] = nil
    local process = dofile("lua/config/salesforce/process.lua")
    local args = { "sf", "project", "retrieve", "start", "--source-dir", "a;$(id).cls" }
    assert.are.equal(42, process.run_in_term(args, { cwd = "/tmp/project" }))
    assert.are.same(args, captured.args)
    assert.are.equal("/tmp/project", captured.opts.cwd)
    package.loaded["config.salesforce.process"] = nil
    package.loaded["config.salesforce.terminal"] = nil
  end)

  it("delivers cancellation to async cleanup callbacks", function()
    local original_system = vim.system
    local on_exit
    local killed = false
    vim.system = function(_, _, callback)
      on_exit = callback
      return {
        kill = function()
          killed = true
        end,
      }
    end
    local process = dofile("lua/config/salesforce/process.lua")
    local completed
    process.run({ "sf", "sobject", "list" }, {}, function(result)
      completed = result
    end)
    assert.are.equal(1, process.cancel_background())
    assert.is_true(killed)
    on_exit({ code = 130, stdout = "", stderr = "" })
    assert(vim.wait(1000, function()
      return completed ~= nil
    end))
    assert.is_true(completed.cancelled)

    local json_error
    process.run_json({ "sf", "config", "get" }, {}, function(err)
      json_error = err
    end)
    assert.are.equal(1, process.cancel_background())
    on_exit({ code = 0, stdout = '{"status":0,"result":[]}', stderr = "" })
    assert(vim.wait(1000, function()
      return json_error ~= nil
    end))
    assert.are.equal("Salesforce operation cancelled.", json_error)
    vim.system = original_system
  end)
end)

describe("Salesforce project storage containment", function()
  local root
  local outside
  local safety

  before_each(function()
    root = vim.fn.tempname()
    outside = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    vim.fn.mkdir(outside, "p")
    vim.fn.writefile({ "{}" }, vim.fs.joinpath(root, "sfdx-project.json"))
    vim.fn.writefile({ "keep" }, vim.fs.joinpath(outside, "sentinel"))
    package.loaded["config.salesforce.safety"] = nil
    safety = require("config.salesforce.safety")
  end)

  after_each(function()
    for _, path in ipairs({
      vim.fs.joinpath(root, "sf_cache"),
      vim.fs.joinpath(root, ".sfdx"),
      vim.fs.joinpath(root, "source-link"),
    }) do
      if uv.fs_lstat(path) and uv.fs_lstat(path).type == "link" then
        uv.fs_unlink(path)
      end
    end
    vim.fn.delete(root, "rf")
    vim.fn.delete(outside, "rf")
    package.loaded["config.salesforce.safety"] = nil
  end)

  it("blocks sf_cache symlinks without touching their target", function()
    assert(uv.fs_symlink(outside, vim.fs.joinpath(root, "sf_cache")))
    local cap, err = safety.preflight(root)
    assert.is_nil(cap)
    assert.matches("symlink", err)
    local ok = safety.atomic_write(root, vim.fs.joinpath(root, "sf_cache", "owned"), "bad")
    assert.is_false(ok)
    assert.are.equal("keep", vim.fn.readfile(vim.fs.joinpath(outside, "sentinel"))[1])
    assert.is_nil(uv.fs_stat(vim.fs.joinpath(outside, "owned")))
  end)

  it("blocks .sfdx symlinks before recursive refresh cleanup", function()
    assert(uv.fs_symlink(outside, vim.fs.joinpath(root, ".sfdx")))
    local cap, err = safety.preflight(root)
    assert.is_nil(cap)
    assert.matches("symlink", err)
    assert.are.equal("keep", vim.fn.readfile(vim.fs.joinpath(outside, "sentinel"))[1])
  end)

  it("resolves a missing source file through its deepest existing parent", function()
    assert(uv.fs_symlink(outside, vim.fs.joinpath(root, "source-link")))
    local actions = dofile("lua/config/salesforce/actions.lua")
    assert.is_false(actions._test.path_within(root, vim.fs.joinpath(root, "source-link", "new.cls")))
  end)

  it("writes atomically and removes only approved contained trees", function()
    local path = vim.fs.joinpath(root, "sf_cache", "diffs", "result.txt")
    assert.is_true(safety.atomic_write(root, path, "safe"))
    assert.are.equal("safe", table.concat(vim.fn.readfile(path, "b"), "\n"))
    local project = assert(safety.preflight(root))
    local diffs = assert(safety.path(project, "sf_cache/diffs"))
    assert.is_true(safety.remove_tree(diffs))
    assert.is_nil(uv.fs_stat(path))
    local arbitrary = assert(safety.path(project, "sf_cache", { allow_missing = true }))
    local removed, err = safety.remove_tree(arbitrary)
    assert.is_nil(removed)
    assert.matches("Refusing recursive removal", err)
  end)
end)

describe("Salesforce root-scoped org context", function()
  local roots
  local pending
  local original_process

  before_each(function()
    roots = { vim.fn.tempname(), vim.fn.tempname() }
    for _, root in ipairs(roots) do
      vim.fn.mkdir(root, "p")
      vim.fn.writefile({ "{}" }, vim.fs.joinpath(root, "sfdx-project.json"))
    end
    pending = {}
    original_process = package.loaded["config.salesforce.process"]
    package.loaded["config.salesforce.process"] = {
      run_sf_json = function(_, opts, callback)
        pending[opts.cwd] = callback
        return {}
      end,
    }
    package.loaded["config.salesforce.org_context"] = nil
  end)

  after_each(function()
    for _, root in ipairs(roots) do
      vim.fn.delete(root, "rf")
    end
    package.loaded["config.salesforce.org_context"] = nil
    package.loaded["config.salesforce.process"] = original_process
  end)

  it("cannot apply one project's async target org to another project", function()
    local contexts = require("config.salesforce.org_context")
    local seen = {}
    contexts.resolve(roots[1], function(ctx)
      seen.a = ctx and ctx.org
    end)
    contexts.resolve(roots[2], function(ctx)
      seen.b = ctx and ctx.org
    end)
    pending[vim.fs.normalize(uv.fs_realpath(roots[2]))](
      nil,
      { { success = true, value = "org-b", location = "Local" } }
    )
    pending[vim.fs.normalize(uv.fs_realpath(roots[1]))](
      nil,
      { { success = true, value = "org-a", location = "Local" } }
    )
    assert(vim.wait(1000, function()
      return seen.a and seen.b
    end))
    assert.are.same({ a = "org-a", b = "org-b" }, seen)
    assert.are.equal("org-a", contexts.current(roots[1]).org)
    assert.are.equal("org-b", contexts.current(roots[2]).org)
  end)
end)

describe("Project-local Vlocity trust boundary", function()
  local root
  local outside

  before_each(function()
    root = vim.fn.tempname()
    outside = vim.fn.tempname()
    vim.fn.mkdir(vim.fs.joinpath(root, "node_modules", ".bin"), "p")
    vim.fn.mkdir(outside, "p")
    vim.fn.writefile({ "{}" }, vim.fs.joinpath(root, "sfdx-project.json"))
  end)

  after_each(function()
    local link = vim.fs.joinpath(root, "node_modules", ".bin", "vlocity")
    if uv.fs_lstat(link) and uv.fs_lstat(link).type == "link" then
      uv.fs_unlink(link)
    end
    vim.fn.delete(root, "rf")
    vim.fn.delete(outside, "rf")
  end)

  it("rejects a project binary symlink that escapes node_modules", function()
    local target = vim.fs.joinpath(outside, "vlocity")
    vim.fn.writefile({ "#!/bin/sh", "exit 0" }, target)
    uv.fs_chmod(target, 493)
    assert(uv.fs_symlink(target, vim.fs.joinpath(root, "node_modules", ".bin", "vlocity")))
    local cli, err = dofile("lua/config/salesforce/vlocity.lua")._test.executable(root, false)
    assert.is_nil(cli)
    assert.matches("outside node_modules", err)
  end)

  it("allows an internal project binary only after Neovim trust approval", function()
    local bin_dir = vim.fs.joinpath(root, "node_modules", "vlocity", "bin")
    vim.fn.mkdir(bin_dir, "p")
    local target = vim.fs.joinpath(bin_dir, "vlocity.js")
    vim.fn.writefile({ "#!/usr/bin/env node", "process.exit(0)" }, target)
    uv.fs_chmod(target, 493)
    assert(uv.fs_symlink("../vlocity/bin/vlocity.js", vim.fs.joinpath(root, "node_modules", ".bin", "vlocity")))

    local original_read = vim.secure.read
    local trusted
    vim.secure.read = function(path)
      trusted = path
      return "approved"
    end
    local cli = assert(dofile("lua/config/salesforce/vlocity.lua")._test.executable(root, true))
    vim.secure.read = original_read
    assert.are.equal(vim.fs.normalize(uv.fs_realpath(target)), cli)
    assert.are.equal(cli, trusted)
  end)
end)
