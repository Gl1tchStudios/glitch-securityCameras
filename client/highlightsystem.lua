-- Glitch Studios - glitch-securityCameras (client)
-- Prop outlines. Entities are looked up once per prop and cached, and the outline is only
-- touched when it changes. SecCam is the one table shared between the client files.

SecCam = {}

local active = false
local outlined = {}                     -- entity -> true
local cache = setmetatable({}, { __mode = 'k' })   -- prop table -> { entity, checkedAt }

local function findEntity(coords, hash)
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, hash, false, false, false)
    if entity ~= 0 and DoesEntityExist(entity) then return entity end
    return nil
end

local function clearAll()
    for entity in pairs(outlined) do
        if DoesEntityExist(entity) then SetEntityDrawOutline(entity, false) end
    end
    outlined = {}
end

local function outline(entity, color)
    color = color or { r = 0, g = 255, b = 0, a = 200 }
    SetEntityDrawOutline(entity, true)
    SetEntityDrawOutlineColor(color.r, color.g, color.b, color.a)
    outlined[entity] = true
end

function SecCam.SetHighlightActive(state)
    active = state and true or false
    if not active then clearAll() end
end

function SecCam.ClearHighlights()
    clearAll()
end

-- Highlights a config prop. The entity is cached and looked up again at most once a second
-- while it is missing (the area may still be streaming in).
function SecCam.HighlightConfigProp(prop, color)
    if not active then return end
    local entry = cache[prop]
    if not entry then
        entry = { entity = nil, checkedAt = 0 }
        cache[prop] = entry
    end
    if not entry.entity or not DoesEntityExist(entry.entity) then
        local now = GetGameTimer()
        if now - entry.checkedAt < 1000 then return end
        entry.checkedAt = now
        entry.entity = findEntity(prop.position, prop.hash)
    end
    if entry.entity and not outlined[entry.entity] then
        outline(entry.entity, color or prop.highlightColor)
    end
end

-- Exports for other resources ---------------------------------------------------------------

exports('HighlightProp', function(coords, modelHash, color)
    if not active or not coords or not modelHash then return nil end
    local entity = findEntity(coords, modelHash)
    if not entity then return nil end
    outline(entity, color)
    return entity
end)

exports('RemoveHighlight', function(entity)
    if entity and outlined[entity] then
        if DoesEntityExist(entity) then SetEntityDrawOutline(entity, false) end
        outlined[entity] = nil
    end
end)

exports('ClearAllHighlights', clearAll)
exports('SetHighlightActive', SecCam.SetHighlightActive)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then clearAll() end
end)
