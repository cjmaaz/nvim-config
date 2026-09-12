--------------------------------------------------------------------------------
-- Salesforce Org Browser commands — branch loading, details, and safe retrieve.
--------------------------------------------------------------------------------

local common = require("neo-tree.sources.common.commands")
local M = vim.tbl_extend("force", {}, common)
local RETRIEVABLE_STATES = {
  unmanaged = true,
  installedEditable = true,
  deprecatedEditable = true,
}

local function source()
  return require("config.salesforce.org_browser")
end

local function metadata()
  return require("config.salesforce.metadata")
end

local function current_node(state)
  return state.tree and state.tree:get_node() or nil
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "SF Org Browser" })
end

local function retrievable_member(member)
  local state = member.manageableState
  return state == nil or state == "" or RETRIEVABLE_STATES[state] == true
end

function M.filter(state)
  if
    state.sf_org_filter_input
    and state.sf_org_filter_input.winid
    and vim.api.nvim_win_is_valid(state.sf_org_filter_input.winid)
  then
    vim.api.nvim_set_current_win(state.sf_org_filter_input.winid)
    return
  end

  local Input = require("nui.input")
  local previous = state.sf_org_filter_raw or ""
  local previous_expanded = require("neo-tree.ui.renderer").get_expanded_nodes(state.tree)
  local input
  local function focus_tree()
    state.sf_org_filter_input = nil
    vim.schedule(function()
      if state.winid and vim.api.nvim_win_is_valid(state.winid) then
        vim.api.nvim_set_current_win(state.winid)
      end
    end)
  end
  local function update(value)
    local category_only = not tostring(value or ""):find("/", 1, true)
    source().set_filter(state, value, category_only and previous_expanded or nil)
  end

  input = Input({
    relative = "win",
    winid = state.winid,
    position = {
      row = math.max(vim.api.nvim_win_get_height(state.winid) - 3, 0),
      col = 0,
    },
    size = {
      width = math.max(vim.api.nvim_win_get_width(state.winid) - 2, 10),
    },
    border = {
      style = "rounded",
      text = {
        top = " Category/Component ",
        top_align = "left",
      },
    },
    win_options = {
      winhighlight = "Normal:NeoTreeNormal,FloatBorder:NeoTreeFloatBorder",
    },
  }, {
    prompt = " / ",
    default_value = previous,
    on_change = function(value)
      update(value)
    end,
    on_submit = function(value)
      update(value)
      focus_tree()
    end,
    on_close = function()
      source().set_filter(state, previous, previous_expanded)
      focus_tree()
    end,
  })
  state.sf_org_filter_input = input
  input:map("i", "<Esc>", function()
    input:unmount()
  end, { noremap = true, nowait = true })
  input:mount()
end

local function retrieve_summary(ctx, members, metadata_type)
  if metadata_type then
    return string.format(
      "Retrieve all %d %s components from %s into the project's default package?\n\nExisting local source can be overwritten.",
      #members,
      metadata_type,
      ctx.org
    )
  end
  if #members == 1 then
    return string.format(
      "Retrieve %s:%s from %s into the project's default package?\n\nExisting local source can be overwritten.",
      members[1].type,
      members[1].fullName,
      ctx.org
    )
  end
  return string.format(
    "Retrieve %d metadata components from %s into the project's default package?\n\nExisting local source can be overwritten.",
    #members,
    ctx.org
  )
end

local function preferred_file(files)
  for _, path in ipairs(files or {}) do
    if not path:match("%-meta%.xml$") then
      return path
    end
  end
  return files and files[1] or nil
end

