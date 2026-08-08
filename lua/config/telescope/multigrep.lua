--------------------------------------------------------------------------------
-- Live multi-grep + file-glob mode (TJ DeVries-inspired Telescope scripting)
-- Content: `search text<space><space>glob` e.g. `function  *.lua`.
-- Files: start with two spaces, then a path glob e.g. `  **/abc/**/*xyz*`.
-- Content-mode shortcuts: l→*.lua, a→*.cls, j→*.{js,jsx}, …
-- Ref: https://www.youtube.com/watch?v=xdXE1tOT-qg
--      https://github.com/tjdevries/config.nvim (multi-ripgrep.lua evolved form)
--------------------------------------------------------------------------------

local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")

local M = {}

--- Flatten nested arg lists for rg (tbl_flatten removed in newer Neovim).
local function flatten(tbl)
  if vim.iter then
    return vim.iter(tbl):flatten():totable()
  end
  return vim.tbl_flatten(tbl) -- older Neovim
end

--- Split only on the first literal double-space delimiter.
---@param prompt string|nil
---@return table
function M.parse_prompt(prompt)
  prompt = prompt or ""
  local delimiter = prompt:find("  ", 1, true)

  if not delimiter then
    return { mode = "grep", pattern = prompt }
  end

  local before = prompt:sub(1, delimiter - 1)
  local after = prompt:sub(delimiter + 2)
  if before == "" then
    return { mode = "files", glob = after }
  end

  return { mode = "grep", pattern = before, glob = after }
end

--- Globs use the same smart-case rule as search text.
---@param glob string
---@return string
function M.glob_flag(glob)
  return glob:find("%u") and "-g" or "--iglob"
end

---@param parsed table
---@param opts table
---@return string[]|nil
function M.grep_args(parsed, opts)
  if parsed.mode ~= "grep" or not parsed.pattern or parsed.pattern == "" then
    return nil
  end

  local args = { "rg", "-e", parsed.pattern }
  if parsed.glob and parsed.glob ~= "" then
    local glob = opts.shortcuts[parsed.glob] or parsed.glob
    vim.list_extend(args, { M.glob_flag(glob), string.format(opts.pattern, glob) })
  end

  return flatten({
    args,
    {
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },
  })
end

---@param parsed table
---@return string[]|nil
function M.file_args(parsed)
  if parsed.mode ~= "files" or not parsed.glob or parsed.glob == "" then
    return nil
  end

  return { "rg", "--files", "--color=never", "--null", M.glob_flag(parsed.glob), parsed.glob }
end

local function new_grep_finder(opts)
  return finders.new_async_job({
    command_generator = function(prompt)
      return M.grep_args(M.parse_prompt(prompt), opts)
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })
end

local function new_file_finder(opts, parsed)
  local args = M.file_args(parsed)
  if not args then
    return finders.new_table({ results = {} })
  end

  return finders.new_oneshot_job(args, {
    cwd = opts.cwd,
    split_char = "\0",
    entry_maker = make_entry.gen_from_file(opts),
  })
end

---@param opts table|nil
function M.open(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or (vim.uv or vim.loop).cwd()

  -- Second prompt piece (after "  ") can be a short alias instead of a raw glob.
  opts.shortcuts = opts.shortcuts
    or {
      l = "*.lua",
      v = "*.vim",
      n = "*.{vim,lua}",
      c = "*.{c,h,cpp,hpp}",
      r = "*.rs",
      g = "*.go",
      j = "*.{js,jsx,ts,tsx}",
      a = "*.{cls,trigger,apex}", -- Apex
      h = "*.{html,htm,cmp}", -- LWC / Aura markup-ish
      p = "*.py",
      m = "*.md",
      -- ["tsx"] = "*.tsx", -- redundant if you type the glob yourself
    }
  -- How the glob/shortcut is passed to `rg -g` (default: as-is).
  opts.pattern = opts.pattern or "%s"
  -- opts.pattern = "**/{}/**" -- alternate wrapping (rarely needed)

  local grep_finder = new_grep_finder(opts)
  local current_mode = "grep"

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = "Live Multi Grep  (pattern  glob)",
      finder = grep_finder,
      previewer = conf.grep_previewer(opts),
      sorter = require("telescope.sorters").empty(), -- rg already ordered
      on_input_filter_cb = function(prompt)
        local parsed = M.parse_prompt(prompt)
        if parsed.mode == "files" then
          current_mode = "files"
          return {
            prompt = "",
            updated_finder = new_file_finder(opts, parsed),
          }
        end

        if current_mode == "files" then
          current_mode = "grep"
          grep_finder = new_grep_finder(opts)
          return {
            prompt = prompt, -- grep finder must receive `pattern  glob`, not only pattern
            updated_finder = grep_finder,
          }
        end

        return {} -- preserve the full grep prompt so command_generator sees its glob
      end,
    })
    :find()
end

return M
