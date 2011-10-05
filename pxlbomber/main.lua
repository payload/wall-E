require "helper"
require "wall"

function p(x) print(x) return x end
math.round = function (x)
    local y = math.floor(x)
    if y + 0.5 < x then return y+1 else return y end
end

function random_bool(x)
    x = x or 0.5
    if math.random() < x then
        return true
    else
        return false
    end
end

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
    self.type = "Plane"
    self.color = "CCCCCC"
    self.x = 0
    self.y = 0
    self.d = 2
    self.locks = {
        forward = TimeLock(4),
        turn = TimeLock(10),
        shoot = TimeLock(9),
    }
    self.faster_forward_time = 2
    self.faster_turn_time = 5
    self.input = {
        faster = false,
        left = false,
        right = false,
        shoot = false,
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
        if x >= 0 and x < 15 and y >= 0 and y < 15 then
            wall:pixel(x, y, c)
        end
    end
end

function Plane:update()
    if self ~= game.player then
        local tx, ty = game.player.x, game.player.y
        local x, y = self.x, self.y
        local a = math.atan2(tx - x, ty - y) + math.pi
        a = math.round(a / math.pi / 2 * 8)
        a = (-a + 1) % 8 + 1
        if self.d ~= a then
            local r = math.random()
            if     r < 0.3 then self.input.left = true
            elseif r < 0.6 then self.input.right = true
            end
        end
    end
    if self.locks.forward:take() then
        local dir = DIRECTIONS[self.d]
        self.x = self.x + dir.x
        self.y = self.y + dir.y
        if self.input.faster then self:faster() end
        if self.input.left then self:left() end
        if self.input.right then self:right() end
        if self.input.shoot then self:shoot() end
    end
    for k, v in pairs(self.locks) do self.locks[k]:dec() end
    for k, v in pairs(self.input) do self.input[k] = false end
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

function Plane:shoot()
    if self.locks.shoot:take() then
        game:add_stuff(Bubs(self.x + 1, self.y + 1, self.d, self))
    end
end



Bubs = Object:new()
function Bubs:init(x, y, d, owner)
    self.x = x or 0
    self.y = y or 0
    self.d = d or 1
    self.owner = owner or nil
    self.ttl = 15
    self.locks = {
        forward = TimeLock(1)
    }
end

function Bubs:update()
    self.ttl = self.ttl - 1
    if self.ttl <= 0 then self.delete = true end
    if self.locks.forward:take() then
        local dir = DIRECTIONS[self.d]
        self.x = self.x + dir.x
        self.y = self.y + dir.y
        for _, plane in ipairs(game.stuff) do
            if plane.type == 'Plane' and plane ~= self.owner then
                local x = self.x - plane.x
                local y = self.y - plane.y
                if x >= 0 and x < 3 and y >= 0 and y < 3 then
                    --plane.delete = true
                    plane.x = 0
                    plane.y = 0
                    self.delete = true
                end
            end
        end
    end
    for k, v in pairs(self.locks) do self.locks[k]:dec() end
end

function Bubs:draw(sx, sy)
    local x = self.x - sx
    local y = self.y - sy
    local c = "FFFF00"
    if x >= 0 and x < 15 and y >= 0 and y < 15 then
        wall:pixel(x, y, c)
    end
end



TimeLock = Object:new()
function TimeLock:init(time)
    self.starttime = time
    self.time = 0
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

tree = 1

function Background:map_pixel(x, y)
    local R = math.random()
    if R < (0.4 / tree) then
        tree = tree + 1
        --return "0000FF"
    else tree = 1
    end
    if R > 0.995 then return "AA0000" end
    local r, g, b
    r = math.random(40, 60)
    g = math.random(140, 160)
    b = math.random(140, 160)
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
    self.player.locks.forward.starttime = 5
    self.player.locks.turn.starttime = 10
    self.player.color = "FFFFFF"
    self.stuff = { Background() }
    for _ = 0, 10, 1 do table.insert(self.stuff, Plane()) end
    table.insert(self.stuff, self.player)
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

switches = { { "faster", 0 } }

function Game:update()
    local input = wall.input[2]

    for _, s in ipairs(switches) do
        local k, p = unpack(s)
        if random_bool(p) then
            switches[k] = not switches[k]
        end
    end

    if self.player then
        local player = self.player.input
        player.left = input.left or random_bool(0.2)
        player.right = input.right or random_bool(0.2)
        player.faster = input.up or switches.faster
        player.shoot = input.a or random_bool(0.1)
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
		love.event.push("q")

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

