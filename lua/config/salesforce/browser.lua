--------------------------------------------------------------------------------
-- Salesforce metadata browser — fzf hierarchy, upper details, right selections
-- Inventory and member audit fields come from the project-local sf_cache.
--------------------------------------------------------------------------------

local M = {}

local metadata = require("config.salesforce.metadata")
local expanded_by_context = {}
local browser_highlights_registered = false

local function apply_browser_highlights()
  local chrome = require("config.ui_chrome")
  vim.api.nvim_set_hl(0, "SFMetadataTitle", { fg = chrome.title_fg, bold = true })
  vim.api.nvim_set_hl(0, "SFMetadataLabel", { fg = chrome.muted_fg })
  vim.api.nvim_set_hl(0, "SFMetadataValue", { fg = chrome.panel_fg })
  vim.api.nvim_set_hl(0, "SFMetadataDate", { fg = "#7BE6AB" })
  vim.api.nvim_set_hl(0, "SFMetadataCategory", { fg = chrome.border_fg, bold = true })
  vim.api.nvim_set_hl(0, "SFMetadataMember", { fg = "#4CA1B3" })
  vim.api.nvim_set_hl(0, "SFMetadataSelectedNormal", { fg = chrome.panel_fg, bg = chrome.panel_bg })
  vim.api.nvim_set_hl(0, "SFMetadataSelectedBorder", { fg = chrome.divider_fg, bg = chrome.panel_bg })
  vim.api.nvim_set_hl(0, "SFMetadataSelectedTitle", { fg = chrome.title_fg, bg = chrome.panel_bg, bold = true })

  if not browser_highlights_registered then
    browser_highlights_registered = true
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("sf_metadata_browser_hl", { clear = true }),
      callback = apply_browser_highlights,
    })
  end
end

local function ansi(group, text)
  local ok, utils = pcall(require, "fzf-lua.utils")
  if not ok then
    return tostring(text)
  end
  local colored = utils.ansi_from_hl(group, tostring(text))
  return colored
end

local function detail_field(label, value, value_group)
  return ansi("SFMetadataLabel", label .. ": ") .. ansi(value_group or "SFMetadataValue", value or "—")
end

local selected_pane = {
  buf = nil,
  win = nil,
  group = nil,
  fzf_win = nil,
  entries = {},
  inventory = nil,
  reposition_pending = false,
}
local selected_ns = vim.api.nvim_create_namespace("sf_metadata_selected")
local render_selected_pane

local function close_selected_pane()
  if selected_pane.group then
    pcall(vim.api.nvim_del_augroup_by_id, selected_pane.group)
  end
  if selected_pane.win and vim.api.nvim_win_is_valid(selected_pane.win) then
    pcall(vim.api.nvim_win_close, selected_pane.win, true)
  end
  if selected_pane.buf and vim.api.nvim_buf_is_valid(selected_pane.buf) then
    pcall(vim.api.nvim_buf_delete, selected_pane.buf, { force = true })
  end
  selected_pane.buf = nil
  selected_pane.win = nil
  selected_pane.group = nil
  selected_pane.fzf_win = nil
  selected_pane.entries = {}
  selected_pane.inventory = nil
  selected_pane.reposition_pending = false
end

local function comma_number(value)
  local reversed = tostring(value or 0):reverse():gsub("(%d%d%d)", "%1,")
  local formatted = reversed:reverse():gsub("^,", "")
  return formatted
end

local function type_path(full_name)
  local path = tostring(full_name or ""):gsub("/", " / "):gsub("%.", " / ")
  return path
end

local function expansion_state(inventory)
  local ctx = inventory.context
  local key = table.concat({ ctx.root or "", ctx.org or "" }, "\0")
  expanded_by_context[key] = expanded_by_context[key] or {}
  return expanded_by_context[key]
end

local function stable_entry_id(kind, value)
  return vim.fn.sha256(table.concat({ kind, value.type or "", value.fullName or "" }, "\0"))
end

