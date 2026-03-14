local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

-- Toggle soft wrap for the current buffer (bound to Alt-z in bindings.json)
function toggleSoftWrap(bp)
    local current = bp.Buf.Settings["softwrap"]
    bp.Buf.Settings["softwrap"] = not current
    if not current then
        micro.InfoBar():Message("softwrap: on")
    else
        micro.InfoBar():Message("softwrap: off")
    end
end
