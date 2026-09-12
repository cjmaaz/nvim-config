--------------------------------------------------------------------------------
-- Salesforce Org Browser nodes — pure inventory slices → Neo-tree node data.
--------------------------------------------------------------------------------

local M = {}

local RETRIEVABLE_STATES = {
  unmanaged = true,
  installedEditable = true,
  deprecatedEditable = true,
}

local function stable_id(context, kind, metadata_type, value)
  local raw = table.concat({
    context.root or "",
    context.org or "",
    kind or "",
    metadata_type or "",
    value or "",
  }, "\0")
  return "sf-org-" .. vim.fn.sha256(raw)
end

local function reference(metadata_type, folder)
  return {
    type = metadata_type,
    folder = folder,
  }
end

local function search_path(context, metadata_type, folder, name)
  local parts = { context.org or "org" }
  local function add(value)
    if value and value ~= "" then
      parts[#parts + 1] = value
    end
  end
  add(metadata_type)
  add(folder)
  add(name)
  return "/" .. table.concat(parts, "/")
end

local function retrievable(member)
  local state = member.manageableState
  return state == nil or state == "" or RETRIEVABLE_STATES[state] == true
end

local function sorted_copy(items)
  local copy = {}
  for index, item in ipairs(items or {}) do
    copy[index] = item
  end
  table.sort(copy, function(a, b)
    return tostring(a.fullName or a.xmlName):lower() < tostring(b.fullName or b.xmlName):lower()
  end)
  return copy
end

local function matches(value, query)
  return query == "" or tostring(value or ""):lower():find(query:lower(), 1, true) ~= nil
end

function M.parse_filter(value)
  local raw = vim.trim(tostring(value or ""))
  if raw == "" then
    return nil
  end
  local slash = raw:find("/", 1, true)
  if not slash then
    return {
      raw = raw,
      category = raw,
    }
  end
  return {
    raw = raw,
    category = vim.trim(raw:sub(1, slash - 1)),
    inner = vim.trim(raw:sub(slash + 1)),
  }
end

local function message_node(context, parent, kind, message, detail)
  return {
    id = stable_id(context, "message", parent.type, table.concat({ parent.folder or "", kind, message }, ":")),
    name = message,
    type = "message",
    extra = {
      kind = kind,
      detail = detail,
      reference = vim.deepcopy(parent),
      search_path = search_path(context, parent.type, parent.folder, message),
    },
  }
end

local function component_node(context, metadata_type, folder, member)
  local full_name = tostring(member.fullName or "")
  local name = folder and (full_name:match("([^/]+)$") or full_name) or full_name
  return {
    id = stable_id(context, "component", metadata_type, full_name),
    name = name,
    type = "file",
    path = full_name,
    extra = {
      kind = "component",
      reference = reference(metadata_type, folder),
      search_path = search_path(context, metadata_type, folder, name),
      member = {
        type = metadata_type,
        fullName = full_name,
        fileName = member.fileName,
        manageableState = member.manageableState,
        namespacePrefix = member.namespacePrefix,
        lastModifiedByName = member.lastModifiedByName,
        lastModifiedDate = member.lastModifiedDate,
        raw = member,
      },
      retrievable = retrievable(member),
    },
  }
end

local function branch_children(context, ref, slice, load_slice, is_loading, inner_query, expand_ids)
  local children = {}
  local loading = is_loading(ref)
  local matched = false

  if slice and slice.error then
    children[#children + 1] = message_node(context, ref, "error", "Refresh failed — press R to retry", slice.error)
  end

  if slice and slice.kind == "folders" then
    local folders = sorted_copy(slice.items)
    for _, folder in ipairs(folders) do
      local folder_name = tostring(folder.fullName or "")
      local folder_ref = reference(ref.type, folder_name)
      local folder_slice = load_slice(folder_ref)
      local folder_matches = inner_query == nil or matches(folder_name, inner_query)
      local child_query = folder_matches and nil or inner_query
      local folder_children, child_matched =
        branch_children(context, folder_ref, folder_slice, load_slice, is_loading, child_query, expand_ids)
      if inner_query == nil or folder_matches or child_matched then
        local folder_id = stable_id(context, "folder", ref.type, folder_name)
        children[#children + 1] = {
          id = folder_id,
          name = folder_name,
          type = "directory",
          loaded = folder_slice and folder_slice.fetched_at ~= nil,
          children = folder_children,
          extra = {
            kind = "folder",
            reference = folder_ref,
            search_path = search_path(context, ref.type, folder_name),
            fetched_at = folder_slice and folder_slice.fetched_at,
            stale = folder_slice and folder_slice.fetched_at ~= nil and folder_slice.stale or false,
            loading = is_loading(folder_ref),
            count = folder_slice and #(folder_slice.items or {}) or nil,
            raw = folder,
          },
        }
        if inner_query ~= nil and folder_children then
          expand_ids[#expand_ids + 1] = folder_id
        end
        matched = true
      end
    end
  elseif slice then
    local members = sorted_copy(slice.items)
    for _, member in ipairs(members) do
      if inner_query == nil or matches(member.fullName, inner_query) then
        children[#children + 1] = component_node(context, ref.type, ref.folder, member)
        matched = true
      end
    end
  end

  if #children == 0 then
    if loading then
      children[1] = message_node(context, ref, "loading", "Loading from org…")
    elseif slice and slice.fetched_at then
      local message = inner_query ~= nil and ("No loaded matches for " .. inner_query) or "No components"
      children[1] = message_node(context, ref, "empty", message)
    else
      return nil, false
    end
  elseif loading then
    table.insert(children, 1, message_node(context, ref, "loading", "Refreshing from org…"))
  end
  return children, matched
end

function M.build(catalog, load_slice, is_loading, filter)
  local context = catalog.context
  local descriptors = sorted_copy(catalog.descriptors)
  local expand_ids = {}

  local type_nodes = {}
  for _, descriptor in ipairs(descriptors) do
    if descriptor.xmlName and (not filter or matches(descriptor.xmlName, filter.category)) then
      local ref = reference(descriptor.xmlName)
      local slice = load_slice(ref)
      local type_id = stable_id(context, "type", descriptor.xmlName)
      local children = branch_children(context, ref, slice, load_slice, is_loading, filter and filter.inner, expand_ids)
      type_nodes[#type_nodes + 1] = {
        id = type_id,
        name = descriptor.xmlName,
        type = "directory",
        loaded = slice and slice.fetched_at ~= nil,
        children = children,
        extra = {
          kind = "metadata_type",
          reference = ref,
          search_path = search_path(context, descriptor.xmlName),
          descriptor = descriptor,
          fetched_at = slice and slice.fetched_at,
          stale = slice and slice.fetched_at ~= nil and slice.stale or false,
          loading = is_loading(ref),
          count = slice and #(slice.items or {}) or nil,
        },
      }
      if filter and filter.inner ~= nil and children then
        expand_ids[#expand_ids + 1] = type_id
      end
    end
  end

  local root_ref = { type = "__catalog__" }
  if catalog.error then
    table.insert(
      type_nodes,
      1,
      message_node(context, root_ref, "error", "Catalog refresh failed — press R to retry", catalog.error)
    )
  end
  if catalog.operation then
    table.insert(type_nodes, 1, message_node(context, root_ref, "loading", catalog.operation))
  end
  if #type_nodes == 0 then
    local empty_message = "No metadata types cached — press R"
    if filter then
      empty_message = "No category matches " .. (filter.category ~= "" and filter.category or "(all categories)")
    end
    type_nodes[1] = message_node(
      context,
      root_ref,
      is_loading(nil) and "loading" or "empty",
      is_loading(nil) and "Loading metadata types…" or empty_message
    )
  elseif is_loading(nil) then
    table.insert(type_nodes, 1, message_node(context, root_ref, "loading", "Refreshing metadata types…"))
  end

  return {
    {
      id = stable_id(context, "org", "", context.org),
      name = context.org,
      type = "org",
      children = type_nodes,
      extra = {
        kind = "org",
        context = context,
        search_path = search_path(context),
        fetched_at = catalog.fetched_at,
        stale = catalog.stale,
        loading = is_loading(nil),
        count = #descriptors,
        filter = filter and filter.raw,
      },
    },
  },
    expand_ids
end

M._test = {
  component_node = component_node,
  retrievable = retrievable,
  stable_id = stable_id,
}

return M
