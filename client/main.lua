-- Glitch Studios - glitch-securityCameras (client)
-- Camera mode, prop targeting and the hack flow. The player ped stays where it is: only the
-- scripted camera and the streaming focus move.

local L = Config.Locale
local C = Config.Controls

local inCameraMode = false
local busy = false          -- entering or switching camera
local exiting = false
local hacking = false

local currentCam = nil      -- the Config.Cameras entry being viewed
local camHandle = nil
local cycleIds = {}         -- camera ids the arrow keys may switch between
local viewMode = 'normal'
local targetProp = nil
local initialZ = nil
local radarWasHidden = false
local enteredAt = 0
local hackedCache = {}      -- mirror of GlobalState['secCam:hacked']
local attempt = nil         -- pending AttemptCameraHack call

local function debugPrint(...)
    if Config.Debug then print('[glitch-securityCameras]', ...) end
end

local function keyOf(cameraId, propId)
    return ('%s:%s'):format(cameraId, propId)
end

local function isHacked(cameraId, propId)
    return hackedCache[keyOf(cameraId, propId)] == true
end

local function nui(message)
    SendNUIMessage(message)
end

local function notify(message, style)
    nui({ type = 'showNotification', message = message, style = style or 'info' })
end

-- Hacked state shared by the server ------------------------------------------------------------

AddStateBagChangeHandler('secCam:hacked', 'global', function(_, _, value)
    hackedCache = type(value) == 'table' and value or {}
end)

CreateThread(function()
    local value = GlobalState['secCam:hacked']
    if type(value) == 'table' then hackedCache = value end
end)

-- Camera cycle ------------------------------------------------------------------------------------

local function groupOf(cam)
    if cam.group then return cam.group end
    local n = tonumber(cam.id)
    if n then return math.floor(n / Config.GroupBlock) end
    return 'other'
end

