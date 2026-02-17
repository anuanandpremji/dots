-- Micro Editor Settings

-- Enable true color if supported
if os.getenv("COLORTERM") == "truecolor" then
    truecolor = true
else
    truecolor = false
end

colorscheme = "cmc-16"   -- Set default color scheme
linenumbers = true        -- Show line numbers
softwrap = true           -- Enable soft wrapping
tabsize = 4               -- Set tab size to 4 spaces
mouse = true              -- Enable mouse support


