describe("asynchronous buffer and window scoping", function()
  it("defers hidden-buffer cursor restore without moving the visible window", function()
    package.loaded["config.ui_chrome"] = dofile("lua/config/ui_chrome.lua")
    dofile("lua/config/autocmds.lua")

    local root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    local a_path = vim.fs.joinpath(root, "a.txt")
    local b_path = vim.fs.joinpath(root, "b.txt")
    vim.fn.writefile({ "a1", "a2", "a3", "a4" }, a_path)
    vim.fn.writefile({ "b1", "b2", "b3", "b4" }, b_path)

    local win = vim.api.nvim_get_current_win()
    local a = vim.fn.bufadd(a_path)
    local b = vim.fn.bufadd(b_path)
    vim.fn.bufload(a)
    vim.fn.bufload(b)
    vim.api.nvim_win_set_buf(win, a)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })
    vim.api.nvim_buf_set_mark(b, '"', 4, 0, {})

    vim.api.nvim_exec_autocmds("BufReadPost", { buffer = b })
    assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(win))

    vim.api.nvim_win_set_buf(win, b)
    assert.are.same({ 4, 0 }, vim.api.nvim_win_get_cursor(win))
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
    vim.api.nvim_win_set_buf(win, a)
    vim.api.nvim_win_set_buf(win, b)
    assert.are.same({ 1, 0 }, vim.api.nvim_win_get_cursor(win))

    pcall(vim.api.nvim_buf_delete, a, { force = true })
    pcall(vim.api.nvim_buf_delete, b, { force = true })
    pcall(vim.api.nvim_del_augroup_by_name, "user_config")
    vim.fn.delete(root, "rf")
  end)

  it("applies async Treesitter folds only to the originating buffer windows", function()
    local original_module = package.loaded["nvim-treesitter"]
    local original_get_lang = vim.treesitter.language.get_lang
    local original_add = vim.treesitter.language.add
    local original_start = vim.treesitter.start
    local original_query_get = vim.treesitter.query.get
    local install_done
    package.loaded["nvim-treesitter"] = {
      get_available = function()
        return { "mocklang" }
      end,
      get_installed = function()
        return {}
      end,
      install = function(request)
        if type(request) == "table" then
          return
        end
        return {
          await = function(_, callback)
            install_done = callback
          end,
        }
      end,
    }
    vim.treesitter.language.get_lang = function(ft)
      return ft == "mockft" and "mocklang" or original_get_lang(ft)
    end
    vim.treesitter.language.add = function()
      return true
    end
    vim.treesitter.start = function() end
    vim.treesitter.query.get = function()
      return nil
    end

    local before = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
      if autocmd.id then
        before[autocmd.id] = true
      end
    end
    local specs = dofile("lua/plugins/treesitter.lua")
    specs[1].config()

    local left = vim.api.nvim_get_current_win()
    local a = vim.api.nvim_create_buf(false, true)
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(left, a)
    vim.cmd("vsplit")
    local right = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(right, b)
    vim.api.nvim_set_option_value("foldmethod", "manual", { scope = "local", win = right })
    vim.bo[a].filetype = "mockft"
    vim.api.nvim_exec_autocmds("FileType", { buffer = a })
    assert.is_function(install_done)
    install_done(nil, true)
    assert(vim.wait(1000, function()
      return vim.api.nvim_get_option_value("foldmethod", { scope = "local", win = left }) == "expr"
    end))
    assert.are.equal("manual", vim.api.nvim_get_option_value("foldmethod", { scope = "local", win = right }))

    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
      if autocmd.id and not before[autocmd.id] then
        pcall(vim.api.nvim_del_autocmd, autocmd.id)
      end
    end
    pcall(vim.api.nvim_win_close, right, true)
    pcall(vim.api.nvim_buf_delete, a, { force = true })
    pcall(vim.api.nvim_buf_delete, b, { force = true })
    package.loaded["nvim-treesitter"] = original_module
    vim.treesitter.language.get_lang = original_get_lang
    vim.treesitter.language.add = original_add
    vim.treesitter.start = original_start
    vim.treesitter.query.get = original_query_get
  end)

  it("lints the originating buffer after an asynchronous Mason install", function()
    local original_lint = package.loaded.lint
    local original_registry = package.loaded["mason-registry"]
    local installed = false
    local install_done
    local linted_buffers = {}
    package.loaded.lint = {
      linters = {
        eslint_d = { cmd = "sh" },
        ruff = { cmd = "sh" },
        sqlfluff = { cmd = "sh" },
        shellcheck = { cmd = "sh" },
        stylelint = { cmd = "sh" },
        markdownlint = { cmd = "sh" },
      },
      try_lint = function()
        linted_buffers[#linted_buffers + 1] = vim.api.nvim_get_current_buf()
      end,
    }
    local mason_package = {
      is_installed = function()
        return installed
      end,
      get_installed_version = function()
        return installed and "15.0.3" or nil
      end,
      is_installing = function()
        return false
      end,
      install = function(_, _, callback)
        install_done = callback
        return {}
      end,
    }
    package.loaded["mason-registry"] = {
      refresh = function(callback)
        callback()
      end,
      get_package = function()
        return mason_package
      end,
    }

    local spec = dofile("lua/plugins/linting.lua")[1]
    spec.config()
    local a = vim.api.nvim_create_buf(false, true)
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, b)
    vim.bo[a].filetype = "javascript"
    assert.is_function(install_done)
    installed = true
    install_done()
    assert(vim.wait(1000, function()
      return #linted_buffers > 0
    end))
    assert.are.same({ a }, linted_buffers)

    pcall(vim.api.nvim_del_augroup_by_name, "user_lint")
    pcall(vim.api.nvim_buf_delete, a, { force = true })
    pcall(vim.api.nvim_buf_delete, b, { force = true })
    package.loaded.lint = original_lint
    package.loaded["mason-registry"] = original_registry
  end)
end)
