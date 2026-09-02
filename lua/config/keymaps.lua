--------------------------------------------------------------------------------
-- Core keymaps (non-plugin). Plugin maps stay in their plugin files.
-- Cheatsheet: docs/keymaps/ (see README.md index)
--
-- vim.keymap.set(mode, lhs, rhs, opts?)
--   mode = when it applies (string or list). Common values:
--     "n" = normal    "i" = insert    "v" = visual (select + visual)
--     "x" = visual only    "o" = operator-pending    "t" = terminal
--     "c" = command-line    { "n", "v" } = several modes at once
--   lhs  = keys you press ("<S-h>", "<leader>bd", "<Esc><Esc>", …)
--   rhs  = command string, key sequence, or Lua function
--   opts = optional { desc = "…" } (and buffer/silent/…)
--------------------------------------------------------------------------------

local map = vim.keymap.set

-- --- Buffers (not tabpages: leave gt / gT alone) ---

-- Cycle through the buffer list.
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" }) -- Shift+h
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" }) -- Shift+l

-- Unimpaired-style ]/[ families (same color within a/A and b/B in which-key).
map("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
-- Uppercase [B/]B are owned by bufferline.lua for visual reordering.
-- map("n", "]B", "<cmd>blast<CR>", { desc = "Last buffer" }) -- previous behavior
-- map("n", "[B", "<cmd>bfirst<CR>", { desc = "First buffer" }) -- previous behavior
map("n", "]a", "<cmd>next<CR>", { desc = "Next argument" })
map("n", "[a", "<cmd>previous<CR>", { desc = "Previous argument" })
map("n", "]A", "<cmd>last<CR>", { desc = "Last argument" })
map("n", "[A", "<cmd>first<CR>", { desc = "First argument" })

-- Close the current buffer (window often stays; next buffer fills it).
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
-- map("n", "<leader>bd", "<cmd>bdelete!<CR>", { desc = "Delete buffer (force)" }) -- discards unsaved
-- map("n", "<leader>c", "<cmd>bdelete<CR>", { desc = "Delete buffer" }) -- LazyVim-ish letter

local function delete_file_buffers(scope)
  local current = vim.api.nvim_get_current_buf()
  local visible = {}
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      visible[vim.api.nvim_win_get_buf(win)] = true
    end
  end

  local deleted, modified, failed = 0, 0, 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local is_file = vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
    local selected = scope == "others" or not visible[buf]

    if buf ~= current and is_file and selected then
      if vim.bo[buf].modified then
        modified = modified + 1
      elseif pcall(vim.api.nvim_buf_delete, buf, {}) then
        deleted = deleted + 1
      else
        failed = failed + 1
      end
    end
  end

  local message = string.format("Deleted %d %s buffer(s)", deleted, scope)
  if modified > 0 then
    message = message .. string.format("; kept %d modified", modified)
  end
  if failed > 0 then
    message = message .. string.format("; %d could not close", failed)
  end
  vim.notify(message, failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO, { title = "Buffers" })
end

-- Close saved file buffers while preserving edits, terminals, and special UI.
map("n", "<leader>bo", function()
  delete_file_buffers("others")
end, { desc = "Delete other buffers" })
map("n", "<leader>bi", function()
  delete_file_buffers("hidden")
end, { desc = "Delete hidden buffers" })

-- Optional: wipe vs delete (wipe drops marks/options harder — usually skip for now)
-- map("n", "<leader>bw", "<cmd>bwipeout<CR>", { desc = "Wipe buffer" })

-- --- Project scaffolding ---

-- Pick an ecosystem, collect its inputs, then run the maintained generator CLI.
map("n", "<leader>pn", function()
  require("config.project_scaffold").open()
end, { desc = "Project: new scaffold" })

-- Detect the nearest project and choose a Run / Build / Test action.
map("n", "<leader>pr", function()
  require("config.project_runner").open()
end, { desc = "Project: run/build/test" })

-- --- Gremlins (dangerous invisible / confusable Unicode) ---

map("n", "<leader>tg", function()
  require("config.gremlins").toggle()
end, { desc = "Toggle Gremlins tracker" })

map("n", "<leader>tG", function()
  require("config.gremlins").quickfix()
end, { desc = "Gremlins quickfix" })

-- --- Small QoL (still core; not a separate topic) ---

-- Clear search highlight (pairs with hlsearch in options).
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Toggle soft wrapping in the current window without changing the file.
map("n", "<leader>tw", function()
  local enabled = not vim.wo.wrap
  vim.wo.wrap = enabled
  if enabled then
    vim.wo.linebreak = true
    vim.wo.breakindent = true
  end
  vim.notify("Word wrap " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO, { title = "Options" })
end, { desc = "Toggle word wrap" })
-- map("n", "<leader>uw", "<cmd>setlocal wrap!<CR>", { desc = "Toggle word wrap" }) -- LazyVim; u is Undotree here

-- Window focus (splits) — different from buffer cycle.
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })

