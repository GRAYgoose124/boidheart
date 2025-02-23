local BoidManager = {}
BoidManager.__index = BoidManager

-- Add to the top of the file after other requires
local BlockEditor = require "block_editor"

function BoidManager.new(maxBoids)
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    self.maxBoids = maxBoids
    self.player = nil
    
    -- Initialize shaders
    local fieldShaderSource = love.filesystem.read("shaders/bounding_field.glsl")
    fieldShaderSource = fieldShaderSource:gsub("#define MAX_BOIDS 100", "#define MAX_BOIDS " .. maxBoids)
    self.fieldShader = love.graphics.newShader(fieldShaderSource)
    
    self.trailShader = love.graphics.newShader("shaders/trail_shader.glsl")
    self.trailShader:send("decay", 0.01) -- Adjust decay rate
    
    -- Create two canvases for trail effect (ping-pong buffering)
    self.trailCanvas = {
        love.graphics.newCanvas(),
        love.graphics.newCanvas()
    }
    self.currentTrailCanvas = 1
    
    self.canvas = love.graphics.newCanvas()
    self.shaderMode = "field" -- or "trail"
    
    -- Send initial resolution to shaders
    local w, h = love.graphics.getDimensions()
    self.fieldShader:send("resolution", {w, h})
    self.trailShader:send("resolution", {w, h})
    
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
    self.fieldShader:send("boidData", unpack(boidData))
    self.fieldShader:send("boidCount", #self.boids)
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
    
    if self.shaderMode == "field" then
        self:drawFieldEffect()
    else
        self:drawTrailEffect()
    end
    
    -- Draw boids
    for _, boid in ipairs(self.boids) do
        boid:draw()
    end
    
    -- Draw block editor on top
    self.blockEditor:draw()
end

function BoidManager:drawFieldEffect()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    love.graphics.setShader(self.fieldShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setShader()
    love.graphics.setCanvas()
    
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.draw(self.canvas)
    love.graphics.setBlendMode("alpha")
end

function BoidManager:drawTrailEffect()
    -- Swap canvases
    self.currentTrailCanvas = self.currentTrailCanvas == 1 and 2 or 1
    local source = self.trailCanvas[self.currentTrailCanvas == 1 and 2 or 1]
    local target = self.trailCanvas[self.currentTrailCanvas]
    
    -- Apply decay shader to previous frame
    love.graphics.setCanvas(target)
    love.graphics.clear()
    love.graphics.setShader(self.trailShader)
    love.graphics.draw(source)
    love.graphics.setShader()
    
    -- Draw new boid positions
    love.graphics.setBlendMode("add")
    for _, boid in ipairs(self.boids) do
        -- Color based on velocity
        local speed = math.sqrt(boid.vx * boid.vx + boid.vy * boid.vy)
        local normalizedSpeed = speed / boid.maxSpeed
        love.graphics.setColor(
            0.5 + normalizedSpeed * 0.5,  -- More red with speed
            0.2,
            0.5 - normalizedSpeed * 0.3,  -- Less blue with speed
            0.1  -- Low alpha for trail buildup
        )
        love.graphics.circle("fill", boid.x, boid.y, 3 + normalizedSpeed * 2)
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    
    -- Draw the result
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.draw(target)
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

function BoidManager:toggleShaderMode()
    self.shaderMode = self.shaderMode == "field" and "trail" or "field"
    -- Clear trail canvases when switching to trail mode
    if self.shaderMode == "trail" then
        love.graphics.setCanvas(self.trailCanvas[1])
        love.graphics.clear()
        love.graphics.setCanvas(self.trailCanvas[2])
        love.graphics.clear()
        love.graphics.setCanvas()
    end
end

return BoidManager 