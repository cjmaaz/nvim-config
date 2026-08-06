--------------------------------------------------------------------------------
-- Undotree — visual undo history (pairs with opt.undofile = true)
-- Refs: none of the four refs require it; classic QoL for bad edits / FoS surprises.
-- Pick: mbbill/undotree (mature Vimscript UI). Alts: neovim undo in :earlier ·
--   debugloop/telescope-undo.nvim · snacks.explorer undo.
-- Cheatsheet: docs/keymaps/qol.md · requires lua/config/options.lua undofile = true
--------------------------------------------------------------------------------

return {
  {
    "mbbill/undotree",

    -- Load on command / key (plugin is Vimscript; no need at startup).
    cmd = {
      "UndotreeToggle",
      -- "UndotreeShow",
      -- "UndotreeHide",
      -- "UndotreeFocus",
    },
    -- event = "VeryLazy",

    keys = {
      -- Toggle the undo tree + (optional) diff panel.
      { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Undotree toggle" },
      -- { "<leader>u", "<cmd>UndotreeFocus<CR>", desc = "…" }, -- focus only if already open
      -- { "<leader>U", "<cmd>UndotreeToggle<CR>", desc = "…" }, -- capital if u feels crowded
    },

    -- Vimscript globals must be set before the plugin loads → use `init`.
    init = function()
      -- Layout of the undotree window (see :h undotree):
      --   1 = left + diff below (common)
      --   2 = left + diff left? / variant — check :h undotree-WindowLayout
      --   3 = right side tree
      --   4 = bottom
      -- vim.g.undotree_WindowLayout = 1 -- default-ish
      -- vim.g.undotree_WindowLayout = 2 -- alternate split arrangement
      -- vim.g.undotree_WindowLayout = 3 -- tree on the right
      -- vim.g.undotree_WindowLayout = 4 -- tree along the bottom

      -- Move cursor into the undotree window when toggled open.
      -- vim.g.undotree_SetFocusWhenToggle = 0 -- default: stay in the code window
      -- vim.g.undotree_SetFocusWhenToggle = 1 -- jump to the tree (keyboard browse)

      -- Show the side-by-side diff panel for the selected undo node.
      vim.g.undotree_DiffAutoOpen = 1 -- on (easier to see what an undo step did)
      -- vim.g.undotree_DiffAutoOpen = 0 -- tree only (more screen space)

      -- Short relative timestamps vs absolute.
      -- vim.g.undotree_RelativeTimestamp = 1 -- e.g. “5 seconds ago”
      -- vim.g.undotree_RelativeTimestamp = 0 -- absolute time

      -- Compact tree glyphs (needs a capable font).
      -- vim.g.undotree_TreeNodeShape = "*"
      -- vim.g.undotree_TreeVertShape = "|"
      -- vim.g.undotree_TreeSplitShape = "/"
      -- vim.g.undotree_TreeReturnShape = "\\"

      -- Help text at the top of the undotree buffer.
      -- vim.g.undotree_HelpLine = 1 -- show
      -- vim.g.undotree_HelpLine = 0 -- hide once you know the keys

      -- Split size hints:
      -- vim.g.undotree_SplitWidth = 30
      -- vim.g.undotree_DiffpanelHeight = 10
    end,
  },
}
