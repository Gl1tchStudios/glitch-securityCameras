description 'Security Camera System'
fx_version 'cerulean'
author 'Luma'
lua54 'yes'
games { 'gta5' }

client_script {
   'client/*',
}

server_scripts {
    'server/*',
}

shared_scripts {
    'shared/config.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/assets/*.png'
}