<div align="center">

# glitch-securityCameras

### Security camera viewer for heists and roleplay.

**Players look through fixed cameras, switch between them, pan within set limits, change to thermal or night vision and hack props they spot on the feed.**<br>
Other resources add cameras and start hacks through exports. The server tracks which props are hacked so every player and late joiner sees the same state.

Works on any framework. It needs ox_lib and nothing else. The default hack minigame comes from glitch-minigames and can be swapped in the config.

![Version](https://img.shields.io/badge/version-1.2.0-blue)
![FiveM](https://img.shields.io/badge/FiveM-cerulean-F40552)
![Framework](https://img.shields.io/badge/framework-standalone-2d6a4f)
![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72?logo=lua&logoColor=white)
![Database](https://img.shields.io/badge/database-none-lightgrey)
![License](https://img.shields.io/badge/license-proprietary-red)

[Features](#features) &middot; [What you need](#what-you-need) &middot; [Install](#install) &middot; [Configuration](#configuration) &middot; [Exports](#exports) &middot; [How it works](#how-it-works) &middot; [Troubleshooting](#troubleshooting)

</div>

---

## Features

| | |
|---|---|
| **Camera viewer** | A scripted camera with mouse panning inside per-camera rotation limits. The player ped stays where it is. |
| **View modes** | Normal, thermal and night vision. Each camera can turn thermal or night vision off. |
| **Prop targeting** | Props in front of the camera are outlined and can be hacked with the interact key. |
| **Hack flow** | Runs any minigame export or event you name. The server opens and closes every hack and shares the result. |
| **Shared state** | Hacked props are published in `GlobalState['secCam:hacked']` and reset after `Config.HackResetSeconds`. |
| **Developer exports** | Add and remove cameras at run time, enter a camera, wait for a hack result, check hacked state on the server. |
| **Text in config** | Every player-facing string is in `Config.Locale`. The font is not loaded from the internet. |

## What you need

Required:

- FiveM server artifact with OneSync enabled
- ox_lib

Tested with ox_lib 3.40.0.

Optional:

- glitch-minigames: the default hack minigame (`Config.DefaultHack`). Point `export` at any other minigame, or set it to `false` and give each prop its own `hackExport` or `hackEvent`.

There is no database and no item. Nothing in this resource needs a framework.

## Install

1. Copy the `glitch-securityCameras` folder into your `resources` folder.
2. Add `ensure glitch-securityCameras` to your `server.cfg`, after ox_lib.
3. Open `shared/config.lua`. Add your cameras to `Config.Cameras`, or set `Config.EnableExamples = true` to load three test cameras (the prop models and some coordinates are placeholders).
4. Call the exports from your own resources (see [Exports](#exports)).

## Configuration

Everything is in `shared/config.lua`.

| Setting | What it does |
|---|---|
| `Config.Debug` | Console output. Leave it off on a live server. |
| `Config.AutoExitEnabled`, `Config.AutoExitTime` | Leave the camera by itself after this many seconds. A running hack does not count. |
| `Config.Controls` | Game control ids for left, right, exit, interact and view mode. If you change them, update the key text in `Config.Locale.keys`. |
| `Config.GroupBlock` | With no allowed list, the arrow keys only cycle through cameras in the same id block. With 100, ids 8501 and 8502 are together and id 100 is separate. A camera can set `group = 'name'` instead. |
| `Config.DefaultHack` | Minigame used when a prop has neither `hackExport` nor `hackEvent`. |
| `Config.HackParamOrder` | Order used to turn a keyed `hackParams` table into arguments. A plain list is passed as it is. |
| `Config.HackResetSeconds` | How long a hacked prop stays hacked for everyone. |
| `Config.MinHackSeconds` | A hack reported finished sooner than this is refused. |
| `Config.BeginCooldownMs` | Minimum time between two hack starts from one player. |
| `Config.AllowRuntimeCameras` | The server accepts hacks for cameras added with `AddCamera`. Cameras listed in the config are always checked. Default is on so existing integrations keep working. Set it to false and call the server export `RegisterCamera` for a strict list. The viewing report comes from the client, so also set `SetHackAuthorizer` before paying out from `hackCompleted`. |
| `Config.Locale` | All player-facing text. |

### Camera fields

```lua
{
    id = 1,                         -- unique, number or string
    name = 'Security Entrance',
    location = 'Casino',
    modes = { nightVision = true, thermal = true },   -- optional, both default to true
    position = vector3(0.0, 0.0, 0.0),
    rotation = vector3(-10.0, 0.0, 136.0),
    rotationLimits = { x = { min = -75, max = -5 }, z = { min = 89, max = 175 } },
    interactiveProps = {
        {
            propUniqueId = 'security_mainframe',
            position = vector3(0.0, 0.0, 0.0),
            hash = -1498975473,
            interactionText = 'Disable the Door Locks',
            successText = 'Security system bypassed',
            failText = 'Security alert triggered',
            highlightColor = { r = 0, g = 255, b = 0, a = 200 },
            exitOnHack = false,
            hackExport = 'glitch-minigames:StartSurgeOverride',   -- 'resource:export', must return true on success
            hackParams = { keys = { 'E', 'F' }, requiredPresses = 30, decayRate = 2 },
            -- hackEvent = 'my:event',                            -- or an event that calls the callback it is given
            -- onSuccessEvent, onFailEvent                        -- client events, receive the prop id
            -- onSuccessServerEvent, onFailServerEvent            -- server events, receive the prop id
        },
    },
}
```

`hackParams` can be a list (`{ {'E','F'}, 30, 2 }`, passed as arguments in order) or a keyed table (turned into arguments with `Config.HackParamOrder`).

## Exports

Client:

| Export | What it does |
|---|---|
| `EnterCameraMode(cameraId, allowedIds)` | Enters the camera. `allowedIds` is an optional list the arrow keys are limited to. Returns `true` when the player is in. |
| `ExitCameraMode()` | Leaves the camera. |
| `SwitchCamera(index)` | Switches to the camera at that position in the camera list, if it is in the current cycle. |
| `AttemptCameraHack(cameraId, propId, allowedIds)` | Enters the camera and waits for the first hack result. Returns `true` only when the hack was won and the server accepted it. Returns `false` straight away when entering fails. |
| `AddCamera(cameraData)` | Adds a camera on this client. Returns `true` or `false, reason`. |
| `RemoveCamera(cameraId)` | Removes a camera on this client. |
| `GetAllCameras()`, `GetCameraById(id)`, `GetCameraConfig()` | Read the camera list or the config. |
| `ShowCameraNotification(message, style)` | Shows a message on the camera screen. `style` is `info`, `success` or `error`. |
| `HighlightProp`, `RemoveHighlight`, `ClearAllHighlights`, `SetHighlightActive` | Prop outline helpers. |

Server:

| Export or event | What it does |
|---|---|
| `IsHacked(cameraId, propId)` | `true` while the prop is hacked. |
| `GetHackedBy(cameraId, propId)` | Source of the player who completed the hack, or `nil`. |
| `ResetHack(cameraId, propId)`, `ResetAllHacks()` | Make props hackable again, for example at the start of a heist run. |
| `glitch-securityCameras:server:hackCompleted` | Local server event `(source, cameraId, propId)` fired after the server accepts a hack. Use this one to pay out or unlock. |

Cameras added with `AddCamera` exist on the client that called it. Call it on every client that needs the camera, for example when the resource starts.

## How it works

1. The player presses the interact key on an outlined prop. The client asks the server to open a hack through `glitch-securityCameras:beginHack`. The server refuses invalid ids, props that are already hacked and starts that come too quickly.
2. The minigame runs on the client.
3. On a win the client calls `completeHack`. The server accepts it only for the hack it opened, only once, and only after `Config.MinHackSeconds`. It then updates `GlobalState['secCam:hacked']` and fires `glitch-securityCameras:server:hackCompleted`.
4. Late joiners read the state bag and see the same hacked props.

The minigame result comes from the client, so the server cannot prove it was won. Pay out or unlock only from `hackCompleted` or `IsHacked`, never from a client event. `onSuccessServerEvent` and `onFailServerEvent` were removed in 1.2.0.

Server exports for integrators: `SetHackAuthorizer(fn)` takes `fn(source, cameraId, propId)` and must return true to let that player start a hack (job, item or permission checks). `RegisterCamera(cameraId, propIds)` limits a runtime camera to the listed props. The hacked list is kept in memory and resets when the resource restarts.

Camera mode does not move the player. It moves the camera and the streaming focus, freezes the ped, hides the radar and puts everything back on exit, on death or damage, on timeout and when the resource stops.

## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing happens when I press the interact key | The prop is not outlined, so it is not in view. Check the camera `rotation`, the prop `position` and that the model exists at that spot. |
| The prop is not outlined | `hash` must be the model of an object at `position` within 10 metres. |
| "Hacking tool unavailable" | The minigame resource in `hackExport` or `Config.DefaultHack.export` is not started. |
| "System already compromised" | The prop was hacked and is waiting out `Config.HackResetSeconds`. Call `ResetHack` from the server to clear it. |
| The arrow keys do not switch cameras | Only cameras in the same group (or the allowed list) are in the cycle. See `Config.GroupBlock`. |

## Credits

Developed by Luma and DexterTheCat3 in collaboration with Glitch Studios.

## License

Proprietary. One copy on one server you operate. See [LICENSE](LICENSE).

Support: https://discord.gg/PAQX8ANEfw
