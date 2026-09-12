local nodes = require("config.salesforce.org_browser.nodes")

describe("Salesforce Org Browser nodes", function()
  local context = { root = "/tmp/project", org = "unit-org" }

  it("sorts types and builds folder/component branches", function()
    local slices = {
      ApexClass = {
        kind = "components",
        fetched_at = os.time(),
        stale = false,
        items = {
          { fullName = "Zulu", manageableState = "unmanaged" },
          { fullName = "Alpha", manageableState = "unmanaged" },
        },
      },
      Report = {
        kind = "folders",
        fetched_at = os.time(),
        stale = false,
        items = { { fullName = "Public" } },
      },
      ["Report\0Public"] = {
        kind = "components",
        fetched_at = os.time(),
        stale = false,
        items = { { fullName = "Public/Pipeline", manageableState = "unmanaged" } },
      },
    }
    local tree = nodes.build({
      context = context,
      descriptors = {
        { xmlName = "Report", inFolder = true },
        { xmlName = "ApexClass", inFolder = false },
      },
      stale = false,
    }, function(reference)
      return slices[table.concat({ reference.type, reference.folder or "" }, "\0")] or slices[reference.type]
    end, function()
      return false
    end)

    assert.are.equal("unit-org", tree[1].name)
    assert.are.equal("ApexClass", tree[1].children[1].name)
    assert.are.equal("Alpha", tree[1].children[1].children[1].name)
    assert.are.equal("Report", tree[1].children[2].name)
    assert.are.equal("Public", tree[1].children[2].children[1].name)
    assert.are.equal("Pipeline", tree[1].children[2].children[1].children[1].name)

    local function assert_search_paths(items)
      for _, node in ipairs(items or {}) do
        assert.are.equal("string", type(node.extra.search_path))
        assert_search_paths(node.children)
      end
    end
    assert_search_paths(tree)
  end)

  it("uses context-safe IDs and marks protected metadata read-only", function()
    local id = nodes._test.stable_id(context, "component", "ApexClass", "Example")
    local other = nodes._test.stable_id({ root = context.root, org = "other" }, "component", "ApexClass", "Example")
    assert.are_not.equal(id, other)
    assert.is_false(nodes._test.retrievable({ manageableState = "installed" }))
    assert.is_true(nodes._test.retrievable({ manageableState = "installedEditable" }))
  end)

  it("uses text before slash for categories and text after slash for components", function()
    assert.are.same({ raw = "Apex", category = "Apex" }, nodes.parse_filter(" Apex "))
    assert.are.same(
      { raw = "ApexClass/Account", category = "ApexClass", inner = "Account" },
      nodes.parse_filter("ApexClass/Account")
    )

    local slices = {
      ApexClass = {
        kind = "components",
        fetched_at = os.time(),
        stale = false,
        items = {
          { fullName = "AccountService" },
          { fullName = "FlowNamedClass" },
        },
      },
      Flow = {
        kind = "components",
        fetched_at = os.time(),
        stale = false,
        items = { { fullName = "AccountFlow" } },
      },
    }
    local catalog = {
      context = context,
      descriptors = {
        { xmlName = "ApexClass", inFolder = false },
        { xmlName = "Flow", inFolder = false },
      },
      stale = false,
    }

    local category_tree = nodes.build(catalog, function(reference)
      return slices[reference.type]
    end, function()
      return false
    end, nodes.parse_filter("Flow"))
    assert.are.equal(1, #category_tree[1].children)
    assert.are.equal("Flow", category_tree[1].children[1].name)

    local component_tree, expanded = nodes.build(catalog, function(reference)
      return slices[reference.type]
    end, function()
      return false
    end, nodes.parse_filter("ApexClass/Account"))
    assert.are.equal(1, #component_tree[1].children)
    assert.are.equal("ApexClass", component_tree[1].children[1].name)
    assert.are.equal("AccountService", component_tree[1].children[1].children[1].name)
    assert.are.equal(1, #expanded)
    assert.are.equal(component_tree[1].children[1].id, expanded[1])
  end)
end)

describe("Salesforce Org Browser metadata service", function()
  local root
  local captured
  local responses
  local pending
  local pendings
  local util
  local metadata

  local function arg_after(args, flag)
    for index, value in ipairs(args) do
      if value == flag then
        return args[index + 1]
      end
    end
  end

  before_each(function()
    root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    vim.fn.writefile({ '{"sourceApiVersion":"65.0"}' }, vim.fs.joinpath(root, "sfdx-project.json"))
    captured = {}
    responses = {}
    pending = nil
    pendings = {}
    util = {
      target_org = "unit-org",
      get_sf_root = function()
        return root
      end,
      get_plugin_folder_path = function()
        return vim.fs.joinpath(root, "sf_cache")
      end,
    }

    package.loaded["sf.util"] = util
    package.loaded["config.salesforce.process"] = {
      run_sf_json = function(args, opts, callback)
        captured[#captured + 1] = { args = vim.deepcopy(args), opts = vim.deepcopy(opts) }
        local response = table.remove(responses, 1) or {}
        if response.defer then
          pending = function()
            callback(response.err, response.result, { code = response.err and 1 or 0 })
          end
          pendings[#pendings + 1] = pending
        else
          callback(response.err, response.result, { code = response.err and 1 or 0 })
        end
        return { kill = function() end }
      end,
      run_in_term = function() end,
      cancel_background = function()
        return 0
      end,
      shell_join = function(args)
        return table.concat(args, " ")
      end,
    }
    package.loaded["config.salesforce.metadata"] = nil
    metadata = require("config.salesforce.metadata")
    vim.g.sf = { types_to_retrieve = {} }
    vim.b.sf_project_root = nil
  end)

  after_each(function()
    package.loaded["config.salesforce.metadata"] = nil
    package.loaded["config.salesforce.process"] = nil
    package.loaded["sf.util"] = nil
    vim.g.sf = nil
    vim.b.sf_project_root = nil
    vim.fn.delete(root, "rf")
  end)

  it("keeps the captured project root while the Org Browser buffer is focused", function()
    util.get_sf_root = function()
      error("remote tree buffer has no filesystem path")
    end
    vim.b.sf_project_root = root
    local catalog = metadata.load_browser_catalog()
    assert.are.equal(vim.fs.normalize(root), catalog.context.root)
  end)

  it("caches a catalog and non-folder branch without a full scan", function()
    responses[#responses + 1] = {
      result = {
        metadataObjects = {
          { xmlName = "ApexClass", directoryName = "classes", suffix = "cls", inFolder = false },
        },
      },
    }
    local catalog_ok
    metadata.refresh_browser_catalog(function(ok)
      catalog_ok = ok
    end)
    assert.is_true(catalog_ok)
    assert.are.equal("metadata-types", captured[1].args[4])
    assert.are.equal(1, #metadata.load_browser_catalog().descriptors)

    responses[#responses + 1] = {
      result = {
        { type = "ApexClass", fullName = "AccountService", manageableState = "unmanaged" },
      },
    }
    local branch
    metadata.refresh_browser_children({ type = "ApexClass" }, function(ok, slice)
      assert.is_true(ok)
      branch = slice
    end)
    assert.are.equal("ApexClass", arg_after(captured[2].args, "--metadata-type"))
    assert.are.equal("AccountService", branch.items[1].fullName)
    assert.is_false(metadata.load_browser_children({ type = "ApexClass" }).stale)
  end)

  it("keeps folder listings and folder components in separate slices", function()
    responses[#responses + 1] = {
      result = {
        metadataObjects = {
          { xmlName = "Report", directoryName = "reports", suffix = "report", inFolder = true },
        },
      },
    }
    metadata.refresh_browser_catalog(function() end)

    responses[#responses + 1] = {
      result = { { type = "ReportFolder", fullName = "Public" } },
    }
    metadata.refresh_browser_children({ type = "Report" }, function(ok)
      assert.is_true(ok)
    end)
    assert.are.equal("ReportFolder", arg_after(captured[2].args, "--metadata-type"))

    responses[#responses + 1] = {
      result = { { type = "Report", fullName = "Public/Pipeline" } },
    }
    metadata.refresh_browser_children({ type = "Report", folder = "Public" }, function(ok)
      assert.is_true(ok)
    end)
    assert.are.equal("Report", arg_after(captured[3].args, "--metadata-type"))
    assert.are.equal("Public", arg_after(captured[3].args, "--folder"))
    assert.are.equal("folders", metadata.load_browser_children({ type = "Report" }).kind)
    assert.are.equal(
      "Public/Pipeline",
      metadata.load_browser_children({ type = "Report", folder = "Public" }).items[1].fullName
    )
  end)

  it("collects every folder before whole-type retrieval", function()
    responses[#responses + 1] = {
      result = {
        metadataObjects = {
          { xmlName = "Report", directoryName = "reports", suffix = "report", inFolder = true },
        },
      },
    }
    metadata.refresh_browser_catalog(function() end)
    responses[#responses + 1] = {
      result = {
        { type = "ReportFolder", fullName = "Public" },
        { type = "ReportFolder", fullName = "Sales" },
      },
    }
    responses[#responses + 1] = {
      result = { { type = "Report", fullName = "Public/Pipeline" } },
    }
    responses[#responses + 1] = {
      result = { { type = "Report", fullName = "Sales/Forecast" } },
    }

    local collected
    metadata.refresh_browser_type_members("Report", function(ok, members)
      assert.is_true(ok)
      collected = members
    end)
    assert.are.equal(2, #collected)
    assert.are.equal("Public", arg_after(captured[3].args, "--folder"))
    assert.are.equal("Sales", arg_after(captured[4].args, "--folder"))
  end)

  it("suppresses a catalog response from a previous target org", function()
    responses[#responses + 1] = {
      defer = true,
      result = { metadataObjects = { { xmlName = "ApexClass" } } },
    }
    local callback_ok
    metadata.refresh_browser_catalog(function(ok)
      callback_ok = ok
    end)
    util.target_org = "other-org"
    pending()
    assert.is_false(callback_ok)
    util.target_org = "unit-org"
    assert.are.equal(0, #metadata.load_browser_catalog().descriptors)
  end)

  it("applies only the latest overlapping target-org selection", function()
    responses[#responses + 1] = { defer = true, result = {} }
    responses[#responses + 1] = { defer = true, result = {} }
    local selected = {}
    metadata._test.set_org({ value = "first-org" }, false, function(choice)
      selected[#selected + 1] = choice.value
    end)
    metadata._test.set_org({ value = "latest-org" }, false, function(choice)
      selected[#selected + 1] = choice.value
    end)

    assert.are.equal(1, #captured)
    pendings[1]()
    assert.are.equal(2, #captured)
    assert.are.equal("unit-org", util.target_org)
    pendings[2]()
    assert.are.same({ "latest-org" }, selected)
    assert.are.equal("latest-org", util.target_org)
  end)

  it("preserves the previous good branch when a refresh fails", function()
    responses[#responses + 1] = {
      result = {
        metadataObjects = { { xmlName = "ApexClass", inFolder = false } },
      },
    }
    metadata.refresh_browser_catalog(function() end)
    responses[#responses + 1] = {
      result = { { type = "ApexClass", fullName = "StableClass" } },
    }
    metadata.refresh_browser_children({ type = "ApexClass" }, function() end)

    responses[#responses + 1] = { err = "network unavailable" }
    local preserved
    metadata.refresh_browser_children({ type = "ApexClass" }, function(ok, slice)
      assert.is_false(ok)
      preserved = slice
    end)
    assert.are.equal("StableClass", preserved.items[1].fullName)
    assert.are.equal("network unavailable", preserved.error)
  end)

  it("coalesces duplicate requests for the same branch", function()
    responses[#responses + 1] = {
      result = {
        metadataObjects = { { xmlName = "ApexClass", inFolder = false } },
      },
    }
    metadata.refresh_browser_catalog(function() end)
    responses[#responses + 1] = {
      defer = true,
      result = { { type = "ApexClass", fullName = "OnlyOnce" } },
    }
    local callbacks = 0
    metadata.refresh_browser_children({ type = "ApexClass" }, function(ok)
      assert.is_true(ok)
      callbacks = callbacks + 1
    end)
    metadata.refresh_browser_children({ type = "ApexClass" }, function(ok)
      assert.is_true(ok)
      callbacks = callbacks + 1
    end)
    assert.are.equal(2, #captured)
    pending()
    assert.are.equal(2, callbacks)
  end)

  it("resolves a pending branch once when cancellation invalidates it", function()
    responses[#responses + 1] = {
      result = {
        metadataObjects = { { xmlName = "ApexClass", inFolder = false } },
      },
    }
    metadata.refresh_browser_catalog(function() end)
    responses[#responses + 1] = {
      defer = true,
      result = { { type = "ApexClass", fullName = "TooLate" } },
    }
    local callbacks = 0
    local last_ok
    metadata.refresh_browser_children({ type = "ApexClass" }, function(ok)
      callbacks = callbacks + 1
      last_ok = ok
    end)
    metadata.cancel_background()
    assert.are.equal(1, callbacks)
    assert.is_false(last_ok)
    pending()
    assert.are.equal(1, callbacks)
  end)

  it("builds structured retrieve argv and returns absolute file paths", function()
    responses[#responses + 1] = {
      result = {
        files = {
          { filePath = "force-app/main/default/classes/Example.cls", state = "Created" },
          { filePath = "force-app/main/default/classes/Example.cls-meta.xml", state = "Created" },
        },
      },
    }
    local payload
    metadata.retrieve_browser({
      { type = "ApexClass", fullName = "Example" },
    }, {}, function(ok, value)
      assert.is_true(ok)
      payload = value
    end)

    assert.are.equal("unit-org", arg_after(captured[1].args, "--target-org"))
    assert.is_not_nil(arg_after(captured[1].args, "--manifest"))
    assert.is_false(vim.tbl_contains(captured[1].args, "--ignore-conflicts"))
    assert.are.equal(vim.fs.joinpath(root, "force-app/main/default/classes/Example.cls"), payload.files[1])

    responses[#responses + 1] = { result = { files = {} } }
    metadata.retrieve_browser({
      { type = "ApexClass", fullName = "Example" },
    }, { ignore_conflicts = true }, function(ok)
      assert.is_true(ok)
    end)
    assert.is_true(vim.tbl_contains(captured[2].args, "--ignore-conflicts"))
    assert.is_true(metadata.is_conflict_error("Local changes conflict with the org"))
  end)

  it("uses the configured five-minute freshness boundary", function()
    assert.is_false(metadata._test.is_stale(os.time()))
    assert.is_true(metadata._test.is_stale(os.time() - 301))
  end)
end)

describe("Salesforce Org Browser source contract", function()
  it("registers the selected sidebar actions", function()
    local source = require("config.salesforce.org_browser")
    local mappings = source.default_config.window.mappings
    assert.are.equal("open", mappings["<cr>"])
    assert.are.equal("refresh", mappings.R)
    assert.are.equal("retrieve_type", mappings.A)
    assert.are.equal("batch_picker", mappings.P)
  end)

  it("prefers source files over companion metadata files", function()
    local commands = require("config.salesforce.org_browser.commands")
    assert.are.equal(
      "/tmp/Example.cls",
      commands._test.preferred_file({ "/tmp/Example.cls-meta.xml", "/tmp/Example.cls" })
    )
    assert.is_truthy(
      commands._test
        .retrieve_summary({ org = "unit-org" }, { { type = "ApexClass", fullName = "Example" } })
        :find("Existing local source can be overwritten", 1, true)
    )
    assert.is_truthy(commands._test
      .retrieve_summary({ org = "unit-org" }, {
        { type = "ApexClass", fullName = "One" },
        { type = "ApexClass", fullName = "Two" },
      }, "ApexClass")
      :find("all 2 ApexClass components", 1, true))
  end)

  it("does not ask Neo-tree to close above a collapsed org root", function()
    local commands = require("config.salesforce.org_browser.commands")
    local root = {
      extra = { kind = "org" },
      is_expanded = function()
        return false
      end,
    }
    local state = {
      tree = {
        get_node = function()
          return root
        end,
      },
    }
    assert.has_no.errors(function()
      commands.close_node(state)
    end)
  end)

  it("runs callbacks inside the source buffer's captured project context", function()
    local source = require("config.salesforce.org_browser")
    local source_buf = vim.api.nvim_create_buf(false, true)
    local other_buf = vim.api.nvim_create_buf(false, true)
    vim.b[source_buf].sf_project_root = "/captured/project"
    vim.api.nvim_set_current_buf(other_buf)
    local root = source.with_context({
      bufnr = source_buf,
      sf_org_project_root = "/captured/project",
    }, function()
      return vim.b.sf_project_root
    end)
    assert.are.equal("/captured/project", root)
    vim.api.nvim_buf_delete(source_buf, { force = true })
    vim.api.nvim_buf_delete(other_buf, { force = true })
  end)
end)
