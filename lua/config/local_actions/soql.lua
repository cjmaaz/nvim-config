--------------------------------------------------------------------------------
-- SOQL localleader provider — always available for named .soql buffers.
--------------------------------------------------------------------------------

local function query()
  return require("config.salesforce.query")
end

return {
  id = "soql",
  label = "SOQL",
  priority = 100,
  resolve = function(context)
    if context.filetype ~= "soql" then
      return nil
    end
    local bufnr = context.bufnr
    return {
      label = "SOQL",
      root = vim.b[bufnr].soql_root or require("config.project_context").salesforce_root(bufnr),
      actions = {
        {
          id = "pick-fields",
          label = "Pick fields",
          desc = "SOQL: pick fields",
          lhs = "<localleader>f",
          run = function()
            query().pick_fields(bufnr)
          end,
        },
        {
          id = "change-object",
          label = "Change SObject",
          desc = "SOQL: change SObject",
          lhs = "<localleader>o",
          run = function()
            query().change_object(bufnr)
          end,
        },
        {
          id = "run-query",
          label = "Run query",
          desc = "SOQL: run query",
          lhs = "<localleader>r",
          slot = "run",
          run = function()
            query().run_current(false, bufnr)
          end,
        },
        {
          id = "run-tooling-query",
          label = "Run Tooling query",
          desc = "SOQL: run Tooling query",
          lhs = "<localleader>t",
          run = function()
            query().run_current(true, bufnr)
          end,
        },
      },
    }
  end,
}
