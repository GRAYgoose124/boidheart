local BoidManager = {}
BoidManager.__index = BoidManager

function BoidManager.new()
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    
    -- Initialize shader
    self.shader = love.graphics.newShader("shaders/bounding_field.glsl")
    self.canvas = love.graphics.newCanvas()
    
    -- Send initial resolution to shader
    local w, h = love.graphics.getDimensions()
    self.shader:send("resolution", {w, h})
    
    self.waypointManager = require("waypoint_manager").new()
    self.selectionRadius = 100
    self.selecting = false
    self.selectionX = 0
    self.selectionY = 0
    
    return self
end

function BoidManager:add(boid)
    table.insert(self.boids, boid)
end

function BoidManager:update(dt)
    for _, boid in ipairs(self.boids) do
        boid:update(dt)
    end
    
    -- Create arrays of positions and velocities
    local positions = {}
    local velocities = {}
    for i = 1, #self.boids do
        positions[i] = {self.boids[i].x, self.boids[i].y}
        velocities[i] = {self.boids[i].vx, self.boids[i].vy}
    end
    
    -- Send data to shader
    self.shader:send("boids", unpack(positions))
    self.shader:send("velocities", unpack(velocities))
    self.shader:send("boidCount", #self.boids)
end

function BoidManager:draw()
    -- Draw selection circle if selecting
    if self.selecting then
        love.graphics.setColor(0, 1, 1, 0.3)
        love.graphics.circle("line", self.selectionX, self.selectionY, self.selectionRadius)
    end
    
    -- Draw waypoints
    for groupId, path in pairs(self.waypointManager.paths) do
        love.graphics.setColor(1, 1, 0, 0.5)
        for i, waypoint in ipairs(path) do
            love.graphics.circle("fill", waypoint.x, waypoint.y, 5)
            if i > 1 then
                local prev = path[i-1]
                love.graphics.line(prev.x, prev.y, waypoint.x, waypoint.y)
            end
        end
    end
    
    -- Draw boids
    for _, boid in ipairs(self.boids) do
        boid:draw()
    end
    
    -- Draw field effect
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)  -- Clear with transparency
    
    love.graphics.setShader(self.shader)
    love.graphics.setColor(1, 1, 1, 1)  -- Full opacity for shader
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setShader()
    love.graphics.setCanvas()
    
    -- Draw the field effect
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, 0.5)  -- Control overall field opacity
    love.graphics.draw(self.canvas)
    love.graphics.setBlendMode("alpha")
    

end

function BoidManager:startSelection(x, y)
    self.selecting = true
    self.selectionX = x
    self.selectionY = y
end

function BoidManager:endSelection()
    self.selecting = false
    local selectedCount = 0
    for _, boid in ipairs(self.boids) do
        if boid.selected then
            boid.groupId = self.waypointManager.currentGroupId
            selectedCount = selectedCount + 1
        end
    end
    
    if selectedCount > 0 then
        self.waypointManager.currentGroupId = self.waypointManager.currentGroupId + 1
    end
end

function BoidManager:updateSelection(x, y)
    for _, boid in ipairs(self.boids) do
        local dx = boid.x - x
        local dy = boid.y - y
        local distance = math.sqrt(dx * dx + dy * dy)
        boid.selected = distance <= self.selectionRadius
    end
end

return BoidManager 