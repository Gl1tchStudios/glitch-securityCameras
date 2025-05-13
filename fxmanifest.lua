description 'Security Camera System'
fx_version 'cerulean'
author 'Luma in collaboration with Glitch'
lua54 'yes'
games { 'gta5' }

client_script {
   'client/cameraContols.lua',
   'client/highlightSystem.lua',
   'client/cameraUI.lua',
   'client/cameraExports.lua'
}

server_scripts {
    'server/server.lua',
}

shared_scripts {
    'shared/config.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}