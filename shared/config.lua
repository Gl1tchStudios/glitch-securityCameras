-- Glitch Studios - glitch-securityCameras
-- Shared config. Loaded on the client and the server. This file is open (escrow_ignore).

Config = {}

-- Prints extra information to the console. Leave off on a live server.
Config.Debug = false

-- Leave the camera by itself after this many seconds (not counted while a hack minigame runs).
Config.AutoExitEnabled = true
Config.AutoExitTime = 300

-- Game control ids used in camera mode. If you change them, change Config.Locale.keys too.
Config.Controls = {
    left = 174,     -- Arrow left: previous camera
    right = 175,    -- Arrow right: next camera
    exit = 194,     -- Backspace: leave the camera
    interact = 38,  -- E: start the hack on the highlighted prop
    viewMode = 44,  -- Q: normal / thermal / night vision
}

-- Cameras are grouped by id block. With no allowed list, the arrow keys only cycle through
-- cameras of the same group (id 8501 and 8502 are group 85, id 100 and 101 are group 1).
-- A camera can also set its own `group = 'name'`.
Config.GroupBlock = 100

-- Minigame used when a prop has neither hackExport nor hackEvent.
-- Set export = false to make those props unhackable until you give them their own minigame.
Config.DefaultHack = {
    export = 'glitch-minigames:StartSurgeOverride', -- 'resource:exportName', must return true on success
    params = { keys = { 'E', 'F' }, requiredPresses = 30, decayRate = 2 },
}

-- hackParams can be a plain list ({ {'E','F'}, 30, 2 }) which is passed as arguments in order,
-- or a keyed table, which is turned into arguments in this order.
Config.HackParamOrder = { 'keys', 'requiredPresses', 'decayRate' }

-- Server side hack tracking
Config.HackResetSeconds = 1800      -- how long a hacked prop stays hacked for everyone
Config.MinHackSeconds = 2           -- a hack reported done faster than this is refused
Config.BeginCooldownMs = 2000       -- minimum time between two hack starts from one player
Config.AllowRuntimeCameras = true   -- accept hacks for cameras added at run time with AddCamera
                                    -- (set false and use the server export RegisterCamera for a strict list)
Config.MaxHacksPerPlayer = 8        -- hacked props one player can hold at once
Config.HackEventTimeoutMs = 120000  -- how long a prop hackEvent may take to answer before it counts as failed

-- Used when the minigame resource in Config.DefaultHack is not running (ox_lib skill check
-- difficulties). Set to false to make those props unhackable instead.
Config.FallbackSkillCheck = { 'easy', 'easy', 'medium' }

-- Player facing text
Config.Locale = {
    hackPrompt = 'Press %s to hack',  -- %s is replaced by interactKey
    interactKey = 'E',                -- the label of Config.Controls.interact
    hackSuccess = 'Hack successful!',
    hackFail = 'Hack failed!',
    alreadyHacked = 'System already compromised',
    unavailable = 'Hacking tool unavailable',
    unknownArea = 'Unknown Area',
    modeNames = { normal = 'Normal View', thermal = 'Thermal Vision', nightvision = 'Night Vision' },
    viewModeSwitched = 'Switched to %s',
    ui = { targetIdentified = 'TARGET IDENTIFIED', mode = 'MODE:', camPrefix = 'CAM_' },
    keys = {
        camera = 'CAMERA:',
        switch = 'SWITCH CAMERA',
        pan = 'PAN',
        viewMode = 'SWITCH VIEW MODE',
        interact = 'INTERACT',
        exit = 'EXIT',
    },
}

-- Cameras can be listed here or added at run time from another resource with
-- exports['glitch-securityCameras']:AddCamera(cameraData) on the client (see README.md).
Config.Cameras = {}

-- Example cameras for testing. Turn them on, look at them, then delete or replace them.
-- The prop hashes and positions are placeholders. Use a model that exists at the spot.
Config.EnableExamples = false

Config.ExampleCameras = {
    {
        id = 1,                                                     -- Unique id for the camera
        name = 'Security Entrance',
        location = 'Example Location',
        modes = { nightVision = true, thermal = true },             -- both default to true
        position = vector3(2519.4429, -252.3573, -53.3036),
        rotation = vector3(-10.0, 0.0, 136.7170),
        rotationLimits = {
            x = { min = -75.0, max = -5 },                          -- vertical limits
            z = { min = 89, max = 175.0 },                          -- horizontal limits
        },
        interactiveProps = {
            {
                propUniqueId = 'security_mainframe',
                position = vector3(2509.0986, -260.3841, -54.0064),
                hash = -1498975473,
                interactionText = 'Disable the Door Locks',
                successText = 'Security system bypassed',
                failText = 'Security alert triggered',
                highlightColor = { r = 0, g = 255, b = 0, a = 200 },
                exitOnHack = false,                                 -- leave the camera after the hack
                hackExport = 'glitch-minigames:StartSurgeOverride', -- 'resource:exportName'
                hackParams = { keys = { 'E', 'F' }, requiredPresses = 30, decayRate = 2 },
            },
        },
    },
    {
        id = 2,
        name = 'Rooftop',
        location = 'Example Location',
        modes = { nightVision = true, thermal = false },
        position = vector3(317.7059, -280.0818, 55.7572),
        rotation = vector3(-15.0, 0.0, 32.0484),
        rotationLimits = {
            x = { min = -60, max = 0 },
            z = { min = 1, max = 70 },
        },
        interactiveProps = {
            {
                -- No hackExport: the camera is used through the AttemptCameraHack export,
                -- and Config.DefaultHack runs when the player presses the interact key.
                propUniqueId = 'door1',
                position = vector3(314.5, -275.0, 54.2),
                hash = 1243560448,
                interactionText = 'Disable the Door Locks',
                successText = 'Security system bypassed',
                failText = 'Security alert triggered',
                highlightColor = { r = 255, g = 165, b = 0, a = 200 },
            },
        },
    },
}

if Config.EnableExamples then
    for _, cam in ipairs(Config.ExampleCameras) do
        Config.Cameras[#Config.Cameras + 1] = cam
    end
end

-- Returns a copy so other resources cannot change the live config.
exports('GetCameraConfig', function()
    local function copy(v)
        if type(v) ~= 'table' then return v end
        local out = {}
        for k, x in pairs(v) do out[k] = copy(x) end
        return out
    end
    return copy(Config)
end)
