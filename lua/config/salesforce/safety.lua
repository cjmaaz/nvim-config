--------------------------------------------------------------------------------
-- Salesforce filesystem safety — project-contained, no-follow cache access.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local removable_roots = {
  ["sf_cache/diffs"] = true,
  [".sfdx/tools/sobjects/standardObjects"] = true,
  [".sfdx/tools/sobjects/customObjects"] = true,
  [".sfdx/tools/sobjects/.nvim-staging"] = true,
  [".sfdx/tools/sobjects/.nvim-backup-standard"] = true,
  [".sfdx/tools/sobjects/.nvim-backup-custom"] = true,
}

local function normalize(path)
  return vim.fs.normalize(path):gsub("/+$", "")
end

local function contained(root, path)
  root, path = normalize(root), normalize(path)
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function canonical_candidate(path)
  path = normalize(path)
  local suffix = {}
  local current = path
  while not uv.fs_realpath(current) do
    local parent = vim.fs.dirname(current)
    if parent == current then
      return path
    end
    table.insert(suffix, 1, vim.fs.basename(current))
    current = parent
  end
  local resolved = normalize(uv.fs_realpath(current))
  for _, component in ipairs(suffix) do
    resolved = vim.fs.joinpath(resolved, component)
  end
  return normalize(resolved)
end

