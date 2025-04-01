-- Luma Security Camera System
-- Copyright (C) 2024 Luma
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

inCameraMode = false

local currentCameraIndex = 1
local currentCamera = nil
local playerOriginalPosition = nil
local interactablePropInView = nil
local completedHacks = {}
local currentViewMode = "normal"

local controls = {
    up = 172,    -- Arrow Up
    down = 173,  -- Arrow Down 
    left = 174,  -- Arrow Left
    right = 175, -- Arrow Right
    exit = 194,  -- ESC
    interact = 38, -- E
    viewMode = 86 -- V
}

-- ============================
--  CORE CAMERA FUNCTIONALITY
-- ============================

function EnterCameraMode(cameraIndex)
    if inCameraMode then return end
    
    cameraIndex = cameraIndex or 1
    if not config.Cameras or not config.Cameras[cameraIndex] then 
        print("^1Invalid camera index or camera config^7")
        return 
    end
    
    exports['luma-securityCameras']:SetHighlightActive(false)
    exports['luma-securityCameras']:ClearAllHighlights()
    
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    
    local playerPed = PlayerPedId()
    playerOriginalPosition = GetEntityCoords(playerPed)
    
    SetEntityVisible(playerPed, false, false)
    SetEntityInvincible(playerPed, true)
    
    local cameraPos = config.Cameras[cameraIndex].position
    SetEntityCoords(playerPed, cameraPos.x, cameraPos.y, cameraPos.z - 5.0, false, false, false, false)
    
    Citizen.Wait(1000)
    
    currentCameraIndex = cameraIndex
    inCameraMode = true
    interactablePropInView = nil
    ResetCameraUI()
    
    currentCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamRot(currentCamera, 
        config.Cameras[currentCameraIndex].rotation.x, 
        config.Cameras[currentCameraIndex].rotation.y, 
        config.Cameras[currentCameraIndex].rotation.z, 2)
    SetCamCoord(currentCamera, 
        config.Cameras[currentCameraIndex].position.x, 
        config.Cameras[currentCameraIndex].position.y, 
        config.Cameras[currentCameraIndex].position.z)
    SetCamActive(currentCamera, true)
    RenderScriptCams(true, false, 0, true, false)
    
    exports['luma-securityCameras']:SetHighlightActive(true)
    
    DoScreenFadeIn(500)
    
    SetNuiFocus(false, false)
    FreezeEntityPosition(playerPed, true)
    DisplayRadar(false)
    
    CreateThread(function()
        while inCameraMode do
            DisableAllControlActions(0)
            
            EnableControlAction(0, 1, true)  -- Mouse look horizontal
            EnableControlAction(0, 2, true)  -- Mouse look vertical
            EnableControlAction(0, controls.interact, true) -- E key
            EnableControlAction(0, controls.exit, true)    -- ESC key
            EnableControlAction(0, controls.left, true)   -- Left arrow
            EnableControlAction(0, controls.right, true)  -- Right arrow
            EnableControlAction(0, controls.viewMode, true) -- V key
            
            HandleCameraControls()
            
            CheckInteractiveProps()
            
            Citizen.Wait(0)
        end
    end)
    
    SendNUIMessage({
        type = 'showCameraUI',
        cameraId = currentCameraIndex,
        cameraName = config.Cameras[currentCameraIndex].name or "Camera " .. currentCameraIndex,
        location = config.Cameras[currentCameraIndex].location or "Unknown Area",
        totalCameras = #config.Cameras
    })
    
    print("^2Camera mode activated: Camera " .. currentCameraIndex .. "^7")
end

function ExitCameraMode()
    if not inCameraMode then return end
    
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(currentCamera, false)
    currentCamera = nil
    inCameraMode = false
    
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, 
        playerOriginalPosition.x, 
        playerOriginalPosition.y, 
        playerOriginalPosition.z, 
        false, false, false, false)
    
    SetEntityVisible(playerPed, true, false)
    SetEntityInvincible(playerPed, false)
    FreezeEntityPosition(playerPed, false)
    DisplayRadar(true)
    
    exports['luma-securityCameras']:SetHighlightActive(false)
    exports['luma-securityCameras']:ClearAllHighlights()
    
    SendNUIMessage({
        type = 'hideCameraUI'
    })
    
    ResetCameraUI()
    interactablePropInView = nil
    
    ClearTimecycleModifier()
    
    currentViewMode = "normal"
    SetNightvision(false)
    
    DoScreenFadeIn(500)
    
    print("^3Camera mode deactivated^7")
