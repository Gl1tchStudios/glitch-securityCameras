fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'glitch-securityCameras'
author 'Glitch Studios'
description 'Security camera viewer with thermal and night vision, prop targeting and a server-tracked hacking flow'
version '1.2.0'

-- Required: ox_lib. Optional, checked at run time: glitch-minigames (the default hack minigame,
-- changeable in shared/config.lua). See README.md.
dependencies {
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

-- Load order matters: highlightsystem.lua defines the shared SecCam table the other two use.
client_scripts {
    'client/highlightsystem.lua',
    'client/cameraExports.lua',
    'client/main.lua',
}

server_scripts {
    'server/server.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
}

escrow_ignore {
    'shared/config.lua',
    'README.md',
    'LICENSE',
    'CHANGELOG.md',
}
