config = config or {}
config.Cameras = config.Cameras or {}

local function validateCameraData(cameraData)
    if not cameraData.id or not cameraData.name or not cameraData.position or not cameraData.rotation then
        return false, "Missing required camera fields (id, name, position, rotation)"
    end
    
    if type(cameraData.position) ~= "vector3" or type(cameraData.rotation) ~= "vector3" then
        return false, "Position and rotation must be vector3"
    end
    
    for _, camera in ipairs(config.Cameras) do
        if camera.id == cameraData.id then
            return false, "Camera ID already exists: " .. cameraData.id
        end
    end
    
    if cameraData.interactiveProps then
        for _, prop in ipairs(cameraData.interactiveProps) do
            if not prop.propUniqueId or not prop.position or not prop.hash then
                return false, "Missing required prop fields (propUniqueId, position, hash)"
            end
            if not prop.interactionText or 
               not prop.successText or 
               not prop.failText then
                return false, "Missing prop interaction text fields"
            end
            if not (prop.hackExport or prop.hackEvent) then
                return false, "Either hackExport or hackEvent must be defined for props"
            end
        end
    end
    
    return true, "Camera validated successfully"
end

local function addCamera(cameraData)
    local isValid, message = validateCameraData(cameraData)
    if not isValid then
        print("Failed to add camera: " .. message)
        return false, message
    end
    
    table.insert(config.Cameras, cameraData)
    
    if CamerasInitialized then
        RefreshCameraSystem()
    end
    
    print("Camera added successfully: " .. cameraData.name)
    return true, "Camera added successfully"
end

local function removeCamera(cameraId)
    for i, camera in ipairs(config.Cameras) do
        if camera.id == cameraId then
            table.remove(config.Cameras, i)
            
            if CamerasInitialized then
                RefreshCameraSystem()
            end
            
            print("Camera removed: ID " .. cameraId)
            return true, "Camera removed successfully"
        end
    end
    
    print("Failed to remove camera: ID " .. cameraId .. " not found")
    return false, "Camera ID not found"
end

local function getAllCameras()
    return config.Cameras
end

local function getCameraById(cameraId)
    for _, camera in ipairs(config.Cameras) do
        if camera.id == cameraId then
            return camera
        end
    end
    return nil
end

exports('AddCamera', addCamera)
exports('RemoveCamera', removeCamera)
exports('GetAllCameras', getAllCameras)
exports('GetCameraById', getCameraById)



-- LUMAA - Thank you Dexter <3 xx

function RefreshCameraSystem()
    TriggerClientEvent('security:refreshCameras', -1, config.Cameras)
end

-- set initialization flag once cameras are fully loaded
RegisterNetEvent('security:camerasInitialized')
AddEventHandler('security:camerasInitialized', function()
    CamerasInitialized = true
    print("Camera system initialized")
end)

-- Example of how to handle camera synchronization for players joining

-- RegisterNetEvent('security:requestCameras')
-- AddEventHandler('security:requestCameras', function()
--     local source = source
--     TriggerClientEvent('security:receiveCameras', source, config.Cameras)
-- end)

-- local newCamera = {
--     id = 99,                                      -- Unique ID for the camera
--     name = "Security Entrance",                                  -- Camera name
--     location = "Diamond Casino & Resort",                        -- Location
--     position = vector3(983.1218, 8.3902, 80.9837),          -- Position
--     rotation = vector3(-10.0, 0.0, 25.0),                        -- Rotation
--     rotationLimits = {
--         x = {min = -75.0, max = -5},                            
--         z = {min = 89, max = 175.0}                             
--     },
--     interactiveProps = {
--         {
--             propUniqueId = "security_mainframe",                
--             position = vector3(2509.0986, -260.3841, -54.0064), 
--             hash = -1498975473,                                  
--             interactionText = "Disable the Door Locks",          
--             successText = "Security system bypassed",            
--             failText = "Security alert triggered",               
--             highlightColor = {r = 0, g = 255, b = 0, a = 200},   
            
--             hackExport = "glitch-minigames:StartSurgeOverride", 
--             hackParams = {                                      
--                 keys = {'E', 'F'},
--                 requiredPresses = 30,
--                 decayRate = 2
--             },
--         }
--     }
-- }


-- RegisterCommand('tcam', function(source, args, rawCommand)
--     --exports['glitch-securityCameras']:AddCamera(newCamera)
--     Citizen.Wait(50)
--     exports['glitch-securityCameras']:AttemptCameraHack(1, "security_mainframe", {1,2,3,4,5,})
-- end, false)