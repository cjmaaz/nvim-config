--------------------------------------------------------------------------------
-- SOQL builder and runner — cached schema picker, draft editor, SFTerm results.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local metadata = require("config.salesforce.metadata")
local process = require("config.salesforce.process")
local schema = require("config.salesforce.schema")

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "SOQL builder" })
end

local function buffer_context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root = vim.b[bufnr].soql_root
  local org = vim.b[bufnr].soql_org
  local browser = vim.b[bufnr].soql_cache_browser
  if type(root) == "string" and type(org) == "string" and type(browser) == "string" then
    return {
      root = root,
      org = org,
      paths = { browser = browser },
    }
  end
  return metadata.get_context()
end

local function object_from_buffer(bufnr)
  local configured = vim.b[bufnr].soql_object
  if configured and configured ~= "" then
    return configured
  end
  local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  return text:match("[Ff][Rr][Oo][Mm]%s+([A-Za-z_][A-Za-z0-9_]*)")
end

local function draft_path(ctx, object_name)
  return vim.fs.joinpath(ctx.paths.browser, "query-builder", object_name .. ".soql")
end

local function set_buffer_context(bufnr, ctx, object_name)
  vim.b[bufnr].soql_root = ctx.root
  vim.b[bufnr].soql_org = ctx.org
  vim.b[bufnr].soql_cache_browser = ctx.paths.browser
  vim.b[bufnr].soql_object = object_name
end

local function query_lines(object_name, fields)
  fields = #fields > 0 and fields or { "Id" }
  local lines = { "SELECT" }
  for index, field in ipairs(fields) do
    lines[#lines + 1] = string.format("  %s%s", field, index < #fields and "," or "")
  end
  lines[#lines + 1] = "FROM " .. object_name
  lines[#lines + 1] = "LIMIT 200"
  return lines
end

local function field_picker(described, callback)
  local lines, lookup = {}, {}
  for _, field in ipairs(described.fields or {}) do
    local flags = {}
    if field.filterable then
      flags[#flags + 1] = "filter"
    end
    if field.sortable then
      flags[#flags + 1] = "sort"
    end
    local line = string.format(
      "%s\t%s\t%s",
      field.name,
      field.type or "",
      table.concat(flags, "/")
    )
    lines[#lines + 1] = line
    lookup[line] = field.name
  end

  require("fzf-lua").fzf_exec(lines, {
    prompt = string.format("%s fields> ", described.name),
    header = "Tab select | Enter confirm",
    fzf_opts = {
      ["--multi"] = true,
      ["--delimiter"] = "\t",
      ["--with-nth"] = "1..",
    },
    actions = {
      ["default"] = function(selected)
        local fields, seen = {}, {}
        for _, line in ipairs(selected or {}) do
          local name = lookup[line] or line:match("^([^\t]+)")
          if name and not seen[name] then
            seen[name] = true
            fields[#fields + 1] = name
          end
        end
        callback(fields)
      end,
    },
  })
end

local function attach_buffer(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "<localleader>f", function()
    M.pick_fields(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "SOQL: pick fields" }))
  vim.keymap.set("n", "<localleader>o", function()
    M.change_object(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "SOQL: change SObject" }))
  vim.keymap.set("n", "<localleader>r", function()
    M.run_current(false, bufnr)
  end, vim.tbl_extend("force", opts, { desc = "SOQL: run query" }))
  vim.keymap.set("n", "<localleader>t", function()
    M.run_current(true, bufnr)
  end, vim.tbl_extend("force", opts, { desc = "SOQL: run Tooling query" }))
end

local function open_draft(ctx, object_name, fields, replace)
  local path = draft_path(ctx, object_name)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local exists = uv.fs_stat(path) ~= nil
  if not exists or replace then
    local ok, error_message = pcall(vim.fn.writefile, query_lines(object_name, fields), path)
    if not ok then
      notify("Could not write SOQL draft:\n" .. tostring(error_message), vim.log.levels.ERROR)
      return
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.bo.filetype = "soql"
  set_buffer_context(0, ctx, object_name)
  attach_buffer(0)
end

local function choose_object(objects, callback)
  local queryable = vim.tbl_filter(function(object)
    return object.queryable ~= false
  end, objects)
  vim.ui.select(queryable, {
    prompt = "SOQL SObject:",
    format_item = function(object)
      return string.format("%s  %s", object.name, object.label or "")
    end,
  }, callback)
end

local function build_for_object(object, ctx)
  schema.ensure_describe(object.name, function(described)
    schema.prefetch_relationships(described, ctx)
    field_picker(described, function(fields)
      local path = draft_path(ctx, object.name)
      if uv.fs_stat(path) then
        vim.ui.select({ "Open existing draft", "Replace with selected fields", "Cancel" }, {
          prompt = "SOQL draft already exists:",
        }, function(choice)
          if choice == "Open existing draft" then
            open_draft(ctx, object.name, fields, false)
          elseif choice == "Replace with selected fields" then
            open_draft(ctx, object.name, fields, true)
          end
        end)
      else
        open_draft(ctx, object.name, fields, true)
      end
    end)
  end, ctx)
end

function M.open()
  schema.ensure_objects(function(objects, ctx)
    choose_object(objects, function(object)
      if object then
        build_for_object(object, ctx)
      end
    end)
  end)
end

function M.pick_fields(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx = buffer_context(bufnr)
  local object_name = object_from_buffer(bufnr)
  if not ctx or not object_name then
    notify("Choose an SObject with <leader>SQ first.", vim.log.levels.ERROR)
    return
  end
  schema.ensure_describe(object_name, function(described)
    field_picker(described, function(fields)
      if #fields == 0 then
        notify("No fields selected.", vim.log.levels.WARN)
        return
      end
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, query_lines(object_name, fields))
      set_buffer_context(bufnr, ctx, object_name)
    end)
  end, ctx)
end

function M.change_object(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx = buffer_context(bufnr)
  if not ctx then
    return
  end
  local objects = schema.load_objects(ctx)
  if #objects == 0 then
    schema.refresh_objects(function(ok, refreshed)
      if ok then
        choose_object(refreshed, function(object)
          if object then
            build_for_object(object, ctx)
          end
        end)
      end
    end)
    return
  end
  choose_object(objects, function(object)
    if object then
      build_for_object(object, ctx)
    end
  end)
end

function M.run_current(tooling, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx = buffer_context(bufnr)
  if not ctx then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or not path:lower():match("%.soql$") then
    notify("Save this query as a .soql file first.", vim.log.levels.ERROR)
    return
  end
  local wrote, write_error = pcall(vim.api.nvim_buf_call, bufnr, function()
    vim.cmd("silent write")
  end)
  if not wrote then
    notify("Could not save query:\n" .. tostring(write_error), vim.log.levels.ERROR)
    return
  end

  local args = {
    "sf",
    "data",
    "query",
    "--target-org",
    ctx.org,
    "--file",
    path,
  }
  if tooling then
    args[#args + 1] = "--use-tooling-api"
  end
  process.run_in_term(args)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_soql_buffers", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "soql",
    callback = function(event)
      attach_buffer(event.buf)
    end,
  })
  if vim.bo.filetype == "soql" then
    attach_buffer(0)
  end
end

M._test = {
  object_from_buffer = object_from_buffer,
  query_lines = query_lines,
}

return M
