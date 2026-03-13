local M = {}

function M.start(plugin)
  M.stop(plugin)

  local uv = vim.loop
  local handle = uv.new_fs_event()
  plugin._watcher_handle = handle

  uv.fs_event_start(handle, plugin.config.active_file, {}, function(err)
    if err then
      return
    end
    vim.schedule(function()
      vim.cmd("hi clear")
      plugin._apply_palette()
      vim.cmd("redraw")
    end)
  end)
end

function M.stop(plugin)
  local handle = plugin._watcher_handle
  if handle then
    handle:stop()
    if not handle:is_closing() then
      handle:close()
    end
    plugin._watcher_handle = nil
  end
end

return M
