local BlockEditor = {}
BlockEditor.__index = BlockEditor

-- Block types and their configurations
local BLOCK_TYPES = {
    TRIGGERS = {
        ALWAYS = { 
            name = "Always", 
            color = {0.2, 0.6, 0.8},
            outputs = {"flow"},
            description = "Runs continuously"
        },
        ON_WAYPOINT = { 
            name = "On Waypoint Reached", 
            color = {0.8, 0.4, 0.2},
            outputs = {"flow"},
            description = "Triggers when reaching a waypoint"
        },
        NEAR_PLAYER = { 
            name = "Near Player", 
            color = {0.4, 0.8, 0.2},
            outputs = {"flow"},
            params = {
                {name = "distance", type = "number", default = 100, min = 0, max = 500}
            },
            description = "Triggers when close to player"
        },
        ON_TIMER = {
            name = "Every X Seconds",
            color = {0.6, 0.6, 0.8},
            outputs = {"flow"},
            params = {
                {name = "interval", type = "number", default = 1.0, min = 0.1, max = 10.0}
            },
            description = "Triggers periodically"
        }
    },
    ACTIONS = {
        FOLLOW_PLAYER = { 
            name = "Follow Player", 
            color = {0.6, 0.2, 0.8},
            inputs = {"flow"},
            params = {
                {name = "weight", type = "number", default = 1.0, min = 0, max = 5}
            },
            description = "Move towards the player"
        },
        FLOCK = { 
            name = "Flock with Others", 
            color = {0.8, 0.2, 0.6},
            inputs = {"flow"},
            params = {
                {name = "separation", type = "number", default = 1.0, min = 0, max = 5},
                {name = "cohesion", type = "number", default = 1.0, min = 0, max = 5},
                {name = "alignment", type = "number", default = 1.0, min = 0, max = 5}
            },
            description = "Group behavior with nearby boids"
        },
        SET_SPEED = {
            name = "Set Speed",
            color = {0.6, 0.6, 0.2},
            inputs = {"flow"},
            params = {
                {name = "speed", type = "number", default = 150, min = 0, max = 300}
            },
            description = "Change movement speed"
        },
        RANDOM_WALK = {
            name = "Random Walk",
            color = {0.4, 0.4, 0.8},
            inputs = {"flow"},
            params = {
                {name = "strength", type = "number", default = 1.0, min = 0, max = 5}
            },
            description = "Add random movement"
        },
        AVOID_WALLS = {
            name = "Avoid Walls",
            color = {0.8, 0.4, 0.4},
            inputs = {"flow"},
            params = {
                {name = "margin", type = "number", default = 50, min = 10, max = 200},
                {name = "strength", type = "number", default = 1.0, min = 0, max = 5}
            },
            description = "Stay away from screen edges"
        }
    },
    CONDITIONS = {
        DISTANCE_TO_PLAYER = { name = "Distance to Player <", color = {0.8, 0.8, 0.2} },
        HAS_WAYPOINT = { name = "Has Waypoint", color = {0.2, 0.8, 0.8} },
    }
}

-- Add these constants near the top
local CONNECTION_TYPES = {
    flow = {
        shape = "circle",
        color = {0.5, 0.5, 0.5},
        radius = 5
    },
    number = {
        shape = "triangle",
        color = {0.8, 0.6, 0.2},
        size = 8
    },
    boolean = {
        shape = "square",
        color = {0.2, 0.8, 0.4},
        size = 8
    }
}

-- Add this helper function near the top of the file
local function drawBezierCurve(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments)
    segments = segments or 32
    local points = {}
    
    for i = 0, segments do
        local t = i / segments
        local t2 = t * t
        local t3 = t2 * t
        local mt = 1 - t
        local mt2 = mt * mt
        local mt3 = mt2 * mt
        
        local x = mt3*x1 + 3*mt2*t*cx1 + 3*mt*t2*cx2 + t3*x2
        local y = mt3*y1 + 3*mt2*t*cy1 + 3*mt*t2*cy2 + t3*y2
        
        table.insert(points, x)
        table.insert(points, y)
    end
    
    love.graphics.line(points)
end

-- Helper function to draw connection points
local function drawConnectionPoint(x, y, type, isInput)
    local config = CONNECTION_TYPES[type]
    if config.shape == "circle" then
        love.graphics.circle("fill", x, y, config.radius)
    elseif config.shape == "triangle" then
        local size = config.size
        if isInput then
            love.graphics.polygon("fill", 
                x, y - size/2,
                x - size/2, y + size/2,
                x + size/2, y + size/2)
        else
            love.graphics.polygon("fill", 
                x, y + size/2,
                x - size/2, y - size/2,
                x + size/2, y - size/2)
        end
    elseif config.shape == "square" then
        love.graphics.rectangle("fill", 
            x - config.size/2, y - config.size/2,
            config.size, config.size)
    end
