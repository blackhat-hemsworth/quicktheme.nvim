local M = {}

M.defaults = {
	active_file = vim.fn.expand("~/.config/base16/ACTIVE.yaml"),

	theme_dirs = {
		{ path = vim.fn.expand("~/.config/base16/quicktheme"), type = "mixed" },
		{ path = vim.fn.expand("~/.config/base16/traditional"), type = "yaml" },
	},

	image_extensions = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "ico", "tiff", "tif" },

	cli = {
		command = "quicktheme",
		args = { "-f", "{source}", "-o", "{output_dir}" },
		install_url = "https://github.com/blackhat-hemsworth/quickthemes",
	},

	picker = {
		layout = { preset = "default", preview = true },
	},

	highlights = "default",

	on_apply = nil,

	watch = true,
}

function M.resolve(user_opts)
	return vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
