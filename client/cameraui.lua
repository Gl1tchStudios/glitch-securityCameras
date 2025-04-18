-- Glitch Security Camera System
-- Copyright (C) 2024 Glitch
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

local display = false
local activeCamera = nil
local activeProp = nil

RegisterNUICallback('closeCamera', function(data, cb)
    ExitCameraMode()
    cb('ok')
end)

RegisterNUICallback('switchCamera', function(data, cb)
    if data.cameraId and type(data.cameraId) == "number" then
        SwitchCamera(data.cameraId)
    end
    cb('ok')
end)

RegisterNUICallback('interactWithProp', function(data, cb)
    if activeProp then
        TriggerHackMinigame(activeProp)
    end
    cb('ok')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    SendNUIMessage({
        type = 'resetCamera'
    })
    
    display = false
end)

function ShowCameraNotification(message, style)
    style = style or "info"  -- info, success, error, warning - incomplete.
    
    SendNUIMessage({
        type = 'showNotification',
        message = message,
        style = style
    })
end

function UpdateCameraUI(cameraData, propInView)
    if not display then return end
    
    SendNUIMessage({
        type = 'updateCameraInfo',
        cameraId = cameraData.id,
        cameraName = cameraData.name,
        timestamp = os.date("%H:%M:%S"),
        date = os.date("%d/%m/%Y"),
        propInView = propInView ~= nil
    })
    
    if propInView then
        activeProp = propInView
        SendNUIMessage({
            type = 'showInteractionPrompt',
            message = propInView.interactionText or "Press E to hack"
        })
    else
        activeProp = nil
        SendNUIMessage({
            type = 'hideInteractionPrompt'
        })
    end
end

function ShowCameraHUD(cameraData)
    if display then return end
    
    display = true
    activeCamera = cameraData
    
    SendNUIMessage({
        type = 'showCameraUI',
        cameraId = cameraData.id,
        cameraName = cameraData.name or "Camera " .. cameraData.id,
        timestamp = os.date("%H:%M:%S"),
        date = os.date("%d/%m/%Y"),
        totalCameras = #config.cameras,
        controls = {
            arrows = "Change camera angle",
            e = "Interact with highlighted objects",
            esc = "Exit camera mode"
        }
    })
end

function HideCameraHUD()
    if not display then return end
    
    display = false
    activeCamera = nil
    activeProp = nil
    
    SendNUIMessage({
        type = 'hideCameraUI'
    })
end

RegisterNetEvent('glitch-securityCameras:client:cameraHacked', function(cameraId, propId)
    if activeCamera and activeCamera.id == cameraId then
        ShowCameraNotification("Camera system compromised", "success")
    end
end)

RegisterNetEvent('glitch-securityCameras:client:cameraAlreadyHacked', function(cameraId, propId)
    if activeCamera and activeCamera.id == cameraId then
        ShowCameraNotification("System already compromised", "info")
    end
end)

RegisterNetEvent('glitch-securityCameras:client:cameraReset', function(cameraId, propId)
    if activeCamera and activeCamera.id == cameraId then
        ShowCameraNotification("Security system reset", "warning")
    end
end)

RegisterNetEvent('glitch-securityCameras:client:cameraCooldown', function(cameraId, remainingTime)
    if activeCamera and activeCamera.id == cameraId then
        ShowCameraNotification("System locked: " .. remainingTime .. "s remaining", "error")
    end
end)

exports('ShowCameraHUD', ShowCameraHUD)
exports('HideCameraHUD', HideCameraHUD)
exports('UpdateCameraUI', UpdateCameraUI)
exports('ShowCameraNotification', ShowCameraNotification)