-- Craftzdog-style split create / focus (also keep <C-hjkl> above).
-- Note: chords start with `s`, so after timeoutlen which-key may list them;
-- stock one-key `s` (substitute) still works if you type the replacement quickly.
map("n", "ss", "<cmd>split<CR>", { desc = "Split horizontal" })
map("n", "sv", "<cmd>vsplit<CR>", { desc = "Split vertical" })
-- map("n", "ss", "<C-w>s", { desc = "Split horizontal" }) -- same via Ctrl-w
-- map("n", "sv", "<C-w>v", { desc = "Split vertical" })
map("n", "sh", "<C-w>h", { desc = "Focus left window" })
map("n", "sl", "<C-w>l", { desc = "Focus right window" })
map("n", "sj", "<C-w>j", { desc = "Focus lower window" })
map("n", "sk", "<C-w>k", { desc = "Focus upper window" })
-- map("n", "te", "<cmd>tabedit<CR>", { desc = "New tabpage" }) -- Craftzdog; we prefer buffers

-- --- Black-hole deletes (don’t clobber the default yank register) ---
-- Refs: Craftzdog keymaps.lua. Skip <leader>c* — that prefix is Code (cf/cl/ca).
map("n", "x", '"_x', { desc = "Delete char (black hole)" })
-- map("n", "x", "x", { desc = "Delete char (into register)" }) -- stock
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete (black hole)" })
map("n", "<leader>D", '"_D', { desc = "Delete to EOL (black hole)" })
-- map({ "n", "v" }, "<leader>d", "d", { desc = "Delete (into register)" }) -- stock d under leader
-- Paste from yank register 0 after a black-hole delete (Craftzdog <leader>p):
-- map({ "n", "v" }, "<leader>p", '"0p', { desc = "Paste from yank register" })
-- map("n", "<leader>P", '"0P', { desc = "Paste before from yank register" })

-- --- Motion comfort (keep cursor centered) ---

-- Search next/prev, then recenter + open folds if needed.
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
-- map("n", "n", "n", { desc = "Next search result" }) -- stock Vim (no recenter)

-- Half-page scroll, then recenter.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
-- map("n", "<C-d>", "<C-d>", { desc = "Half page down" }) -- stock (no recenter)

-- --- Visual: move selected lines ---

-- Move the visual selection down/up without dropping the selection.
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
-- Note: overrides visual-mode J (join) / K (keyword lookup). Join in visual → :join
-- map("v", "J", "J", { desc = "Join lines" }) -- restore stock if you prefer

-- --- Terminal ---
-- Enter with :terminal (or :split | terminal / :vsplit | terminal) — not :!
-- :!cmd runs once in the shell and returns; :terminal opens an interactive job buffer.

-- Built-in leave is <C-\><C-n>; double Esc is easier to discover.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" }) -- single Esc (can fight TUI apps)

-- --- Diagnostics (work before LSP; empty until a server/linter reports) ---
-- Refs: CodeOSS keymaps.lua; Kickstart diagnostic.config + <leader>q.
-- Alts: Craftzdog <C-j> next-diag (we keep <C-j> for windows) · wait until LSP file.

vim.diagnostic.config({
  update_in_insert = false, -- don't spam while typing
  -- update_in_insert = true,
  severity_sort = true, -- errors before hints in lists/floats
  float = { border = "rounded", source = "if_many" },
  underline = { severity = { min = vim.diagnostic.severity.WARN } }, -- skip hint underlines
  -- underline = true, -- underline every severity
  virtual_text = true, -- message at end of line
  -- virtual_text = false,
  -- virtual_lines = true, -- Kickstart alt: under the line (noisier)
  signs = {
    text = vim.g.have_nerd_font and {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.INFO] = "󰋽",
      [vim.diagnostic.severity.HINT] = "󰌶",
    } or {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
  -- Prefer on_jump over jump float=true (float opt deprecated toward 0.14).
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({
        bufnr = bufnr,
        scope = "cursor",
        focus = false,
      })
    end,
  },
})

-- Hide/show end-of-line messages while keeping signs, underlines, and floats.
local previous_virtual_text
map("n", "<leader>td", function()
  local current = vim.diagnostic.config().virtual_text
  if current == false then
    vim.diagnostic.config({ virtual_text = previous_virtual_text or true })
    vim.notify("Inline diagnostics enabled", vim.log.levels.INFO, { title = "Diagnostics" })
  else
    previous_virtual_text = current
    vim.diagnostic.config({ virtual_text = false })
    vim.notify("Inline diagnostics disabled", vim.log.levels.INFO, { title = "Diagnostics" })
  end
end, { desc = "Toggle inline diagnostics" })

map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
-- map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" }) -- deprecated API

map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
-- Diagnostic **lists** live in Trouble now (`lua/plugins/trouble.lua`):
--   <leader>xx  workspace diagnostics
--   <leader>xX  buffer diagnostics
--   <leader>xl  location list
--   <leader>xq  quickfix
-- map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" }) -- old; clashes with sessions
-- map("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Diagnostic quickfix" }) -- global qflist
-- <leader>q… → persistence sessions (`lua/plugins/persistence.lua`).

-- --- hjkl training (arrows do not move) ---

map("n", "<left>", '<cmd>echo "Use h to move!"<CR>', { desc = "Remind: use h" })
map("n", "<right>", '<cmd>echo "Use l to move!"<CR>', { desc = "Remind: use l" })
map("n", "<up>", '<cmd>echo "Use k to move!"<CR>', { desc = "Remind: use k" })
map("n", "<down>", '<cmd>echo "Use j to move!"<CR>', { desc = "Remind: use j" })
-- To allow arrows again, delete or comment the four lines above.
