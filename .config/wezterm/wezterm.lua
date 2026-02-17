-- Import WezTerm API
local wezterm = require("wezterm")
local act = wezterm.action

-- Configuration initialization
local config = {}

-- On Windows, use powershell instead of cmd
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.default_prog = { 'pwsh.exe', '-NoLogo' }
end

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

-- Tab Bar
config.hide_tab_bar_if_only_one_tab = true

-- Font
config.font = wezterm.font("JetBrainsMonoNL Nerd Font", { weight = 'Bold' })
config.font_size = 12

-- Keybindings
config.keys = {
  { key = 'j', mods = 'CTRL|ALT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'CTRL|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'CTRL',     action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL',     action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL',     action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL',     action = act.ActivatePaneDirection 'Right' },
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

