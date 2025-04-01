# Luma Security Camera System [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A comprehensive security camera system for your FiveM server. This resource allows players to access, control, and interact with security cameras throughout your server, making it perfect for heist scenarios, security jobs, and more.

---

## 📌 Features

- 📹 **Dynamic Camera System**: Access and control security cameras with realistic controls  
- 🖥️ **Interactive UI**: Clean, modern interface with camera information and controls  
- 🌙 **View Modes**: Toggle between normal, thermal, and night vision views  
- 🔍 **Object Detection**: Identify and interact with hackable objects in camera view  
- 🔓 **Hacking System**: Integrated hacking interface compatible with popular minigames  
- 🧩 **Modular Design**: Easy to integrate with other scripts and resources  
- 🛠️ **Developer API**: Comprehensive exports for developers to integrate with other systems  

## 📷 Media

### **Preview Image**
![Luma Security Camera System](https://kappa.lol/rFcose)
- Example of Camera System UI
![Luma Security Camera System with Debug](https://kappa.lol/z6RqYU)
-  Camera System with Debug Enabled
### **Feature Demonstration**
![Camera System in Action](Incomplete)

---

## 🔧 Installation

1. **Download** the latest release from GitHub.  
2. **Extract** the `luma-securityCamera` folder to your server's `resources` directory.  
3. **Add** `ensure luma-securityCamera` to your `server.cfg`.  
4. **Configure** cameras in the `config.lua` file.  
5. **Restart** your server.  

---

## ⚙️ Configuration

The system is configured through the `config.lua` file. Here you can define:  

- **Camera locations and positions**  
- **Camera rotation limits**  
- **Interactive props and their behavior**  
- **Hack types and parameters**  

### 📌 Camera Configuration Example  
``` lua
config.Cameras = {
    {
        name = "Vault Entrance",                                   -- Camera name
        location = "Diamond Casino & Resort",                      -- Location of the camera
        position = vector3(914.1590, 59.8150, 114.8563),           -- Camera position
        rotation = vector3(-15.0, 0.0, 80.0),                      -- Camera rotation
        interactiveProps = {
            {
                -- Example using a specific export
                id = "vault_panel",                                 -- Unique ID for the prop
                position = vector3(918.593, 52.019, 110.709),       -- Prop position
                hash = 1878378076,                                  -- Hash of the prop model
                interactionText = "Bypass Vault Security",          -- Text displayed when interacting with the prop
                successText = "Vault security disabled",            -- Text displayed on success
                failText = "Security breach detected",              -- Text displayed on failure
                highlightColor = {r = 255, g = 165, b = 0, a = 200},-- Color of the highlight

                hackExport = "ps-ui:Thermite",                      -- Export to call for hack minigame
                hackParams = {                                      -- Parameters for the hack minigame
                    time = 60,
                    gridSize = 6,
                    incorrectBlocks = 10
                },
                useClientEvent = true,                                              -- Use client event for hack
                onSuccessEvent = "luma-casinoHeist:client:vaultHackSuccess",        -- Event triggered on success
                onFailEvent = "luma-casinoHeist:client:vaultHackFail",              -- Event triggered on failure
                useSeverEvent = false,                                              -- Use server event for hack
                onSuccessServerEvent = "luma-heists:server:vaultHackSuccess",       -- Server event triggered on success
                onFailServerEvent = "luma-heists:server:vaultHackFail"              -- Server event triggered on failure
            }
        }
    },
}
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
RegisterNetEvent('luma-securityCamera:openCamera')
AddEventHandler('luma-securityCamera:openCamera', function(cameraIndex)
    exports['luma-securityCamera']:EnterCameraMode(cameraIndex)
end)
```

---

### **Exported Functions**

#### **Client Exports**
``` lua
EnterCameraMode(cameraIndex)                                        -- Enter camera mode with specified camera
ExitCameraMode()                                                    -- Exit camera mode
SwitchCamera(cameraIndex)                                           -- Switch to a different camera
SetHighlightActive(active)                                          -- Enable/disable object highlighting
HighlightProp(coords, modelHash, color)                             -- Highlight a specific prop
RemoveHighlight(highlightId)                                        -- Remove a specific highlight
ClearAllHighlights()                                                -- Remove all highlights
IsLookingAtProp(propCoords, cameraCoords, cameraRot, maxDistance)   -- Check if a prop is in view
```

#### **Server Exports**
``` lua
IsHacked(cameraId, propId) -- Check if a camera has been hacked
```

---

## 🔄 Integration Examples

- **Integration with any of your minigame scripts like `luma-minigames`, `ps-ui`...**  
- **Integration with your targeting system e.g. `ox-target`, `qb-target`...**  

---

## 📜 Credits

- **Developed by** Luma  
- **Special thanks** to the FiveM community for support and inspiration  

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.  

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

For support or inquiries, please join and open a ticket **https://discord.gg/uZ7bJwtM4c**.
