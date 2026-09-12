--------------------------------------------------------------------------------
-- Salesforce Org Browser — external Neo-tree source with lazy org branches.
--------------------------------------------------------------------------------

local M = {
  name = "sf_org",
  display_name = " 󰢎 Org ",
}

local components = require("config.salesforce.org_browser.components")
local nodes = require("config.salesforce.org_browser.nodes")
local renderer = require("neo-tree.ui.renderer")

M.components = components
M.commands = require("config.salesforce.org_browser.commands")

M.default_config = {
  renderers = {
    org = {
      { "indent", with_expanders = true },
      { "icon" },
      { "name" },
      { "status" },
    },
    directory = {
      { "indent", with_expanders = true },
      { "icon" },
      { "name" },
      { "status" },
    },
    file = {
      { "indent" },
      { "icon" },
      { "name" },
      { "status" },
    },
    message = {
      { "indent" },
      { "icon" },
      { "name" },
    },
  },
  window = {
    mappings = {
      ["<space>"] = "none",
      ["<cr>"] = "open",
      ["l"] = "open",
      ["h"] = "close_node",
      ["r"] = "retrieve",
      ["A"] = "retrieve_type",
      ["R"] = "refresh",
      ["K"] = "details",
      ["o"] = "change_org",
      ["P"] = "batch_picker",
      ["/"] = "filter",
      ["?"] = "show_help",
      ["q"] = "close_window",
      -- Filesystem clipboard/create/open commands do not apply to remote nodes.
      ["w"] = "noop",
      ["s"] = "noop",
      ["S"] = "noop",
      ["t"] = "noop",
      ["a"] = "noop",
      ["d"] = "noop",
      ["m"] = "noop",
      ["c"] = "noop",
      ["y"] = "noop",
      ["x"] = "noop",
      ["p"] = "noop",
      ["u"] = "noop",
      ["U"] = "noop",
      ["T"] = "noop",
      ["<Tab>"] = "noop",
      ["<C-s>"] = "noop",
      ["<C-r>"] = "noop",
      ["<C-S-i>"] = "noop",
      ["<C-;>"] = "noop",
    },
  },
}

local function metadata()
  return require("config.salesforce.metadata")
end

local function state_is_visible(state)
  return not state.disposed and renderer.window_exists(state)
end

local function expected_stop(err)
  return err == "Target org or Salesforce project changed." or err == "Salesforce operation cancelled."
end

local function fallback_catalog(err)
  return {
    context = {
      root = vim.fn.getcwd(),
      org = "Salesforce unavailable",
    },
    descriptors = {},
    stale = true,
    error = tostring(err or "Open the browser from a Salesforce project."),
    unavailable = true,
  }
end

function M.with_context(state, callback)
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) and state.sf_org_project_root then
    return vim.api.nvim_buf_call(state.bufnr, callback)
  end
  return callback()
end

local function load_catalog(state)
  if not state.sf_org_project_root and not require("config.project_context").is_salesforce() then
    return fallback_catalog("Open the browser from a Salesforce project.")
  end
  local ok, catalog = pcall(function()
    return M.with_context(state, function()
      return metadata().load_browser_catalog()
    end)
  end)
  if not ok or not catalog then
    return fallback_catalog(ok and nil or catalog)
  end
  return catalog
end

local function force_expand(state, node_id)
  local expanded = state.tree and renderer.get_expanded_nodes(state.tree) or {}
  if not vim.tbl_contains(expanded, node_id) then
    expanded[#expanded + 1] = node_id
  end
  state.sf_org_expand_once = expanded
end

local function reference_key(reference)
  if not reference then
    return "__catalog__"
  end
  return table.concat({ reference.type or "", reference.folder or "" }, "\0")
end

function M.render(state, callback)
  local catalog = load_catalog(state)
  catalog.operation = state.sf_org_operation
  state.path = catalog.context.root
  if not catalog.unavailable then
    state.sf_org_project_root = catalog.context.root
  end
  local context_key = table.concat({ catalog.context.root or "", catalog.context.org or "" }, "\0")
  if state.sf_org_context ~= context_key then
    state.sf_org_context = context_key
    state.sf_org_slices = {}
    state.sf_org_loading = {}
  end
  state.sf_org_slices = state.sf_org_slices or {}
  state.sf_org_loading = state.sf_org_loading or {}

  local tree_nodes = nodes.build(catalog, function(reference)
    return state.sf_org_slices[reference_key(reference)]
  end, function(reference)
    return state.sf_org_loading[reference_key(reference)] == true
  end)

  if state.sf_org_expand_once then
    state.default_expanded_nodes = state.sf_org_expand_once
  elseif not state.tree then
    state.default_expanded_nodes = { tree_nodes[1].id }
  end
  renderer.show_nodes(tree_nodes, state)
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) and state.sf_org_project_root then
    vim.b[state.bufnr].sf_project_root = state.sf_org_project_root
  end
  state.default_expanded_nodes = nil
  state.sf_org_expand_once = nil
  if callback then
    vim.schedule(callback)
  end
  return catalog