-- Returns the ordered list of camera ids the player can switch between, or nil when the
-- entered camera is not in the allowed list.
local function buildCycle(entered, allowed)
    local set = nil
    if type(allowed) == 'table' and #allowed > 0 then
        set = {}
        for _, id in ipairs(allowed) do set[id] = true end
        if not set[entered.id] then return nil end
    end

    local ids = {}
    local group = groupOf(entered)
    for _, cam in ipairs(Config.Cameras) do
        if set then
            if set[cam.id] then ids[#ids + 1] = cam.id end
        elseif groupOf(cam) == group then
            ids[#ids + 1] = cam.id
        end
    end
    return ids
end

-- View modes --------------------------------------------------------------------------------------

local function applyViewMode(mode)
    viewMode = mode
    if mode == 'normal' then
        ClearTimecycleModifier()
        SetNightvision(false)
        SetSeethrough(false)
    elseif mode == 'thermal' then
        SetNightvision(true)
        SetSeethrough(true)
    else
        SetNightvision(true)
        SetSeethrough(false)
    end
    nui({ type = 'setViewMode', mode = mode })
end

local function nextViewMode()
    local modes = currentCam and currentCam.modes or {}
    local nightVision = modes.nightVision ~= false
    local thermal = modes.thermal ~= false
    if not nightVision and not thermal then return nil end

    if viewMode == 'normal' then
        return thermal and 'thermal' or 'nightvision'
    elseif viewMode == 'thermal' then
        return nightVision and 'nightvision' or 'normal'
    end
    return 'normal'
end

-- Rotation ----------------------------------------------------------------------------------------

local DEFAULT_LIMITS = { x = { min = -75.0, max = -5 }, z = { min = 0.0, max = 360.0 } }

local function updateRotation()
    local mouseX = GetDisabledControlNormal(0, 1) * 8.0
    local mouseY = GetDisabledControlNormal(0, 2) * 8.0
    if math.abs(mouseX) <= 0.01 and math.abs(mouseY) <= 0.01 then return end

    local camRot = GetCamRot(camHandle, 2)
    local limits = currentCam.rotationLimits or DEFAULT_LIMITS

    local rotX = math.max(limits.x.min, math.min(limits.x.max, camRot.x - mouseY * 0.5))
    local rotZ = camRot.z - mouseX * 0.5

    local normalizedZ = (camRot.z % 360 + 360) % 360
    local potentialZ = (rotZ % 360 + 360) % 360
    if not initialZ then initialZ = normalizedZ end

    local minZ, maxZ = limits.z.min, limits.z.max
    if math.abs(maxZ - minZ) < 360 and math.abs(mouseX) > 0.01 and minZ <= maxZ then
        local nearMin = math.abs(normalizedZ - minZ) < 5.0
        local nearMax = math.abs(normalizedZ - maxZ) < 5.0
        if nearMin and mouseX > 0 then
            rotZ = camRot.z + (minZ - normalizedZ)
        elseif nearMax and mouseX < 0 then
            rotZ = camRot.z + (maxZ - normalizedZ)
        elseif normalizedZ >= minZ and normalizedZ <= maxZ then
            if potentialZ < minZ then
                rotZ = rotZ + (minZ - potentialZ)
            elseif potentialZ > maxZ then
                rotZ = rotZ + (maxZ - potentialZ)
            end
        elseif normalizedZ < minZ and potentialZ > normalizedZ then
            if potentialZ > maxZ then rotZ = rotZ + (maxZ - potentialZ) end
        elseif normalizedZ > maxZ and potentialZ < normalizedZ then
            if potentialZ < minZ then rotZ = rotZ + (minZ - potentialZ) end
        else
            rotZ = camRot.z
        end
    end

    SetCamRot(camHandle, rotX, camRot.y, rotZ, 2)
end

-- Prop detection ----------------------------------------------------------------------------------

local PROP_SIZES = {
    default = { radius = 1.0, tolerance = 15.0 },
    door = { radius = 1.5, tolerance = 20.0 },
    doubleDoor = { radius = 1.2, tolerance = 18.0 },
}

local function isPropInView(camCoords, camRot, prop)
    local distance = #(prop.position - camCoords)
    if distance > 50.0 or distance < 0.01 then return false end

    local size = prop.size or PROP_SIZES[prop.type or 'default'] or PROP_SIZES.default
    local rz, rx = math.rad(camRot.z), math.rad(camRot.x)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local toProp = (prop.position - camCoords) / distance
    local dot = dir.x * toProp.x + dir.y * toProp.y + dir.z * toProp.z
    local angle = math.deg(math.acos(math.min(1.0, math.max(-1.0, dot))))

    local tolerance = size.tolerance * (size.radius * 0.5) * (1.0 + distance / 40.0)
    return angle < math.max(tolerance, 10.0)
end

local function setTarget(prop)
    targetProp = prop
    SecCam.ClearHighlights()
    if prop then
        SecCam.HighlightConfigProp(prop)
        local text = L.hackPrompt:format(L.interactKey or 'E')
        if prop.interactionText then text = text .. ' - ' .. prop.interactionText end
        nui({ type = 'setTarget', text = text })
    else
        nui({ type = 'setTarget' })
    end
end

local function updateTarget()
    local camCoords = GetCamCoord(camHandle)
    local camRot = GetCamRot(camHandle, 2)
    local found = nil
    for _, prop in ipairs(currentCam.interactiveProps or {}) do
        if not isHacked(currentCam.id, prop.propUniqueId) and isPropInView(camCoords, camRot, prop) then
            found = prop
            break
        end
    end

    if found ~= targetProp then
        setTarget(found)
    elseif found then
        SecCam.HighlightConfigProp(found)   -- retries while the prop is still streaming in
    end
end

-- Hack flow ---------------------------------------------------------------------------------------

local function buildArgs(params)
    if type(params) ~= 'table' then
        if params == nil then return {}, 0 end
        return { params }, 1
    end
    if params[1] ~= nil then return params, #params end

    local args, n = {}, 0
    for i, name in ipairs(Config.HackParamOrder) do
        if params[name] ~= nil then
            args[i] = params[name]
            n = i
        end
    end
    return args, n
end

-- Returns true or false for the minigame result, or nil when it could not be started.
local function runMinigame(prop)
    local spec, params = prop.hackExport, prop.hackParams
    if not spec and not prop.hackEvent and Config.DefaultHack then
        spec, params = Config.DefaultHack.export, Config.DefaultHack.params
    end

    if type(spec) == 'string' then
        local resource, name = spec:match('^([^:]+):(.+)$')
        if not resource or GetResourceState(resource) ~= 'started' then
            -- Minigame resource missing: fall back to an ox_lib skill check when allowed.
            if not prop.hackExport and Config.FallbackSkillCheck then
                return lib.skillCheck(Config.FallbackSkillCheck) and true or false
            end
            return nil
        end
        local args, n = buildArgs(params)
        local ok, result = pcall(function()
            return exports[resource][name](table.unpack(args, 1, n))
        end)
        if not ok then
            debugPrint('hack export failed:', result)
            return nil
        end
        return result and true or false
    end

    if prop.hackEvent then
        local p = promise.new()
        local resolved = false
        local function resolve(value)
            if resolved then return end
            resolved = true
            p:resolve(value)
        end
        TriggerEvent(prop.hackEvent, params or {}, function(success) resolve(success and true or false) end)
        SetTimeout(Config.HackEventTimeoutMs or 120000, function() resolve(false) end)
        return Citizen.Await(p)
    end

    return nil
end

local function finishAttempt(success)
    if attempt and not attempt.done then
        attempt.success = success
        attempt.done = true
    end
end

local exitCameraMode

local function runHack(prop, camera)
    if hacking or not inCameraMode then return end
    hacking = true
    setTarget(nil)

    local cameraId, propId = camera.id, prop.propUniqueId
    local okToStart, reason = lib.callback.await('glitch-securityCameras:beginHack', false, cameraId, propId)
    if not okToStart and reason == 'not_viewing' and inCameraMode then
        -- The server lost our view (resource restart or a dropped report): report it again and retry once.
        TriggerServerEvent('glitch-securityCameras:setCamera', cameraId)
        Wait(300)
        okToStart, reason = lib.callback.await('glitch-securityCameras:beginHack', false, cameraId, propId)
    end
    if not okToStart then
        if inCameraMode then notify(L.alreadyHacked, 'info') end
        hacking = false
        return
    end

    local result = runMinigame(prop)
    local success = false

    if result == nil then
        if inCameraMode then notify(L.unavailable, 'error') end
    elseif result then
        success = lib.callback.await('glitch-securityCameras:completeHack', false, cameraId, propId) and true or false
    end
    if not success then
        lib.callback.await('glitch-securityCameras:failHack', false)
    end

    if success then
        hackedCache[keyOf(cameraId, propId)] = true
        if inCameraMode then
            applyViewMode('normal')
            notify(prop.successText or L.hackSuccess, 'success')
        end
        if prop.onSuccessEvent then TriggerEvent(prop.onSuccessEvent, propId) end
    else
        if result ~= nil and inCameraMode then notify(prop.failText or L.hackFail, 'error') end
        if prop.onFailEvent then TriggerEvent(prop.onFailEvent, propId) end
    end

    hacking = false
    finishAttempt(success)

    if prop.exitOnHack and inCameraMode then
        if success then Wait(1500) end
        exitCameraMode()
    end
end

-- Enter, exit, switch -----------------------------------------------------------------------------

-- Undoes everything camera mode changed. No Waits, so it is safe in onResourceStop.
local function cleanup()
    RenderScriptCams(false, false, 0, true, false)
    if camHandle then
        DestroyCam(camHandle, false)
        camHandle = nil
    end
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
    DisplayRadar(not radarWasHidden)
    ClearTimecycleModifier()
    SetNightvision(false)
    SetSeethrough(false)
    SecCam.SetHighlightActive(false)
    TriggerServerEvent('glitch-securityCameras:setCamera', nil)
    nui({ type = 'hideCameraUI' })
    viewMode = 'normal'
    targetProp = nil
    currentCam = nil
    initialZ = nil
end

exitCameraMode = function()
    if not inCameraMode or exiting then return end
    exiting = true
    inCameraMode = false

    while busy do Wait(50) end

    DoScreenFadeOut(500)
    Wait(500)
    cleanup()
    DoScreenFadeIn(500)

    exiting = false
    finishAttempt(false)
end

local function moveTo(cam)
    if busy or hacking or not inCameraMode then return end
    busy = true

    applyViewMode('normal')
    setTarget(nil)

    DoScreenFadeOut(300)
    Wait(300)
    SetFocusPosAndVel(cam.position.x, cam.position.y, cam.position.z, 0.0, 0.0, 0.0)
    Wait(500)

    if inCameraMode then
        currentCam = cam
        initialZ = nil
        TriggerServerEvent('glitch-securityCameras:setCamera', cam.id)
        SetCamRot(camHandle, cam.rotation.x, cam.rotation.y, cam.rotation.z, 2)
        SetCamCoord(camHandle, cam.position.x, cam.position.y, cam.position.z)
        nui({
            type = 'updateCameraInfo',
            cameraId = cam.id,
            cameraName = cam.name,
            location = cam.location or L.unknownArea,
        })
    end
    DoScreenFadeIn(300)
    busy = false
end

local function switchStep(step)
    if not inCameraMode or busy or hacking or #cycleIds < 2 then return end

    local pos = 1
    for i, id in ipairs(cycleIds) do
        if id == currentCam.id then pos = i break end
    end
    for _ = 1, #cycleIds do
        pos = (pos - 1 + step) % #cycleIds + 1
        local cam = SecCam.GetCameraById(cycleIds[pos])
        if cam then
            if cam ~= currentCam then CreateThread(function() moveTo(cam) end) end
            return
        end
    end
end

local function pressed(control)
    return IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control)
end

local function controlLoop()
    while inCameraMode do
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, C.interact, true)
        EnableControlAction(0, C.exit, true)
        EnableControlAction(0, C.left, true)
        EnableControlAction(0, C.right, true)
        EnableControlAction(0, C.viewMode, true)

        if not busy and not hacking and currentCam and camHandle then
            updateRotation()

            if pressed(C.exit) then
                CreateThread(exitCameraMode)
            elseif pressed(C.left) then
                switchStep(-1)
            elseif pressed(C.right) then
                switchStep(1)
            elseif pressed(C.viewMode) then
                local mode = nextViewMode()
                if mode then
                    applyViewMode(mode)
                    notify(L.viewModeSwitched:format(L.modeNames[mode] or mode), 'info')
                end
            elseif pressed(C.interact) and targetProp then
                local prop, camera = targetProp, currentCam
                CreateThread(function() runHack(prop, camera) end)
            end
        end
        Wait(0)
    end
