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

local hackedCameras = {}
local cameraCooldowns = {}

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    hackedCameras = {}
    cameraCooldowns = {}
end)

RegisterNetEvent('glitch-securityCameras:server:registerCameraHack', function(cameraId, propId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if type(cameraId) ~= "number" or type(propId) ~= "string" then
        return
    end
    
    local cameraKey = cameraId .. "-" .. propId
    if not hackedCameras[cameraKey] then
        hackedCameras[cameraKey] = {
            timestamp = os.time(),
            hackedBy = Player.PlayerData.citizenid
        }
        
        TriggerClientEvent('glitch-securityCameras:client:cameraHacked', -1, cameraId, propId)
        
        print(string.format("Camera %s hacked by %s (%s)", cameraKey, Player.PlayerData.charinfo.firstname, Player.PlayerData.citizenid))
    end
end)

RegisterNetEvent('glitch-securityCameras:server:checkCameraStatus', function(cameraId, propId)
    local src = source
    local cameraKey = cameraId .. "-" .. propId
    
    if hackedCameras[cameraKey] then
        TriggerClientEvent('glitch-securityCameras:client:cameraAlreadyHacked', src, cameraId, propId)
    end
end)

RegisterNetEvent('glitch-securityCameras:server:setCameraCooldown', function(cameraId)
    local src = source
    cameraCooldowns[cameraId] = os.time() + 60
end)

RegisterNetEvent('glitch-securityCameras:server:checkCameraCooldown', function(cameraId)
    local src = source
    
    if cameraCooldowns[cameraId] and cameraCooldowns[cameraId] > os.time() then
        local remainingTime = cameraCooldowns[cameraId] - os.time()
        TriggerClientEvent('glitch-securityCameras:client:cameraCooldown', src, cameraId, remainingTime)
    else
        TriggerClientEvent('glitch-securityCameras:client:cameraAvailable', src, cameraId)
    end
end)

exports('IsHacked', function(cameraId, propId)
    local cameraKey = cameraId .. "-" .. propId
    return hackedCameras[cameraKey] ~= nil
end)