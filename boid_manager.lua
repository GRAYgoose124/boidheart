local BoidManager = {}
BoidManager.__index = BoidManager

function BoidManager.new(maxBoids)
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    self.maxBoids = maxBoids
    
    -- Initialize shader with dynamic MAX_BOIDS
    local shaderSource = love.filesystem.read("shaders/bounding_field.glsl")
    shaderSource = shaderSource:gsub("#define MAX_BOIDS 100", "#define MAX_BOIDS " .. maxBoids)
    
    self.shader = love.graphics.newShader(shaderSource)
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
    if #self.boids >= self.maxBoids then
        print("Warning: Attempted to add more boids than the maximum allowed.")
        return
    end
    table.insert(self.boids, boid)
end

function BoidManager:update(dt)
    for _, boid in ipairs(self.boids) do
        boid:update(dt)
    end
    
    -- Create array of combined position and velocity data
    local boidData = {}
    for i = 1, #self.boids do
        boidData[i] = {
            self.boids[i].x, 
            self.boids[i].y, 
            self.boids[i].vx, 
            self.boids[i].vy
        }
    end
    
    -- Send combined data to shader
    self.shader:send("boidData", unpack(boidData))
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