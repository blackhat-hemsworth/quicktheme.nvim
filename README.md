# quicktheme.nvim

A Neovim plugin for browsing and applying [base16](https://github.com/tinted-theming/base16-schemes) color schemes from images and YAML files, with live preview via [Snacks.picker](https://github.com/folke/snacks.nvim).

Uses the optional [`quicktheme`](https://github.com/blackhat-hemsworth/quickthemes) CLI to generate base16 palettes from images on-demand.

## Features

- Browse images and auto-generate base16 palettes via the `quicktheme` CLI
- Browse YAML themes with live preview
- Minimalist defaults. Overrides some of the more prominent contrasting highlights in mini-base16.nvim.
- File watcher: external changes to `ACTIVE.yaml` update Neovim in real time -- you can also point terminals to pick up on the generated theme.
- Configurable theme directories, highlight overrides, and hooks

## Requirements

- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [mini.base16](https://github.com/nvim-mini/mini.base16)
- (Optional) [`quicktheme` CLI](https://github.com/blackhat-hemsworth/quickthemes) for image-to-palette generation

## Installation

### lazy.nvim

```lua
{
  "blackhat-hemsworth/quicktheme.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-mini/mini.base16",
  },
  keys = {
    { "<leader>t", function() require("quicktheme").pick("image") end, desc = "Image Themes" },
    { "<leader>y", function() require("quicktheme").pick("yaml") end, desc = "YAML Themes" },
  },
  opts = {
    on_apply = function()
      pcall(function() require("bufferline").setup() end)
    end,
  },
}
```

### packer.nvim

```lua
use {
  "blackhat-hemsworth/quicktheme.nvim",
  requires = { "folke/snacks.nvim", "nvim-mini/mini.base16" },
  config = function()
    require("quicktheme").setup()
  end,
}
```

### vim-plug

```vim
Plug 'folke/snacks.nvim'
Plug 'nvim-mini/mini.base16'
Plug 'blackhat-hemsworth/quicktheme.nvim'
```

After installing the plugin with vim-plug, add to your init.lua:

```lua
require("quicktheme").setup()
```

### Installing the quicktheme CLI

```
cargo install --git https://github.com/blackhat-hemsworth/quickthemes
```

## Configuration

All options with their defaults:

```lua
require("quicktheme").setup({
  -- Path to the active theme file
  active_file = vim.fn.expand("~/.config/base16/ACTIVE.yaml"),

  -- Directories to scan
  -- type: "mixed" (images + yamls), "yaml" (yamls only), "image" (images only)
  theme_dirs = {
    { path = vim.fn.expand("~/.config/base16/quicktheme"), type = "mixed" },
    { path = vim.fn.expand("~/.config/base16/traditional"), type = "yaml" },
  },

  image_extensions = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "ico", "tiff", "tif", "avif" },

  -- quicktheme CLI config. Set to false to disable image-to-theme generation.
  cli = {
    command = "quicktheme",
    args = { "-f", "{source}", "-o", "{output_dir}" },
    install_url = "https://github.com/blackhat-hemsworth/quickthemes",
  },

  -- Snacks.picker layout
  picker = {
    layout = { preset = "default", preview = true },
  },

  -- Highlight overrides: "default" | false | function(palette)
  highlights = "default",

  -- Hook called after theme is applied
  on_apply = nil, -- function(palette) end

  -- Watch ACTIVE.yaml for external changes
  watch = true,
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:Quicktheme` | Browse all themes |
| `:QuickthemeImage` | Browse image themes only |
| `:QuickthemeYaml` | Browse YAML themes only |

No default keymaps are set. Bind your own:

```lua
vim.keymap.set("n", "<leader>t", function() require("quicktheme").pick("image") end)
vim.keymap.set("n", "<leader>y", function() require("quicktheme").pick("yaml") end)
```

## Health Check

```vim
:checkhealth quicktheme
```

Reports status of dependencies, CLI availability, ACTIVE.yaml, and theme directories.

## License

GPLv3