local function components(relative)
  if type(relative) ~= "string" or relative == "" or relative:find("[%z\1-\31\127]") then
    return nil, "Path must be a non-empty relative path without control characters."
  end
  relative = relative:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "")
  local result = {}
  for component in relative:gmatch("[^/]+") do
    if component == "." or component == ".." or component == "" then
      return nil, "Relative Salesforce paths cannot contain `.` or `..`."
    end
    result[#result + 1] = component
  end
  if #result == 0 then
    return nil, "Salesforce path resolves to the project root."
  end
  return result, table.concat(result, "/")
end

local function project(root)
  if type(root) ~= "string" or root == "" then
    return nil, "Salesforce project root is missing."
  end
  local real = uv.fs_realpath(root)
  if not real then
    return nil, "Salesforce project root does not exist."
  end
  real = normalize(real)
  local marker_stat
  for _, marker_name in ipairs({ "sfdx-project.json", ".forceignore" }) do
    local candidate = uv.fs_lstat(vim.fs.joinpath(real, marker_name))
    if candidate and candidate.type == "link" then
      return nil, "Salesforce project markers cannot be symlinks."
    end
    if candidate and candidate.type == "file" then
      marker_stat = candidate
      break
    end
  end
  if not marker_stat then
    return nil, "Salesforce project marker must be a regular, non-symlink file."
  end
  local stat = uv.fs_stat(real)
  return {
    root = real,
    dev = stat and stat.dev,
    ino = stat and stat.ino,
  }
end

local function revalidate_project(cap)
  if type(cap) ~= "table" or type(cap.root) ~= "string" then
    return nil, "Invalid Salesforce project capability."
  end
  local real = uv.fs_realpath(cap.root)
  local stat = real and uv.fs_stat(real) or nil
  if
    not real
    or normalize(real) ~= cap.root
    or not stat
    or (cap.dev and stat.dev ~= cap.dev)
    or (cap.ino and stat.ino ~= cap.ino)
  then
    return nil, "Salesforce project root changed while the operation was pending."
  end
  return true
end

local function validate(cap, relative, opts)
  opts = opts or {}
  local ok, project_error = revalidate_project(cap)
  if not ok then
    return nil, project_error
  end
  local parts, clean_or_error = components(relative)
  if not parts then
    return nil, clean_or_error
  end
  local clean = clean_or_error
  local current = cap.root
  for index, part in ipairs(parts) do
    current = vim.fs.joinpath(current, part)
    local stat = uv.fs_lstat(current)
    if stat then
      if stat.type == "link" then
        return nil, ("Refusing symlink in Salesforce project storage: %s"):format(current)
      end
      if index < #parts and stat.type ~= "directory" then
        return nil, ("Salesforce storage parent is not a directory: %s"):format(current)
      end
      local real = uv.fs_realpath(current)
      if not real or not contained(cap.root, real) then
        return nil, ("Salesforce storage escapes the project: %s"):format(current)
      end
    elseif not opts.allow_missing then
      return nil, ("Salesforce storage path does not exist: %s"):format(current)
    end
  end
  return {
    project = cap,
    relative = clean,
    path = vim.fs.joinpath(cap.root, unpack(parts)),
    removable = removable_roots[clean] == true,
  }
end

local function cap_for(root, path, opts)
  local cap, cap_error = project(root)
  if not cap then
    return nil, cap_error
  end
  local absolute = canonical_candidate(path)
  if not contained(cap.root, absolute) then
    return nil, "Salesforce storage path is outside the project."
  end
  local relative = vim.fs.relpath(cap.root, absolute)
  return validate(cap, relative, opts)
end

local function mkdirs(cap)
  local ok, err = revalidate_project(cap.project)
  if not ok then
    return nil, err
  end
  local current = cap.project.root
  for component in cap.relative:gmatch("[^/]+") do
    current = vim.fs.joinpath(current, component)
    local stat = uv.fs_lstat(current)
    if stat then
      if stat.type == "link" then
        return nil, ("Refusing symlink in Salesforce project storage: %s"):format(current)
      elseif stat.type ~= "directory" then
        return nil, ("Expected Salesforce storage directory: %s"):format(current)
      end
    else
      local made, make_error = uv.fs_mkdir(current, 448)
      if not made and not uv.fs_lstat(current) then
        return nil, make_error
      end
      local created = uv.fs_lstat(current)
      if not created or created.type ~= "directory" then
        return nil, ("Could not create safe Salesforce storage directory: %s"):format(current)
      end
    end
  end
  return validate(cap.project, cap.relative)
end

local function write_bytes(root, path, bytes)
  local target, target_error = cap_for(root, path, { allow_missing = true })
  if not target then
    return false, target_error
  end
  local parent_relative = vim.fs.dirname(target.relative)
  if parent_relative == "." then
    return false, "Salesforce cache files must be stored below a dedicated directory."
  end
  local parent, parent_error = validate(target.project, parent_relative, { allow_missing = true })
  if not parent then
    return false, parent_error
  end
  parent, parent_error = mkdirs(parent)
  if not parent then
    return false, parent_error
  end
  target, target_error = validate(target.project, target.relative, { allow_missing = true })
  if not target then
    return false, target_error
  end

  local tmp = ("%s.tmp.%d.%d"):format(target.path, uv.os_getpid(), uv.hrtime())
  local tmp_cap, tmp_error = cap_for(root, tmp, { allow_missing = true })
  if not tmp_cap then
    return false, tmp_error
  end
  local fd, open_error = uv.fs_open(tmp_cap.path, "wx", 384)
  if not fd then
    return false, open_error
  end
  local written, write_error = uv.fs_write(fd, bytes, 0)
  if written then
    uv.fs_fsync(fd)
  end
  uv.fs_close(fd)
  if not written then
    pcall(uv.fs_unlink, tmp_cap.path)
    return false, write_error
  end

  local rechecked, recheck_error = validate(target.project, target.relative, { allow_missing = true })
  if not rechecked then
    pcall(uv.fs_unlink, tmp_cap.path)
    return false, recheck_error
  end
  local existing = uv.fs_lstat(rechecked.path)
  if existing and existing.type == "link" then
    pcall(uv.fs_unlink, tmp_cap.path)
    return false, "Refusing to replace a Salesforce cache symlink."
  end
  local renamed, rename_error = uv.fs_rename(tmp_cap.path, rechecked.path)
  if not renamed then
    pcall(uv.fs_unlink, tmp_cap.path)
    return false, rename_error
  end
  return true
end

local function remove_node(cap, path)
  local relative = vim.fs.relpath(cap.project.root, path)
  local checked, check_error = validate(cap.project, relative)
  if not checked then
    return nil, check_error
  end
  local stat = uv.fs_lstat(path)
  if not stat then
    return true
  end
  if stat.type == "link" then
    return nil, ("Refusing to follow Salesforce storage symlink: %s"):format(path)
  end
  if stat.type ~= "directory" then
    local removed, error_message = uv.fs_unlink(path)
    return removed and true or nil, error_message
  end
  local scan, scan_error = uv.fs_scandir(path)
  if not scan then
    return nil, scan_error
  end
  while true do
    local name = uv.fs_scandir_next(scan)
    if not name then
      break
    end
    local ok, err = remove_node(cap, vim.fs.joinpath(path, name))
    if not ok then
      return nil, err
    end
  end
  local removed, remove_error = uv.fs_rmdir(path)
  return removed and true or nil, remove_error
end

function M.project(root)
  return project(root)
end

function M.resolve_path(path)
  return type(path) == "string" and path ~= "" and canonical_candidate(path) or nil
end

function M.root_for_path(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end
  local start = uv.fs_stat(path) and path or vim.fs.dirname(path)
  local start_stat = uv.fs_stat(start)
  if start_stat and start_stat.type ~= "directory" then
    start = vim.fs.dirname(start)
  end
  while not uv.fs_stat(start) do
    local parent = vim.fs.dirname(start)
    if parent == start then
      return nil
    end
    start = parent
  end
  local marker = vim.fs.find({ "sfdx-project.json", ".forceignore" }, { path = start, upward = true, type = "file" })[1]
  return marker and normalize(uv.fs_realpath(vim.fs.dirname(marker)) or vim.fs.dirname(marker)) or nil
end

function M.path(project_cap, relative, opts)
  return validate(project_cap, relative, opts)
end

function M.path_for(root, path, opts)
  return cap_for(root, path, opts)
end

function M.mkdirs(cap)
  return mkdirs(cap)
end

function M.atomic_write(root, path, bytes)
  return write_bytes(root, path, bytes)
end

function M.atomic_write_lines(root, path, lines)
  return write_bytes(root, path, table.concat(lines, "\n") .. (#lines > 0 and "\n" or ""))
end

function M.atomic_write_json(root, path, value)
  local ok, encoded = pcall(vim.json.encode, value)
  if not ok then
    return false, encoded
  end
  return write_bytes(root, path, encoded)
end

function M.read_file(root, path)
  local cap, cap_error = cap_for(root, path)
  if not cap then
    return nil, cap_error
  end
  local fd, open_error = uv.fs_open(cap.path, "r", 384)
  if not fd then
    return nil, open_error
  end
  local stat = uv.fs_fstat(fd)
  local data, read_error = uv.fs_read(fd, stat and stat.size or 0, 0)
  uv.fs_close(fd)
  return data, read_error
end

function M.read_json(root, path)
  local data, err = M.read_file(root, path)
  if not data then
    return nil, err
  end
  local ok, decoded = pcall(vim.json.decode, data)
  return ok and decoded or nil, ok and nil or decoded
end

function M.remove_tree(cap)
  if type(cap) ~= "table" or not cap.removable then
    return nil, "Refusing recursive removal outside an approved Salesforce storage subtree."
  end
  if not uv.fs_lstat(cap.path) then
    return true
  end
  return remove_node(cap, cap.path)
end

function M.preflight(root)
  local cap, cap_error = project(root)
  if not cap then
    return nil, cap_error
  end
  for _, relative in ipairs({ "sf_cache", ".sfdx/tools/sobjects" }) do
    local checked, check_error = validate(cap, relative, { allow_missing = true })
    if not checked then
      return nil, check_error
    end
  end
  return cap
end

M._test = {
  components = components,
  contained = contained,
  removable_roots = removable_roots,
}

return M
