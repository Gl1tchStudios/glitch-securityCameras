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

local isHighlightActive = false
local highlightedProps = {}
local highlightedEntities = {}

function HighlightProp(coords, modelHash, color)
    if not isHighlightActive then return end
    
    color = color or {r = 0, g = 255, b = 0, a = 200}
    
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, modelHash, false, false, false)
    
    if entity and DoesEntityExist(entity) then
        SetEntityDrawOutline(entity, true)
        SetEntityDrawOutlineColor(color.r, color.g, color.b, color.a)
        
        local highlightId = #highlightedEntities + 1
        highlightedEntities[highlightId] = entity
        
        table.insert(highlightedProps, {
            id = highlightId,
            entity = entity,
            coords = coords,
            hash = modelHash
        })
        
        return highlightId
    end
    
    return nil
end

function RemoveHighlight(highlightId)
    if not highlightId then return end
    
    for i, prop in ipairs(highlightedProps) do
        if prop.id == highlightId then
            if DoesEntityExist(prop.entity) then
                SetEntityDrawOutline(prop.entity, false)
            end
            table.remove(highlightedProps, i)
            break
        end
    end
end

function ClearAllHighlights()
    for _, prop in ipairs(highlightedProps) do
        if DoesEntityExist(prop.entity) then
            SetEntityDrawOutline(prop.entity, false)
        end
    end
    
    highlightedProps = {}
    highlightedEntities = {}
end

function SetHighlightActive(active)
    isHighlightActive = active
    if not active then
        ClearAllHighlights()
    end
end

function IsLookingAtProp(propCoords, cameraCoords, cameraRot, maxDistance) -- pain in my ass
    local distance = #(vector3(propCoords.x, propCoords.y, propCoords.z) - vector3(cameraCoords.x, cameraCoords.y, cameraCoords.z))
    
    if distance > maxDistance then return false end
    
    local direction = GetDirectionFromRotation(cameraRot)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(propCoords.x, propCoords.y, propCoords.z)

    if onScreen then
        local centerZoneSize = 0.05
        local isCentered = (math.abs(screenX - 0.5) < centerZoneSize) and (math.abs(screenY - 0.5) < centerZoneSize)

        if isCentered then
            local hit, _, _, _, entityHit = StartShapeTestRay(
                cameraCoords.x, cameraCoords.y, cameraCoords.z,
                propCoords.x, propCoords.y, propCoords.z,
                -1, -1, 0
            )

            local result = GetShapeTestResult(hit)
            
            if result == 2 or entityHit == 0 then
                return true
            end
        end
    end
    
    return false
end

function IsInExpandedViewCone(propCoords, modelHash, cameraCoords, cameraDirection, maxDistance)
    local minDim, maxDim = GetModelDimensions(modelHash)
    
    local checkPoints = {
        vector3(propCoords.x + minDim.x, propCoords.y + minDim.y, propCoords.z + minDim.z),
        vector3(propCoords.x + minDim.x, propCoords.y + minDim.y, propCoords.z + maxDim.z),
        vector3(propCoords.x + minDim.x, propCoords.y + maxDim.y, propCoords.z + minDim.z),
        vector3(propCoords.x + minDim.x, propCoords.y + maxDim.y, propCoords.z + maxDim.z),
        vector3(propCoords.x + maxDim.x, propCoords.y + minDim.y, propCoords.z + minDim.z),
        vector3(propCoords.x + maxDim.x, propCoords.y + minDim.y, propCoords.z + maxDim.z),
        vector3(propCoords.x + maxDim.x, propCoords.y + maxDim.y, propCoords.z + minDim.z),
        vector3(propCoords.x + maxDim.x, propCoords.y + maxDim.y, propCoords.z + maxDim.z)
    }
    
    for _, point in ipairs(checkPoints) do
        local toPoint = vector3(point.x - cameraCoords.x, point.y - cameraCoords.y, point.z - cameraCoords.z)
        local length = #toPoint
        
        if length <= maxDistance then
            local normalized = vector3(toPoint.x/length, toPoint.y/length, toPoint.z/length)
            local dot = DotProduct(normalized, cameraDirection)
            
            if dot > 0.5 then
                return true
            end
        end
    end
    
    return false
end

function GetDirectionFromRotation(rotation)
    local rotationRadians = {
        x = math.rad(rotation.x),
        y = math.rad(rotation.y),
        z = math.rad(rotation.z)
    }
    
    local dx = -math.sin(rotationRadians.z) * math.abs(math.cos(rotationRadians.x))
    local dy = math.cos(rotationRadians.z) * math.abs(math.cos(rotationRadians.x))
    local dz = math.sin(rotationRadians.x)
    
    return vector3(dx, dy, dz)
end

function DotProduct(v1, v2)
    return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z)
end

exports('HighlightProp', HighlightProp)
exports('RemoveHighlight', RemoveHighlight)
exports('ClearAllHighlights', ClearAllHighlights)
exports('SetHighlightActive', SetHighlightActive)
exports('IsLookingAtProp', IsLookingAtProp)