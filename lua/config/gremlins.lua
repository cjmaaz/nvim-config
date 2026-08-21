--------------------------------------------------------------------------------
-- Gremlins tracker — reveal dangerous invisible and ASCII-lookalike Unicode.
-- Diagnostics only: never rewrites or normalizes buffer content.
--------------------------------------------------------------------------------

local M = {}

local uv = vim.uv or vim.loop
local ns_highlight = vim.api.nvim_create_namespace("user_gremlins_highlight")
local ns_diagnostic = vim.api.nvim_create_namespace("user_gremlins_diagnostic")
local debounce_tokens = {}
local MAX_FILE_SIZE = 1024 * 1024

local allowed_filetypes = {
  apex = true,
  apexcode = true,
  bash = true,
  c = true,
  cmake = true,
  cpp = true,
  css = true,
  dart = true,
  dockerfile = true,
  go = true,
  html = true,
  java = true,
  javascript = true,
  javascriptreact = true,
  json = true,
  jsonc = true,
  lua = true,
  make = true,
  python = true,
  rust = true,
  scss = true,
  sh = true,
  soql = true,
  sosl = true,
  sql = true,
  toml = true,
  typescript = true,
  typescriptreact = true,
  vim = true,
  vue = true,
  xml = true,
  yaml = true,
  zsh = true,
}

local confusables = {
  -- Greek capitals.
  [0x0391] = "A",
  [0x0392] = "B",
  [0x0395] = "E",
  [0x0396] = "Z",
  [0x0397] = "H",
  [0x0399] = "I",
  [0x039A] = "K",
  [0x039C] = "M",
  [0x039D] = "N",
  [0x039F] = "O",
  [0x03A1] = "P",
  [0x03A4] = "T",
  [0x03A5] = "Y",
  [0x03A7] = "X",
  [0x03BF] = "o",
  [0x03C1] = "p",

  -- Cyrillic capitals and lower-case letters commonly used in identifiers.
  [0x0405] = "S",
  [0x0406] = "I",
  [0x0408] = "J",
  [0x0410] = "A",
  [0x0412] = "B",
  [0x0415] = "E",
  [0x041A] = "K",
  [0x041C] = "M",
  [0x041D] = "H",
  [0x041E] = "O",
  [0x0420] = "P",
  [0x0421] = "C",
  [0x0422] = "T",
  [0x0425] = "X",
  [0x0423] = "Y",
  [0x0430] = "a",
  [0x0435] = "e",
  [0x043E] = "o",
  [0x0440] = "p",
  [0x0441] = "c",
  [0x0443] = "y",
  [0x0445] = "x",
  [0x0455] = "s",
  [0x0456] = "i",
  [0x0458] = "j",
}

local invisible_names = {
  [0x00A0] = "non-breaking space",
  [0x00AD] = "soft hyphen",
  [0x034F] = "combining grapheme joiner",
  [0x061C] = "Arabic letter mark",
  [0x115F] = "Hangul choseong filler",
  [0x1160] = "Hangul jungseong filler",
  [0x17B4] = "Khmer vowel inherent AQ",
  [0x17B5] = "Khmer vowel inherent AA",
  [0x200B] = "zero-width space",
  [0x200C] = "zero-width non-joiner",
  [0x200D] = "zero-width joiner",
  [0x200E] = "left-to-right mark",
  [0x200F] = "right-to-left mark",
  [0x2028] = "line separator",
  [0x2029] = "paragraph separator",
  [0x202A] = "left-to-right embedding",
  [0x202B] = "right-to-left embedding",
  [0x202C] = "pop directional formatting",
  [0x202D] = "left-to-right override",
  [0x202E] = "right-to-left override",
  [0x202F] = "narrow non-breaking space",
  [0x2060] = "word joiner",
  [0x2061] = "function application",
  [0x2062] = "invisible times",
  [0x2063] = "invisible separator",
  [0x2064] = "invisible plus",
  [0x2066] = "left-to-right isolate",
  [0x2067] = "right-to-left isolate",
  [0x2068] = "first-strong isolate",
  [0x2069] = "pop directional isolate",
  [0x206A] = "inhibit symmetric swapping",
  [0x206B] = "activate symmetric swapping",
  [0x206C] = "inhibit Arabic form shaping",
  [0x206D] = "activate Arabic form shaping",
  [0x206E] = "national digit shapes",
  [0x206F] = "nominal digit shapes",
  [0x3164] = "Hangul filler",
  [0xFEFF] = "byte-order mark / zero-width no-break space",
  [0xFFA0] = "halfwidth Hangul filler",
  [0xE0001] = "language tag",
}

