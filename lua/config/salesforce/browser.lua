--------------------------------------------------------------------------------
-- Salesforce metadata browser — fzf-lua path hierarchy + multi-select actions
-- Selected items render in the upper preview; inventory comes from project sf_cache.
--------------------------------------------------------------------------------

local M = {}

local metadata = require("config.salesforce.metadata")

local function type_path(full_name)
  local path = tostring(full_name or ""):gsub("/", " / "):gsub("%.", " / ")
  return path
end

local function build_entries(inventory)
  local lines = {}
  local lookup = {}
  local next_id = 0
  local types = vim.tbl_keys(inventory.types)
  table.sort(types)

  local function add(kind, display, value)
    next_id = next_id + 1
    local id = tostring(next_id)
    lookup[id] = { kind = kind, display = display, value = value }
    lines[#lines + 1] = table.concat({ id, kind, display }, "\t")
  end

  for _, metadata_type in ipairs(types) do
    local type_data = inventory.types[metadata_type]
    local members = type_data.members
    local suffix
    if members then
      suffix = string.format("%d cached", #members)
    elseif type_data.error then
      suffix = "error — Alt-U to retry"
    else
      suffix = "not cached — Enter to fetch"
    end

    add("type", string.format("▸ %s / [%s]", metadata_type, suffix), {
      type = metadata_type,
      descriptor = type_data.descriptor,
      error = type_data.error,
      fetched = type_data.fetched,
    })

    if members then
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

local function member_values(entries)
  local values = {}
  for _, entry in ipairs(entries) do
    if entry.kind == "member" then
      values[#values + 1] = entry.value
    end
  end
  return values
end

local function preview_lines(selected, lookup, inventory)
  local entries = selected_entries(selected, lookup)
  local lines = {}
  local members = member_values(entries)

  if #members > 0 then
    lines[#lines + 1] = string.format("Selected metadata (%d)", #members)
    lines[#lines + 1] = string.rep("─", 42)
    for _, member in ipairs(members) do
      lines[#lines + 1] = string.format("• %s:%s", member.type, member.fullName)
    end
    return lines
  end

  local entry = entries[1]
  if not entry then
    return {
      "Tab toggles selection · Alt-A toggles all",
      "Enter retrieve · Alt-D deploy · Alt-X remote delete · Alt-U refresh type",
    }
  end

  if entry.kind == "type" then
    local value = entry.value
    lines[#lines + 1] = value.type
    lines[#lines + 1] = string.rep("─", #value.type)
    local type_data = inventory.types[value.type]
    lines[#lines + 1] = "Cached members: " .. tostring(type_data.members and #type_data.members or 0)
    lines[#lines + 1] = "Fetched: " .. tostring(value.fetched and value.fetched.at or "never")
    if value.error then
      lines[#lines + 1] = "Error: " .. tostring(value.error)
    end
    return lines
  end

  local value = entry.value
  lines[#lines + 1] = string.format("%s:%s", value.type, value.fullName)
  lines[#lines + 1] = string.rep("─", 42)
  lines[#lines + 1] = "File: " .. tostring(value.fileName or "—")
  lines[#lines + 1] = "State: " .. tostring(value.manageableState or "—")
  lines[#lines + 1] = "Namespace: " .. tostring(value.namespacePrefix or "—")
  lines[#lines + 1] = "Modified by: " .. tostring(value.lastModifiedByName or "—")
  lines[#lines + 1] = "Modified at: " .. tostring(value.lastModifiedDate or "—")
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

local function refresh_entry_type(entries)
  local entry = entries[1]
  if not entry then
    return
  end
  local metadata_type = entry.value.type
  metadata.refresh_type(metadata_type, function()
    M.open()
  end)
end

local function retrieve(entries)
  local members = member_values(entries)
  if #members == 0 then
    refresh_entry_type(entries)
    return
  end
  metadata.retrieve(members)
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

  local lines, lookup = build_entries(inventory)
  require("fzf-lua").fzf_exec(lines, {
    prompt = string.format("Metadata [%s]> ", inventory.context.org),
    header = "Tab select | Enter retrieve/fetch | Alt-D deploy | Alt-X remote delete | Alt-U refresh type",
    fzf_opts = {
      ["--multi"] = true,
      ["--delimiter"] = "\t",
      ["--with-nth"] = "3..",
      ["--scheme"] = "path",
    },
    winopts = {
      preview = {
        layout = "vertical",
        vertical = "up:35%", -- selected items above the filter/results
        -- vertical = "down:50%", -- conventional preview below results
        hidden = false,
        title = " Selected metadata ",
      },
    },
    preview = {
      field_index = "{+}",
      fn = function(selected)
        return preview_lines(selected, lookup, inventory)
      end,
    },
    actions = {
      ["default"] = function(selected)
        retrieve(selected_entries(selected, lookup))
      end,
      ["alt-d"] = function(selected)
        deploy(selected_entries(selected, lookup))
      end,
      ["alt-x"] = function(selected)
        delete_remote(selected_entries(selected, lookup))
      end,
      ["alt-u"] = function(selected)
        refresh_entry_type(selected_entries(selected, lookup))
      end,
    },
  })
end

M._test = {
  build_entries = build_entries,
  destructive_members = destructive_members,
  member_values = member_values,
  preview_lines = preview_lines,
  selected_entries = selected_entries,
  type_path = type_path,
}

return M
