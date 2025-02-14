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
    
    return self
end

function BoidManager:add(boid)
    table.insert(self.boids, boid)
end

function BoidManager:update(dt)
    for _, boid in ipairs(self.boids) do
        boid:update(dt)
    end
    
    -- Create array of vec2 positions
    local positions = {}
    for i = 1, #self.boids do
        positions[i] = {self.boids[i].x, self.boids[i].y}  -- Send as vec2
    end
    
    -- Send positions to shader
    self.shader:send("boids", unpack(positions))  -- Unpack array of vec2s
    self.shader:send("boidCount", #self.boids)
end

function BoidManager:draw()
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

return BoidManager 