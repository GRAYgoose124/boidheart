local BoidManager = {}
BoidManager.__index = BoidManager

-- Add to the top of the file after other requires
local BlockEditor = require "block_editor"

function BoidManager.new(maxBoids)
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    self.maxBoids = maxBoids
    self.player = nil
    
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
    
    self.blockEditor = BlockEditor.new()
    
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
    
    -- if selection has waypoints circle them
    if self.waypointManager.paths[self.waypointManager.currentGroupId] then
        love.graphics.setColor(1, 1, 0, 0.5)
        for _, waypoint in ipairs(self.waypointManager.paths[self.waypointManager.currentGroupId]) do
            love.graphics.circle("line", waypoint.x, waypoint.y, 10)
        end
    end

    -- Draw waypoints
    self.waypointManager:draw()
    
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
    
    -- Draw block editor on top
    self.blockEditor:draw()
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
        self.waypointManager.currentGroupId = self.waypointManager.currentGroupId+1
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

function BoidManager:cycleGroupSelection(nextGroup)
    -- Deselect all and select new group
    for _, boid in ipairs(self.boids) do
        boid.selected = (boid.groupId == nextGroup)
    end
end

function BoidManager:setPlayer(player)
    self.player = player
end

return BoidManager 