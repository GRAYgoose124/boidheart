local Entity = require "entity"

local Boid = setmetatable({}, {__index = Entity})
Boid.__index = Boid

function Boid.new(x, y, leader, manager)
    local self = Entity.new(x, y)
    setmetatable(self, Boid)
    self.leader = leader
    self.boidManager = manager
    self.maxSpeed = 150
    self.maxForce = 300
    self.vx = math.random(-50, 50)
    self.vy = math.random(-50, 50)
    
    -- Flocking parameters
    self.separationRadius = 30
    self.separationWeight = 1.0
    self.neighborRadius = 150
    self.cohesionWeight = 0.5
    self.alignmentWeight = 0.5
    return self
end

function Boid:update(dt)
    -- Base seeking behavior
    local desiredX = self.leader.x - self.x
    local desiredY = self.leader.y - self.y
    local distance = math.sqrt(desiredX^2 + desiredY^2)
    
    if distance > 0 then
        desiredX = desiredX / distance * self.maxSpeed
        desiredY = desiredY / distance * self.maxSpeed
    end

    local steerX = desiredX - self.vx
    local steerY = desiredY - self.vy

    -- Add flocking behaviors
    local sepX, sepY = 0, 0
    local cohX, cohY = 0, 0
    local aliX, aliY = 0, 0
    local neighborCount = 0

    for _, other in ipairs(self.boidManager.boids) do
        if other ~= self then
            local d, dx, dy = self:getDistance(other)
            
            -- Separation
            if d < self.separationRadius then
                sepX = sepX - dx*d
                sepY = sepY - dy*d
            end
            
            -- Cohesion and Alignment
            if d < self.neighborRadius then
                cohX = cohX + other.x
                cohY = cohY + other.y
                aliX = aliX + other.vx
                aliY = aliY + other.vy
                neighborCount = neighborCount + 1
            end
        end
    end

    -- Apply flocking forces
    if neighborCount > 0 then
        -- Cohesion
        cohX = (cohX / neighborCount - self.x) * self.cohesionWeight
        cohY = (cohY / neighborCount - self.y) * self.cohesionWeight
        
        -- Alignment
        aliX = (aliX / neighborCount - self.vx) * self.alignmentWeight
        aliY = (aliY / neighborCount - self.vy) * self.alignmentWeight
        
        steerX = steerX + cohX + aliX
        steerY = steerY + cohY + aliY
    end

    -- Apply separation
    steerX = steerX + sepX * self.separationWeight
    steerY = steerY + sepY * self.separationWeight

    -- Limit steering force
    local steerMag = math.sqrt(steerX^2 + steerY^2)
    if steerMag > self.maxForce then
        steerX = steerX / steerMag * self.maxForce
        steerY = steerY / steerMag * self.maxForce
    end

    -- Apply steering force
    self:applyForce(steerX * dt, steerY * dt)
    self:limitVelocity()
    self:move(dt)
end

function Boid:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", self.x, self.y, 5)
end

return Boid 