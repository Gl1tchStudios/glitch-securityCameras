config = {}

config.TestingMode = false -- Set to true for testing purposes, false for production

config.AutoExitEnabled = true -- Set to false to disable the automatic camera exit feature
config.AutoExitTime = 300 -- Time in seconds before automatically exiting camera mode

config.Cameras = {
    {
        id = 1,                                                     -- Unique ID for the camera
        name = "Security Entrance",                                 -- Camera name
        location = "Diamond Casino & Resort",                       -- Location of the camera
        position = vector3(2519.4429, -252.3573, -53.3036),         -- Camera position
        rotation = vector3(-10.0, 0.0, 25.0),                       -- Camera rotation
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
        name = "Security Staff Facilities",                         -- Camera name
        location = "Diamond Casino & Resort",                       -- Location of the camera
        position = vector3(2530.2432, -265.8049, -56.6363),         -- Camera position
        rotation = vector3(-15.0, 0.0, 44.5),                       -- Camera rotation
        interactiveProps = {
            -- Example using an export for the minigame
            {
                propUniqueId = "door1",                             -- Unique ID for the prop
                position = vector3(2530.8559, -273.8801, -58.5731), -- Prop position
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
    },
    {
        id = 3,                                                     -- Unique ID for the camera
        name = "Security Staff Facilities",                         -- Camera name
        location = "Diamond Casino & Resort",                       -- Location of the camera
        position = vector3(2544.5154, -288.5128, -57.0363),         -- Camera position
        rotation = vector3(-15.0, 0.0, 80.0),                       -- Camera rotation
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
    },
    {
        id = 4,                                                    -- Unique ID for the camera
        name = "Security Staff Facilities",                        -- Camera name
        location = "Diamond Casino & Resort",                      -- Location of the camera
        position = vector3(2529.7446, -288.6646, -56.6363),        -- Camera position
        rotation = vector3(-15.0, 0.0, 80.0),                      -- Camera rotation
        interactiveProps = {
            -- Example using an export for the minigame
            {
                propUniqueId = "door3",                             -- Unique ID for the prop
                position = vector3(2533.6467, -284.9404, -58.5731), -- Prop position
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
    },
    {
        id = 5,                                                    -- Unique ID for the camera
        name = "Staff Area",                                       -- Camera name
        location = "Diamond Casino & Resort",                      -- Location of the camera
        position = vector3(-42.2057, -476.2073, 48.6294),          -- Camera position
        rotation = vector3(-5.0, 0.0, 170.0),                      -- Camera rotation
        interactiveProps = {
            -- Example using an event for the minigame
            {
                propUniqueId = "staff_computer",                    -- Unique ID for the prop
                position = vector3(2535.16, -266.65, 70.54),        -- Prop position
                hash = `xm_prop_x17_laptop_mrk2_01a`,               -- Hash of the prop model
                interactionText = "Access Staff Records",           -- Text displayed when interacting with the prop
                successText = "Staff records downloaded",           -- Text displayed on success
                failText = "Access denied",                         -- Text displayed on failure
                highlightColor = {r = 0, g = 191, b = 255, a = 200},-- Color of the highlight

                hackEvent = "mhacking:show",                        -- Event to trigger for hack minigame
                hackParams = {                                      -- Parameters for the hack minigame
                    difficulty = 2,
                    gridSize = 4,
                    timeout = 30
                },
            }
        }
    },
}

function GetCameraConfig()
    return config
end

exports('GetCameraConfig', GetCameraConfig)