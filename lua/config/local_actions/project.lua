--------------------------------------------------------------------------------
-- Project localleader provider — typed actions from the native project runner.
--------------------------------------------------------------------------------

local runner = require("config.project_runner")

return {
  id = "project",
  label = "Project",
  priority = 50,
  resolve = function(context)
    local candidates = runner.get_actions(context.bufnr)
    if #candidates == 0 then
      return nil
    end

    local labels = {}
    local seen = {}
    local actions = {}
    for _, candidate in ipairs(candidates) do
      local selected = candidate
      local project_label = candidate.project.label
      if not seen[project_label] then
        seen[project_label] = true
        labels[#labels + 1] = project_label
      end
      actions[#actions + 1] = {
        id = candidate.id,
        label = candidate.label,
        desc = string.format("%s: %s", project_label, candidate.label),
        context = project_label,
        slot = vim.tbl_contains({ "run", "build", "test" }, candidate.kind) and candidate.kind or nil,
        run = function()
          runner.execute(selected)
        end,
      }
    end

    return {
      label = table.concat(labels, " + "),
      root = candidates[1].project.root,
      actions = actions,
    }
  end,
}