end

function SwitchCamera(cameraIndex)
    if not inCameraMode or not config.Cameras[cameraIndex] then return end
    
    exports['luma-securityCameras']:ClearAllHighlights()
    interactablePropInView = nil
    ResetCameraUI()
    
    DoScreenFadeOut(300)
    Citizen.Wait(300)
    
    local playerPed = PlayerPedId()
    local cameraPos = config.Cameras[cameraIndex].position
    SetEntityCoords(playerPed, cameraPos.x, cameraPos.y, cameraPos.z - 5.0, false, false, false, false)
    
    Citizen.Wait(500)
    
    currentCameraIndex = cameraIndex
    
    SetCamRot(currentCamera, 
        config.Cameras[currentCameraIndex].rotation.x, 
        config.Cameras[currentCameraIndex].rotation.y, 
        config.Cameras[currentCameraIndex].rotation.z, 2)
    SetCamCoord(currentCamera, 
        config.Cameras[currentCameraIndex].position.x, 
        config.Cameras[currentCameraIndex].position.y, 
        config.Cameras[currentCameraIndex].position.z)
    
    DoScreenFadeIn(300)
    
    SendNUIMessage({
        type = 'updateCamera',
        cameraId = currentCameraIndex,
        cameraName = config.Cameras[currentCameraIndex].name or "Camera " .. currentCameraIndex,
        location = config.Cameras[currentCameraIndex].location or "Unknown Area"
    })
    
    print("^2Switched to camera " .. currentCameraIndex .. "^7")
end

-- ============================
--  CAMERA CONTROL HANDLING
-- ============================

function HandleCameraControls()
    local mouseX = GetDisabledControlNormal(0, 1) * 8.0  -- mouse Right/Left
    local mouseY = GetDisabledControlNormal(0, 2) * 8.0  -- mouse Up/Down
    
    local camRot = GetCamRot(currentCamera, 2)
    local modified = false
    
    if math.abs(mouseX) > 0.01 or math.abs(mouseY) > 0.01 then
        camRot = vector3(
            camRot.x - mouseY * 0.5,
            camRot.y,
            camRot.z - mouseX * 0.5
        )
        modified = true
    end
    
    local rotLimits = config.Cameras[currentCameraIndex].rotationLimits or {
        x = {min = -89.0, max = 89.0},
        z = {min = -180.0, max = 180.0}
    }

    camRot = vector3(
        math.max(rotLimits.x.min, math.min(rotLimits.x.max, camRot.x)),
        camRot.y,
        math.max(rotLimits.z.min, math.min(rotLimits.z.max, camRot.z))
    )
    
    if modified then
        SetCamRot(currentCamera, camRot.x, camRot.y, camRot.z, 2)
    end
    
    if IsDisabledControlJustPressed(0, controls.exit) then
        ExitCameraMode()
    end
    
    if IsControlJustPressed(0, controls.left) then
        local newIndex = currentCameraIndex - 1
        if newIndex < 1 then newIndex = #config.Cameras end
        SwitchCamera(newIndex)
    elseif IsControlJustPressed(0, controls.right) then
        local newIndex = currentCameraIndex + 1
        if newIndex > #config.Cameras then newIndex = 1 end
        SwitchCamera(newIndex)
    end
    
    if IsControlJustPressed(0, controls.interact) then
        if interactablePropInView then
            TriggerHackMinigame(interactablePropInView)
        end
    end
    
    -- currently not complete
    if IsControlJustPressed(0, controls.viewMode) then -- V key
        if currentViewMode == "normal" then
            SetCameraViewMode("thermal")
        elseif currentViewMode == "thermal" then
            SetCameraViewMode("nightvision")
        else
            SetCameraViewMode("normal")
        end
        
        SendNUIMessage({
            type = 'setViewMode',
            mode = currentViewMode
        })
    end
end

-- ============================
--  PROP DETECTION SYSTEM
-- ============================

