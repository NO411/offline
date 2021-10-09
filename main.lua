local love = love
local math = love.math
local graphics = love.graphics
local mouse = love.mouse

function love.load(arg)
        graphics.setDefaultFilter("nearest", "nearest")
        status = {
                on = false,
                paused = false,
        }
        speed = 0
        day = true
        textures = {}
        for _, texture in pairs({"cactus", "cloud", "dino", "dino_stand", "dino_walk1", "dino_walk2", "ground", "paused", "dino_dead"}) do
                textures[texture] = graphics.newImage("textures/" .. texture .. ".png")
        end
        score = {score = 0, highscore = 0}
        dino = {
                pos = {x = 30, y = 340},
                body = "dino",
                texture = "stand",
                jumped = false,
        }
        pebble = {}
        for i = 1, 50 do
                pebble[i] = {
                        pos = {x = math.random(800), y = math.random(330, 360)},
                        scale = math.random(8),
                }
        end
        clouds = {}
        for i = 1, 4 do
                clouds[i] = {
                        pos = {x = 200*i + math.random(-220, -180), y = math.random(50, 200)},
                }
        end
        cacti = {}
        for i = 1, 20 do
                cacti[i] = {
                        pos = {x = 900, y = 340},
                        scale = math.random(150, 250) / 100,
                        moving = false,
                }
        end
        timer = {
                day = 0,
                score = 0,
                pebble = 0,
                dino_feat = 0,
                clouds = 0,
                cacti = 0,
        }
end

dino_feat_order = {
        stand = "walk1",
        walk1 = "walk2",
        walk2 = "walk1",
}

local function get_active_cacti()
        local active = 0
        for i = 1, #cacti do
                if cacti[i].moving then
                        active = active + 1
                end
        end
        return active
end

local function reset()
        for b = 1, #cacti do
                cacti[b].moving = false
                cacti[b].pos.x = 900
        end
        dino.body = "dino"
        status.paused = false
        score.score = 0
        dino.pos.y = 340
end

function love.keypressed(key)
        if key == "space" then
                if status.paused then
                        reset()
                elseif not status.on then
                        status.on = true
                end
        elseif key == "escape" then
                love.event.quit()
        end
end