local function build_entries(inventory, expanded)
  expanded = expanded or {}
  local lines = {}
  local lookup = {}
  local types = vim.tbl_keys(inventory.types)
  table.sort(types)

  local function add(kind, display, value)
    local id = stable_entry_id(kind, value)
    lookup[id] = { kind = kind, display = display, value = value }
    lines[#lines + 1] = table.concat({ id, kind, display }, "\t")
  end

  for _, metadata_type in ipairs(types) do
    local type_data = inventory.types[metadata_type]
    local members = type_data.members

    local is_expanded = expanded[metadata_type] == true
    local marker = is_expanded and "▾" or "▸"
    -- Keep the row ending at `/`: an exact `Type /` query then ranks this
    -- category above all of its members for quick collapse/selection.
    add("type", string.format("%s %s /", marker, metadata_type), {
      type = metadata_type,
      descriptor = type_data.descriptor,
      error = type_data.error,
      fetched = type_data.fetched,
    })

    if members and is_expanded then
      table.sort(members, function(a, b)
        return tostring(a.fullName):lower() < tostring(b.fullName):lower()
      end)
      for _, member in ipairs(members) do
        local display = string.format("  %s / %s", metadata_type, type_path(member.fullName))
        add("member", display, {
          type = member.type or metadata_type,
          fullName = member.fullName,
          fileName = member.fileName,
          manageableState = member.manageableState,
          namespacePrefix = member.namespacePrefix,
          lastModifiedByName = member.lastModifiedByName,
          lastModifiedDate = member.lastModifiedDate,
          raw = member,
        })
      end
    end
  end

  return lines, lookup
end

local function selected_entries(selected, lookup)
  local entries = {}
  local seen = {}
  for _, line in ipairs(selected or {}) do
    local id = line:match("^([^\t]+)")
    local entry = id and lookup[id] or nil
    if entry and not seen[id] then
      seen[id] = true
      entries[#entries + 1] = entry
    end
  end
  return entries
end

local function update_selected_pane(payload, lookup, inventory)
  local count = tonumber(payload and payload[#payload]) or 0
  local selected = {}
  if count > 0 and payload[1] then
    local ok, lines = pcall(vim.fn.readfile, payload[1])
    if ok then
      selected = selected_entries(lines, lookup)
    end
  end
  selected_pane.entries = selected
  selected_pane.inventory = inventory
  render_selected_pane()
end

local function member_values(entries)
  local values = {}
  for _, entry in ipairs(entries) do
    if entry.kind == "member" then
      values[#values + 1] = entry.value
    end
  end
  return values
end

local function selected_pane_lines(entries, inventory, max_lines)
  local lines = {}
  local groups = {}
  max_lines = math.max(max_lines or 1, 1)

  for _, entry in ipairs(entries) do
    if #lines >= max_lines then
      break
    end
    if entry.kind == "type" then
      local metadata_type = entry.value.type
      local type_data = inventory.types[metadata_type]
      local count = type_data and type_data.members and #type_data.members or 0
      lines[#lines + 1] = string.format("▸ %s — all %s cached members", metadata_type, comma_number(count))
      groups[#groups + 1] = "SFMetadataCategory"
    else
      lines[#lines + 1] = string.format("• %s:%s", entry.value.type, entry.value.fullName)
      groups[#groups + 1] = "SFMetadataMember"
    end
  end

  if #entries > #lines then
    if #lines == max_lines then
      lines[#lines] = string.format("… %s more selected", comma_number(#entries - max_lines + 1))
      groups[#groups] = "SFMetadataLabel"
    else
      lines[#lines + 1] = string.format("… %s more selected", comma_number(#entries - #lines))
      groups[#groups + 1] = "SFMetadataLabel"
    end
  end
  if #lines == 0 then
    lines[1] = "No metadata selected"
    groups[1] = "SFMetadataLabel"
  end
  return lines, groups
end

render_selected_pane = function()
  if not selected_pane.buf or not vim.api.nvim_buf_is_valid(selected_pane.buf) then
    return
  end
  local height = selected_pane.win
      and vim.api.nvim_win_is_valid(selected_pane.win)
      and vim.api.nvim_win_get_height(selected_pane.win)
    or 20
  local lines, groups = selected_pane_lines(selected_pane.entries, selected_pane.inventory, height)

  vim.bo[selected_pane.buf].modifiable = true
  vim.api.nvim_buf_set_lines(selected_pane.buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(selected_pane.buf, selected_ns, 0, -1)
  for index, group in ipairs(groups) do
    vim.api.nvim_buf_add_highlight(selected_pane.buf, selected_ns, group, index - 1, 0, -1)
  end
  vim.bo[selected_pane.buf].modifiable = false

  if selected_pane.win and vim.api.nvim_win_is_valid(selected_pane.win) then
    local config = vim.api.nvim_win_get_config(selected_pane.win)
    config.title = string.format(" Selected metadata (%s) ", comma_number(#selected_pane.entries))
    config.title_pos = "center"
    vim.api.nvim_win_set_config(selected_pane.win, config)
  end
end

local function place_selected_pane()
  local fzf_win = selected_pane.fzf_win
  if not fzf_win or not vim.api.nvim_win_is_valid(fzf_win) then
    return
  end

  local wins = { fzf_win }
  local ok, fzf_utils = pcall(require, "fzf-lua.utils")
  local winobj = ok and fzf_utils.fzf_winobj() or nil
  if winobj and winobj.preview_winid and vim.api.nvim_win_is_valid(winobj.preview_winid) then
    wins[#wins + 1] = winobj.preview_winid
  end

  local top = vim.o.lines
  local bottom = 0
  local right = 0
  for _, win in ipairs(wins) do
    local pos = vim.api.nvim_win_get_position(win)
    top = math.min(top, math.max(pos[1] - 1, 0))
    bottom = math.max(bottom, pos[1] + vim.api.nvim_win_get_height(win) + 1)
    right = math.max(right, pos[2] + vim.api.nvim_win_get_width(win) + 2)
  end

  local width = vim.o.columns - right - 2
  local max_bottom = vim.o.lines - vim.o.cmdheight - 1
  local height = math.min(bottom, max_bottom) - top
  local too_narrow = vim.o.columns < 100 or width < 24 or height < 8 or (winobj and winobj.fullscreen)
  if too_narrow then
    if selected_pane.win and vim.api.nvim_win_is_valid(selected_pane.win) then
      vim.api.nvim_win_close(selected_pane.win, true)
    end
    selected_pane.win = nil
    return
  end

  if not selected_pane.buf or not vim.api.nvim_buf_is_valid(selected_pane.buf) then
    selected_pane.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[selected_pane.buf].buftype = "nofile"
    vim.bo[selected_pane.buf].bufhidden = "wipe"
    vim.bo[selected_pane.buf].swapfile = false
    vim.bo[selected_pane.buf].filetype = "sfmetadata-selected"
  end

  local config = {
    relative = "editor",
    row = top,
    col = right,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = string.format(" Selected metadata (%s) ", comma_number(#selected_pane.entries)),
    title_pos = "center",
    focusable = false,
    mouse = false,
    zindex = 51,
  }
  if selected_pane.win and vim.api.nvim_win_is_valid(selected_pane.win) then
    vim.api.nvim_win_set_config(selected_pane.win, config)
  else
    selected_pane.win = vim.api.nvim_open_win(selected_pane.buf, false, config)
    vim.wo[selected_pane.win].wrap = false
    vim.wo[selected_pane.win].cursorline = false
    vim.wo[selected_pane.win].winhighlight =
      "Normal:SFMetadataSelectedNormal,NormalFloat:SFMetadataSelectedNormal,FloatBorder:SFMetadataSelectedBorder,FloatTitle:SFMetadataSelectedTitle"
  end
  render_selected_pane()
end

local function schedule_selected_pane()
  if selected_pane.reposition_pending then
    return
  end
  selected_pane.reposition_pending = true
  vim.schedule(function()
    selected_pane.reposition_pending = false
    place_selected_pane()
  end)
end

local function open_selected_pane(event, inventory)
  close_selected_pane()
  selected_pane.fzf_win = event.winid
  selected_pane.inventory = inventory
  selected_pane.group = vim.api.nvim_create_augroup("sf_metadata_selected_pane", { clear = true })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = selected_pane.group,
    callback = schedule_selected_pane,
  })
  vim.defer_fn(schedule_selected_pane, 10)
end

local function detail_lines(current, lookup, inventory)
  local entries = selected_entries(current, lookup)
  local lines = {}
  local entry = entries[1]
  if not entry then
    return {
      ansi("SFMetadataTitle", "Metadata details"),
      detail_field("Focus", "Move onto a category or member"),
    }
  end

  if entry.kind == "type" then
    local value = entry.value
    local descriptor = value.descriptor or {}
    local type_data = inventory.types[value.type]
    local fetched_at = value.fetched and value.fetched.at

    lines[#lines + 1] = ansi("SFMetadataTitle", "Category · " .. value.type)
    lines[#lines + 1] = ansi("SFMetadataLabel", string.rep("─", 50))
    lines[#lines + 1] = detail_field("XML name", descriptor.xmlName or value.type)
    lines[#lines + 1] = detail_field("Directory", descriptor.directoryName)
    lines[#lines + 1] = detail_field("Suffix", descriptor.suffix)
    lines[#lines + 1] = detail_field("Folder based", tostring(descriptor.inFolder == true))
    lines[#lines + 1] = detail_field("Requires meta file", tostring(descriptor.metaFile == true))
    lines[#lines + 1] = detail_field("Expanded", tostring(expansion_state(inventory)[value.type] == true))
    lines[#lines + 1] = detail_field("Cached members", tostring(type_data.members and #type_data.members or 0))
    lines[#lines + 1] = detail_field(
      "Fetched",
      fetched_at and os.date("%Y-%m-%d %H:%M:%S", fetched_at) or "never",
      fetched_at and "SFMetadataDate" or nil
    )
    lines[#lines + 1] = detail_field(
      "Child metadata",
      type(descriptor.childXmlNames) == "table" and table.concat(descriptor.childXmlNames, ", ") or nil
    )
    if value.error then
      lines[#lines + 1] = detail_field("Error", tostring(value.error), "DiagnosticError")
    end
    return lines
  end

  local value = entry.value
  local raw = value.raw or {}
  lines[#lines + 1] = ansi("SFMetadataTitle", string.format("%s:%s", value.type, value.fullName))
  lines[#lines + 1] = ansi("SFMetadataLabel", string.rep("─", 50))
  lines[#lines + 1] = detail_field("File", value.fileName or raw.fileName)
  lines[#lines + 1] = detail_field("Metadata ID", raw.id)
  lines[#lines + 1] = detail_field("Manageable state", value.manageableState or raw.manageableState)
  lines[#lines + 1] = detail_field("Namespace", value.namespacePrefix or raw.namespacePrefix)
  lines[#lines + 1] = detail_field("Created by", raw.createdByName)
  lines[#lines + 1] = detail_field("Created at", raw.createdDate, "SFMetadataDate")
  lines[#lines + 1] = detail_field("Modified by", value.lastModifiedByName or raw.lastModifiedByName)
  lines[#lines + 1] = detail_field("Modified at", value.lastModifiedDate or raw.lastModifiedDate, "SFMetadataDate")
  return lines
end

local function org_label(ctx)
  local identity = ctx.identity or {}
  local pieces = { ctx.org }
  if identity.username and identity.username ~= ctx.org then
    pieces[#pieces + 1] = identity.username
  end
  if identity.org_id then
    pieces[#pieces + 1] = identity.org_id
  end
  if identity.instance_url then
    pieces[#pieces + 1] = identity.instance_url
  end
  return table.concat(pieces, " · ")
end

local function selection_summary(ctx, members, verb)
  local lines = {
    string.format("%s %d metadata item(s)?", verb, #members),
    "",
    "Target: " .. org_label(ctx),
    "",
  }
  for index, member in ipairs(members) do
    if index > 12 then
      lines[#lines + 1] = string.format("… and %d more", #members - 12)
      break
    end
    lines[#lines + 1] = string.format("  %s:%s", member.type, member.fullName)
  end
  return table.concat(lines, "\n")
end

local function entry_type(entry)
  return entry and entry.value and entry.value.type or nil
end

local function toggle_category(entries, inventory)
  local entry = entries[1]
  if not entry then
    return
  end

  local metadata_type = entry_type(entry)
  local type_data = metadata_type and inventory.types[metadata_type] or nil
  if not type_data then
    return
  end

  local expanded = expansion_state(inventory)
  if type_data.members == nil then
    metadata.refresh_type(metadata_type, function(ok)
      if ok then
        expanded[metadata_type] = true
        require("fzf-lua").close()
        M.open() -- uncached data arrives asynchronously; one reopen is required
      end
    end)
    return
  end

  expanded[metadata_type] = not expanded[metadata_type]
end

local function collect_retrieve_members(entries, inventory)
  local members = {}
  local missing = {}
  local seen = {}

  local function add(member)
    local id = string.format("%s:%s", member.type, member.fullName)
    if not seen[id] then
      seen[id] = true
      members[#members + 1] = member
    end
  end

  for _, entry in ipairs(entries) do
    if entry.kind == "member" then
      add(entry.value)
    elseif entry.kind == "type" then
      local metadata_type = entry.value.type
      local type_members = inventory.types[metadata_type].members
      if type_members == nil then
        missing[#missing + 1] = metadata_type
      else
        for _, member in ipairs(type_members) do
          add({
            type = member.type or metadata_type,
            fullName = member.fullName,
            fileName = member.fileName,
            manageableState = member.manageableState,
            namespacePrefix = member.namespacePrefix,
            raw = member,
          })
        end
      end
    end
  end

  return members, missing
end

local function refresh_missing_types(types, index, done)
  if index > #types then
    done(true)
    return
  end
  metadata.refresh_type(types[index], function(ok)
    if not ok then
      done(false)
      return
    end
    refresh_missing_types(types, index + 1, done)
  end)
end

local function with_resolved_members(entries, inventory, callback)
  local members, missing = collect_retrieve_members(entries, inventory)
  if #missing == 0 then
    callback(members)
    return
  end

  refresh_missing_types(missing, 1, function(ok)
    if not ok then
      vim.notify("Could not cache every selected metadata category.", vim.log.levels.ERROR, {
        title = "SF metadata",
      })
      return
    end
    local refreshed = metadata.load_inventory()
    local refreshed_members = refreshed and collect_retrieve_members(entries, refreshed) or {}
    callback(refreshed_members)
  end)
end

local function retrieve(entries, inventory)
  with_resolved_members(entries, inventory, function(members)
    if #members == 0 then
      vim.notify("The selected metadata category is empty.", vim.log.levels.WARN, { title = "SF metadata" })
      return
    end
    metadata.retrieve(members)
  end)
end

local function generate_manifest(entries, inventory)
  with_resolved_members(entries, inventory, function(members)
    if #members == 0 then
      vim.notify("Select metadata members or categories first.", vim.log.levels.WARN, { title = "SF metadata" })
      return
    end

    vim.ui.input({ prompt = "Package manifest filename: " }, function(filename)
      if filename == nil then
        return
      end
      local path, err = metadata.write_package_manifest(members, filename)
      if not path then
        vim.notify(err, vim.log.levels.ERROR, { title = "SF metadata" })
        return
      end
      local ctx = metadata.get_context()
      local relative = ctx and vim.fs.relpath(ctx.root, path) or path
      vim.notify("Created " .. (relative or path), vim.log.levels.INFO, { title = "SF metadata" })
    end)
  end)
end

local function refresh_entry_type(entries)
  local metadata_type = entry_type(entries[1])
  if not metadata_type then
    return
  end
  metadata.refresh_type(metadata_type, function()
    M.open()
  end)
end

local function deploy(entries)
  local members = member_values(entries)
  if #members == 0 then
    vim.notify("Select metadata members before deploying.", vim.log.levels.WARN, { title = "SF metadata" })
    return
  end
  local ctx = metadata.get_context()
  if not ctx then
    return
  end
  local answer = vim.fn.confirm(selection_summary(ctx, members, "Deploy"), "&Deploy\n&Cancel", 2)
  if answer == 1 then
    metadata.deploy(members)
  end
end

local function destructive_members(entries)
  local members = member_values(entries)
  local blocked = {}
  local allowed = {}
  for _, member in ipairs(members) do
    local state = member.manageableState
    if state and state ~= "" and state ~= "unmanaged" then
      blocked[#blocked + 1] = string.format("%s:%s (%s)", member.type, member.fullName, state)
    else
      allowed[#allowed + 1] = member
    end
  end
  return allowed, blocked
end

local function delete_remote(entries)
  local members, blocked = destructive_members(entries)
  if #blocked > 0 then
    vim.notify(
      "Delete blocked for managed metadata:\n" .. table.concat(blocked, "\n"),
      vim.log.levels.ERROR,
      { title = "SF metadata" }
    )
    return
  end
  if #members == 0 then
    vim.notify("Select unmanaged metadata members before deleting.", vim.log.levels.WARN, { title = "SF metadata" })
    return
  end

  local ctx = metadata.get_context()
  if not ctx then
    return
  end
  metadata.delete_dry_run(members, function(ok, _, dry_ctx, manifests)
    if not ok then
      vim.notify("Delete dry-run failed; nothing was deleted.", vim.log.levels.ERROR, { title = "SF metadata" })
      return
    end

    vim.ui.input({
      prompt = string.format("Dry-run passed. Type DELETE for remote deletion from %s: ", dry_ctx.org),
    }, function(value)
      if value ~= "DELETE" then
        vim.notify("Remote delete cancelled.", vim.log.levels.INFO, { title = "SF metadata" })
        return
      end

      local answer = vim.fn.confirm(
        selection_summary(dry_ctx, members, "Dry-run passed. DELETE REMOTELY"),
        "&Delete remotely\n&Cancel",
        2
      )
      if answer ~= 1 then
        return
      end

      metadata.delete_apply(dry_ctx, manifests, function(deleted)
        if deleted then
          metadata.refresh_items(members, function()
            vim.notify("Remote metadata deleted; local files were preserved.", vim.log.levels.INFO, {
              title = "SF metadata",
            })
          end)
        end
      end)
    end)
  end)
end

function M.open()
  apply_browser_highlights()
  local inventory = metadata.load_inventory()
  if not inventory then
    return
  end
  if vim.tbl_isempty(inventory.types) then
    vim.ui.select({ "Update common inventory", "Cancel" }, {
      prompt = "No cached metadata inventory:",
    }, function(choice)
      if choice == "Update common inventory" then
        metadata.refresh_common(function()
          M.open()
        end)
      end
    end)
    return
  end

  local expanded = expansion_state(inventory)
  local lookup = {}
  local function contents(fzf_cb)
    local lines
    lines, lookup = build_entries(inventory, expanded)
    for _, line in ipairs(lines) do
      fzf_cb(line)
    end
    fzf_cb()
  end

  require("fzf-lua").fzf_exec(contents, {
    prompt = string.format("Metadata [%s]> ", inventory.context.org),
    header = "Tab select | <CR> retrieve | ^G package.xml | ^E expand\n^D deploy | ^X delete | ^U refresh",
    fzf_opts = {
      ["--multi"] = true,
      ["--delimiter"] = "\t",
      ["--with-nth"] = "3..",
      ["--id-nth"] = "1",
      ["--scheme"] = "path",
      ["--preview-label"] = " Details ",
    },
    fzf_colors = {
      ["preview-fg"] = { "fg", "SFMetadataValue" },
      ["preview-bg"] = { "bg", "SFMetadataSelectedNormal" },
      ["preview-border"] = { "fg", "SFMetadataSelectedBorder" },
      ["preview-label"] = { "fg", "SFMetadataTitle" },
    },
    keymap = {
      fzf = {
        ["ctrl-a"] = "toggle-all",
        -- These defaults are replaced by metadata actions below.
        ["ctrl-d"] = false, -- preview-page-down
        ["ctrl-e"] = false, -- end-of-line
        ["ctrl-u"] = false, -- preview-page-up
        ["ctrl-x"] = false,
      },
    },
    winopts = {
      width = 0.66,
      height = 0.85,
      row = 0.50,
      col = 0.05,
      on_create = function(event)
        open_selected_pane(event, inventory)
      end,
      on_close = close_selected_pane,
      preview = {
        layout = "vertical",
        vertical = "up:35%", -- focused-item details above the filter/results
        -- vertical = "down:50%", -- conventional preview below results
        hidden = false,
      },
    },
    preview = {
      field_index = "{}",
      fn = function(current)
        return detail_lines(current, lookup, inventory)
      end,
    },
    actions = {
      ["load"] = {
        field_index = "{+f} $FZF_SELECT_COUNT",
        exec_silent = true,
        header = false,
        fn = function(payload)
          update_selected_pane(payload, lookup, inventory)
        end,
      },
      ["multi"] = {
        field_index = "{+f} $FZF_SELECT_COUNT",
        exec_silent = true,
        header = false,
        fn = function(payload)
          update_selected_pane(payload, lookup, inventory)
        end,
      },
      ["default"] = function(selected)
        retrieve(selected_entries(selected, lookup), inventory)
      end,
      ["ctrl-d"] = function(selected)
        deploy(selected_entries(selected, lookup))
      end,
      ["ctrl-g"] = function(selected)
        generate_manifest(selected_entries(selected, lookup), inventory)
      end,
      ["ctrl-x"] = function(selected)
        delete_remote(selected_entries(selected, lookup))
      end,
      ["ctrl-u"] = function(selected)
        refresh_entry_type(selected_entries(selected, lookup))
      end,
      ["ctrl-e"] = {
        field_index = "{}",
        reload = true, -- update the list in place; preserve query/cursor and avoid flash
        fn = function(selected)
          toggle_category(selected_entries(selected, lookup), inventory)
        end,
      },
    },
  })
end

M._test = {
  build_entries = build_entries,
  close_selected_pane = close_selected_pane,
  collect_retrieve_members = collect_retrieve_members,
  destructive_members = destructive_members,
  detail_lines = detail_lines,
  member_values = member_values,
  open_selected_pane = open_selected_pane,
  place_selected_pane = place_selected_pane,
  selected_pane_lines = selected_pane_lines,
  selected_entries = selected_entries,
  stable_entry_id = stable_entry_id,
  update_selected_pane = update_selected_pane,
  selected_pane_state = function()
    return selected_pane
  end,
  type_path = type_path,
}

return M