end

function M.refresh_catalog(state, force)
  local key = reference_key()
  local expected_context = state.sf_org_context
  local ok, handle = pcall(function()
    return M.with_context(state, function()
      return metadata().ensure_browser_catalog({ force = force == true }, function(_, _, err)
        if state.sf_org_context ~= expected_context then
          return
        end
        state.sf_org_loading = state.sf_org_loading or {}
        state.sf_org_loading[key] = nil
        if err and not expected_stop(err) then
          vim.notify(err, vim.log.levels.ERROR, { title = "SF Org Browser" })
        end
        if state_is_visible(state) then
          M.render(state)
        end
      end)
    end)
  end)
  if not ok then
    vim.notify(tostring(handle), vim.log.levels.ERROR, { title = "SF Org Browser" })
    return
  end
  if handle and state_is_visible(state) then
    state.sf_org_loading[key] = true
    M.render(state)
  end
end

function M.load_reference(state, reference, force, expand_id)
  local key = reference_key(reference)
  local expected_context = state.sf_org_context
  state.sf_org_slices = state.sf_org_slices or {}
  state.sf_org_loading = state.sf_org_loading or {}
  if expand_id then
    force_expand(state, expand_id)
  end
  state.sf_org_slices[key] = M.with_context(state, function()
    return metadata().load_browser_children(reference)
  end)
  local handle = M.with_context(state, function()
    return metadata().ensure_browser_children(reference, { force = force == true }, function(_, slice, err)
      if state.sf_org_context ~= expected_context then
        return
      end
      state.sf_org_loading[key] = nil
      if slice then
        state.sf_org_slices[key] = slice
      end
      if err and not expected_stop(err) then
        vim.notify(err, vim.log.levels.ERROR, { title = "SF Org Browser" })
      end
      if state_is_visible(state) then
        M.render(state)
      end
    end)
  end)
  if handle and state_is_visible(state) then
    state.sf_org_loading[key] = true
    M.render(state)
  end
end

function M.load_branch(state, node, force)
  local reference = node.extra and node.extra.reference
  if not reference or reference.type == "__catalog__" then
    M.refresh_catalog(state, force)
    return
  end
  M.load_reference(state, reference, force, node:get_id())
end

function M.set_operation(state, message)
  state.sf_org_operation = message
  if state_is_visible(state) then
    M.render(state)
  end
end

function M.reset(state)
  state.path = nil
  state.sf_org_operation = nil
  state.sf_org_context = nil
  state.sf_org_slices = {}
  state.sf_org_loading = {}
  state.sf_org_expand_once = nil
  M.render(state)
  M.refresh_catalog(state, false)
end

function M.navigate(state, _, _, callback)
  local current_buf = vim.api.nvim_get_current_buf()
  if current_buf ~= state.bufnr then
    local detected = require("config.project_context").salesforce_root(current_buf)
    if detected and vim.fs.normalize(detected) ~= state.sf_org_project_root then
      state.sf_org_project_root = nil
      state.sf_org_context = nil
      state.sf_org_slices = {}
      state.sf_org_loading = {}
    end
  end
  local catalog = M.render(state, callback)
  if not catalog.unavailable and (catalog.stale or #(catalog.descriptors or {}) == 0) then
    M.refresh_catalog(state, false)
  end
end

function M.setup()
  components.apply_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("sf_org_browser_hl", { clear = true }),
    callback = components.apply_highlights,
  })
end

return M
