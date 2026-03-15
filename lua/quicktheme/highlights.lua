local M = {}

function M.apply_default(palette)
	vim.o.cursorline = false
	local hl = vim.api.nvim_set_hl
	italics = { "Structure", "DiagnosticWarn", "Comment", "@namespace" }
	for _, v in ipairs(italics) do
		local l = vim.api.nvim_get_hl(0, { name = v })
		l.italic = true
		hl(0, v, l)
	end

	hl(0, "String", { fg = palette.base03 })
	hl(0, "Operator", { fg = palette.base08 })

	hl(0, "LineNr", { fg = palette.base03 })
	hl(0, "LineNrAbove", { fg = palette.base03 })
	hl(0, "LineNrBelow", { fg = palette.base03 })
	hl(0, "FoldColumn", { fg = palette.base0C })
	hl(0, "SignColumn", { fg = palette.base03 })
	hl(0, "DiagnosticFloatingError", { fg = palette.base08 })
	hl(0, "DiagnosticFloatingHint", { fg = palette.base0D })
	hl(0, "DiagnosticFloatingInfo", { fg = palette.base0C })
	hl(0, "DiagnosticFloatingOk", { fg = palette.base0B })
	hl(0, "DiagnosticFloatingWarn", { fg = palette.base0B })
	hl(0, "NormalFloat", { fg = palette.base03 })
	hl(0, "FloatBorder", { fg = palette.base03 })
	hl(0, "WhichKeyFloat", { fg = palette.base03 })
	hl(0, "WhichKeySeparator", { fg = palette.base03 })
	hl(0, "GitSignsAdd", { fg = palette.base0C })
	hl(0, "GitSignsChange", { fg = palette.base0C })
	hl(0, "GitSignsDelete", { fg = palette.base0C })
	hl(0, "GitSignsUntracked", { fg = palette.base0C })
	hl(0, "TabLine", { fg = palette.base03 })
	hl(0, "TabLineFill", { fg = palette.base03 })
	hl(0, "TabLineSel", { fg = palette.base03 })
	hl(0, "NvimTreeWindowPicker", { fg = palette.base03 })
	hl(0, "BufferlineFill", {})
	hl(0, "DiagnosticSignError", { fg = palette.base08 })
	hl(0, "DiagnosticSignHint", { fg = palette.base0D })
	hl(0, "DiagnosticSignInfo", { fg = palette.base0C })
	hl(0, "DiagnosticSignOk", { fg = palette.base0B })
	hl(0, "DiagnosticSignWarn", { fg = palette.base0E })
	hl(0, "CursorLineFold", { fg = palette.base03 })
	hl(0, "CursorLineNr", { fg = palette.base03 })
	hl(0, "CursorLineSign", { fg = palette.base03 })
	hl(0, "Pmenu", { fg = palette.base03 })
	hl(0, "PmenuSel", { fg = palette.base03 })
	hl(0, "QuickFixLine", { fg = palette.base03 })
	hl(0, "CmpItemMenu", { fg = palette.base03 })
	hl(0, "CmpItemKind", { fg = palette.base03 })
	hl(0, "CursorColumn", {})
	hl(0, "ColorColumn", {})
	hl(0, "StatusLine", { fg = palette.base03 })
	hl(0, "StatusLineNC", { fg = palette.base03 })
	hl(0, "WinBarNC", { fg = palette.base02 })
	hl(0, "BufferVisibleTarget", { fg = palette.base08 })
	hl(0, "BufferInactiveTarget", { fg = palette.base08 })
end

return M
