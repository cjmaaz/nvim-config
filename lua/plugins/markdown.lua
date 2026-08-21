--------------------------------------------------------------------------------
-- Markdown rendering — inline decorations plus an optional live side preview.
-- Ref: current LazyVim Markdown extra. Alt: browser markdown-preview.nvim.
--------------------------------------------------------------------------------

local preview_windows = {}

local function toggle_preview()
  local source_buf = vim.api.nvim_get_current_buf()
  local existing = preview_windows[source_buf]
  if existing and vim.api.nvim_win_is_valid(existing) then
    vim.api.nvim_win_close(existing, true)
    preview_windows[source_buf] = nil
    return
  end

  local before = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    before[win] = true
  end
  require("render-markdown").preview()
  vim.schedule(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if not before[win] then
        preview_windows[source_buf] = win
        break
      end
    end
  end)
end

local function set_markdown_maps(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "<leader>mr", function()
    require("render-markdown").buf_toggle()
  end, vim.tbl_extend("force", opts, { desc = "Markdown: toggle rendering" }))
  vim.keymap.set("n", "<leader>mp", toggle_preview, vim.tbl_extend("force", opts, {
    desc = "Markdown: toggle side preview",
  }))
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown.mdx" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    opts = {
      file_types = { "markdown", "markdown.mdx" },
      -- file_types = { "markdown" }, -- standard Markdown only
      heading = {
        sign = false, -- keep the sign column for diagnostics/git only
        -- sign = true, -- repeat heading icons in the sign column
      },
      code = {
        sign = false,
        width = "block", -- calm full-width code background
        -- width = "full", -- extend through all remaining window columns
        right_pad = 1,
      },
      checkbox = {
        enabled = true,
        -- enabled = false, -- show raw [ ] / [x] markers
      },
      pipe_table = {
        style = "full",
        -- style = "normal", -- less decorative table edges
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      local group = vim.api.nvim_create_augroup("render_markdown_maps", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "markdown", "markdown.mdx" },
        callback = function(event)
          set_markdown_maps(event.buf)
        end,
      })
      if vim.bo.filetype == "markdown" or vim.bo.filetype == "markdown.mdx" then
        set_markdown_maps(0)
      end
    end,
  },
}
