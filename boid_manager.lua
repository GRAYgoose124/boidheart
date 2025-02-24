local BoidManager = {}
BoidManager.__index = BoidManager

-- Add to the top of the file after other requires
local BlockEditor = require "editors.block_editor"
local ShaderManager = require "shader_manager"
local SelectionManager = require "selection_manager"
local WaypointManager = require "waypoint_manager"

function BoidManager.new(maxBoids)
    local self = setmetatable({}, BoidManager)
    self.boids = {}
    self.maxBoids = maxBoids
    self.player = nil
    
    self.shaderManager = ShaderManager.new(maxBoids)
    self.selectionManager = SelectionManager.new(self)
    self.waypointManager = WaypointManager.new()
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
    -- Draw selection UI
    self.selectionManager:draw()
    
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

function BoidManager:setPlayer(player)
    self.player = player
end

function BoidManager:toggleShaderMode()
    self.shaderManager:toggleMode()
end

return BoidManager 