# Glitch Security Camera System [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A comprehensive security camera system for your FiveM server. This resource allows players to access, control, and interact with security cameras throughout your server, making it perfect for heist scenarios, security jobs, and more.

---

## 📌 Features

- 📹 **Dynamic Camera System**: Access and control security cameras with realistic controls  
- 🖥️ **Interactive UI**: Clean, modern interface with camera information and controls  
- 🌙 **View Modes**: Toggle between normal, thermal, and night vision views  
- 🔍 **Object Detection**: Identify and interact with hackable objects in camera view  
- 🔓 **Hacking System**: Integrated hacking interface compatible with popular minigames  
- 🧩 **Modular Design**: Easy to integrate with other scripts and resources  
- 🛠️ **Easy to use for Intergration**: Comprehensive exports for developers to integrate with other systems  
- 🔄 **Dynamic Camera Management**: Add and remove cameras programmatically during runtime

## 📷 Media

### **Preview Image**
Example of Camera System UI
![Glitch Security Camera System](https://kappa.lol/rFcose)
Camera System with Debug Enabled
![Glitch Security Camera System with Debug](https://kappa.lol/z6RqYU)
### **Feature Demonstration**
![Camera System in Action](Incomplete)

---

## 🔧 Installation

1. **Download** the latest release from GitHub.  
2. **Extract** the `glitch-securityCamera` folder to your server's `resources` directory.  
3. **Add** `ensure glitch-securityCamera` to your `server.cfg`.  
4. **Configure** cameras in the `config.lua` file.  
5. **Restart** your server.  

---

## ⚙️ Configuration

The system is configured through the `config.lua` file. Here you can define:  

- **Camera locations and positions**  
- **Camera rotation limits**  
- **Interactive props and their behavior**  
- **Hack types and parameters**  
- **Auto-exit behavior settings**

### 📌 Configuration Options
```lua
-- Testing mode for development
config.TestingMode = true -- Set to true for testing purposes, false for production

-- Camera auto-exit settings
config.AutoExitEnabled = true -- Set to false to disable the automatic camera exit feature
config.AutoExitTime = 60 -- Time in seconds before automatically exiting camera mode
```

### 📌 Camera Configuration Example  
``` lua
-- Static configuration in config.lua (legacy method)
config.Cameras = {
    {
        id = "vault_cam1",                                        -- Unique identifier for the camera
        name = "Vault Entrance",                                   -- Camera name
        location = "Diamond Casino & Resort",                      -- Location of the camera
        position = vector3(914.1590, 59.8150, 114.8563),           -- Camera position
        rotation = vector3(-15.0, 0.0, 80.0),                      -- Camera rotation
        interactiveProps = {
            {
                -- Example using a specific export
                propUniqueId = "vault_panel",                      -- Unique ID for the prop
                position = vector3(918.593, 52.019, 110.709),       -- Prop position
                hash = 1878378076,                                  -- Hash of the prop model
                interactionText = "Bypass Vault Security",          -- Text displayed when interacting with the prop
                successText = "Vault security disabled",            -- Text displayed on success
                failText = "Security breach detected",              -- Text displayed on failure
                highlightColor = {r = 255, g = 165, b = 0, a = 200},-- Color of the highlight

                hackExport = "glitch-minigames:StartSurgeOverride", -- Export to call for hack minigame
                hackParams = {                                      -- Parameters for the hack minigame
                    possibleKeys = {'E'},
                    requiredPresses = 50,
                    decayRate = 2
                },
            }
        }
    },
}
```

### 📌 Dynamic Camera Configuration Example
```lua
-- Dynamic camera adding (recommended method)
local newCamera = {
    id = "casino_entrance",                                      -- Unique ID for the camera
    name = "Security Entrance",                                  -- Camera name
    location = "Diamond Casino & Resort",                        -- Location
    position = vector3(2519.4429, -252.3573, -53.3036),          -- Position
    rotation = vector3(-10.0, 0.0, 25.0),                        -- Rotation
    rotationLimits = {
        x = {min = -75.0, max = -5},                            
        z = {min = 89, max = 175.0}                             
    },
    interactiveProps = {
        {
            propUniqueId = "security_mainframe",                
            position = vector3(2509.0986, -260.3841, -54.0064), 
            hash = -1498975473,                                  
            interactionText = "Disable the Door Locks",          
            successText = "Security system bypassed",            
            failText = "Security alert triggered",               
            highlightColor = {r = 0, g = 255, b = 0, a = 200},   
            
            hackExport = "glitch-minigames:StartSurgeOverride", 
            hackParams = {                                      
                keys = {'E', 'F'},
                requiredPresses = 30,
                decayRate = 2
            },
        }
    }
}

local success, message = exports['glitch-securityCameras']:AddCamera(newCamera)
if success then
    print("Camera added successfully!")
else
    print("Failed to add camera: " .. message)
end
```

---

## 🎮 Usage

### **Player Controls**
- **Mouse**: Pan/rotate camera  
- **Arrow Keys (← →)**: Switch between cameras  
- **E**: Interact with highlighted objects  
- **Q**: Toggle view modes (normal, thermal, night vision)  
- **ESC**: Exit camera mode  

---

## 👨‍💻 Developer Usage

### **Basic Implementation**
#### **Triggering Camera Access from Items**
``` lua
local success = exports['glitch-securityCameras']:AttemptCameraHack(1, "security_mainframe")
if success then
    print("Hack success!")
elseif not success then
    print("Hack failed!")
else
    print("No hack attempted!")
end
```

---

### **Camera Hack Implementation**
#### **Using the AttemptCameraHack Export**

The `AttemptCameraHack` export allows you to trigger camera hacking from your scripts. This is useful for implementing actions like using a security keycard on a door, hacking a terminal, or any other interaction that should give access to cameras.

```lua
-- Syntax:
exports['glitch-securityCameras']:AttemptCameraHack(cameraIndex, propId, allowedCameras)

-- Parameters:
-- cameraIndex: The index or ID of the camera to start with
-- propId: (Optional) The specific prop ID to focus on when entering camera mode
-- allowedCameras: (Optional) Table of camera IDs that the player is allowed to access

-- Example 1: Basic camera hack allowing access to all cameras
RegisterNetEvent('items:useSecurityKeycard')
AddEventHandler('items:useSecurityKeycard', function()
    local success = exports['glitch-securityCameras']:AttemptCameraHack(1)
    if success then
        -- Player successfully accessed and used the cameras
        TriggerServerEvent('items:removeKeycard')
    end
end)

-- Example 2: Restricted camera access with focus on specific prop
RegisterNetEvent('items:useHackingDevice')
AddEventHandler('items:useHackingDevice', function()
    -- Only allow access to cameras 2, 5, and 8, and focus on the vault_panel prop
    local success = exports['glitch-securityCameras']:AttemptCameraHack(2, "vault_panel", {2, 5, 8})
    if success then
        -- The player successfully hacked something in the camera system
        TriggerEvent('notifications:client:SendAlert', {
            text = "You successfully bypassed the security system",
            type = "success"
        })
    elseif success == false then
        -- The player failed the hack
        TriggerEvent('notifications:client:SendAlert', {
            text = "Hack failed - security alerted!",
            type = "error"
        })
    else
        -- The player exited without attempting a hack
        TriggerEvent('notifications:client:SendAlert', {
            text = "You disconnected from the security system",
            type = "inform"
        })
    end
end)
```

When using `AttemptCameraHack`, the function will return:
- `true` if the player successfully completed a hack while in camera mode
- `false` if the player attempted a hack but failed
- `nil` if the player exited camera mode without attempting any hack

---

### **Exported Functions**

#### **Client Exports**
``` lua
-- Camera Control
EnterCameraMode(cameraIndex, allowedCameraIds)                      -- Enter camera mode with specified camera (optional: limit to specific IDs)
ExitCameraMode()                                                    -- Exit camera mode
SwitchCamera(cameraIndex)                                           -- Switch to a different camera
SetCameraViewMode(mode)                                             -- Set view mode (normal, thermal, nightvision)

-- Camera Management
AddCamera(cameraData)                                               -- Add a new camera to the system
RemoveCamera(cameraId)                                              -- Remove a camera by ID
GetAllCameras()                                                     -- Get all cameras in the system
GetCameraById(cameraId)                                             -- Get a camera by ID
AttemptCameraHack(cameraIndex, propId, allowedCameras)              -- Try to hack a camera with optional camera restrictions

-- Props and Highlighting
SetHighlightActive(active)                                          -- Enable/disable object highlighting
HighlightProp(coords, modelHash, color)                             -- Highlight a specific prop
RemoveHighlight(highlightId)                                        -- Remove a specific highlight
ClearAllHighlights()                                                -- Remove all highlights
IsLookingAtProp(propCoords, cameraCoords, cameraRot, maxDistance)   -- Check if a prop is in view

-- Hack System
ResetCompletedHacks()                                               -- Reset all completed hacks to their initial state
```

#### **Server Exports**
``` lua
IsHacked(cameraId, propId)                                          -- Check if a camera has been hacked
RefreshCameraSystem()                                               -- Refresh cameras for all connected clients
```

---

## 🔄 Integration Examples

- **Integration with any of your minigame scripts like `glitch-minigames`, `ps-ui`...**  
- **Integration with your targeting system e.g. `ox-target`, `qb-target`...**  

---

## 📜 Credits

- **Developed by** Luma in collaboration with Glitch Studios  
- **Special thanks** to the FiveM community for support and inspiration  

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.  

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

For support or inquiries, please join and open a ticket **https://discord.gg/uZ7bJwtM4c**.
