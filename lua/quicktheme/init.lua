local M = {}

M.config = {}
M._watcher_handle = nil
M._last_selected = {}

function M._apply_palette(palette)
  local yaml = require("quicktheme.yaml")

  if not palette then
    local err
    palette, err = yaml.read(M.config.active_file)
    if not palette then
      vim.notify("quicktheme: " .. (err or "Failed to read ACTIVE.yaml"), vim.log.levels.ERROR)
      return
    end
  end

  require("mini.base16").setup({ palette = palette })

  if M.config.highlights == "default" then
    require("quicktheme.highlights").apply_default(palette)
  elseif type(M.config.highlights) == "function" then
    M.config.highlights(palette)
  end

  if type(M.config.on_apply) == "function" then
    M.config.on_apply(palette)
  end
end

function M.pick(filter_type)
  require("quicktheme.picker").open(M, filter_type)
end

function M.setup(opts)
  local config_mod = require("quicktheme.config")
  M.config = config_mod.resolve(opts)

  -- Apply current theme
  if vim.fn.filereadable(M.config.active_file) == 1 then
    M._apply_palette()
  end

  -- Start watcher
  if M.config.watch then
    require("quicktheme.watcher").start(M)
  end

  -- Register commands
  vim.api.nvim_create_user_command("Quicktheme", function()
    M.pick()
  end, { desc = "Browse all themes" })

  vim.api.nvim_create_user_command("QuickthemeImage", function()
    M.pick("image")
  end, { desc = "Browse image themes" })

  vim.api.nvim_create_user_command("QuickthemeYaml", function()
    M.pick("yaml")
  end, { desc = "Browse YAML themes" })
end

return M