end

function BlockEditor.new()
    local self = setmetatable({}, BlockEditor)
    self.blocks = {}
    self.connections = {}
    self.programs = {}
    self.currentProgram = nil
    self.editorVisible = false
    self.showHelp = false
    self.draggingBlock = nil
    self.selectedBlock = nil
    
    -- Block dimensions
    self.blockWidth = 150
    self.blockHeight = 40
    
    -- Palette settings
    self.paletteX = 10
    self.paletteY = 10
    self.paletteWidth = 180
    self.paletteSpacing = 10
    
    -- Workspace settings
    self.workspaceX = 200  -- Start after palette
    self.workspaceY = 10
    self.gridSize = 20
    
    -- Connection settings
    self.connectionRadius = 5
    self.connectionSpacing = 15
    self.draggingConnection = nil
    self.hoveredConnection = nil
    
    -- Parameter settings
    self.paramSliderWidth = 100
    self.paramSliderHeight = 10
    
    return self
end

function BlockEditor:addBlock(blockType, category, x, y)
    local block = {
        type = blockType,
        category = category,
        config = BLOCK_TYPES[category][blockType],
        x = x,
        y = y,
        params = {},
        inputs = {},
        outputs = {}
    }
    
    -- Initialize parameters with default values
    if block.config.params then
        for _, param in ipairs(block.config.params) do
            block.params[param.name] = param.default
        end
    end
    
    -- Initialize inputs and outputs arrays
    if block.config.inputs then
        for _, inputType in ipairs(block.config.inputs) do
            table.insert(block.inputs, inputType)
        end
    end
    
    if block.config.outputs then
        for _, outputType in ipairs(block.config.outputs) do
            table.insert(block.outputs, outputType)
        end
    end
    
    table.insert(self.blocks, block)
    return block
end

function BlockEditor:draw()
    if not self.editorVisible then return end
    
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw workspace grid (optional)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    for x = self.workspaceX, love.graphics.getWidth(), self.gridSize do
        love.graphics.line(x, 0, x, love.graphics.getHeight())
    end
    for y = 0, love.graphics.getHeight(), self.gridSize do
        love.graphics.line(self.workspaceX, y, love.graphics.getWidth(), y)
    end
    
    -- Draw palette
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, self.paletteWidth + self.paletteX*2, love.graphics.getHeight())
    
    -- Draw blocks in palette
    local y = self.paletteY
    for category, blocks in pairs(BLOCK_TYPES) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(category, self.paletteX, y)
        y = y + 20
        
        for blockType, config in pairs(blocks) do
            love.graphics.setColor(config.color)
            love.graphics.rectangle("fill", self.paletteX, y, self.paletteWidth, self.blockHeight)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(config.name, self.paletteX + 5, y + 5)
            y = y + self.blockHeight + self.paletteSpacing
        end
        y = y + self.paletteSpacing
    end
    
    -- Draw workspace blocks and connections
    self:drawConnections()
    for _, block in ipairs(self.blocks) do
        self:drawBlock(block)
    end
    
    -- Draw help text
    if self.showHelp then
        love.graphics.setColor(1, 1, 1)
        local helpText = [[
Controls:
B - Toggle editor
N - New program
S - Save program
L - Load program
H - Toggle help
Enter - Apply to selected boids
Click and drag blocks to move them
Click parameters to adjust values]]
        love.graphics.print(helpText, love.graphics.getWidth() - 200, 10)
    end
end

function BlockEditor:drawBlock(block)
    if not block or not block.config then return end  -- Add safety check
    
    -- Draw block background
    love.graphics.setColor(block.config.color)
    if block == self.selectedBlock then
        love.graphics.setLineWidth(2)
    else
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("fill", block.x, block.y, self.blockWidth, self.blockHeight)
    
    -- Draw block name
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(block.config.name, block.x + 5, block.y + 5)
    
    -- Draw connection points
    if block.config.inputs then
        for i, inputType in ipairs(block.inputs) do
            local x = block.x
            local y = block.y + (i * self.connectionSpacing)
            love.graphics.setColor(CONNECTION_TYPES[inputType].color)
            drawConnectionPoint(x, y, inputType, true)
            
            -- Highlight if valid connection target
            if self.draggingConnection and self:isValidConnection(self.draggingConnection.sourceType, inputType) then
                local mx, my = love.mouse.getPosition()
                local dist = math.sqrt((mx-x)^2 + (my-y)^2)
                if dist < 15 then
                    love.graphics.setColor(1, 1, 1, 0.3)
                    love.graphics.circle("fill", x, y, 12)
                end
            end
        end
    end
    
    if block.config.outputs then
        for i, outputType in ipairs(block.outputs) do
            local x = block.x + self.blockWidth
            local y = block.y + (i * self.connectionSpacing)
            love.graphics.setColor(CONNECTION_TYPES[outputType].color)
            drawConnectionPoint(x, y, outputType, false)
        end
    end
    
    -- Draw parameters if block is selected
    if block == self.selectedBlock and block.config.params then
        local paramY = block.y + self.blockHeight + 5
        for _, param in ipairs(block.config.params) do
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(param.name .. ": " .. tostring(block.params[param.name]), 
                block.x, paramY)
            
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", 
                block.x, paramY + 15, 
                self.paramSliderWidth, self.paramSliderHeight)
            
            local value = block.params[param.name]
            local min = param.min or 0
            local max = param.max or 1
            local pos = (value - min) / (max - min) * self.paramSliderWidth
            
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("fill", 
                block.x + pos - 2, paramY + 13,
                4, self.paramSliderHeight + 4)
            
            paramY = paramY + 35
        end
    end
