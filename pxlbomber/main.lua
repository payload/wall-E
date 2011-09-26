require "helper"
require "wall"

function p(x) print(x) return x end

DIRECTIONS = {
    { -1, -1 }, { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 },
    { -1, 0 }
}
do
    for i, o in ipairs(DIRECTIONS) do
        local x, y, l = o[1], o[2]
        l = math.sqrt(x*x + y*y)
        DIRECTIONS[i] = {
            i = i,
            x = x,
            y = y,
            --name = "%c%c" % { x+66, y+66 },
        }
    end
end



Plane = Object:new()
function Plane:init()
    self.color = "FFFFFF"
    self.x = 0
    self.y = 0
    self.d = 2
    self.locks = {
        forward = TimeLock(4),
        turn = TimeLock(10),
    }
    self.faster_forward_time = 2
    self.faster_turn_time = 15
    self.input = {
        faster = false,
        left = false,
        right = false,
    }
    -- 012
    -- 345
    -- 678
    self.pics = {
        { 0, 1, 3 }, -- NW
        { 1, 3, 5 }, -- N
        { 1, 2, 5 }, -- NE
        { 1, 5, 7 }, -- E
        { 5, 7, 8 }, -- SE
        { 3, 5, 7 }, -- S
        { 3, 6, 7 }, -- SW
        { 1, 3, 7 }, -- W
    }
end

function Plane:draw(sx, sy)
    local x, y, c = 0, 0, self.color
    for _, i in ipairs(self.pics[self.d]) do
        x = math.floor(self.x + i % 3 - sx)
        y = math.floor(self.y + i / 3 - sy)
        if x >= 0 and x <= 15 and y >= 0 and y <= 15 then
            wall:pixel(x, y, c)
        end
    end
end

function Plane:update()
    if self.locks.forward:take() then
        local dir = DIRECTIONS[self.d]
        self.x = self.x + dir.x
        self.y = self.y + dir.y
        if self.input.faster then self:faster() end
        if self.input.left then self:left() end
        if self.input.right then self:right() end
    end
    for k, v in pairs(self.locks) do self.locks[k]:dec() end
end

function Plane:faster()
    self.locks.forward.time = self.faster_forward_time
end

function Plane:left()
    if self.locks.turn:take() then
        self.d = self.d > 1 and self.d - 1 or #DIRECTIONS
        if self.input.faster then
            self.locks.turn.time = self.faster_turn_time
        end
    end
end

function Plane:right()
    if self.locks.turn:take() then
        self.d = self.d < #DIRECTIONS and self.d + 1 or 1
        if self.input.faster then
            self.locks.turn.time = self.faster_turn_time
        end
    end
end



TimeLock = Object:new()
function TimeLock:init(time)
    self.starttime = time
    self.time = time
end

function TimeLock:dec()
    if self.time > 0 then self.time = self.time - 1 end
end

function TimeLock:take()
    if self.time > 0 then return false
    else
        self.time = self.starttime
        return true
    end
end



Background = Object:new()
function Background:init()
    self.pixels = {}
    self.cur = { x = 0, y = 0 }
    self:set_pixels(0, 0)
end

function Background:draw(sx, sy)
    if sx ~= self.cur.x or sy ~= self.cur.y then
        self:set_pixels(sx, sy)
        self.cur.x = sx
        self.cur.y = sy
    end
    for y, row in ipairs(self.pixels) do
        for x, color in ipairs(row) do
            wall:pixel(x-1, y-1, color)
        end
    end
end

function Background:map_pixel(x, y)
    if x ==  5 and y ==  5 then return "00FF00" end
    if x == 13 and y == 13 then return "0000FF" end
    local r, g, b
    g = math.random(145, 150)
    r = math.random(140, 145)
    b = math.random(140, 150)
    return string.format("%02x%02x%02x", r, g, b)
end

function Background:set_pixels(fx, fy)
    local row, cl, dx, dy, img
    dx = fx - self.cur.x
    dy = fy - self.cur.y
    img = {}
    for y = 1, 15 do
        row = {}
        for x = 1, 15 do
            cl = self.pixels[y + dy]
            if cl then cl = cl[x + dx] end
            if not cl then
                cl = self:map_pixel(fx + x - 1, fy + y - 1)
            end
            row[x] = cl
        end
        img[y] = row
    end
    self.pixels = img
end



Game = Object:new()
function Game:init()
    self.timeouts = {}
    self.player = Plane()
    self.stuff = { Background(), self.player }
    self.x = 0
    self.y = 0
end

function Game:draw()
    for _, x in ipairs(self.stuff) do
        x:draw(self.x, self.y)
    end
end

function Game:add_stuff(x)
    table.insert(self.stuff, x)
end

function Game:update()
    local input = wall.input[2]

    --if input.up    then y = y - 1 end
    --if input.down  then y = y + 1 end
    if self.player then
        local player = self.player.input
        player.left = input.left
        player.right = input.right
        player.faster = input.up
    end

    local stay = {}
    for i, x in ipairs(self.stuff) do
        if x.update then
            x:update()
        end
        if not x.delete then
            table.insert(stay, x)
        end
    end
    local stuff = {}
    for _, x in ipairs(stay) do
        table.insert(stuff, x)
    end
    self.stuff = stuff
    self.x = self.player.x - 6
    self.y = self.player.y - 6
end

function love.keypressed(key)
	if key == "escape" then
		love.event.push "q"

	elseif key == "f1" then
		wall:record(true)
		print("recording...")

	elseif key == "f2" then
		wall:record(false)
		print("recording stopped")

	end
end

love.graphics.setMode(200, 200, false, true, 0)

function love.load()
	wall = Wall("ledwall", 1338, 3, false)
    game = Game()
	tick = 0
end

function love.update(dt)
	tick = tick + 1
    game:update()
	wall:update_input()
end


function love.draw()
	game:draw()
	wall:draw()
end

