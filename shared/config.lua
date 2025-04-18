config = {}

config.TestingMode = false -- Set to true for testing purposes, false for production

-- can only acess cameras which are set when function to go into camera mode is called

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
                propUniqueId = "security_mainframe",                          -- Unique ID for the prop
                position = vector3(2509.0986, -260.3841, -54.0064), -- Prop position
                hash = -1498975473,                                 -- Hash of the prop model
                interactionText = "Hack Security Mainframe",        -- Text displayed when interacting with the prop
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
        name = "Vault Entrance",                                   -- Camera name
        location = "Diamond Casino & Resort",                      -- Location of the camera
        position = vector3(914.1590, 59.8150, 114.8563),           -- Camera position
        rotation = vector3(-15.0, 0.0, 80.0),                      -- Camera rotation
        interactiveProps = {
            -- Example using an export for the minigame
            {
                propUniqueId = "vault_panel",                                 -- Unique ID for the prop
                position = vector3(918.593, 52.019, 110.709),       -- Prop position
                hash = 1878378076,                                  -- Hash of the prop model
                interactionText = "Bypass Vault Security",          -- Text displayed when interacting with the prop
                successText = "Vault security disabled",            -- Text displayed on success
                failText = "Security breach detected",              -- Text displayed on failure
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
        name = "Staff Area",                                       -- Camera name
        location = "Diamond Casino & Resort",                      -- Location of the camera
        position = vector3(-42.2057, -476.2073, 48.6294),          -- Camera position
        rotation = vector3(-5.0, 0.0, 170.0),                      -- Camera rotation
        interactiveProps = {
            -- Example using an event for the minigame
            {
                propUniqueId = "staff_computer",                              -- Unique ID for the prop
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