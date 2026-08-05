  --------------------------------------------
  --- TBD ---
  --------------------------------------------


  -- Scoped Variable
  local opt = vim.opt


  -- Hides -- INSERT -- in the command line so the statusline can own mode.
  opt.showmode = false

  -- One statusline for the whole UI (not one per split). 2 = per-window.
  opt.laststatus = 3

  -- Always reserve the gutter so git signs don't shift text later.
  opt.signcolumn = "yes"