end

-- Slow checks: prop in view, damage, auto exit. Every 150 ms instead of every frame.
local function watchLoop()
    local ped = PlayerPedId()
    local lastHealth = GetEntityHealth(ped)
    while inCameraMode do
        Wait(150)
        if not inCameraMode then break end

        if not busy and not hacking and currentCam and camHandle then
            updateTarget()
        end

        local health = GetEntityHealth(ped)
        if IsEntityDead(ped) or health < lastHealth then
            CreateThread(exitCameraMode)
        end
        lastHealth = health

        if Config.AutoExitEnabled and not hacking
            and GetGameTimer() - enteredAt > Config.AutoExitTime * 1000 then
            CreateThread(exitCameraMode)
        end
    end
end

local function enterCameraMode(cameraId, allowed)
    if inCameraMode or busy or exiting then return false end

    local cam = SecCam.GetCameraById(cameraId)
    if not cam then
        debugPrint('unknown camera', cameraId)
        return false
    end
    local ids = buildCycle(cam, allowed)
    if not ids then
        debugPrint('camera not in the allowed list', cameraId)
        return false
    end

    busy = true
    cycleIds = ids

    DoScreenFadeOut(500)
    Wait(500)

    local ped = PlayerPedId()
    radarWasHidden = IsRadarHidden()
    FreezeEntityPosition(ped, true)
    SetFocusPosAndVel(cam.position.x, cam.position.y, cam.position.z, 0.0, 0.0, 0.0)
    Wait(1000)

    currentCam = cam
    camHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamRot(camHandle, cam.rotation.x, cam.rotation.y, cam.rotation.z, 2)
    SetCamCoord(camHandle, cam.position.x, cam.position.y, cam.position.z)
    SetCamActive(camHandle, true)
    RenderScriptCams(true, false, 0, true, false)

    inCameraMode = true
    targetProp = nil
    initialZ = nil
    enteredAt = GetGameTimer()
    TriggerServerEvent('glitch-securityCameras:setCamera', cam.id)
    SecCam.SetHighlightActive(true)
    SetNuiFocus(false, false)
    DisplayRadar(false)

    nui({
        type = 'showCameraUI',
        cameraId = cam.id,
        cameraName = cam.name or ('Camera ' .. tostring(cam.id)),
        location = cam.location or L.unknownArea,
        labels = L.keys,
        ui = L.ui,
    })
    DoScreenFadeIn(500)
    busy = false

    CreateThread(controlLoop)
    CreateThread(watchLoop)
    return true
