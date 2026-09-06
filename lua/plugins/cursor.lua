--------------------------------------------------------------------------------
-- Cursor animation — smear-cursor (Neovide-like movement in terminal Neovim)
-- Ref landscape: current LazyVim extra; absent from our four pinned references.
-- Alts: SmoothCursor.nvim (decorative trail) · mini.animate (cursor + UI motion).
--------------------------------------------------------------------------------

return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    cond = vim.g.neovide == nil, -- Neovide already provides native cursor animation
    -- cond = true, -- also enable inside graphical Neovim clients
    opts = {
      -- Animate long jumps between buffers and windows.
      smear_between_buffers = true,
      -- smear_between_buffers = false, -- animate only within the current buffer

      -- Keep ordinary hjkl movement calm; enable for the full smear effect.
      smear_between_neighbor_lines = false,
      -- smear_between_neighbor_lines = true, -- animate nearby line movement too

      -- Keep the trail attached to buffer text while scrolling.
      scroll_buffer_space = true,
      -- scroll_buffer_space = false, -- draw in fixed screen coordinates

      -- Avoid animation noise while typing.
      smear_insert_mode = false,
      -- smear_insert_mode = true, -- animate insert-mode cursor movement

      -- Keep the animation on the active theme's Cursor color.
      cursor_color = "Cursor",
      -- cursor_color = "none", -- borrow the syntax color beneath the target

      -- LazyVim-style target handling: hide the real cursor under the animation.
      hide_target_hack = true,

      -- Use blockier portable symbols unless the active font supports Symbols
      -- for Legacy Computing (U+1FB00–U+1FBFF).
      legacy_computing_symbols_support = false,
      -- legacy_computing_symbols_support = true, -- smoother trail with a supporting font
    },
    config = function(_, opts)
      local themed_guicursor = vim.o.guicursor
      require("smear_cursor").setup(opts)

      -- This target-hiding method draws a cell; it does not need the plugin's
      -- empty SmearCursorHideable group to replace the themed cursor color.
      if opts.hide_target_hack then
        vim.o.guicursor = themed_guicursor
      end
    end,
  },
}
