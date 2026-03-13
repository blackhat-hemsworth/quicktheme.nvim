local M = {}

local HEX_NS = vim.api.nvim_create_namespace("quicktheme_hex_colors")

local function hex_fg(hex)
	local r = tonumber(hex:sub(2, 3), 16)
	local g = tonumber(hex:sub(4, 5), 16)
	local b = tonumber(hex:sub(6, 7), 16)
	return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5 and "#000000" or "#ffffff"
end

local function highlight_hex_colors(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, HEX_NS, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for lnum, line in ipairs(lines) do
		local col = 0
		while true do
			local s, e, _, bare =
				line:find("(#?)([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", col + 1)
			if not s then
				break
			end
			local hex = "#" .. bare
			local hl_group = "QuickthemeHex_" .. bare
			vim.api.nvim_set_hl(0, hl_group, { bg = hex, fg = hex_fg(hex) })
			vim.api.nvim_buf_add_highlight(buf, HEX_NS, hl_group, lnum - 1, s - 1, e)
			col = e
		end
	end
end

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

	-- Floating image window shown alongside the YAML preview for image items
	local img_win = nil
	local img_closing = {} -- IDs of floats being intentionally closed (suppress WinClosed reaction)
	local preview_gen = 0 -- incremented per preview call; stale scheduled callbacks self-cancel

	local function close_img_win()
		if img_win and vim.api.nvim_win_is_valid(img_win) then
			img_closing[img_win] = true
			local buf = vim.api.nvim_win_get_buf(img_win)
			-- Explicitly delete the image placement before closing the window so
			-- Snacks.image sends the kitty/sixel delete escape synchronously,
			-- clearing the pixels from the terminal immediately.
			if Snacks.image then
				pcall(Snacks.image.placement.clean, buf)
			end
			pcall(vim.api.nvim_win_close, img_win, true)
			-- Wipeout the scratch buffer so it doesn't accumulate.
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
		img_win = nil
	end

	local function open_image_float(image_path, preview_win)
		if not (Snacks.image and vim.api.nvim_win_is_valid(preview_win)) then
			return
		end
		local ok, pos = pcall(vim.api.nvim_win_get_position, preview_win)
		if not ok then
			return
		end
		local pwidth = vim.api.nvim_win_get_width(preview_win)
		local pheight = vim.api.nvim_win_get_height(preview_win)
		local img_w = math.max(10, math.floor(pwidth * 0.45))
		local img_h = math.max(5, math.floor(pheight * 0.45))
		local buf = vim.api.nvim_create_buf(false, true)
		img_win = vim.api.nvim_open_win(buf, false, {
			relative = "editor",
			row = pos[1] + pheight - img_h,
			col = pos[2] + pwidth - img_w,
			width = img_w,
			height = img_h,
			zindex = 200,
			style = "minimal",
			border = "single",
			title = " image ",
			title_pos = "center",
		})
		Snacks.image.buf.attach(buf, { src = image_path })
	end

	Snacks.picker({
		title = title,
		layout = config.picker.layout,
		items = items,
		format = function(item, _)
			return {
				{ item.text, item.text_hl },
			}
		end,
		preview = function(ctx)
			preview_gen = preview_gen + 1
			local gen = preview_gen
			close_img_win()
			if ctx.item and ctx.item.source_type == "image" then
				local yaml_path = ctx.item.target
				-- Generate YAML if missing (preview may run before on_change)
				if vim.fn.filereadable(yaml_path) == 0 and cli_enabled and vim.fn.executable(config.cli.command) == 1 then
					local cmd = build_cli_command(config.cli, ctx.item.file, vim.fn.fnamemodify(yaml_path, ":h"))
					vim.fn.system(cmd)
				end
				if vim.fn.filereadable(yaml_path) == 1 then
					ctx.preview:reset()
					ctx.preview:set_lines(vim.fn.readfile(yaml_path))
					ctx.preview:highlight({ ft = "yaml" })
					ctx.preview:set_title(ctx.item.name)
					local preview_buf = ctx.buf
					local preview_win = ctx.win
					local image_file = ctx.item.file
					vim.schedule(function()
						if gen ~= preview_gen then
							return
						end -- newer preview took over
						highlight_hex_colors(preview_buf)
						open_image_float(image_file, preview_win)
					end)
				else
					ctx.preview:notify("No palette generated for " .. ctx.item.name, "warn")
				end
			else
				Snacks.picker.preview.file(ctx)
				local preview_buf = ctx.buf
				vim.schedule(function()
					if gen ~= preview_gen then
						return
					end
					highlight_hex_colors(preview_buf)
				end)
			end
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
				close_img_win()
				picker:close()
				plugin._last_selected[key] = item.name
				os.execute("cp " .. vim.fn.shellescape(item.target) .. " " .. vim.fn.shellescape(config.active_file))
				plugin._apply_palette()
			end)
		end,
	})

	-- Revert to ACTIVE.yaml on cancel; ignore intentional closes of our img_win float
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(ev)
			local closed = tonumber(ev.match)
			if img_closing[closed] then
				img_closing[closed] = nil
				return
			end
			close_img_win()
			vim.schedule(function()
				vim.cmd("hi clear")
				plugin._apply_palette()
			end)
			vim.api.nvim_del_autocmd(ev.id)
		end,
	})
end

return M
