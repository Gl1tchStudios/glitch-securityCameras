-- Glitch Studios - glitch-securityCameras (server)
-- Hack tracking. The minigame itself runs on the client, so the server cannot prove it was won.
-- What it does enforce: the player must have told the server which camera they are viewing, a
-- hack must be opened through a callback first, only one hack per player at a time, a minimum
-- play time, one result per opened hack, a cap on hacked props per player, an optional
-- authorizer (exports SetHackAuthorizer) and a shared hacked state (GlobalState['secCam:hacked'])
-- so every player and late joiner sees the same props. The hacked list is kept in memory only.

local hacked = {}       -- key -> { expires = os.time(), by = source }
local hackedCount = 0
local sessions = {}     -- source -> { key, cameraId, propId, startedAt }
local lastBegin = {}    -- source -> GetGameTimer() of the last start
local viewing = {}      -- source -> camera id the player reports they are viewing
local registered = {}   -- camera id (as string) -> { propId = true }, from RegisterCamera
local authorizer        -- optional function(src, cameraId, propId) -> boolean

local MAX_HACKED = 512
local STATE_KEY = 'secCam:hacked'

local function debugPrint(...)
    if Config.Debug then print('[glitch-securityCameras]', ...) end
end

local function keyOf(cameraId, propId)
    return ('%s:%s'):format(cameraId, propId)
end

local function validId(value)
    local t = type(value)
    if t == 'number' then return value == value end
    return t == 'string' and #value > 0 and #value <= 48
end

local function publish()
    local snapshot = {}
    for key in pairs(hacked) do snapshot[key] = true end
    GlobalState[STATE_KEY] = snapshot
end

-- Static cameras from the config are checked. Cameras added at run time by other resources
-- live on the client only, so they are accepted when Config.AllowRuntimeCameras is on.
local function isKnownProp(cameraId, propId)
    for _, camera in ipairs(Config.Cameras) do
        if camera.id == cameraId then
            for _, prop in ipairs(camera.interactiveProps or {}) do
                if prop.propUniqueId == propId then return true end
            end
            return false
        end
    end
    local reg = registered[tostring(cameraId)]
    if reg then return reg[tostring(propId)] == true end
    return Config.AllowRuntimeCameras
end

local function hackedBy(src)
    local n = 0
    for _, entry in pairs(hacked) do
        if entry.by == src then n = n + 1 end
    end
    return n
end

local function setHacked(key, src)
    if not hacked[key] then
        if hackedCount >= MAX_HACKED then return false end
        if hackedBy(src) >= (Config.MaxHacksPerPlayer or 8) then return false end
        hackedCount = hackedCount + 1
    end
    hacked[key] = { expires = os.time() + Config.HackResetSeconds, by = src }
    publish()
    return true
end

local function clearHacked(key)
    if hacked[key] then
        hacked[key] = nil
        hackedCount = hackedCount - 1
        publish()
    end
end

lib.callback.register('glitch-securityCameras:beginHack', function(src, cameraId, propId)
    if not validId(cameraId) or not validId(propId) then return false, 'invalid' end
    if not isKnownProp(cameraId, propId) then return false, 'unknown' end

    if viewing[src] ~= cameraId then return false, 'not_viewing' end

    local now = GetGameTimer()
    if lastBegin[src] and now - lastBegin[src] < Config.BeginCooldownMs then return false, 'cooldown' end

    local key = keyOf(cameraId, propId)
    if hacked[key] then return false, 'hacked' end

    if authorizer then
        local ok, allowed = pcall(authorizer, src, cameraId, propId)
        if not ok or not allowed then return false, 'denied' end
    end
    lastBegin[src] = now

    sessions[src] = { key = key, cameraId = cameraId, propId = propId, startedAt = now }
    return true
end)