end

function BlockEditor:drawConnections()
    love.graphics.setLineWidth(2)
    
    -- Draw existing connections
    for _, conn in ipairs(self.connections) do
        local startX = conn.source.x + self.blockWidth
        local startY = conn.source.y + (conn.outputIndex * self.connectionSpacing)
        local endX = conn.target.x
        local endY = conn.target.y + (conn.inputIndex * self.connectionSpacing)
        
        -- Use connection type color
        love.graphics.setColor(CONNECTION_TYPES[conn.type].color)
        drawBezierCurve(
            startX, startY,
            startX + 50, startY,
            endX - 50, endY,
            endX, endY
        )
    end
    
    -- Draw connection being dragged
    if self.draggingConnection then
        local mouseX, mouseY = love.mouse.getPosition()
        love.graphics.setColor(CONNECTION_TYPES[self.draggingConnection.sourceType].color)
        drawBezierCurve(
            self.draggingConnection.startX, self.draggingConnection.startY,
            self.draggingConnection.startX + 50, self.draggingConnection.startY,
            mouseX - 50, mouseY,
            mouseX, mouseY
        )
    end
end

function BlockEditor:toggle()
    self.editorVisible = not self.editorVisible
    if not self.editorVisible then
        -- Reset all editor states when closing
        self.draggingBlock = nil
        self.draggingConnection = nil
        self.selectedBlock = nil
        self.hoveredConnection = nil
    end
end

function BlockEditor:mousepressed(x, y, button)
    if not self.editorVisible then return end
    
    if button == 1 then  -- Left click
        -- Check for parameter interaction first
        if self.selectedBlock and self.selectedBlock.config.params then
            local paramY = self.selectedBlock.y + self.blockHeight + 5
            for _, param in ipairs(self.selectedBlock.config.params) do
                if y >= paramY + 15 and y <= paramY + 15 + self.paramSliderHeight and
                   x >= self.selectedBlock.x and x <= self.selectedBlock.x + self.paramSliderWidth then
                    -- Calculate new parameter value
                    local percentage = (x - self.selectedBlock.x) / self.paramSliderWidth
                    local min = param.min or 0
                    local max = param.max or 1
                    self.selectedBlock.params[param.name] = min + (percentage * (max - min))
                    self.draggingParam = {
                        block = self.selectedBlock,
                        param = param.name,
                        min = min,
                        max = max
                    }
                    return
                end
                paramY = paramY + 35
            end
        end

        -- Check for output connection points first
        for _, block in ipairs(self.blocks) do
            if block.config.outputs then
                for i, outputType in ipairs(block.outputs) do
                    local connX = block.x + self.blockWidth
                    local connY = block.y + (i * self.connectionSpacing)
                    local dist = math.sqrt((x-connX)^2 + (y-connY)^2)
                    
                    if dist < 10 then
                        self.draggingConnection = {
                            startX = connX,
                            startY = connY,
                            source = block,
                            outputIndex = i,
                            sourceType = outputType
                        }
                        return
                    end
                end
            end
        end
        
        -- Check for block selection in workspace
        for _, block in ipairs(self.blocks) do
            if x >= block.x and x <= block.x + self.blockWidth and
               y >= block.y and y <= block.y + self.blockHeight then
                self.selectedBlock = block
                self.draggingBlock = block
                self.draggingOffset = {
                    x = x - block.x,
                    y = y - block.y
                }
                return
            end
        end
        
        -- Check for adding new blocks from palette
        local paletteY = self.paletteY
        for category, blocks in pairs(BLOCK_TYPES) do
            paletteY = paletteY + 20  -- Category header
            for blockType, config in pairs(blocks) do
                if x >= self.paletteX and x <= self.paletteX + self.paletteWidth and
                   y >= paletteY and y <= paletteY + self.blockHeight then
                    local newBlock = self:addBlock(blockType, category, 
                        self.workspaceX + 50, paletteY)
                    self.selectedBlock = newBlock
                    self.draggingBlock = newBlock
                    self.draggingOffset = {
                        x = self.blockWidth/2,
                        y = self.blockHeight/2
                    }
                    return
                end
                paletteY = paletteY + self.blockHeight + self.paletteSpacing
            end
            paletteY = paletteY + self.paletteSpacing
        end
        
        -- If clicked empty space, deselect
        self.selectedBlock = nil
    end
