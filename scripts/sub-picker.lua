-- ctrl+o: pick a subtitle file with zenity and load it
local utils = require "mp.utils"

mp.add_key_binding("ctrl+o", "pick-subtitle", function()
    local path = mp.get_property("path")
    local dir = path and utils.split_path(utils.join_path(mp.get_property("working-directory"), path)) or os.getenv("HOME")
    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = {"zenity", "--file-selection", "--title=Select subtitle",
                "--filename=" .. dir .. "/",
                "--file-filter=Subtitles | *.srt *.ass *.ssa *.vtt *.sub *.idx *.sup",
                "--file-filter=All files | *"},
    }, function(ok, res)
        if not ok or res.status ~= 0 then return end
        local file = res.stdout:gsub("\n$", "")
        if file ~= "" then
            mp.commandv("sub-add", file, "select")
            mp.osd_message("Loaded: " .. file:match("[^/]+$"))
        end
    end)
end)