end

-- Exports -----------------------------------------------------------------------------------------

exports('EnterCameraMode', enterCameraMode)
exports('ExitCameraMode', exitCameraMode)

-- Takes an index into the camera list, like it always did.
exports('SwitchCamera', function(cameraIndex)
    local cam = Config.Cameras[cameraIndex]
    if not cam or not inCameraMode then return end
    for _, id in ipairs(cycleIds) do
        if id == cam.id then
            if cam ~= currentCam then CreateThread(function() moveTo(cam) end) end
            return
        end
    end
end)

-- Enters the camera and waits for the first hack result. Returns true when the hack was won
-- and confirmed by the server, false when it failed, the player left or entering failed.
exports('AttemptCameraHack', function(cameraId, propId, allowedCameras)
    if not cameraId or not propId or attempt then return false end

    local current = { done = false, success = false }
    attempt = current
    if not enterCameraMode(cameraId, allowedCameras) then
        attempt = nil
        return false
    end

    while not current.done do Wait(100) end
    attempt = nil
    return current.success
end)

-- Shows a message on the camera screen.
exports('ShowCameraNotification', function(message, style)
    if inCameraMode and type(message) == 'string' then notify(message, style) end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if inCameraMode or camHandle then
        inCameraMode = false
        cleanup()
        if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(0) end
    end
end)
