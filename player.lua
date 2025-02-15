local Entity = require "entity"

local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(x, y)
    local self = Entity.new(x, y)
    setmetatable(self, Player)
    return self
end

function Player:update(dt)
    local ax, ay = 0, 0
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then ay = ay - 1 end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then ay = ay + 1 end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then ax = ax - 1 end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then ax = ax + 1 end

    local len = ax * ax + ay * ay
    if len > 0 then
        ax = ax / len * self.acceleration
        ay = ay / len * self.acceleration
    end
    
    -- Update velocity with acceleration
    self.vx = self.vx + ax * dt
    self.vy = self.vy + ay * dt

    -- Clamp velocity to max speed
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > self.maxSpeed then
        self.vx = self.vx / speed * self.maxSpeed
        self.vy = self.vy / speed * self.maxSpeed
    end

    -- Apply damping to simulate drift
    local damping = 0.99
    self.vx = self.vx * damping
    self.vy = self.vy * damping
    
    self:move(dt)
end

function Player:draw()
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", self.x, self.y, 10)
end

return Player 