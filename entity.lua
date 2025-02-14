local Entity = {}
Entity.__index = Entity

function Entity.new(x, y)
    local self = setmetatable({}, Entity)
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.maxSpeed = 200
    self.maxForce = 300
    return self
end

function Entity:applyForce(fx, fy)
    self.vx = self.vx + fx
    self.vy = self.vy + fy
end

function Entity:limitVelocity()
    local speed = math.sqrt(self.vx^2 + self.vy^2)
    if speed > self.maxSpeed then
        self.vx = self.vx / speed * self.maxSpeed
        self.vy = self.vy / speed * self.maxSpeed
    end
end

function Entity:move(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Entity:getDistance(other)
    local dx = other.x - self.x
    local dy = other.y - self.y
    return math.sqrt(dx * dx + dy * dy), dx, dy
end

return Entity 