local function open_file(state, path)
  if not path or not (vim.uv or vim.loop).fs_stat(path) then
    return false
  end
  local winid = select(1, require("neo-tree.utils").get_appropriate_window(state))
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return false
  end
  vim.api.nvim_win_call(winid, function()
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
  return true
end

local function run_retrieve(state, members, open_after, ignore_conflicts)
  source().set_operation(state, string.format("Retrieving %d component%s…", #members, #members == 1 and "" or "s"))
  source().with_context(state, function()
    metadata().retrieve_browser(members, {
      ignore_conflicts = ignore_conflicts == true,
    }, function(ok, payload, err)
      source().set_operation(state, nil)
      if not ok then
        if metadata().is_conflict_error(err) and not ignore_conflicts then
          local overwrite =
            vim.fn.confirm(tostring(err) .. "\n\nRetry and overwrite local conflicts?", "&Overwrite\n&Cancel", 2)
          if overwrite == 1 then
            run_retrieve(state, members, open_after, true)
          end
        elseif err ~= "Salesforce operation cancelled." and err ~= "Target org or Salesforce project changed." then
          notify(err or "Retrieve failed.", vim.log.levels.ERROR)
        end
        return
      end

      vim.cmd.checktime()
      local files = payload and payload.files or {}
      if #files == 0 then
        notify("Retrieve completed, but Salesforce CLI reported no source files.", vim.log.levels.WARN)
        return
      end
      notify(string.format("Retrieved %d file%s.", #files, #files == 1 and "" or "s"))
      if open_after and not open_file(state, preferred_file(files)) then
        notify("Retrieve succeeded, but no returned source file could be opened.", vim.log.levels.WARN)
      end
    end)
  end)
end

local function confirm_and_retrieve(state, members, open_after, metadata_type)
  local ctx = source().with_context(state, function()
    return metadata().get_context()
  end)
  if not ctx or #members == 0 then
    return
  end
  local answer = vim.fn.confirm(retrieve_summary(ctx, members, metadata_type), "&Retrieve\n&Cancel", 2)
  if answer == 1 then
    run_retrieve(state, members, open_after, false)
  end
end

function M.open(state)
  local node = current_node(state)
  if not node then
    return
  end
  local extra = node.extra or {}

  if extra.kind == "component" then
    if not extra.retrievable then
      notify("This managed component is not retrievable.", vim.log.levels.WARN)
      return
    end
    confirm_and_retrieve(state, { extra.member }, true)
    return
  end
  if extra.kind == "error" then
    M.refresh(state)
    return
  end
  if extra.kind == "loading" or extra.kind == "empty" then
    return
  end
  if extra.kind == "org" then
    common.toggle_node(state)
    return
  end

  local was_expanded = node:is_expanded()
  if node:has_children() then
    common.toggle_node(state)
  end
  if not was_expanded and (not extra.fetched_at or extra.stale) then
    source().load_branch(state, node, false)
  end
end

function M.close_node(state)
  local node = current_node(state)
  if not node or ((node.extra or {}).kind == "org" and not node:is_expanded()) then
    return
  end
  common.close_node(state)
end

function M.retrieve(state)
  local node = current_node(state)
  local extra = node and node.extra or {}
  if extra.kind ~= "component" then
    notify("Move onto a component; use A on a metadata type.", vim.log.levels.WARN)
    return
  end
  if not extra.retrievable then
    notify("This managed component is not retrievable.", vim.log.levels.WARN)
    return
  end
  confirm_and_retrieve(state, { extra.member }, false)
end

function M.retrieve_type(state)
  local node = current_node(state)
  local extra = node and node.extra or {}
  if extra.kind ~= "metadata_type" then
    notify("Move onto a metadata type to retrieve all of it.", vim.log.levels.WARN)
    return
  end

  local metadata_type = extra.reference.type
  source().set_operation(state, "Refreshing " .. metadata_type .. " before retrieve…")
  source().with_context(state, function()
    metadata().refresh_browser_type_members(metadata_type, function(ok, members, err)
      source().set_operation(state, nil)
      if not ok then
        if err ~= "Salesforce operation cancelled." and err ~= "Target org or Salesforce project changed." then
          notify(err or ("Could not refresh " .. metadata_type), vim.log.levels.ERROR)
        end
        return
      end
      source().load_branch(state, node, false)
      local skipped = #members
      members = vim.tbl_filter(retrievable_member, members)
      skipped = skipped - #members
      if #members == 0 then
        notify(metadata_type .. " has no retrievable components.", vim.log.levels.WARN)
        return
      end
      if skipped > 0 then
        notify(string.format("Skipping %d non-retrievable managed component%s.", skipped, skipped == 1 and "" or "s"))
      end
      confirm_and_retrieve(state, members, false, metadata_type)
    end)
  end)
end

function M.refresh(state)
  local node = current_node(state)
  local extra = node and node.extra or {}
  local reference = extra.reference
  if extra.kind == "org" or not reference or reference.type == "__catalog__" then
    source().refresh_catalog(state, true)
  elseif extra.kind == "metadata_type" or extra.kind == "folder" then
    source().load_branch(state, node, true)
  elseif extra.kind == "component" then
    source().load_reference(state, reference, true)
  else
    source().refresh_catalog(state, true)
  end
end

local function detail_lines(node)
  local extra = node.extra or {}
  if extra.kind == "org" then
    local ctx = extra.context or {}
    return {
      "Target org: " .. (ctx.org or "—"),
      "Project: " .. (ctx.root or "—"),
      "API version: " .. (ctx.api_version or "project/default"),
      "Cached types: " .. tostring(extra.count or 0),
    }
  elseif extra.kind == "metadata_type" then
    local descriptor = extra.descriptor or {}
    return {
      "Metadata type: " .. (descriptor.xmlName or node.name or "—"),
      "Directory: " .. (descriptor.directoryName or "—"),
      "Suffix: " .. (descriptor.suffix or "—"),
      "Folder based: " .. tostring(descriptor.inFolder == true),
      "Requires meta file: " .. tostring(descriptor.metaFile == true),
      "Cached children: " .. tostring(extra.count or 0),
    }
  elseif extra.kind == "folder" then
    return {
      "Folder: " .. (extra.reference.folder or node.name or "—"),
      "Metadata type: " .. (extra.reference.type or "—"),
      "Cached components: " .. tostring(extra.count or 0),
    }
  elseif extra.kind == "component" then
    local member = extra.member or {}
    local raw = member.raw or {}
    return {
      string.format("%s:%s", member.type or "Metadata", member.fullName or node.name or "—"),
      "File: " .. (member.fileName or "—"),
      "Metadata ID: " .. (raw.id or "—"),
      "Namespace: " .. (member.namespacePrefix or "—"),
      "Manageable state: " .. (member.manageableState or "unmanaged"),
      "Modified by: " .. (member.lastModifiedByName or "—"),
      "Modified at: " .. (member.lastModifiedDate or "—"),
      "Created by: " .. (raw.createdByName or "—"),
      "Created at: " .. (raw.createdDate or "—"),
    }
  elseif extra.kind == "error" then
    return {
      node.name or "Refresh failed",
      "",
      tostring(extra.detail or "No additional error details."),
    }
  end
  return { node.name or "No details" }
end

function M.details(state)
  local node = current_node(state)
  if not node then
    return
  end
  vim.lsp.util.open_floating_preview(detail_lines(node), "plaintext", {
    border = "rounded",
    focusable = true,
    title = " Salesforce metadata ",
  })
end

function M.change_org(state)
  source().with_context(state, function()
    metadata().select_target(function()
      source().reset(state)
    end)
  end)
end

function M.batch_picker(state)
  common.close_window(state)
  vim.schedule(function()
    require("config.salesforce.browser").open()
  end)
end

M._test = {
  preferred_file = preferred_file,
  retrievable_member = retrievable_member,
  retrieve_summary = retrieve_summary,
}

return M
