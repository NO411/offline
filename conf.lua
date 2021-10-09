local settings = {
        title = "offline",
        width = 800,
        height = 500,
        icon = "icon.png"
}

function love.conf(conf)
        for setting, value in pairs(settings) do
                conf.window[setting] = value
        end
        conf.version = "11.3"
end