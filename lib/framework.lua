
require 'socket'
math.randomseed(socket.gettime()*10000)

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
