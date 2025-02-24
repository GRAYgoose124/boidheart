local Connection = require "block_editor.connection"
local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

-- Define connection type colors and compatibility
local CONNECTION_TYPES = {
    flow = {
        color = {0.8, 0.8, 0.8},
        shape = "triangle",
        size = 8,
        compatible = {"flow"}
    },
    condition = {
        color = {0.8, 0.4, 0.4},
        shape = "double_triangle",
        size = 8,
        compatible = {"condition"}
    },
    number = {
        color = {0.2, 0.8, 0.2},
        shape = "circle",
        radius = 4,
        compatible = {"number"}
    },
    boolean = {
        color = {0.8, 0.2, 0.2},
        shape = "square",
        size = 8,
        compatible = {"boolean"}
    },
    any = {
        color = {0.8, 0.8, 0.8},
        shape = "circle",
        radius = 4,
        compatible = {"flow", "condition", "number", "boolean", "any"}
    }
}

function ConnectionManager.new(editor)
    local self = setmetatable({}, ConnectionManager)
    self.editor = editor
    self.connections = {}
    self.draggingConnection = nil
    return self
end

function ConnectionManager:draw()
    -- Draw background grid
    self.editor:drawGrid()
    
    -- Draw all connections
    self:drawConnections()
    
    -- Draw connection being dragged
    if self.draggingConnection then
        self:drawDraggingConnection()
    end
end

function ConnectionManager:drawConnections()
    -- Draw existing connections
    for _, connection in ipairs(self.connections) do
        self:drawConnection(connection)
    end
end

function ConnectionManager:drawConnection(connection)
    -- Get connection points using the helper method
    local startX, startY, endX, endY = connection:getPoints(self)
    
    -- Calculate control points for bezier curve
    local controlX = (endX - startX) * 0.5
    local x2 = startX + controlX
    local x3 = endX - controlX
    
    -- Get connection type info with fallback to 'any'
    local typeInfo = CONNECTION_TYPES[connection.type] or CONNECTION_TYPES.any
    
    -- Draw the connection
    love.graphics.setColor(unpack(typeInfo.color))
    self:drawBezierConnection(startX, startY, x2, startY, x3, endY, endX, endY)
end

function ConnectionManager:drawDraggingConnection()
    if not self.draggingConnection.source then return end
    
    local mx, my = love.mouse.getPosition()
    local startX, startY
    
    if self.draggingConnection.isInput then
        -- If dragging from an input, start at the input point
        startX, startY = self:getConnectionPointPosition(
            self.draggingConnection.source, 
            self.draggingConnection.outputIndex, 
            true
        )
    else
        -- If dragging from an output, start at the output point
        startX, startY = self:getConnectionPointPosition(
            self.draggingConnection.source, 
            self.draggingConnection.outputIndex, 
            false
        )
    end
    
    -- Draw preview line
    love.graphics.setColor(0.8, 0.8, 1.0, 0.5)
    love.graphics.setLineWidth(2)
    
    -- Draw bezier curve for preview
    local controlX1 = startX + (mx - startX) * 0.5
    local controlX2 = mx - (mx - startX) * 0.5
    self:drawBezierConnection(
        startX, startY,
        controlX1, startY,
        controlX2, my,
        mx, my
    )
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw snap indicator if hovering over valid connection point
    local snapTarget = self:findSnapTarget(mx, my)
    if snapTarget then
        love.graphics.setColor(0.4, 1.0, 0.4, 0.8)
        love.graphics.circle("fill", snapTarget.x, snapTarget.y, 6)
    end
end

function ConnectionManager:drawBezierConnection(x1, y1, x2, y2, x3, y3, x4, y4)
    local segments = 20
    local points = {}
    
    for i = 0, segments do
        local t = i / segments
        local px, py = self:bezierPoint(t, x1, y1, x2, y2, x3, y3, x4, y4)
        table.insert(points, px)
        table.insert(points, py)
    end
    
    love.graphics.line(points)
end

