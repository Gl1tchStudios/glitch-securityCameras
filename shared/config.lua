config = {}

config.TestingMode = true -- Set to true for testing purposes, false for production

config.AutoExitEnabled = true -- Set to false to disable the automatic camera exit feature
config.AutoExitTime = 300 -- Time in seconds before automatically exiting camera mode

config.Cameras = {
    {
        id = 1,                                                     -- Unique ID for the camera
        name = "Security Entrance",                                 -- Camera name
        location = "Diamond Casino & Resort",                       -- Location of the camera
        modes = { -- both set to true by default
            nightVision = true,
            thermal = true
        },
        position = vector3(2519.4429, -252.3573, -53.3036),         -- Camera position
        rotation = vector3(-10.0, 0.0, 136.7170),                       -- Camera rotation
        rotationLimits = {
            x = {min = -75.0, max = -5},                            -- Vertical limits
            z = {min = 89, max = 175.0}                             -- Horizontal limits
        },
        interactiveProps = {
            -- Example using an export for the minigame
            {
                propUniqueId = "security_mainframe",                -- Unique ID for the prop
                position = vector3(2509.0986, -260.3841, -54.0064), -- Prop position
                hash = -1498975473,                                 -- Hash of the prop model
                interactionText = "Disable the Door Locks",         -- Text displayed when interacting with the prop
                successText = "Security system bypassed",           -- Text displayed on success
                failText = "Security alert triggered",              -- Text displayed on failure
                highlightColor = {r = 0, g = 255, b = 0, a = 200},  -- Color of the highlight
                
                exitOnHack = false,
                hackExport = "glitch-minigames:StartSurgeOverride", -- Export to call for hack minigame
                hackParams = {                                      -- Parameters for the hack minigame
                    keys = {'E', 'F'},
                    requiredPresses = 30,
                    decayRate = 2
                },
            }
        }
    },
    {
        id = 2,                                                     -- Unique ID for the camera
        name = "Pink Cage",                                         -- Camera name
        location = "Fleeca Bank",                                   -- Location of the camera
        modes = { -- both set to true by default
            nightVision = true,
            thermal = false
        },
        position = vector3(317.7059, -280.0818, 55.7572),         -- Camera position
        rotation = vector3(-15.0, 0.0, 32.0484),                   -- Camera rotation
        rotationLimits = {
            x = {min = -60, max = 0},                            -- Vertical limits
            z = {min = 1, max = 70}                             -- Horizontal limits
        },
        interactiveProps = {
            -- Example using no hackExport and instead relys on the user using the AttemptCameraHack export
            {
                propUniqueId = "door1",                             -- Unique ID for the prop
                position = vector3(2530.8559, -273.8801, -58.5731), -- Prop position
                hash = 1243560448,                                  -- Hash of the prop model
                interactionText = "Disable the Door Locks",         -- Text displayed when interacting with the prop
                successText = "Security system bypassed",           -- Text displayed on success
                failText = "Security alert triggered",              -- Text displayed on failure
                highlightColor = {r = 255, g = 165, b = 0, a = 200},-- Color of the highlight

                -- hackExport = "glitch-minigames:StartSurgeOverride", -- Export to call for hack minigame
                -- hackParams = {                                      -- Parameters for the hack minigame
                --     keys = {'E', 'F'},
                --     requiredPresses = 30,
                --     decayRate = 2
                -- },
            }
        }
    },
    {
        id = 3,                                                     -- Unique ID for the camera
        name = "Front Entrance",                                    -- Camera name
        location = "Mission Row Police Department",                 -- Location of the camera
        position = vector3(432.9822, -978.0745, 34.2088),           -- Camera position
        rotation = vector3(-15.0, 0.0, 107.9355),                   -- Camera rotation
        rotationLimits = {
            x = {min = -60, max = 30},                              -- Vertical limits
            z = {min = 1, max = 184},                               -- Horizontal limits
        },
        interactiveProps = {
            -- Example using an export for the minigame
            {
                propUniqueId = "door2",                             -- Unique ID for the prop
                position = vector3(2536.1564, -283.6008, -58.5731), -- Prop position
                hash = 1243560448,                                  -- Hash of the prop model
                interactionText = "Disable the Door Locks",         -- Text displayed when interacting with the prop
                successText = "Security system bypassed",           -- Text displayed on success
                failText = "Security alert triggered",              -- Text displayed on failure
                highlightColor = {r = 255, g = 165, b = 0, a = 200},-- Color of the highlight

                hackExport = "glitch-minigames:StartSurgeOverride", -- Export to call for hack minigame
                hackParams = {                                      -- Parameters for the hack minigame
                    keys = {'E', 'F'},
                    requiredPresses = 30,
                    decayRate = 2
                },
            }
        }
    }
}

function GetCameraConfig()
    return config
end

exports('GetCameraConfig', GetCameraConfig)