local function codepoint(value)
  return string.format("U+%04X", value)
end

local function decode_utf8(value, index)
  local first = value:byte(index)
  if not first then
    return nil, 0
  end
  if first < 0x80 then
    return first, 1
  end

  local second = value:byte(index + 1)
  if first >= 0xC2 and first <= 0xDF and second and second >= 0x80 and second <= 0xBF then
    return (first - 0xC0) * 0x40 + (second - 0x80), 2
  end

  local third = value:byte(index + 2)
  if
    first >= 0xE0
    and first <= 0xEF
    and second
    and third
    and second >= 0x80
    and second <= 0xBF
    and third >= 0x80
    and third <= 0xBF
  then
    return (first - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80), 3
  end

  local fourth = value:byte(index + 3)
  if
    first >= 0xF0
    and first <= 0xF4
    and second
    and third
    and fourth
    and second >= 0x80
    and second <= 0xBF
    and third >= 0x80
    and third <= 0xBF
    and fourth >= 0x80
    and fourth <= 0xBF
  then
    return
      (first - 0xF0) * 0x40000
        + (second - 0x80) * 0x1000
        + (third - 0x80) * 0x40
        + (fourth - 0x80),
      4
  end

  return nil, 1
end

local function invisible_name(cp)
  if invisible_names[cp] then
    return invisible_names[cp]
  end
  if (cp < 0x20 and cp ~= 0x09) or cp == 0x7F then
    return "control character"
  end
  if (cp >= 0x180B and cp <= 0x180F) or (cp >= 0xFE00 and cp <= 0xFE0F) then
    return "variation selector"
  end
  if cp >= 0x2000 and cp <= 0x200A then
    return "exotic Unicode space"
  end
  if cp == 0x205F or cp == 0x3000 then
    return "exotic Unicode space"
  end
  if cp >= 0xFFF9 and cp <= 0xFFFB then
    return "interlinear annotation control"
  end
  if cp >= 0xE0020 and cp <= 0xE007F then
    return "invisible tag character"
  end
  if cp >= 0xE0100 and cp <= 0xE01EF then
    return "supplementary variation selector"
  end
end

local function classify(cp)
  local invisible = invisible_name(cp)
  if invisible then
    return {
      kind = "invisible",
      severity = vim.diagnostic.severity.ERROR,
      highlight = "GremlinsInvisible",
      message = string.format("%s: %s", codepoint(cp), invisible),
    }
  end

  local alternative = confusables[cp]
  if cp >= 0xFF01 and cp <= 0xFF5E then
    alternative = string.char(cp - 0xFEE0)
  end
  if alternative then
    return {
      kind = "confusable",
      severity = vim.diagnostic.severity.WARN,
      highlight = "GremlinsConfusable",
      message = string.format("%s looks like ASCII %q", codepoint(cp), alternative),
    }
  end
end

local function clear(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns_highlight, 0, -1)
    vim.diagnostic.reset(ns_diagnostic, bufnr)
  end
end

local function should_scan(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end
  if vim.b[bufnr].gremlins_disabled or vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].binary then
    return false
  end
  if not allowed_filetypes[vim.bo[bufnr].filetype] then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  local stat = name ~= "" and uv.fs_stat(name) or nil
  return not stat or not stat.size or stat.size <= MAX_FILE_SIZE
end