function GetPropSize(propType)
    local sizes = {
        default = {radius = 1.0, tolerance = 15.0},
        computer = {radius = 1.5, tolerance = 20.0},
        panel = {radius = 1.2, tolerance = 18.0},
        keypad = {radius = 0.5, tolerance = 12.0},
        camera = {radius = 0.6, tolerance = 13.0},
        server = {radius = 2.0, tolerance = 22.0},
        laptop = {radius = 0.8, tolerance = 15.0},
        terminal = {radius = 1.2, tolerance = 18.0},
        switch = {radius = 0.4, tolerance = 10.0},
        router = {radius = 0.7, tolerance = 14.0},
        breaker = {radius = 1.0, tolerance = 16.0},
        door = {radius = 1.8, tolerance = 20.0},
        small = {radius = 0.5, tolerance = 12.0},
        medium = {radius = 1.0, tolerance = 16.0},
        large = {radius = 2.0, tolerance = 22.0},
    }
    
    return sizes[propType] or sizes.default
end

function IsPropInView(camCoords, camRot, propPosition, propSize)
    local distance = #(propPosition - camCoords)

    if distance > 50.0 then return false end
    
    local rotationZ = math.rad(camRot.z)
    local rotationX = math.rad(camRot.x)
    
    local dirVector = vector3(
        -math.sin(rotationZ) * math.cos(rotationX),
        math.cos(rotationZ) * math.cos(rotationX),
        math.sin(rotationX)
    )
    
    local toPropVector = propPosition - camCoords
    local toPropVectorNorm = toPropVector / distance
    
    local dotProduct = dirVector.x * toPropVectorNorm.x + dirVector.y * toPropVectorNorm.y + dirVector.z * toPropVectorNorm.z
    
    local angle = math.acos(math.min(1.0, math.max(-1.0, dotProduct))) * 180 / math.pi
    
    local sizeFactor = propSize.radius * 0.5
    local distanceFactor = 1.0 + (distance / 40.0)
    local baseTolerance = propSize.tolerance * 1.0
    
    local adjustedTolerance = baseTolerance * sizeFactor * distanceFactor
    
    adjustedTolerance = math.max(adjustedTolerance, 10.0)
    
    if config.TestingMode then
        local rayLength = 50.0
        local rayEndPoint = vector3(
            camCoords.x + dirVector.x * rayLength,
            camCoords.y + dirVector.y * rayLength,
            camCoords.z + dirVector.z * rayLength
        )
        
        DrawLine(
            camCoords.x, camCoords.y, camCoords.z,
            rayEndPoint.x, rayEndPoint.y, rayEndPoint.z,
            0, 255, 0, 255
        )
        
        local lineColor = angle < adjustedTolerance and {0, 255, 0, 150} or {255, 0, 0, 150}
        DrawLine(
            camCoords.x, camCoords.y, camCoords.z,
            propPosition.x, propPosition.y, propPosition.z,
            lineColor[1], lineColor[2], lineColor[3], lineColor[4]
        )
        
        DrawMarker(
            28,
            propPosition.x, propPosition.y, propPosition.z,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            propSize.radius, propSize.radius, propSize.radius,
            255, 128, 0, 100,
            false, false, 2, false, nil, nil, false
        )
        
        local status = angle < adjustedTolerance and "IN VIEW" or "NOT IN VIEW"
        local statusColor = angle < adjustedTolerance and {0, 255, 0, 255} or {255, 0, 0, 255}
        local textPos = vector3(propPosition.x, propPosition.y, propPosition.z + propSize.radius + 0.3)
        
        DrawText3D(textPos, string.format("Angle: %.1f° | Tol: %.1f° | %s", angle, adjustedTolerance, status), 0.3, statusColor)
        DrawTargetingBox(angle, adjustedTolerance)
    end
    
    return angle < adjustedTolerance
end

function DrawTargetingBox(currentAngle, toleranceAngle)
    local color = currentAngle < toleranceAngle and {0, 255, 0, 100} or {255, 0, 0, 100}
    local size = toleranceAngle / 90.0
    size = math.max(0.05, math.min(0.2, size))
    
    DrawRect(0.5, 0.5, size, size, color[1], color[2], color[3], color[4])
    DrawRect(0.5, 0.5, 0.005, 0.005, 255, 255, 255, 200)
end

