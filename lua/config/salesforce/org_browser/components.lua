--------------------------------------------------------------------------------
-- Salesforce Org Browser renderers — compact Bordo-themed tree components.
--------------------------------------------------------------------------------

local M = {}
local common = require("neo-tree.sources.common.components")

M.indent = common.indent

local function age(timestamp)
  if not timestamp then
    return nil
  end
  local seconds = math.max(os.time() - timestamp, 0)
  if seconds < 60 then
    return "<1m"
  elseif seconds < 3600 then
    return string.format("%dm", math.floor(seconds / 60))
  elseif seconds < 86400 then
    return string.format("%dh", math.floor(seconds / 3600))
  end
  return string.format("%dd", math.floor(seconds / 86400))
end

function M.apply_highlights()
  local chrome = require("config.ui_chrome")
  local hl = vim.api.nvim_set_hl
  hl(0, "SFOrgBrowserOrg", { fg = chrome.title_fg, bg = chrome.panel_bg, bold = true })
  hl(0, "SFOrgBrowserType", { fg = chrome.border_fg, bg = chrome.panel_bg, bold = true })
  hl(0, "SFOrgBrowserFolder", { fg = chrome.rose, bg = chrome.panel_bg })
  hl(0, "SFOrgBrowserComponent", { fg = chrome.foam, bg = chrome.panel_bg })
  hl(0, "SFOrgBrowserMuted", { fg = chrome.muted_fg, bg = chrome.panel_bg })
  hl(0, "SFOrgBrowserLoading", { fg = chrome.gold, bg = chrome.panel_bg, italic = true })
  hl(0, "SFOrgBrowserError", { fg = chrome.love, bg = chrome.panel_bg })
  hl(0, "SFOrgBrowserReadonly", { fg = chrome.dimmed3, bg = chrome.panel_bg, italic = true })
end

local ICONS = {
  org = "󰢎",
  metadata_type = "󰆦",
  folder = "󰉋",
  component = "󰈙",
  loading = "󰔟",
  empty = "󰅖",
  error = "󰅚",
}

function M.icon(_, node)
  local extra = node.extra or {}
  local kind = extra.kind
  local highlight = "SFOrgBrowserMuted"
  if kind == "org" then
    highlight = "SFOrgBrowserOrg"
  elseif kind == "metadata_type" then
    highlight = "SFOrgBrowserType"
  elseif kind == "folder" then
    highlight = "SFOrgBrowserFolder"
  elseif kind == "component" then
    highlight = extra.retrievable and "SFOrgBrowserComponent" or "SFOrgBrowserReadonly"
  elseif kind == "loading" then
    highlight = "SFOrgBrowserLoading"
  elseif kind == "error" then
    highlight = "SFOrgBrowserError"
  end
  return {
    text = (ICONS[kind] or "·") .. " ",
    highlight = highlight,
  }
end

function M.name(_, node)
  local extra = node.extra or {}
  local highlights = {
    org = "SFOrgBrowserOrg",
    metadata_type = "SFOrgBrowserType",
    folder = "SFOrgBrowserFolder",
    component = extra.retrievable and "SFOrgBrowserComponent" or "SFOrgBrowserReadonly",
    loading = "SFOrgBrowserLoading",
    empty = "SFOrgBrowserMuted",
    error = "SFOrgBrowserError",
  }
  return {
    text = node.name or "",
    highlight = highlights[extra.kind] or "SFOrgBrowserMuted",
  }
end

function M.status(_, node)
  local extra = node.extra or {}
  if extra.kind == "component" and not extra.retrievable then
    return {
      text = "  read-only",
      highlight = "SFOrgBrowserReadonly",
    }
  end
  if not vim.tbl_contains({ "org", "metadata_type", "folder" }, extra.kind) then
    return {}
  end

  local pieces = {}
  if extra.count ~= nil then
    pieces[#pieces + 1] = tostring(extra.count)
  end
  local fetched_age = age(extra.fetched_at)
  if fetched_age then
    pieces[#pieces + 1] = fetched_age
  end
  if extra.loading then
    pieces[#pieces + 1] = "refreshing"
  elseif extra.stale then
    pieces[#pieces + 1] = "stale"
  end
  if #pieces == 0 then
    return {}
  end
  return {
    text = "  " .. table.concat(pieces, " · "),
    highlight = extra.loading and "SFOrgBrowserLoading" or "SFOrgBrowserMuted",
  }
end

M._test = {
  age = age,
}

return M
