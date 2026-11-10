# Changelog

## 1.2.0

- Sync fixes: leaving camera mode is never dropped by the server rate limit, switching cameras closes an open hack, and the client re-reports its camera once if the server lost it (for example after a resource restart).

- The NUI camera label is now in `Config.Locale.keys`.
- Removed unused hack overlay CSS, trimmed the example cameras to two and fixed a duplicated locale key.
- The server ignores camera reports for unknown cameras and rate limits them, a dropped player no longer leaves a hack count behind for the next player with the same server id, and the licence is now proprietary.
- Hacks now need a camera the server knows the player is viewing. Added a per-player cap on hacked props (`Config.MaxHacksPerPlayer`), the `SetHackAuthorizer` and `RegisterCamera` server exports, and an ox_lib skill check fallback when the hack minigame resource is not running. Removed `onSuccessServerEvent` and `onFailServerEvent`. `GetCameraConfig` returns a copy. The hack prompt key and the remaining NUI text are in `Config.Locale`.

## 1.1.0

- The server now tracks hacks. A hack must be opened through `glitch-securityCameras:beginHack`, is closed once with `completeHack`, and is refused if it comes back faster than `Config.MinHackSeconds`. The old client-triggered events and the undefined `QBCore` call are gone. Hacked props are shared through `GlobalState['secCam:hacked']` and expire after `Config.HackResetSeconds`.
- New server exports `GetHackedBy`, `ResetHack` and `ResetAllHacks`, and the server event `glitch-securityCameras:server:hackCompleted`. `IsHacked` keeps its signature.
- Camera mode no longer teleports the player or makes them invisible and invincible. It moves the camera and streaming focus only, and leaves on death, damage, timeout and resource stop.
- One input path for the arrow keys, exit and view mode. The arrow keys cycle only through the allowed list, or through cameras in the same group when none is given.
- `AttemptCameraHack` returns `false` at once when entering fails, and no longer leaks an event handler per call.
- `hackParams` given as a keyed table now reaches the minigame (`Config.HackParamOrder`). Props without `hackExport` or `hackEvent` use `Config.DefaultHack`.
- Prop checks run every 150 ms, prop entities are cached and the outline and NUI only update when the target changes.
- The NUI is one message listener with no console output, no unused minigame, a clock that only runs while the camera is open and no Google Fonts request.
- Text moved to `Config.Locale`. Debug prints are behind `Config.Debug`. The example cameras are off by default (`Config.EnableExamples`).
- Manifest metadata, README, LICENSE notice and this changelog added.

## 1.0.0

First release.
