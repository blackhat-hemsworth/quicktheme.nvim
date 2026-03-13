local M = {}

--- Parse a base16 YAML file into a palette table.
--- Handles both quoted ("262626") and unquoted (262626) hex values.
---@param filename string
---@return table|nil palette
---@return string|nil error
function M.read(filename)
  local file = io.open(filename, "r")
  if not file then
    return nil, "Failed to open file: " .. filename
  end

  local data = {}
  for line in file:lines() do
    local key, value = line:match("(%w+):%s*(.+)")
    if key and value then
      value = value:gsub("%s*#.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
      -- Handle quoted values: "262626" -> 262626
      local unquoted = value:match('^"(.-)"$')
      if unquoted then
        data[key] = "#" .. unquoted
      else
        -- Unquoted bare hex value
        data[key] = "#" .. value
      end
    end
  end

  file:close()

  if not data.base00 then
    return nil, "Invalid base16 YAML: missing base00 in " .. filename
  end

  return data
end

return M