function ConnectionManager:bezierPoint(t, x1, y1, x2, y2, x3, y3, x4, y4)
    local t1 = (1 - t)
    local t2 = t1 * t1
    local t3 = t2 * t1
    local tt = t * t
    local ttt = tt * t
    
    return x1 * t3 + 3 * x2 * t2 * t + 3 * x3 * t1 * tt + x4 * ttt,
           y1 * t3 + 3 * y2 * t2 * t + 3 * y3 * t1 * tt + y4 * ttt
end

function ConnectionManager:startDraggingConnection(block, index, isInput, type)
    self.draggingConnection = {
        source = block,
        outputIndex = index,
        isInput = isInput,
        type = type
    }
end

function ConnectionManager:handleMousePressed(x, y, button)
    if button ~= 1 then return false end
    
    -- Check for connection dragging
    for _, block in ipairs(self.editor.blockManager.blocks) do
        local connectionPoint = self:findConnectionPoint(block, x, y)
        if connectionPoint then
            -- Get the connection type from the block's config
            local type
            if connectionPoint.isInput then
                type = block.config.inputs[connectionPoint.index].type
            else
                type = block.config.outputs[connectionPoint.index].type
            end
            
            self:startDraggingConnection(block, connectionPoint.index, 
                connectionPoint.isInput, type)
            return true
        end
    end
    
    return false
end

function ConnectionManager:handleMouseReleased(x, y, button)
    if not self.draggingConnection then return false end
    
    local snapTarget = self:findSnapTarget(x, y)
    if snapTarget and snapTarget.block then  -- Add check for block
        if self.draggingConnection.isInput then
            -- If dragging from input, swap source and target
            self:createConnection(
                snapTarget.block,
                self.draggingConnection.source,
                snapTarget.index,
                self.draggingConnection.outputIndex
            )
        else
            self:createConnection(
                self.draggingConnection.source,
                snapTarget.block,
                self.draggingConnection.outputIndex,
                snapTarget.index
            )
        end
    end
    
    self.draggingConnection = nil
    return true
end

function ConnectionManager:handleMouseMoved(x, y, dx, dy)
    if self.draggingConnection then
        return true
    end
    return false
end

function ConnectionManager:findConnectionPoint(block, x, y)
    if not block or not block.config then return nil end
    
    local snapDistance = 10
    
    -- Check input points
    if block.config.inputs then
        for i, input in ipairs(block.config.inputs) do
            local px, py = self:getConnectionPointPosition(block, i, true)
            if math.abs(x - px) < snapDistance and math.abs(y - py) < snapDistance then
                return {
                    x = px,
                    y = py,
                    index = i,
                    isInput = true,
                    type = input.type,
                    block = block
                }
            end
        end
    end
    
    -- Check output points
    if block.config.outputs then
        for i, output in ipairs(block.config.outputs) do
            local px, py = self:getConnectionPointPosition(block, i, false)
            if math.abs(x - px) < snapDistance and math.abs(y - py) < snapDistance then
                return {
                    x = px,
                    y = py,
                    index = i,
                    isInput = false,
                    type = output.type,
                    block = block
                }
            end
        end
    end
    
    return nil
end

function ConnectionManager:getConnectionPointPosition(block, index, isInput)
    -- Guard against nil values
    if not block or not index then return 0, 0 end
    
    local baseY = block.y + (self.editor.blockHeight * 0.4)
    local spacing = 20
    local yOffset = (index - 1) * spacing
    
    if isInput then
        -- Input points go on the left side of the block
        return block.x, baseY + yOffset
    else
        -- Output points go on the right side of the block
        return block.x + self.editor.blockWidth, baseY + yOffset
    end
end

function ConnectionManager:createConnection(sourceBlock, targetBlock, outputIndex, inputIndex)
    -- Validate blocks and indices
    if not sourceBlock or not targetBlock then
        print("Warning: Attempted to create connection with nil block")
        return false
    end
    
    if not sourceBlock.config or not sourceBlock.config.outputs or
       not targetBlock.config or not targetBlock.config.inputs then
        print("Warning: Invalid block configuration")
        return false
    end
    
    if not sourceBlock.config.outputs[outputIndex] or
       not targetBlock.config.inputs[inputIndex] then
        print("Warning: Invalid connection indices")
        return false
    end
    
    -- Get connection types
    local outputType = sourceBlock.config.outputs[outputIndex].type
    local inputType = targetBlock.config.inputs[inputIndex].type
    
    -- Check compatibility
    if not self:isConnectionCompatible(outputType, inputType) then
        return false
    end
    
    -- Remove any existing connections to this input
    self:disconnectInput(targetBlock, inputIndex)
    
    -- Create and store the new connection
    local connection = Connection.new(sourceBlock, targetBlock, outputIndex, inputIndex, outputType)
    table.insert(self.connections, connection)
    
    -- Emit connection created event if we have events
    if self.editor.uiManager and self.editor.uiManager.events then
        self.editor.uiManager.events:emit("connection_created", connection)
    end
    
    return true