function love.update(dt)
        for a, _ in pairs(timer) do
                timer[a] = timer[a] + dt
        end
        if status.on and not status.paused then
                speed = speed + 0.001
                if dino.pos.y == 340 and love.keyboard.isDown("space") then
                        dino.jumped = true
                end
                if dino.jumped then
                        local pos = dino.pos
                        if love.keyboard.isDown("space") and pos.y >= 220 then
                                pos.y = pos.y - 9
                        elseif pos.y >= 240 then
                                pos.y = pos.y - 7
                        else
                                dino.jumped = false
                        end
                end
                if not dino.jumped and dino.pos.y ~= 340 then
                        local pos = dino.pos
                        local h = pos.y + 4
                        if h >= 340 then
                                pos.y = 340
                        else
                                pos.y = pos.y + 4
                        end
                end
                if timer.pebble >= 0.001 then
                        for i = 1, #pebble do
                                local pos = pebble[i].pos
                                if pos.x <= 0 then
                                        pos.x = 800 + pos.x - (3 + speed)
                                        pebble[i].scale = math.random(8)
                                else
                                        pos.x = pos.x - (3 + speed)
                                end
                        end
                        timer.pebble = 0
                end
                if timer.cacti >= 0.001 then
                        for i = 1, #cacti do
                                local cactus = cacti[i]
                                if cactus.moving then
                                        local pos = cactus.pos
                                        if pos.x <= -22 then
                                                pos.x = 822 + pos.x - (3 + speed)
                                                cactus.moving = false
                                                cactus.scale = math.random(150, 250) / 100
                                                cactus.collisionbox = nil
                                        else
                                                pos.x = pos.x - (3 + speed)
                                        end
                                end
                        end
                        timer.cacti = 0
                end
                if math.random(50) == 1 and get_active_cacti() <= 10 then
                        local random_cactus = cacti[math.random(#cacti)]
                        local can_place = true
                        if random_cactus.moving then
                                can_place = false
                        else
                                local rcpos = random_cactus.pos.x
                                for i = 1, #cacti do
                                        if i ~= r then
                                                local cactus = cacti[i]
                                                if cactus.moving then
                                                        local cpos = cactus.pos.x
                                                        local dif = rcpos - cpos 
                                                        if dif <= 25 or (40 <= dif and dif <= 150) then
                                                                can_place = false
                                                        end
                                                end
                                        end
                                end
                        end
                        if can_place then
                                random_cactus.moving = true
                        end
                end
                for i = 1, #cacti do
                        local cactus = cacti[i]
                        if cactus.moving then
                                local cpos = cactus.pos
                                local cx, cy = cpos.x, cpos.y
                                local scale = cactus.scale
                                cactus.collisionbox = {
                                        {x = cx + 5, y = cy + 1},
                                        {x = cx + 17 * scale, y = cy + 1},
                                        {x = cx + 5, y = cy - 17 * scale},
                                        {x = cx + 17 * scale, y = cy - 17 * scale},
                                }
                                local dpos = dino.pos
                                local dx, dy = dpos.x, dpos.y
                                local dino_collisions = {
                                        {x = dx + 24, y = dy},
                                        {x = dx, y = dy - 22},
                                        {x = dx + 38, y = dy - 38},
                                        {x = dx + 32, y = dy - 22},
                                }
                                local collides = false
                                local box = cactus.collisionbox
                                for _, pos in pairs(dino_collisions) do
                                        if pos.x >= box[1].x and pos.x <= box[2].x and pos.y >= box[3].y and pos.y <= box[1].y then
                                                collides = true
                                                break
                                        end
                                end
                                if collides then
                                        status.paused = true
                                        if score.score > score.highscore then
                                                score.highscore = score.score
                                        end
                                        dino.body = "dino_dead"
                                        for i = 1, #cacti do
                                                cacti[i].collisionbox = nil
                                        end
                                        speed = 0
                                end 
                        end
                end
                if timer.clouds >= 0.01 then
                        for i = 1, #clouds do
                                local pos = clouds[i].pos
                                if pos.x <= -120 then
                                        pos.x = 920 + pos.x - 1
                                        pos.y = math.random(50, 200)
                                else
                                        pos.x = pos.x - 1
                                end
                        end
                        timer.clouds = 0
                end
                if timer.day >= 100 then
                        if day then
                                day = false
                        else
                                day = true
                        end
                        timer.day = 0
                end
                if timer.score >= 0.1 then
                        score.score = score.score + 1
                        timer.score = 0
                end
                if timer.dino_feat >= 0.1 then
                        if dino.pos.y == 340 then
                                dino.texture = dino_feat_order[dino.texture]
                        else
                                dino.texture = "stand"
                        end
                        timer.dino_feat = 0
                end
        elseif mouse.isDown(1) and status.paused then
                local x, y = mouse.getPosition()
                if x <= 422 and x >= 378 and y <= 272 and y >= 228 then
                        reset()
                end
        end
end

local function get_score(highscore)
        local n = score.score
        if highscore then
                n = score.highscore
        end
        local score = tostring(n)
        local len = string.len(score)
        if len < 5 then
                for i = 1, 5 - len do
                        score = 0 .. score
                end
        end
        return score
end

local function set_color(r, g, b, v)
        graphics.setColor({r/255, g/255, b/255, v})
end

local function set_white()
        set_color(255, 255, 255)
end

function love.draw()
        if day then
                set_white()
        else
                set_color(18, 32, 54)
        end
        graphics.rectangle("fill", 0, 0, 800, 500)
        set_color(85, 85, 85)
        graphics.print("HI  " .. get_score(true) .. "  " .. get_score(), 650, 10, 0, 1.2, 1.2, 0, 0)
        graphics.line(0, 325, 800, 325)
        for i = 1, #pebble do
                local pebble = pebble[i]
                local pos = pebble.pos
                graphics.line(pos.x, pos.y, pos.x + pebble.scale, pos.y)
        end
        set_white()
        for i = 1, #clouds do
                local cloud = clouds[i]
                local pos = cloud.pos
                graphics.draw(textures.cloud, pos.x, pos.y, 0, 2, 2, 0, 0)
        end
        for i = 1, #cacti do
                local cactus = cacti[i]
                local pos = cactus.pos
                if cactus.moving then
                        graphics.draw(textures.cactus, pos.x, pos.y, 0, cactus.scale, cactus.scale, 0, 22)
                end
        end
        graphics.draw(textures[dino.body], dino.pos.x, dino.pos.y, 0, 2, 2, 0, 22)
        graphics.draw(textures["dino_" .. dino.texture], dino.pos.x, dino.pos.y, 0, 2, 2, 0, 22)
        if status.paused then
                graphics.draw(textures.paused, 400, 250, 0, 1, 1, 22, 22)
        end
end