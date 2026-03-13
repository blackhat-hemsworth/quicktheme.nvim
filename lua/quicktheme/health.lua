local M = {}

function M.check()
	vim.health.start("quicktheme")

	-- Check snacks.nvim
	local has_snacks = pcall(require, "snacks")
	if has_snacks then
		vim.health.ok("snacks.nvim found")
	else
		vim.health.error("snacks.nvim not found", { "Install folke/snacks.nvim" })
	end

	-- Check mini.base16
	local has_base16 = pcall(require, "mini.base16")
	if has_base16 then
		vim.health.ok("mini.base16 found")
	else
		vim.health.error("mini.base16 not found", { "Install mini-nvim//mini.base16" })
	end

	-- Check CLI
	local config = require("quicktheme").config
	if config.cli and config.cli ~= false then
		if vim.fn.executable(config.cli.command) == 1 then
			vim.health.ok("CLI '" .. config.cli.command .. "' found")
		else
			vim.health.warn(
				"CLI '" .. config.cli.command .. "' not found",
				{
					"Install: " .. (config.cli.install_url or "N/A"),
					"Or set cli = false to disable image-to-theme generation",
				}
			)
		end
	else
		vim.health.info("CLI disabled (cli = false)")
	end

	-- Check ACTIVE.yaml
	if vim.fn.filereadable(config.active_file) == 1 then
		vim.health.ok("ACTIVE.yaml readable: " .. config.active_file)
	else
		vim.health.error("ACTIVE.yaml not readable: " .. config.active_file)
	end

	-- Check theme directories
	for _, dir_entry in ipairs(config.theme_dirs) do
		local dir = dir_entry.path
		if vim.fn.isdirectory(dir) == 1 then
			local count = #vim.fn.readdir(dir)
			vim.health.ok(dir .. " (" .. count .. " files, type: " .. (dir_entry.type or "mixed") .. ")")
		else
			vim.health.warn("Directory not found: " .. dir)
		end
	end
end

return M
