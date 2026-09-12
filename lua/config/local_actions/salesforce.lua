--------------------------------------------------------------------------------
-- Salesforce localleader provider — guarded cloud actions for project buffers.
--------------------------------------------------------------------------------

local M = {}

local metadata_filetypes = {
  apex = true,
  apexcode = true,
  html = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

function M.new(deps)
  local function sf_method(bufnr, method)
    return function()
      deps.guarded_load(deps.sf_action(method), bufnr)
    end
  end

  return {
    id = "salesforce",
    label = "Salesforce",
    priority = 80,
    resolve = function(context)
      local root = deps.salesforce_root(context.bufnr)
      if not root then
        return nil
      end

      local bufnr = context.bufnr
      local actions = {
        {
          id = "org-browser",
          label = "Open Org Browser",
          run = function()
            deps.guarded_load(function()
              vim.cmd("Neotree sf_org toggle left")
            end, bufnr)
          end,
        },
        {
          id = "metadata-browser",
          label = "Open metadata/package.xml browser",
          run = function()
            deps.guarded_load(function()
              require("config.salesforce.browser").open()
            end, bufnr)
          end,
        },
        {
          id = "open-org",
          label = "Open target org in browser",
          run = sf_method(bufnr, "org_open"),
        },
        {
          id = "cancel",
          label = "Cancel active Salesforce actions",
          run = function()
            deps.cancel()
          end,
        },
      }

      if metadata_filetypes[context.filetype] then
        vim.list_extend(actions, {
          {
            id = "retrieve-current",
            label = "Retrieve current metadata",
            run = sf_method(bufnr, "retrieve"),
          },
          {
            id = "deploy-current",
            label = "Save and deploy current metadata",
            desc = "Salesforce: save and deploy current metadata",
            slot = "build",
            run = sf_method(bufnr, "save_and_push"),
          },
          {
            id = "diff-current",
            label = "Diff current metadata with org",
            run = sf_method(bufnr, "diff_in_target_org"),
          },
          {
            id = "open-current",
            label = "Open current metadata in org",
            run = sf_method(bufnr, "org_open_current_file"),
          },
        })
      end

      if context.filetype == "apex" or context.filetype == "apexcode" then
        actions[#actions + 1] = {
          id = "test-current",
          label = "Run Apex test under cursor",
          desc = "Salesforce: test under cursor",
          slot = "test",
          run = sf_method(bufnr, "run_current_test"),
        }
        actions[#actions + 1] = {
          id = "test-current-coverage",
          label = "Run Apex test under cursor with coverage",
          run = sf_method(bufnr, "run_current_test_with_coverage"),
        }
      end

      return {
        label = "Salesforce",
        root = root,
        actions = actions,
      }
    end,
  }
end

return M
