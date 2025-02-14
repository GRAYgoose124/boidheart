local Entity = require "entity"

local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(x, y)
    local self = Entity.new(x, y)
    setmetatable(self, Player)
    return self
end

function Player:update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then dx = dx + 1 end

    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx = dx / len * self.maxSpeed
        dy = dy / len * self.maxSpeed
    end
    
    self.vx = dx
    self.vy = dy
    self:move(dt)
end

function Player:draw()
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", self.x, self.y, 10)
end

return Player 