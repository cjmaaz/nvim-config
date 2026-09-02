--------------------------------------------------------------------------------
-- Guess Indent — adapt buffer-local indentation to the file being opened.
-- Built-in EditorConfig stays authoritative; options.lua supplies the fallback.
-- Refs: CodeOSS + Kickstart use guess-indent; no equivalent in the other refs.
-- Alts: vim-sleuth (smarter/slower Vimscript) · indent-o-matic (simpler heuristic).
--------------------------------------------------------------------------------

return {
  {
    "NMAC427/guess-indent.nvim",
    -- Load before the plugin's BufReadPost scan; blank new files keep defaults.
    event = { "BufReadPre", "BufNewFile" },
    -- event = "VeryLazy", -- lighter startup hook, but can miss the first opened buffer
    cmd = "GuessIndent", -- allow a manual re-scan
    opts = {
      -- Detect indentation automatically for normal file buffers.
      auto_cmd = true,
      -- auto_cmd = false, -- only detect when :GuessIndent is run

      -- Respect a repository's .editorconfig when it defines indentation.
      override_editorconfig = false,
      -- override_editorconfig = true, -- prefer sampled file contents instead
    },
  },
}