function CheckInteractiveProps()
    if not currentCamera then return end
    
    local camCoords = GetCamCoord(currentCamera)
    local camRot = GetCamRot(currentCamera, 2)
    local oldInteractableProp = interactablePropInView
    interactablePropInView = nil
    
    exports['luma-securityCameras']:ClearAllHighlights()
    
    if not config.Cameras[currentCameraIndex].interactiveProps then
        if config.TestingMode then
            print("^1No interactive props defined for camera " .. currentCameraIndex .. "^7")
        end
        return
    end
    
    for _, prop in ipairs(config.Cameras[currentCameraIndex].interactiveProps) do
        if completedHacks[prop.id] then
            if config.TestingMode then
                exports['luma-securityCameras']:HighlightProp(prop.position, prop.hash, {r = 0, g = 0, b = 255, a = 100})
            end
            goto continue
        end
        
        local propSize = prop.size or GetPropSize(prop.type or "default")
        
        if IsPropInView(camCoords, camRot, prop.position, propSize) then
            interactablePropInView = prop
            exports['luma-securityCameras']:HighlightProp(prop.position, prop.hash, {r = 0, g = 255, b = 0, a = 200})
            
            if config.TestingMode then
                print("^2Prop is interactable: " .. prop.id .. "^7")
            end
            
            SendNUIMessage({
                type = 'setInteractableProp',
                prop = {
                    id = prop.id,
                    type = prop.type or "default"
                }
            })
            
            SendNUIMessage({
                type = 'setReticleState',
                state = 'targeting'
            })
            
            SendNUIMessage({
                type = 'showInteractionPrompt',
                message = "Press E to hack"
            })
            
            break
        elseif config.TestingMode then
            exports['luma-securityCameras']:HighlightProp(prop.position, prop.hash, {r = 255, g = 165, b = 0, a = 100})
        end
        
        ::continue::
    end
    
    if not interactablePropInView and oldInteractableProp then
        SendNUIMessage({
            type = 'setInteractableProp',
            prop = nil
        })
        
        SendNUIMessage({
            type = 'hideInteractionPrompt'
        })
        
        SendNUIMessage({
            type = 'setReticleState',
            state = 'default'
        })
    end
end

-- ============================
--  UI STATE MANAGEMENT
-- ============================

function ResetCameraUI()
    SendNUIMessage({
        type = 'setInteractableProp',
        prop = nil
    })
    
    SendNUIMessage({
        type = 'hideInteractionPrompt'
    })
    
    SendNUIMessage({
        type = 'setReticleState',
        state = 'default'
    })
end

-- ============================
--  HACK MINIGAME SYSTEM
-- ============================

