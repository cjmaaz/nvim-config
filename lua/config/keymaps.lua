--------------------------------------------------------------------------------
-- Core keymaps (non-plugin). Plugin maps stay in their plugin files.
-- Cheatsheet: docs/KEYMAPS.md
--
-- vim.keymap.set(mode, lhs, rhs, opts?)
--   mode = when it applies ("n"/"i"/"v"/… or { "n", "v" })
--   lhs  = keys you press ("<S-h>", "<leader>bd", …)
--   rhs  = command string, key sequence, or Lua function
--   opts = optional { desc = "…" } (and buffer/silent/…)
--------------------------------------------------------------------------------

local map = vim.keymap.set

-- --- Buffers (not tabpages: leave gt / gT alone) ---

-- Cycle through the buffer list.
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" }) -- Shift+h
-- map("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" }) -- ]b/[b style
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" }) -- Shift+l
-- map("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- Close the current buffer (window often stays; next buffer fills it).
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
-- map("n", "<leader>bd", "<cmd>bdelete!<CR>", { desc = "Delete buffer (force)" }) -- discards unsaved
-- map("n", "<leader>c", "<cmd>bdelete<CR>", { desc = "Delete buffer" }) -- LazyVim-ish letter

-- Optional: wipe vs delete (wipe drops marks/options harder — usually skip for now)
-- map("n", "<leader>bw", "<cmd>bwipeout<CR>", { desc = "Wipe buffer" })

-- --- Small QoL (still core; not a separate topic) ---

-- Clear search highlight (pairs with hlsearch in options).
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Window focus (splits) — different from buffer cycle.
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
