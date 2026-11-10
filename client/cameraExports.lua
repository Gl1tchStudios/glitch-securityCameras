-- Glitch Studios - glitch-securityCameras (client)
-- Runtime camera management. Cameras added here live on this client only, so the resource
-- that adds them has to add them on every client that needs them (see README.md).

local function debugPrint(...)
    if Config.Debug then print('[glitch-securityCameras]', ...) end
end

local function validateCameraData(cameraData)
    if type(cameraData) ~= 'table' then
        return false, 'Camera data must be a table'
    end
    if not cameraData.id or not cameraData.name or not cameraData.position or not cameraData.rotation then
        return false, 'Missing required camera fields (id, name, position, rotation)'
    end
    if type(cameraData.position) ~= 'vector3' or type(cameraData.rotation) ~= 'vector3' then
        return false, 'Position and rotation must be vector3'
    end

    for _, camera in ipairs(Config.Cameras) do
        if camera.id == cameraData.id then
            return false, 'Camera ID already exists: ' .. tostring(cameraData.id)
        end
    end

    for _, prop in ipairs(cameraData.interactiveProps or {}) do
        if not prop.propUniqueId or not prop.position or not prop.hash then
            return false, 'Missing required prop fields (propUniqueId, position, hash)'
        end
        -- hackExport and hackEvent are optional: without them Config.DefaultHack runs.
    end

    return true, 'Camera validated successfully'
end

local function addCamera(cameraData)
    local isValid, message = validateCameraData(cameraData)
    if not isValid then
        debugPrint('Failed to add camera: ' .. message)
        return false, message
    end

    Config.Cameras[#Config.Cameras + 1] = cameraData
    debugPrint('Camera added: ' .. tostring(cameraData.name))
    return true, 'Camera added successfully'
end

local function removeCamera(cameraId)
    for i, camera in ipairs(Config.Cameras) do
        if camera.id == cameraId then
            table.remove(Config.Cameras, i)
            debugPrint('Camera removed: ID ' .. tostring(cameraId))
            return true, 'Camera removed successfully'
        end
    end
    return false, 'Camera ID not found'
end

local function getCameraById(cameraId)
    for _, camera in ipairs(Config.Cameras) do
        if camera.id == cameraId then return camera end
    end
    return nil
end

SecCam.GetCameraById = getCameraById

exports('AddCamera', addCamera)
exports('RemoveCamera', removeCamera)
exports('GetAllCameras', function() return Config.Cameras end)
exports('GetCameraById', getCameraById)