lib.callback.register('glitch-securityCameras:completeHack', function(src, cameraId, propId)
    local session = sessions[src]
    sessions[src] = nil
    if not session or not validId(cameraId) or not validId(propId) then return false end
    if viewing[src] ~= cameraId then return false end
    if session.key ~= keyOf(cameraId, propId) then return false end
    if GetGameTimer() - session.startedAt < Config.MinHackSeconds * 1000 then
        debugPrint(('hack by %s on %s was too fast'):format(src, session.key))
        return false
    end
    if hacked[session.key] then return false end
    if not setHacked(session.key, src) then return false end

    debugPrint(('hack on %s completed by %s'):format(session.key, src))
    TriggerEvent('glitch-securityCameras:server:hackCompleted', src, session.cameraId, session.propId)
    return true
end)

lib.callback.register('glitch-securityCameras:failHack', function(src)
    sessions[src] = nil
    return true
end)

-- The client reports which camera it is viewing (nil when it leaves camera mode).
local function isKnownCamera(cameraId)
    for _, camera in ipairs(Config.Cameras) do
        if camera.id == cameraId then return true end
    end
    if registered[tostring(cameraId)] then return true end
    return Config.AllowRuntimeCameras == true
end

local lastSet = {}      -- source -> GetGameTimer() of the last setCamera call

RegisterNetEvent('glitch-securityCameras:setCamera', function(cameraId)
    local src = source
    -- Leaving camera mode is never rate limited, so a quick exit cannot leave a stale view behind.
    if cameraId == nil then
        viewing[src] = nil
        sessions[src] = nil
        return
    end
    local now = GetGameTimer()
    if lastSet[src] and now - lastSet[src] < 250 then return end
    lastSet[src] = now
    if validId(cameraId) and isKnownCamera(cameraId) then
        -- Moving to another camera abandons any hack opened on the previous one.
        if viewing[src] ~= cameraId then sessions[src] = nil end
        viewing[src] = cameraId
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    sessions[src] = nil
    lastBegin[src] = nil
    viewing[src] = nil
    lastSet[src] = nil
    -- Server ids are reused: detach this player's hacks so a new player does not inherit the cap.
    for _, entry in pairs(hacked) do
        if entry.by == src then entry.by = nil end
    end
end)

-- Drop expired hacks. Does nothing while the table is empty.
CreateThread(function()
    while true do
        Wait(5000)
        if hackedCount > 0 then
            local now = os.time()
            local changed = false
            for key, entry in pairs(hacked) do
                if entry.expires <= now then
                    hacked[key] = nil
                    hackedCount = hackedCount - 1
                    changed = true
                end
            end
            if changed then publish() end
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    GlobalState[STATE_KEY] = {}
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    GlobalState[STATE_KEY] = nil
end)

-- Exports ---------------------------------------------------------------------------------

exports('IsHacked', function(cameraId, propId)
    if not validId(cameraId) or not validId(propId) then return false end
    return hacked[keyOf(cameraId, propId)] ~= nil
end)

-- Returns the player source that completed the hack, or nil.
exports('GetHackedBy', function(cameraId, propId)
    if not validId(cameraId) or not validId(propId) then return nil end
    local entry = hacked[keyOf(cameraId, propId)]
    return entry and entry.by or nil
end)

-- Restricts hacking to cameras and props a server resource declared. propIds is a list.
-- Once a camera is registered, only its listed props can be hacked (even with AllowRuntimeCameras).
exports('RegisterCamera', function(cameraId, propIds)
    if not validId(cameraId) or type(propIds) ~= 'table' then return false end
    local set = {}
    for _, id in ipairs(propIds) do
        if validId(id) then set[tostring(id)] = true end
    end
    registered[tostring(cameraId)] = set
    return true
end)

-- Optional gate: fn(source, cameraId, propId) must return true to let a player start a hack.
-- Use it for job, item or permission checks. Pass nil to remove it.
exports('SetHackAuthorizer', function(fn)
    authorizer = type(fn) == 'function' and fn or nil
    return true
end)

-- Lets a heist script make a prop hackable again (for example when a new run starts).
exports('ResetHack', function(cameraId, propId)
    if not validId(cameraId) or not validId(propId) then return false end
    clearHacked(keyOf(cameraId, propId))
    return true
end)

exports('ResetAllHacks', function()
    hacked = {}
    hackedCount = 0
    publish()
    return true
end)
