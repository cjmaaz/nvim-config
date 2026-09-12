--------------------------------------------------------------------------------
-- SObject definitions — staged, project-contained refresh for apex_ls.
--------------------------------------------------------------------------------

local M = {}

local api = vim.api
local uv = vim.uv or vim.loop
local org_context = require("config.salesforce.org_context")
local process = require("config.salesforce.process")
local safety = require("config.salesforce.safety")
local running = false
local generation = 0
local BATCH_CONCURRENCY = 8

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "SObject refresh" })
end

local function is_custom(name)
  return name:match("__c$") ~= nil
    or name:match("__mdt$") ~= nil
    or name:match("__e$") ~= nil
    or name:match("__b$") ~= nil
    or name:match("__x$") ~= nil
end

local function required(name)
  return not name:match("Share$")
    and not name:match("History$")
    and not name:match("Feed$")
    and not name:match(".+Event$")
end

local function restart_apex_ls()
  for _, client in ipairs(vim.lsp.get_clients({ name = "apex_ls" })) do
    local config = client.config
    local attached = {}
    for bufnr in pairs(client.attached_buffers or {}) do
      if api.nvim_buf_is_valid(bufnr) then
        attached[#attached + 1] = bufnr
      end
    end
    client:stop()
    local id = vim.lsp.start(config, { attach = false })
    if id then
      for _, bufnr in ipairs(attached) do
        vim.lsp.buf_attach_client(bufnr, id)
      end
    end
  end
end

local function remove_if_present(project_cap, relative)
  local cap, err = safety.path(project_cap, relative, { allow_missing = true })
  if not cap then
    return nil, err
  end
  if uv.fs_lstat(cap.path) then
    return safety.remove_tree(cap)
  end
  return true
end

local function prepare_staging(project_cap, category)
  local removed, remove_error = remove_if_present(project_cap, ".sfdx/tools/sobjects/.nvim-staging")
  if not removed then
    return nil, remove_error
  end
  local staging, staging_error =
    safety.path(project_cap, ".sfdx/tools/sobjects/.nvim-staging", { allow_missing = true })
  if not staging then
    return nil, staging_error
  end
  staging, staging_error = safety.mkdirs(staging)
  if not staging then
    return nil, staging_error
  end
  for _, name in ipairs({ "standardObjects", "customObjects" }) do
    if
      category == "ALL"
      or (category == "STANDARD" and name == "standardObjects")
      or (category == "CUSTOM" and name == "customObjects")
    then
      local child = safety.path(project_cap, staging.relative .. "/" .. name, { allow_missing = true })
      local made, err
      if child then
        made, err = safety.mkdirs(child)
      else
        err = "Invalid staging directory."
      end
      if not made then
        return nil, err
      end
    end
  end
  return staging
end

local function generated_text(describe)
  local ok, upstream = pcall(require, "sf.sobject")
  local helpers = ok and upstream.__test or nil
  if not helpers then
    return nil, "sf.nvim SObject declaration helpers are unavailable."
  end
  local definition = helpers._generate_sobject_definition(describe)
  return helpers._generate_faux_text(definition)
end

local function write_describe(ctx, staging, describe)
  if type(describe) ~= "table" or type(describe.name) ~= "string" then
    return nil, "Salesforce returned an invalid SObject description."
  end
  local text, text_error = generated_text(describe)
  if not text then
    return nil, text_error
  end
  local custom = describe.custom == true or is_custom(describe.name)
  local subdir = custom and "customObjects" or "standardObjects"
  local path = vim.fs.joinpath(staging.path, subdir, describe.name .. ".cls")
  return safety.atomic_write(ctx.root, path, text)
end

local function commit(ctx, project_cap, staging, category)
  if not org_context.is_current(ctx) then
    return nil, "Target org or Salesforce project changed before SObject definitions were committed."
  end
  local kinds = category == "STANDARD" and { "standardObjects" }
    or category == "CUSTOM" and { "customObjects" }
    or { "standardObjects", "customObjects" }

  local entries = {}
  for _, kind in ipairs(kinds) do
    local target_relative = ".sfdx/tools/sobjects/" .. kind
    local backup_relative = kind == "standardObjects" and ".sfdx/tools/sobjects/.nvim-backup-standard"
      or ".sfdx/tools/sobjects/.nvim-backup-custom"
    local stage, stage_error = safety.path(project_cap, staging.relative .. "/" .. kind)
    local target, target_error = safety.path(project_cap, target_relative, { allow_missing = true })
    local backup, backup_error = safety.path(project_cap, backup_relative, { allow_missing = true })
    if not stage or not target or not backup then
      return nil, stage_error or target_error or backup_error
    end
    local cleaned, clean_error = remove_if_present(project_cap, backup_relative)
    if not cleaned then
      return nil, clean_error
    end
    entries[#entries + 1] = {
      stage = stage,
      target = target,
      backup = backup,
      backup_relative = backup_relative,
      had_target = uv.fs_lstat(target.path) ~= nil,
      old_moved = false,
      new_moved = false,
    }
  end

  for _, entry in ipairs(entries) do
    if entry.had_target then
      local moved, move_error = uv.fs_rename(entry.target.path, entry.backup.path)
      if not moved then
        for _, rollback in ipairs(entries) do
          if rollback.old_moved then
            pcall(uv.fs_rename, rollback.backup.path, rollback.target.path)
          end
        end
        return nil, move_error
      end
      entry.old_moved = true
    end
  end

  for _, entry in ipairs(entries) do
    local installed, install_error = uv.fs_rename(entry.stage.path, entry.target.path)
    if not installed then
      for _, rollback in ipairs(entries) do
        if rollback.new_moved then
          local new_cap = safety.path(project_cap, rollback.target.relative)
          if new_cap then
            safety.remove_tree(new_cap)
          end
        end
      end
      for _, rollback in ipairs(entries) do
        if rollback.old_moved then
          pcall(uv.fs_rename, rollback.backup.path, rollback.target.path)
        end
      end
      return nil, install_error
    end
    entry.new_moved = true
  end

  for _, entry in ipairs(entries) do
    if entry.old_moved then
      local backup_cap = safety.path(project_cap, entry.backup_relative)
      if backup_cap then
        safety.remove_tree(backup_cap)
      end
    end
  end
  local staging_cap = safety.path(project_cap, staging.relative, { allow_missing = true })
  if staging_cap and uv.fs_lstat(staging_cap.path) then
    safety.remove_tree(staging_cap)
  end
  return true
end

local function describe_all(ctx, command_org, project_cap, staging, names, category, opts, token)
  local next_index, active, completed, failure = 1, 0, 0, nil

  local function finish()
    running = false
    if failure then
      remove_if_present(project_cap, staging.relative)
      notify("SObject refresh failed; existing definitions were preserved:\n" .. failure, vim.log.levels.ERROR)
      return
    end
    local committed, commit_error = commit(ctx, project_cap, staging, category)
    if not committed then
      remove_if_present(project_cap, staging.relative)
      notify("SObject refresh was not committed:\n" .. tostring(commit_error), vim.log.levels.ERROR)
      return
    end
    notify(("SObject definitions refreshed (%d objects)."):format(completed))
    if opts.restart_lsp ~= false then
      restart_apex_ls()
    end
    if type(opts.on_done) == "function" then
      opts.on_done(vim.fs.joinpath(ctx.root, ".sfdx", "tools", "sobjects"))
    end
  end

  local launch
  launch = function()
    if token ~= generation then
      failure = "A newer SObject refresh replaced this request."
    end
    while not failure and active < BATCH_CONCURRENCY and next_index <= #names do
      local name = names[next_index]
      next_index = next_index + 1
      active = active + 1
      process.run_sf_json({
        "sf",
        "sobject",
        "describe",
        "--sobject",
        name,
        "--target-org",
        command_org,
        "--json",
      }, { cwd = ctx.root }, function(err, result)
        active = active - 1
        if not failure and err then
          failure = ("%s: %s"):format(name, err)
        elseif not failure then
          local wrote, write_error = write_describe(ctx, staging, result)
          if not wrote then
            failure = ("%s: %s"):format(name, tostring(write_error))
          else
            completed = completed + 1
          end
        end
        if failure and active == 0 or next_index > #names and active == 0 then
          finish()
        else
          launch()
        end
      end)
    end
    if (#names == 0 or failure) and active == 0 then
      finish()
    end
  end
  launch()
end

function M.refresh(opts)
  opts = opts or {}
  if running then
    notify("An SObject refresh is already running.", vim.log.levels.WARN)
    return
  end
  local category = tostring(opts.category or "ALL"):upper()
  if category ~= "ALL" and category ~= "STANDARD" and category ~= "CUSTOM" then
    notify("Use SObject category ALL, STANDARD, or CUSTOM.", vim.log.levels.ERROR)
    return
  end

  local metadata = require("config.salesforce.metadata")
  local ctx = metadata.get_context()
  if not ctx then
    return
  end
  local command_org = type(opts.org) == "string" and vim.trim(opts.org) ~= "" and vim.trim(opts.org) or ctx.org
  local project_cap, cap_error = safety.preflight(ctx.root)
  if not project_cap then
    notify(cap_error, vim.log.levels.ERROR)
    return
  end
  local staging, staging_error = prepare_staging(project_cap, category)
  if not staging then
    notify(staging_error, vim.log.levels.ERROR)
    return
  end

  running = true
  generation = generation + 1
  local token = generation
  notify("Refreshing SObject definitions…")
  process.run_sf_json({
    "sf",
    "sobject",
    "list",
    "--sobject",
    "ALL",
    "--target-org",
    command_org,
    "--json",
  }, { cwd = ctx.root }, function(err, entries)
    if err then
      running = false
      remove_if_present(project_cap, staging.relative)
      notify("Could not list SObjects: " .. err, vim.log.levels.ERROR)
      return
    end
    local names = {}
    for _, entry in ipairs(entries or {}) do
      local name = type(entry) == "string" and entry or entry.name
      if type(name) == "string" and required(name) then
        local custom = is_custom(name)
        if category == "ALL" or category == "CUSTOM" and custom or category == "STANDARD" and not custom then
          names[#names + 1] = name
        end
      end
    end
    table.sort(names)
    if #names == 0 then
      running = false
      remove_if_present(project_cap, staging.relative)
      notify("No SObjects matched category " .. category .. ".", vim.log.levels.WARN)
      return
    end
    describe_all(ctx, command_org, project_cap, staging, names, category, opts, token)
  end)
end

function M.is_running()
  return running
end

M._test = {
  commit = commit,
  is_custom = is_custom,
  prepare_staging = prepare_staging,
  required = required,
  write_describe = write_describe,
}

return M
