-- Import WezTerm API
local wezterm = require("wezterm")
local act = wezterm.action

-- Configuration initialization
local config = {}

-- On Windows, use powershell instead of cmd
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.default_prog = { 'pwsh.exe', '-NoLogo' }
end

-- Performance
config.max_fps = 120
config.animation_fps = 120
config.automatically_reload_config = true

-- Scrollback & Scrollbar
config.enable_scroll_bar = true
config.scrollback_lines  = 100000

-- Window Padding
config.window_frame    = {
  border_left_width    = '0.25cell',
  border_right_width   = '0.25cell',
  border_bottom_height = '0.12cell',
  border_top_height    = '0.0cell',
  border_left_color    = 'gray',
  border_right_color   = 'gray',
  border_bottom_color  = 'gray',
  border_top_color     = 'gray',
}

-- Initial Window Size
config.initial_cols = 160
config.initial_rows = 48

-- Tab Bar
config.hide_tab_bar_if_only_one_tab = true

-- Font
config.font = wezterm.font("JetBrainsMonoNL Nerd Font", { weight = 'Bold' })
config.font_size = 12

-- Keybindings
config.keys = {
  -- Split
  { key = 'v', mods = 'CTRL|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } }, -- Vertical (side-by-side)
  { key = 's', mods = 'CTRL|ALT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } }, -- Horizontal (top-bottom)
  -- Navigate
  { key = 'LeftArrow',  mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'DownArrow',  mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'UpArrow',    mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'RightArrow', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Right' },
  -- Resize
  { key = 'LeftArrow',  mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'DownArrow',  mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'UpArrow',    mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'RightArrow', mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  -- Zoom
  { key = 'Escape', mods = 'SHIFT', action = act.TogglePaneZoomState },
}

-- Set color scheme based on system theme
local function set_appearance(window)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = appearance:find 'Dark' and 'GruvboxDarkHard' or 'Alabaster'
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end

-- Configure integrated title button style based on OS
config.integrated_title_button_style =
    wezterm.target_triple:find("linux") and "Gnome" or
    wezterm.target_triple:find("macos") and "MacOsNative" or
    "Windows" -- Use Windows style buttons everywhere else

-- Event listeners
wezterm.on('window-config-reloaded', set_appearance)

-- Return configuration
return config