function TriggerHackMinigame(prop)
    if not inCameraMode then return end
    
    if completedHacks[prop.id] then
        if config.TestingMode then
            print("^3This hack has already been completed^7")
        end
        return
    end
    
    if config.TestingMode then
        print("^2Preparing hack minigame for prop: " .. prop.id .. "^7")
    end
    
    SendNUIMessage({
        type = 'preparingHack',
        active = true
    })
    
    Citizen.Wait(200)
    
    local hackCompleted = false
    
    local function handleSuccess()
        if hackCompleted then return end

        hackCompleted = true
        
        -- if prop.hackStage == "unlockStairsDoorOfficeLevel" then
        --     TriggerServerEvent('luma-casinoHeist:server:setdoor', 8, 0)
        -- end

        completedHacks[prop.id] = true
        
        exports['luma-securityCameras']:HighlightProp(prop.position, prop.hash, {r = 0, g = 0, b = 255, a = 100})
        
        ResetCameraUI()
        
        SendNUIMessage({
            type = 'showNotification',
            message = prop.successText or "Hack successful!",
            style = "success"
        })
        
        if prop.onSuccessEvent and prop.useClientEvent then
            TriggerEvent(prop.onSuccessEvent, prop.id)
        elseif prop.onSuccessEvent and not prop.useClientEvent then
            TriggerEvent(prop.onSuccessEvent, prop.id)
        end
        
        if prop.onSuccessServerEvent and prop.useSeverEvent then
            TriggerServerEvent(prop.onSuccessServerEvent, prop.id)
        elseif prop.onSuccessServerEvent and not prop.useSeverEvent then
            TriggerServerEvent(prop.onSuccessServerEvent, prop.id)
        end
        
        SetTimeout(1500, function()
            if inCameraMode then
                ExitCameraMode()
                
                if prop.successMessage then
                    TriggerEvent('luma-securityCameras:notify', prop.successMessage, 'success')
                end
            end
        end)
    end
    
    local function handleFailure()
        if hackCompleted then return end
        hackCompleted = true
        
        SendNUIMessage({
            type = 'showNotification',
            message = prop.failText or "Hack failed!",
            style = "error"
        })
        
        ResetCameraUI()
        
        if prop.onFailEvent then
            TriggerEvent(prop.onFailEvent, prop.id)
        end
        
        if prop.onFailServerEvent then
            TriggerServerEvent(prop.onFailServerEvent, prop.id)
        end
        
        SendNUIMessage({
            type = 'preparingHack',
            active = false
        })
    end
    
    -- export method for hack
    if prop.hackExport then
        local resourceName, exportName = table.unpack(prop.hackExport:split(':'))
        
        if config.TestingMode then
            print("^2Using export: " .. resourceName .. ":" .. exportName .. "^7")
        end
        
        local params = prop.hackParams or {}
        local success
        
        if type(params) == "table" then
            success = exports[resourceName][exportName](table.unpack(params))
        else
            success = exports[resourceName][exportName](params)
        end
        
        if success then
            handleSuccess()
        else
            handleFailure()
        end
    
    -- event method for hack
    elseif prop.hackEvent then
        if config.TestingMode then
            print("^2Triggering hack event: " .. prop.hackEvent .. "^7")
        end
        
        local params = prop.hackParams or {}
        
        TriggerEvent(prop.hackEvent, params, function(success)
            if success then
                handleSuccess()
            else
                handleFailure()
            end
        end)
    
    -- Luma Casino Heist method for hack
    else
        local hackType = prop.hackType or "default"
        local hackStage = prop.hackStage or 1
        local params = prop.hackParams or {}
        
        if config.TestingMode then
            print("^2Using default hack system: " .. hackType .. " (Stage: " .. tostring(hackStage) .. ")^7")
        end
        
        -- Pass parameters to PerformHack
        PerformHack(hackType, hackStage, function(success)
            if config.TestingMode then
                print("^3Hack result received: " .. (success and "SUCCESS" or "FAILURE") .. "^7")
            end
            
            if success then
                handleSuccess()
            else
                handleFailure()
            end
        end, params)
    end
    
    interactablePropInView = nil
end

-- Helper function to split strings
string.split = function(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    
    table.insert(result, string.sub(str, from))
    return result
end

RegisterNUICallback('startHack', function(data, cb)
    if interactablePropInView then
        TriggerHackMinigame(interactablePropInView)
    end
    cb('ok')
end)

RegisterNUICallback('setViewMode', function(data, cb)
    SetCameraViewMode(data.mode)
    cb('ok')
end)

-- ============================
--  HELPER FUNCTIONS
-- ============================

completedHacks = {}

function ResetCompletedHacks()
    completedHacks = {}
    print("^3All completed hacks have been reset^7")
    
    if inCameraMode then
        exports['luma-securityCameras']:ClearAllHighlights()
        CheckInteractiveProps()
    end
end

function DrawText3D(coords, text, scale, color)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(color[1], color[2], color[3], color[4])
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

-- ============================
--  COMMANDS & INITIALIZATION
-- ============================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        completedHacks = {}
        print("^2Camera system initialized with fresh hack state^7")
    end
end)

RegisterCommand('testcam', function(source, args)
    if config.TestingMode then
        if inCameraMode then
            ExitCameraMode()
        else
            local cameraIndex = tonumber(args[1]) or 1
            EnterCameraMode(cameraIndex)
        end
    end
end, false)

RegisterKeyMapping('+exitCamera', 'Exit Camera Mode', 'keyboard', 'escape')

RegisterCommand('+exitCamera', function()
    if inCameraMode then 
        ExitCameraMode() 
    end
end, false)

RegisterCommand('-exitCamera', function() end, false)

exports('EnterCameraMode', EnterCameraMode)
exports('ExitCameraMode', ExitCameraMode)
exports('SwitchCamera', SwitchCamera)

-- ============================
--  VIEW MODE MANAGEMENT
-- ============================

function SetCameraViewMode(mode)
    if not inCameraMode then return end
    
    currentViewMode = mode
    
    if mode == "normal" then
        ClearTimecycleModifier()
        SetNightvision(false)
    elseif mode == "thermal" then
        SetTimecycleModifier("scanning")
        SetNightvision(false)
    elseif mode == "nightvision" then
        SetNightvision(true)
    end
end