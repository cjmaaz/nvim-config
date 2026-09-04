--------------------------------------------------------------------------------
-- Neogen — generate Javadoc, Doxygen, docstrings, and related annotations.
-- Command/key lazy-loaded: no startup or editing-loop work until requested.
-- Refs: none active; LazyVim offers the same <leader>cn command-lazy extra.
-- Apex reuses Javadoc because its Treesitter declaration nodes mirror Java.
--------------------------------------------------------------------------------

local function apex_configuration()
  local apex = vim.deepcopy(require("neogen.configurations.java"))
  local class_extractor = apex.data.class.class_declaration

  -- Apex adds these top-level declarations beyond Java's class/interface nodes.
  for _, node_type in ipairs({ "enum_declaration", "trigger_declaration" }) do
    apex.parent.class[#apex.parent.class + 1] = node_type
    apex.data.class[node_type] = vim.deepcopy(class_extractor)
  end

  return apex
end

return {
  {
    "danymat/neogen",
    cmd = "Neogen", -- :Neogen [func|class|type|file]
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
    },
    keys = {
      {
        "<leader>cn",
        function()
          require("neogen").generate()
        end,
        desc = "Generate documentation",
      },
    },
    opts = function()
      local apex = apex_configuration()
      return {
        snippet_engine = "luasnip", -- jump through generated placeholders
        -- snippet_engine = "nvim", -- native snippets; avoids loading LuaSnip here
        input_after_comment = true, -- enter the first editable description
        -- input_after_comment = false, -- remain in Normal mode after generation
        languages = {
          apex = apex,
          apexcode = vim.deepcopy(apex),
        },
      }
    end,
  },
}
