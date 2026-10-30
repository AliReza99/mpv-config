-- load subtitles from the video's folder whose season/episode match the video
-- (movies: every sub without an episode tag). Best one gets selected.
local utils = require "mp.utils"

local VIDEO = {mkv=1, mp4=1, avi=1, m4v=1, webm=1, mov=1, wmv=1, ts=1}
-- .sub left out: here it is only the vobsub half of an .idx pair
local SUB = {srt=1, ass=1, ssa=1, vtt=1, idx=1, sup=1}

local function ext(name) return (name:match("%.([^.]+)$") or ""):lower() end
local function stem(name) return name:gsub("%.[^.]+$", "") end

-- each returns season (or nil), episode; first hit wins
local WITH_SEASON = {
    function(n) return n:match("%f[%w]se?(%d%d?)[ %-]*x?e ?%(?(%d%d?%d?)%f[%D]") end, -- s01e01 s01 e01 s05xe01 s1-e1 se02e01 s08 e (14)
    function(n) return n:match("%f[%d](%d%d?)x(%d%d)%f[%D]") end,                      -- 01x02, 2x01 (not 1920x1080)
    function(n) return n:match("season (%d+)%A+episode (%d+)") end,                    -- lost(season 5-episode 0-...)
    function(n) return n:match("%f[%w]s(%d%d?) %- (%d%d?%d?)%f[%D]") end,              -- attack on titan s2 - 01
}
local EPISODE_ONLY = {
    function(n) return n:match("%f[%w]ep?(%d%d?%d?)%f[%D]") end,   -- e01, ep01
    function(n) return n:match("^(%d%d?%d?) ?[-&]") end,           -- 1-pilot, 01 - dekalog, 1 & 2-la x
    function(n) return n:match("^(%d%d?%d?)%a*$") end,             -- 1, 11en
    function(n) return n:match(" %- (%d%d?%d?)%f[%D]") end,        -- arcane - 01
    function(n)                                                    -- dekalog 1 720p: first short number token
        for tok in n:gmatch("[^ %-%[%]()]+") do
            if tok:match("^%d%d?%d?$") then return tok end
        end
    end,
}

-- returns {s=, e=} or nil. series=false skips episode-only rules (movies like "12 Monkeys")
local function parse(filename, series)
    local n = stem(filename):lower():gsub("[._]", " ")
    for _, f in ipairs(WITH_SEASON) do
        local s, e = f(n)
        if s then return {s = tonumber(s), e = tonumber(e)} end
    end
    if not series then return nil end
    -- "05. the last of us s02e02" already returned above, so a leading number here is the episode
    for _, f in ipairs(EPISODE_ONLY) do
        local e = f(n)
        if e then return {e = tonumber(e)} end
    end
end

local function score(sub, video)
    local n, s = sub:lower(), 0
    if stem(sub) == stem(video) then s = s + 4 end
    if n:find(".edited", 1, true) then s = s + 2 end
    for _, p in ipairs({"%f[%a]fa%f[%A]", "farsi", "persian", "parsian", "%f[%a]per%f[%A]"}) do
        if n:find(p) then s = s + 1; break end
    end
    return s
end

-- pure matcher: names in dir -> sorted list of matching sub names
local function pick(video, files, dir)
    local nvideo = 0
    for _, f in ipairs(files) do if VIDEO[ext(f)] then nvideo = nvideo + 1 end end
    local series = nvideo > 1
    local v = parse(video, series)
    local folder_season = tonumber((dir:gsub("/+$", ""):match("[^/]*$") or ""):lower():match("^s?(%d%d?)$"))
    local vs = v and (v.s or folder_season)

    local out = {}
    for _, f in ipairs(files) do
        if SUB[ext(f)] then
            local s = parse(f, series)
            local ok
            if not v then ok = not (s and s.s)            -- movie: skip subs tagged with season+episode
            else ok = s and s.e == v.e and (not s.s or not vs or s.s == vs) end
            if ok then out[#out + 1] = f end
        end
    end
    table.sort(out, function(a, b)
        local sa, sb = score(a, video), score(b, video)
        if sa ~= sb then return sa > sb end
        return a < b
    end)
    return out
end

local function on_load()
    local path = mp.get_property("path")
    if not path or path:find("://", 1, true) then return end
    path = utils.join_path(mp.get_property("working-directory", ""), path)
    local dir, video = utils.split_path(path)
    local files = utils.readdir(dir, "files")
    if not files then return end

    local subs = pick(video, files, dir)
    if #subs == 0 then return end

    local loaded = {}
    for _, t in ipairs(mp.get_property_native("track-list", {})) do
        if t.type == "sub" and t["external-filename"] then loaded[t["external-filename"]] = t.id end
    end
    for i, f in ipairs(subs) do
        local p = utils.join_path(dir, f)
        if loaded[p] then
            if i == 1 then mp.set_property_number("sid", loaded[p]) end
        else
            mp.commandv("sub-add", p, i == 1 and "select" or "auto")
        end
    end
end

mp.register_event("file-loaded", function()
    local ok, err = pcall(on_load)
    if not ok then mp.msg.warn("autosub-match: " .. tostring(err)) end
end)

return {parse = parse, pick = pick}
