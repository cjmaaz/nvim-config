--------------------------------------------------------------------------------
-- Grug Far — reviewable project-wide search and replace over ripgrep.
-- Telescope remains the finder; this owns applying replacements.
-- Ref: current LazyVim default. None of the other local refs ships an equivalent.
-- Alts: nvim-rip-substitute (smaller UI) · ssr.nvim (structural, buffer-focused).
--------------------------------------------------------------------------------

return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      {
        "<leader>sR",
        function()
          -- Visual mode pre-fills the selected text; Normal starts empty.
          require("grug-far").open({ transient = true })
        end,
        mode = { "n", "x" },
        desc = "Search and replace",
      },
    },
    opts = {},
  },
}