end

function ConnectionManager:drawConnectionPoint(x, y, type, isInput)
    -- Get connection type info
    local typeInfo = CONNECTION_TYPES[type] or CONNECTION_TYPES.any
    
    -- Draw connection point with type-specific shape
    love.graphics.setColor(unpack(typeInfo.color))
    
    if typeInfo.shape == "triangle" then
        local size = typeInfo.size or 8
        if isInput then
            love.graphics.polygon("fill", 
                x - size, y - size/2,
                x, y,
                x - size, y + size/2)
        else
            love.graphics.polygon("fill", 
                x, y - size/2,
                x + size, y,
                x, y + size/2)
        end
    elseif typeInfo.shape == "square" then
        local size = typeInfo.size or 8
        love.graphics.rectangle("fill", x - size/2, y - size/2, size, size)
    elseif typeInfo.shape == "double_triangle" then
        local size = typeInfo.size or 8
        if isInput then
            love.graphics.polygon("fill", 
                x - size, y - size/2,
                x - size/2, y,
                x - size, y + size/2)
            love.graphics.polygon("fill", 
                x - size/2, y - size/2,
                x, y,
                x - size/2, y + size/2)
        else
            love.graphics.polygon("fill", 
                x, y - size/2,
                x + size/2, y,
                x, y + size/2)
            love.graphics.polygon("fill", 
                x + size/2, y - size/2,
                x + size, y,
                x + size/2, y + size/2)
        end
    else -- Default to circle
        local radius = typeInfo.radius or 4
        love.graphics.circle("fill", x, y, radius)
    end
    
    -- Draw outline
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", x, y, 5)
    
    -- Draw highlight for compatible points during dragging
    if self.draggingConnection then
        local dragType = self.draggingConnection.type
        if self:isConnectionCompatible(dragType, type) and
           self.draggingConnection.isInput ~= isInput then
            love.graphics.setColor(0.8, 0.8, 0.2, 0.5)
            love.graphics.circle("fill", x, y, 8)
        end
    end
end

function ConnectionManager:isConnectionCompatible(sourceType, targetType)
    -- Handle any type connections
    if sourceType == "any" or targetType == "any" then
        return true
    end
    
    -- Check direct type match
    if sourceType == targetType then
        return true
    end
    
    -- Check compatible types from CONNECTION_TYPES
    local sourceInfo = CONNECTION_TYPES[sourceType]
    if sourceInfo and sourceInfo.compatible then
        for _, compatType in ipairs(sourceInfo.compatible) do
            if compatType == targetType then
                return true
            end
        end
    end
    
    return false
end

function ConnectionManager:disconnectInput(block, inputIndex)
    for i = #self.connections, 1, -1 do
        local conn = self.connections[i]
        if conn.target == block and conn.inputIndex == inputIndex then
            table.remove(self.connections, i)
        end
    end
end

function ConnectionManager:update(dt)
end

function ConnectionManager:findSnapTarget(x, y)
    -- Check all blocks for potential connection points
    for _, block in ipairs(self.editor.blockManager.blocks) do
        local connectionPoint = self:findConnectionPoint(block, x, y)
        if connectionPoint then
            -- Only return if the connection point is compatible and of opposite type
            -- (input vs output) compared to what we're dragging
            if self.draggingConnection and
               self:isConnectionCompatible(self.draggingConnection.type, connectionPoint.type) and
               self.draggingConnection.isInput ~= connectionPoint.isInput then
                return connectionPoint
            end
        end
    end
    return nil
end

ConnectionManager.CONNECTION_TYPES = CONNECTION_TYPES

return ConnectionManager 