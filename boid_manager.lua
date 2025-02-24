local BoidManager = {}
BoidManager.__index = BoidManager

-- Add to the top of the file after other requires
local BlockEditor = require "editors.block_editor"
local ShaderManager = require "shader_manager"

function BoidManager.new(maxBoids)
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    self.maxBoids = maxBoids
    self.player = nil
    
    self.shaderManager = ShaderManager.new(maxBoids)
    
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
    
    self.shaderManager:update(self.boids)
end

function BoidManager:draw()
    -- Draw selection circle if selecting
    if self.selecting then
        love.graphics.setColor(0, 1, 1, 0.3)
        love.graphics.circle("line", self.selectionX, self.selectionY, self.selectionRadius)
    end
    
    -- Draw waypoints
    self.waypointManager:draw()
    
    if self.shaderManager.mode == "field" then
        self.shaderManager:drawFieldEffect()
    else
        self.shaderManager:drawTrailEffect(self.boids)
    end
    
    -- Draw boids
    for _, boid in ipairs(self.boids) do
        boid:draw()
    end
    
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
    local newGroupId = #self.waypointManager.paths + 1
    for _, boid in ipairs(self.boids) do
        if boid.selected then
            boid.groupId = newGroupId
            selectedCount = selectedCount + 1
        end
    end
    
    if selectedCount > 0 then
        self.waypointManager:createPath(newGroupId)
        self.waypointManager.currentGroupId = newGroupId
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

function BoidManager:cycleGroupSelection()
    self.waypointManager:cycleGroupId()
    local nextGroup = self.waypointManager.currentGroupId
    -- Deselect all and select new group
    for _, boid in ipairs(self.boids) do
        boid.selected = (boid.groupId == nextGroup)
    end
end

function BoidManager:setPlayer(player)
    self.player = player
end

function BoidManager:toggleShaderMode()
    self.shaderManager:toggleMode()
end

return BoidManager 