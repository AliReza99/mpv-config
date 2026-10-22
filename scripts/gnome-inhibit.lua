-- mpv runs under XWayland (gpu-context=x11vk), so its built-in X11 screensaver
-- blocking never reaches GNOME. Hold a GNOME idle inhibitor while playing instead.

local inhibitor = nil

local function release()
    if inhibitor then
        mp.abort_async_command(inhibitor)
        inhibitor = nil
    end
end

local function acquire()
    if inhibitor then return end
    inhibitor = mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        args = {"gnome-session-inhibit", "--inhibit=idle", "--inhibit-only",
                "--app-id=mpv", "--reason=Playing video"},
    }, function() end)
end

local function update()
    local playing = not mp.get_property_bool("pause", true)
        and not mp.get_property_bool("idle-active", false)
        and mp.get_property("video") ~= "no"
    if playing then acquire() else release() end
end

mp.observe_property("pause", "bool", update)
mp.observe_property("idle-active", "bool", update)
mp.observe_property("video", "string", update)
mp.register_event("shutdown", release)
