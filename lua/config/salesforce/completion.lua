--------------------------------------------------------------------------------
-- Blink source for cached, org-aware SOQL completion. Never calls the org while
-- the user is typing; schema refresh happens through the query builder/actions.
--------------------------------------------------------------------------------

local source = {}
source.__index = source

local schema = require("config.salesforce.schema")

local keywords = {
  "SELECT",
  "FROM",
  "WHERE",
  "AND",
  "OR",
  "NOT",
  "NULL",
  "TRUE",
  "FALSE",
  "GROUP BY",
  "HAVING",
  "ORDER BY",
  "ASC",
  "DESC",
  "NULLS FIRST",
  "NULLS LAST",
  "LIMIT",
  "OFFSET",
  "WITH DATA CATEGORY",
  "FOR UPDATE",
  "TYPEOF",
  "WHEN",
  "THEN",
  "ELSE",
  "END",
  "IN",
  "LIKE",
  "INCLUDES",
  "EXCLUDES",
}

local functions = {
  "AVG",
  "COUNT",
  "COUNT_DISTINCT",
  "MIN",
  "MAX",
  "SUM",
  "CALENDAR_MONTH",
  "CALENDAR_QUARTER",
  "CALENDAR_YEAR",
  "DAY_IN_MONTH",
  "DAY_IN_WEEK",
  "DAY_ONLY",
  "FISCAL_MONTH",
  "FISCAL_QUARTER",
  "FISCAL_YEAR",
  "FORMAT",
  "GROUPING",
  "HOUR_IN_DAY",
  "WEEK_IN_MONTH",
  "WEEK_IN_YEAR",
}

local date_literals = {
  "TODAY",
  "YESTERDAY",
  "TOMORROW",
  "LAST_WEEK",
  "THIS_WEEK",
  "NEXT_WEEK",
  "LAST_MONTH",
  "THIS_MONTH",
  "NEXT_MONTH",
  "LAST_YEAR",
  "THIS_YEAR",
  "NEXT_YEAR",
  "LAST_N_DAYS:",
  "NEXT_N_DAYS:",
  "N_DAYS_AGO:",
}

local function item(label, kind, detail, insert_text)
  return {
    label = label,
    kind = kind,
    detail = detail,
    insertText = insert_text or label,
  }
end

local function buffer_text(bufnr)
  return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
end

local function object_from_query(text)
  local object
  for name in text:gmatch("[Ff][Rr][Oo][Mm]%s+([A-Za-z_][A-Za-z0-9_]*)") do
    object = name
  end
  return object
end

local function last_clause(text)
  local upper = text:upper()
  local clauses = { "SELECT", "FROM", "WHERE", "GROUP BY", "HAVING", "ORDER BY" }
  local selected, position
  for _, clause in ipairs(clauses) do
    local start = 1
    while true do
      local found = upper:find(clause, start, true)
      if not found then
        break
      end
      if not position or found > position then
        selected, position = clause, found
      end
      start = found + #clause
    end
  end
  return selected
end

local function field_allowed(field, clause)
  if clause == "WHERE" or clause == "HAVING" then
    return field.filterable
  end
  if clause == "GROUP BY" then
    return field.groupable
  end
  if clause == "ORDER BY" then
    return field.sortable
  end
  return true
end

local function add_static(items, kinds)
  for _, keyword in ipairs(keywords) do
    items[#items + 1] = item(keyword, kinds.Keyword, "SOQL keyword")
  end
  for _, name in ipairs(functions) do
    items[#items + 1] = item(name, kinds.Function, "SOQL function", name .. "(")
  end
  for _, literal in ipairs(date_literals) do
    items[#items + 1] = item(literal, kinds.Constant, "SOQL date literal")
  end
end

local function add_objects(items, ctx, kinds)
  for _, object in ipairs(schema.load_objects(ctx)) do
    if object.queryable ~= false then
      items[#items + 1] = item(object.name, kinds.Class, object.label or "SObject")
    end
  end
end

local function add_fields(items, described, clause, kinds)
  if not described then
    return
  end
  local seen = {}
  for _, field in ipairs(described.fields or {}) do
    if field_allowed(field, clause) and not seen[field.name] then
      seen[field.name] = true
      local parts = {}
      if field.type and field.type ~= "" then
        parts[#parts + 1] = field.type
      end
      if field.label and field.label ~= "" then
        parts[#parts + 1] = field.label
      end
      local detail = table.concat(parts, " · ")
      items[#items + 1] = item(field.name, kinds.Field, detail)
    end
    if field.relationship_name and not seen[field.relationship_name] then
      seen[field.relationship_name] = true
      items[#items + 1] = item(
        field.relationship_name,
        kinds.Reference,
        "Relationship → " .. table.concat(field.reference_to or {}, ", ")
      )
    end
  end
end

local function relationship_fields(items, described, relationship, ctx, kinds)
  if not described then
    return false
  end
  for _, field in ipairs(described.fields or {}) do
    if field.relationship_name and field.relationship_name:lower() == relationship:lower() then
      local target = field.reference_to and field.reference_to[1]
      local related = target and schema.load_describe(target, ctx) or nil
      if related then
        add_fields(items, related, "SELECT", kinds)
        return true
      end
    end
  end
  return false
end

function source.new()
  return setmetatable({}, source)
end

function source:enabled()
  return vim.bo.filetype == "soql"
end

function source:get_trigger_characters()
  return { "." }
end

function source:get_completions(_, callback)
  local kinds = require("blink.cmp.types").CompletionItemKind
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line():sub(1, cursor[2])
  local text = buffer_text(bufnr)
  local ctx = schema.context_for_buffer(bufnr)
  local object_name = vim.b[bufnr].soql_object or object_from_query(text)
  local described = object_name and schema.load_describe(object_name, ctx) or nil
  local items = {}

  local relationship = current_line:match("([A-Za-z_][A-Za-z0-9_]*)%.[A-Za-z0-9_]*$")
  if relationship and relationship_fields(items, described, relationship, ctx, kinds) then
    callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local upper_line = current_line:upper()
  if upper_line:match("FROM%s+[A-Z0-9_]*$") or upper_line:match("FROM%s*$") then
    add_objects(items, ctx, kinds)
  else
    add_fields(items, described, last_clause(text), kinds)
    add_static(items, kinds)
  end

  callback({
    items = items,
    is_incomplete_forward = false,
    is_incomplete_backward = false,
  })
end

source._test = {
  field_allowed = field_allowed,
  last_clause = last_clause,
  object_from_query = object_from_query,
}

return source
