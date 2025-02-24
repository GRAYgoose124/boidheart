local ShaderManager = {}
ShaderManager.__index = ShaderManager

function ShaderManager.new(maxBoids)
    local self = setmetatable({}, ShaderManager)
    
    -- Initialize shaders
    local fieldShaderSource = love.filesystem.read("shaders/bounding_field.glsl")
    fieldShaderSource = fieldShaderSource:gsub("#define MAX_BOIDS 100", "#define MAX_BOIDS " .. maxBoids)
    self.fieldShader = love.graphics.newShader(fieldShaderSource)
    
    self.trailShader = love.graphics.newShader("shaders/trail_shader.glsl")
    self.trailShader:send("decay", 0.01) -- Adjust decay rate
    
    -- Create canvases
    self.canvas = love.graphics.newCanvas()
    self.trailCanvas = {
        love.graphics.newCanvas(),
        love.graphics.newCanvas()
    }
    self.currentTrailCanvas = 1
    
    self.mode = "field" -- or "trail"
    
    -- Send initial resolution to shaders
    local w, h = love.graphics.getDimensions()
    self.fieldShader:send("resolution", {w, h})
    -- self.trailShader:send("resolution", {w, h})
    
    return self
end

function ShaderManager:update(boids)
    -- Create array of combined position and velocity data
    local boidData = {}
    for i = 1, #boids do
        boidData[i] = {
            boids[i].x, 
            boids[i].y, 
            boids[i].vx, 
            boids[i].vy
        }
    end
    
    -- Send combined data to shader
    if self.mode == "field" then
        self.fieldShader:send("boidData", unpack(boidData))
        self.fieldShader:send("boidCount", #boids)
    elseif self.mode == "trail" then
        -- self.trailShader:send("time", love.timer.getTime())
    end
end

function ShaderManager:drawFieldEffect()
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

function ShaderManager:drawTrailEffect(boids)
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
    for _, boid in ipairs(boids) do
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

function ShaderManager:toggleMode()
    self.mode = self.mode == "field" and "trail" or "field"
    -- Clear trail canvases when switching to trail mode
    if self.mode == "trail" then
        love.graphics.setCanvas(self.trailCanvas[1])
        love.graphics.clear()
        love.graphics.setCanvas(self.trailCanvas[2])
        love.graphics.clear()
        love.graphics.setCanvas()
    end
end

function ShaderManager:resize(w, h)
    self.canvas = love.graphics.newCanvas()
    self.trailCanvas = {
        love.graphics.newCanvas(),
        love.graphics.newCanvas()
    }
    self.fieldShader:send("resolution", {w, h})
    self.trailShader:send("resolution", {w, h})
end

return ShaderManager 