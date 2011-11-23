require "helper"
require "wall"

require 'socket'
math.randomseed(socket.gettime()*10000)

-- helpers

function R(...)
    return math.random(...)
end

function hex(r,g,b)
    if g == nil then
        b = r.b
        g = r.b
        r = r.r
    end
    return string.format("%.2x%.2x%.2x",r,g,b)
end

function shuffle(t)
  local n = #t

  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end

  return t
end

function inbound(p, _min, _max)
    if _min == nil then _min = 0 end
    if _max == nil then _max = 1 end
    if p > _max then p = _max elseif p < _min then p = _min end
    return p
end

function sqdist(a, b)
    local x = b.x - a.x
    local y = b.y - a.y
    return x*x + y*y
end

function dist(...)
    return math.sqrt(sqdist(...))
end

-- values

nr = 13
blobs = {}


-- helpervalues
local __maxbound = 1.5
local __reznr = 1 / nr
local __maxd = 0

--------------------------------------------------------------------------------


function update()
    for _, blob in ipairs(blobs) do
        local d = 0.3
        blob.dir.x = (blob.dir.x + R()*d - d*0.5)*0.9
        blob.dir.y = (blob.dir.y + R()*d - d*0.5)*0.9

        blob.strength = (blob.strength + R()*10 - 5)*0.8
        --blob.radius = (blob.radius     + R()*0.1 - 0.05)

        blob.x = blob.x + blob.dir.x
        blob.y = blob.y + blob.dir.y

        if blob.x > wall.width * __maxbound then
            blob.x = - wall.width * __maxbound
        elseif blob.x < - wall.width * __maxbound then
            blob.x = wall.width * __maxbound
        end

        if blob.y > wall.height * __maxbound then
            blob.y = - wall.height * __maxbound
        elseif blob.y < - wall.height * __maxbound then
            blob.y = wall.height * __maxbound
        end


        for k, c in pairs(blob.color) do
            blob.color[k] = c + R()*10 - 5
        end
    end
end

function draw()

    for y = 1, wall.height do
        for x = 1, wall.width do
            local curpos = {x=x,y=y}

            local r,g,b = 0,0,0
            for _, blob in ipairs(blobs) do

                local d = dist(curpos, blob)
                if d < 0.9 then d = d * 0.9 end
                --d = math.log(d)*2
                --d = math.log((d*d) / (__maxd*__maxd))
                ---d = math.log10((__maxd / (d * blob.radius))
                d = math.log((__maxd*blob.radius) / d)
                --d = (1 - d) / __maxd
                --d = math.log(d)

                d = d * blob.strength

                r = r + blob.color.r * d
                g = g + blob.color.g * d
                b = b + blob.color.b * d
            end

            r = inbound(r * __reznr,0,255)
            g = inbound(g * __reznr,0,255)
            b = inbound(b * __reznr,0,255)

            --print(x,y,r,g,b)

            wall:pixel(x-1, y-1, hex(r,g,b))
        end
    end

end

--------------------------------------------------------------------------------

function love.load()
    wall = Wall("ledwall", 1338, 3)

    __maxd = math.sqrt(wall.width*wall.height)

    time = love.timer.getTime() * 1000

    tick = 0


    -- initialize

    for i=1,nr do
        local blob = {
            dir={
                x = R()*1.5-0.75,
                y = R()*1.5-0.75,
            },
            strength = (R()*9 + 1),
            radius = R()+0.5,
            color = {r=0,g=0,b=0},--{ r=R(150,200), g=R(150,200), b=R(150.200) },
            x = R()*wall.width*__maxbound - wall.width*__maxbound*0.5,
            y = R()*wall.height*__maxbound - wall.height*__maxbound*0.5,
        }

        for i, c in ipairs(shuffle({"r","g","b"})) do
            blob.color[c] = R() * 40 + 60 * i
        end

        table.insert(blobs, blob)
    end

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