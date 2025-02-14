local BoidManager = {}
BoidManager.__index = BoidManager

function BoidManager.new()
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    return self
end

function BoidManager:add(boid)
    table.insert(self.boids, boid)
end

function BoidManager:update(dt)
    for _, boid in ipairs(self.boids) do
        boid:update(dt)
    end
end

function BoidManager:draw()
    for _, boid in ipairs(self.boids) do
        boid:draw()
    end
end

return BoidManager 