function M.scan(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  clear(bufnr)
  if not should_scan(bufnr) then
    return {}
  end

  local diagnostics = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for line_index, line in ipairs(lines) do
    local byte_index = 1
    while byte_index <= #line do
      local cp, length = decode_utf8(line, byte_index)
      local finding = cp and classify(cp) or nil
      if finding then
        local col = byte_index - 1
        local end_col = col + length
        diagnostics[#diagnostics + 1] = {
          lnum = line_index - 1,
          col = col,
          end_col = end_col,
          severity = finding.severity,
          source = "gremlins",
          code = codepoint(cp),
          message = finding.message,
          user_data = { kind = finding.kind, codepoint = cp },
        }
        vim.api.nvim_buf_add_highlight(
          bufnr,
          ns_highlight,
          finding.highlight,
          line_index - 1,
          col,
          end_col
        )
      end
      byte_index = byte_index + math.max(length, 1)
    end
  end

  vim.diagnostic.set(ns_diagnostic, bufnr, diagnostics)
  return diagnostics
end

local function schedule_scan(bufnr)
  debounce_tokens[bufnr] = (debounce_tokens[bufnr] or 0) + 1
  local token = debounce_tokens[bufnr]
  vim.defer_fn(function()
    if token == debounce_tokens[bufnr] then
      M.scan(bufnr)
    end
  end, 120)
end

function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.b[bufnr].gremlins_disabled = not vim.b[bufnr].gremlins_disabled
  if vim.b[bufnr].gremlins_disabled then
    clear(bufnr)
  else
    M.scan(bufnr)
  end
  vim.notify(
    "Gremlins tracker: " .. (vim.b[bufnr].gremlins_disabled and "disabled" or "enabled"),
    vim.log.levels.INFO,
    { title = "Gremlins" }
  )
end

function M.quickfix(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr, { namespace = ns_diagnostic })
  local items = {}
  for _, diagnostic in ipairs(diagnostics) do
    items[#items + 1] = {
      bufnr = bufnr,
      lnum = diagnostic.lnum + 1,
      col = diagnostic.col + 1,
      end_lnum = diagnostic.lnum + 1,
      end_col = (diagnostic.end_col or diagnostic.col + 1) + 1,
      text = diagnostic.message,
      type = diagnostic.severity == vim.diagnostic.severity.ERROR and "E" or "W",
    }
  end
  vim.fn.setqflist({}, " ", { title = "Gremlins", items = items })
  if #items > 0 then
    vim.cmd("copen")
  else
    vim.notify("No Gremlins found in this buffer.", vim.log.levels.INFO, { title = "Gremlins" })
  end
end

local function apply_highlights()
  local chrome = require("config.ui_chrome")
  vim.api.nvim_set_hl(0, "GremlinsInvisible", { fg = chrome.love, bg = chrome.active_bg, bold = true })
  vim.api.nvim_set_hl(0, "GremlinsConfusable", { fg = chrome.gold, bg = chrome.active_bg, bold = true })
end

function M.setup()
  apply_highlights()
  vim.diagnostic.config({
    signs = false,
    underline = true,
    virtual_text = {
      prefix = "󰀪",
      spacing = 2,
    },
    update_in_insert = true,
  }, ns_diagnostic)

  vim.api.nvim_create_user_command("GremlinsToggle", function()
    M.toggle()
  end, { desc = "Toggle Gremlins tracking in the current buffer" })
  vim.api.nvim_create_user_command("GremlinsRescan", function()
    M.scan()
  end, { desc = "Rescan the current buffer for Gremlins" })
  vim.api.nvim_create_user_command("GremlinsQuickfix", function()
    M.quickfix()
  end, { desc = "Open current-buffer Gremlins in quickfix" })

  local group = vim.api.nvim_create_augroup("user_gremlins", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufEnter" }, {
    group = group,
    callback = function(event)
      schedule_scan(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(event)
      schedule_scan(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event)
      debounce_tokens[event.buf] = nil
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = apply_highlights,
  })
end

M._test = {
  classify = classify,
  should_scan = should_scan,
  namespace = ns_diagnostic,
}

return M