end

function BlockEditor:mousemoved(x, y)
    if not self.editorVisible then return end
    
    if self.draggingParam then
        local percentage = math.max(0, math.min(1, (x - self.draggingParam.block.x) / self.paramSliderWidth))
        local value = self.draggingParam.min + (percentage * (self.draggingParam.max - self.draggingParam.min))
        self.draggingParam.block.params[self.draggingParam.param] = value
        return
    end
    
    if self.draggingBlock and self.draggingOffset then
        self.draggingBlock.x = math.floor((x - self.draggingOffset.x) / self.gridSize) * self.gridSize
        self.draggingBlock.y = math.floor((y - self.draggingOffset.y) / self.gridSize) * self.gridSize
    end
end

function BlockEditor:mousereleased(x, y, button)
    if not self.editorVisible then return end
    
    if button == 1 then
        if self.draggingConnection then
            -- Check for valid input connection point
            for _, block in ipairs(self.blocks) do
                if block.config.inputs then
                    for i, inputType in ipairs(block.config.inputs) do
                        local connX = block.x
                        local connY = block.y + (i * self.connectionSpacing)
                        local dist = math.sqrt((x-connX)^2 + (y-connY)^2)
                        
                        if dist < 15 and self:isValidConnection(self.draggingConnection.sourceType, inputType) then
                            -- Remove any existing connections to this input
                            for j = #self.connections, 1, -1 do
                                local conn = self.connections[j]
                                if conn.target == block and conn.inputIndex == i then
                                    table.remove(self.connections, j)
                                end
                            end
                            
                            -- Add new connection
                            table.insert(self.connections, {
                                source = self.draggingConnection.source,
                                target = block,
                                outputIndex = self.draggingConnection.outputIndex,
                                inputIndex = i,
                                type = self.draggingConnection.sourceType
                            })
                        end
                    end
                end
            end
        end
        self.draggingConnection = nil
        self.draggingBlock = nil
        self.draggingOffset = nil
        self.draggingParam = nil
    end
end

-- Compile the current block arrangement into a behavior function
function BlockEditor:compileBehavior()
    local behavior = {}
    
    -- Find all trigger blocks
    for _, block in ipairs(self.blocks) do
        if block.category == "TRIGGERS" then
            local actions = self:compileBlockChain(block)
            if #actions > 0 then  -- Only add triggers that have connected actions
                behavior[block.type] = actions
            end
        end
    end
    
    return behavior
end

function BlockEditor:compileBlockChain(startBlock)
    local chain = {}
    
    -- Follow connections to build action chain
    for _, conn in ipairs(self.connections) do
        if conn.source == startBlock and conn.target.category == "ACTIONS" then
            table.insert(chain, {
                type = conn.target.type,
                params = conn.target.params or {}  -- Ensure params exists
            })
        end
    end
    
    return chain
end

function BlockEditor:applyToSelected(boids)
    local behavior = self:compileBehavior()
    for _, boid in ipairs(boids) do
        if boid.selected then
            boid.behaviors = behavior
        end
    end
end

-- Add these new functions for program management
function BlockEditor:newProgram(name)
    self.currentProgram = name
    self.blocks = {}
    self.connections = {}
end

function BlockEditor:saveProgram()
    if not self.currentProgram then return end
    self.programs[self.currentProgram] = {
        blocks = self.blocks,
        connections = self.connections
    }
end

function BlockEditor:loadProgram(name)
    local program = self.programs[name]
    if program then
        self.currentProgram = name
        self.blocks = program.blocks
        self.connections = program.connections
    end
end

function BlockEditor:keypressed(key)
    if not self.editorVisible then return end
    
    if key == "delete" or key == "backspace" then
        if self.selectedBlock then
            -- Remove all connections involving this block
            for i = #self.connections, 1, -1 do
                local conn = self.connections[i]
                if conn.source == self.selectedBlock or conn.target == self.selectedBlock then
                    table.remove(self.connections, i)
                end
            end
            -- Remove the block
            for i, block in ipairs(self.blocks) do
                if block == self.selectedBlock then
                    table.remove(self.blocks, i)
                    break
                end
            end
            self.selectedBlock = nil
        end
    end
end

function BlockEditor:isValidConnection(sourceType, targetType)
    return sourceType == targetType
end

return BlockEditor 