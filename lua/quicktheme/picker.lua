local M = {}

local function is_image_file(filename, extensions)
  for _, ext in ipairs(extensions) do
    if filename:match("%." .. ext .. "$") or filename:match("%." .. ext:upper() .. "$") then
      return true
    end
  end
  return false
end

local function build_cli_command(cli_config, source, output_dir)
  local args = {}
  for _, arg in ipairs(cli_config.args) do
    local replaced = arg:gsub("{source}", vim.fn.shellescape(source))
    replaced = replaced:gsub("{output_dir}", vim.fn.shellescape(output_dir))
    table.insert(args, replaced)
  end
  return cli_config.command .. " " .. table.concat(args, " ")
end

local function collect_items(config, filter_type)
  local items = {}
  local cli_enabled = config.cli and config.cli ~= false

  for _, dir_entry in ipairs(config.theme_dirs) do
    local dir = dir_entry.path
    local dtype = dir_entry.type or "mixed"

    if vim.fn.isdirectory(dir) == 0 then
      vim.notify("quicktheme: directory not found: " .. dir, vim.log.levels.INFO)
      goto continue
    end

    local dir_files = vim.fn.readdir(dir)
    if #dir_files == 0 then
      vim.notify("quicktheme: empty directory: " .. dir, vim.log.levels.INFO)
      goto continue
    end

    -- Collect image items
    if (filter_type == "image" or filter_type == nil) and (dtype == "mixed" or dtype == "image") then
      for _, file in ipairs(dir_files) do
        if is_image_file(file, config.image_extensions) then
          local image_name = file:gsub("%.[^.]+$", "")
          local full_path = dir .. "/" .. file
          local yaml_path = dir .. "/" .. image_name .. ".yaml"
          table.insert(items, {
            idx = #items + 1,
            name = image_name,
            text = image_name,
            file = full_path,
            target = yaml_path,
            source_type = "image",
            source_dir = dir,
          })
        end
      end
    end

    -- Collect YAML items
    if (filter_type == "yaml" or filter_type == nil) and (dtype == "mixed" or dtype == "yaml") then
      for _, file in ipairs(dir_files) do
        if file:match("%.yaml$") then
          local theme_name = file:gsub("%.yaml$", "")
          local full_path = dir .. "/" .. file
          table.insert(items, {
            idx = #items + 1,
            name = theme_name,
            text = theme_name,
            file = full_path,
            target = full_path,
            source_type = "yaml",
            source_dir = dir,
          })
        end
      end
    end

    ::continue::
  end

  return items
end

function M.open(plugin, filter_type)
  local config = plugin.config
  local yaml = require("quicktheme.yaml")

  local items = collect_items(config, filter_type)

  if #items == 0 then
    vim.notify("quicktheme: No themes found", vim.log.levels.INFO)
    return
  end

  local title = "Quicktheme"
  if filter_type == "yaml" then
    title = "Quicktheme YAML"
  elseif filter_type == "image" then
    title = "Quicktheme Image"
  end

  local key = filter_type or "all"
  local cli_enabled = config.cli and config.cli ~= false

  Snacks.picker({
    title = title,
    layout = config.picker.layout,
    items = items,
    format = function(item, _)
      return {
        { item.text, item.text_hl },
      }
    end,
    on_show = function(picker)
      local prev = plugin._last_selected[key]
      if not prev then
        return
      end
      for i, item in ipairs(picker:items()) do
        if item.name == prev then
          picker.list:view(i)
          Snacks.picker.actions.list_scroll_center(picker)
          break
        end
      end
    end,
    on_change = function(picker, item)
      if not item or not item.target then
        return
      end

      -- Generate YAML on demand if needed
      if vim.fn.filereadable(item.target) == 0 then
        if not cli_enabled then
          vim.notify("quicktheme: CLI disabled, no pre-generated YAML for " .. item.name, vim.log.levels.WARN)
          return
        end
        if vim.fn.executable(config.cli.command) == 0 then
          vim.notify(
            "quicktheme: '" .. config.cli.command .. "' not found. Install: " .. config.cli.install_url,
            vim.log.levels.WARN
          )
          return
        end
        local cmd = build_cli_command(config.cli, item.file, vim.fn.fnamemodify(item.target, ":h"))
        vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
          vim.notify("quicktheme: CLI failed for " .. item.name, vim.log.levels.ERROR)
          return
        end
      end

      local b16 = yaml.read(item.target)
      if not b16 or type(b16) ~= "table" then
        vim.notify("quicktheme: Failed to read theme: " .. item.target, vim.log.levels.ERROR)
        return
      end
      require("mini.base16").setup({ palette = b16 })
      if config.highlights == "default" then
        require("quicktheme.highlights").apply_default(b16)
      elseif type(config.highlights) == "function" then
        config.highlights(b16)
      end
    end,
    confirm = function(picker, item)
      return picker:norm(function()
        picker:close()
        plugin._last_selected[key] = item.name
        os.execute("cp " .. vim.fn.shellescape(item.target) .. " " .. vim.fn.shellescape(config.active_file))
        plugin._apply_palette()
      end)
    end,
  })

  -- Revert to ACTIVE.yaml on cancel
  vim.api.nvim_create_autocmd("WinClosed", {
    once = true,
    callback = function()
      vim.schedule(function()
        vim.cmd("hi clear")
        plugin._apply_palette()
      end)
    end,
  })
end

return M
