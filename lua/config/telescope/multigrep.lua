--------------------------------------------------------------------------------
-- Live multi-grep (TJ DeVries — Advanced Telescope scripting)
-- Prompt: `search text<space><space>glob` e.g. `function  *.lua` or `TODO  **/*.cls`
-- After the double space, optional shortcuts: l→*.lua, a→*.cls, j→*.{js,jsx}, …
-- Ref: https://www.youtube.com/watch?v=xdXE1tOT-qg
--      https://github.com/tjdevries/config.nvim (multi-ripgrep.lua evolved form)
--------------------------------------------------------------------------------

local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")

--- Flatten nested arg lists for rg (tbl_flatten removed in newer Neovim).
local function flatten(tbl)
  if vim.iter then
    return vim.iter(tbl):flatten():totable()
  end
  return vim.tbl_flatten(tbl) -- older Neovim
end

---@param opts table|nil
return function(opts)
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

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil -- wait until the user types something
      end

      -- Double space separates ripgrep pattern from file glob (video behavior).
      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }

      if pieces[1] and pieces[1] ~= "" then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end

      if pieces[2] and pieces[2] ~= "" then
        table.insert(args, "-g")
        local glob = opts.shortcuts[pieces[2]] or pieces[2]
        table.insert(args, string.format(opts.pattern, glob))
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
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = "Live Multi Grep  (pattern  glob)",
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require("telescope.sorters").empty(), -- rg already ordered
    })
    :find()
end
