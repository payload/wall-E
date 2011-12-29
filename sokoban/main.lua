require "helper"
require "wall"
require "framework"

-- values

env = {
}


-- helpervalues
-- local __maxbound = 1.5
-- local __reznr = 1 / (nr*0.1) -- / (nr*3)
-- local __maxd = 0


local operator = {
    ["+"]=function(a,b)return a+b end,
    ["-"]=function(a,b)return a-b end}

--------------------------------------------------------------------------------

Player = Object:new()
function Player:init(opts)
    opts = opts or {}
    self.pos = { x = 1, y=2 }
end

function Player:update()
    local x, y = self.pos.x, self.pos.y
    wall:pixel(round(x), round(y), self.color)
end

function Player:draw()
    local x, y = self.pos.x, self.pos.y
    wall:pixel(round(x), round(y), self.color)
end

--------------------------------------------------------------------------------

function update()
    wall:update_input()

    for y = 1, wall.height do
        for x = 1, wall.width do
            wall:pixel(x-1, y-1, hex(0,0,0))
        end
    end

    env.player:update()

    tick = tick + 1
end

function draw()

    env.player:draw()

end

--------------------------------------------------------------------------------

function love.load()
    wall = Wall(false, 1338, 3, false) -- "176.99.24.251"
    --wall = Wall('176.99.24.251', 1338, 3, false) -- "176.99.24.251"

--     __maxd = math.sqrt(wall.width*wall.height)

    time = love.timer.getTime() * 1000

    env.player = Player {
        x = wall.width*0.5,
        y = wall.height*0.5,
    }

    tick = 0

end

function love.keypressed(key)
    if key == "escape" then
        love.event.push "q"
    end
end

function love.update(dt)
    -- constant 30 FPS
    local t = love.timer.getTime() * 1000
    time = time + 1000 / 30
    love.timer.sleep(time - t)

    update()
end


function love.draw()
    draw()
    -- send the stuff abroad
    wall:draw()
end
