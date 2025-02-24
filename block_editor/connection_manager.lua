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
    -- Calculate connection points
    local sourceX = connection.sourceBlock.x + self.editor.blockWidth
    local sourceY = connection.sourceBlock.y + 
                   (connection.outputIndex * 20) + 30
    
    local targetX = connection.targetBlock.x
    local targetY = connection.targetBlock.y + 
                   (connection.inputIndex * 20) + 30
    
    -- Draw connection line
    love.graphics.setColor(0.8, 0.8, 1.0, 0.8)
    love.graphics.setLineWidth(2)
    
    -- Draw bezier curve
    local controlX1 = sourceX + 50
    local controlX2 = targetX - 50
    self:drawBezierConnection(
        sourceX, sourceY,
        controlX1, sourceY,
        controlX2, targetY,
        targetX, targetY
    )
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function ConnectionManager:drawDraggingConnection()
    if not self.draggingConnection.source then return end
    
    local mx, my = love.mouse.getPosition()
    local sourceX = self.draggingConnection.source.x + self.editor.blockWidth
    local sourceY = self.draggingConnection.source.y + 
                   (self.draggingConnection.outputIndex * 20) + 30
    
    -- Draw preview line
    love.graphics.setColor(0.8, 0.8, 1.0, 0.5)
    love.graphics.setLineWidth(2)
    
    -- Draw bezier curve for preview
    local controlX1 = sourceX + 50
    local controlX2 = mx - 50
    self:drawBezierConnection(
        sourceX, sourceY,
        controlX1, sourceY,
        controlX2, my,
        mx, my
    )
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw snap indicator if hovering over valid connection point
    local snapTarget = self:findSnapTarget(mx, my)
    if snapTarget then
        love.graphics.setColor(0.4, 1.0, 0.4, 0.8)
        love.graphics.circle("fill", 
            snapTarget.x, 
            snapTarget.y, 
            6)
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

function ConnectionManager:handleMousePressed(x, y, button)
    if button ~= 1 then return false end
    
    -- Check for connection dragging
    for _, block in ipairs(self.editor.blockManager.blocks) do
        local connectionPoint = self:findConnectionPoint(block, x, y)
        if connectionPoint then
            if connectionPoint.isInput then
                -- Find and disconnect existing connection to this input
                self:disconnectInput(block, connectionPoint.index)
            end
            
            -- Store connection info including type
            local type = connectionPoint.isInput and 
                block.config.inputs[connectionPoint.index].type or
                block.config.outputs[connectionPoint.index].type
                
            self.draggingConnection = {
                source = block,
                outputIndex = connectionPoint.index,
                isInput = connectionPoint.isInput,
                type = type
            }
            return true
        end
    end
    return false
end

function ConnectionManager:handleMouseReleased(x, y, button)
    if not self.draggingConnection then return false end
    
    -- Find target connection point
    for _, block in ipairs(self.editor.blockManager.blocks) do
        local connectionPoint = self:findConnectionPoint(block, x, y)
        if connectionPoint then
            -- Check if connection types are compatible
            local sourceBlock = self.draggingConnection.source
            local sourceIndex = self.draggingConnection.outputIndex
            local sourceType = sourceBlock.config.outputs[sourceIndex].type
            local targetType = block.config.inputs[connectionPoint.index].type
            
            if self:isConnectionCompatible(sourceType, targetType) then
                if self.draggingConnection.isInput then
                    -- Swap source and target for input dragging
                    self:createConnection(block, sourceBlock, 
                        connectionPoint.index, sourceIndex)
                else
                    self:createConnection(sourceBlock, block,
                        sourceIndex, connectionPoint.index)
                end
                break  -- Exit loop after creating connection
            end
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
    -- Check inputs
    if block.config.inputs then
        for i, input in ipairs(block.config.inputs) do
            local px, py = self:getConnectionPointPosition(block, i, true)
            local dist = math.sqrt((x - px)^2 + (y - py)^2)
            if dist < 10 then
                return {index = i, x = px, y = py, isInput = true, type = input.type}
            end
        end
    end
    
    -- Check outputs
    if block.config.outputs then
        for i, output in ipairs(block.config.outputs) do
            local px, py = self:getConnectionPointPosition(block, i, false)
            local dist = math.sqrt((x - px)^2 + (y - py)^2)
            if dist < 10 then
                return {index = i, x = px, y = py, isInput = false, type = output.type}
            end
        end
    end
    return nil
end

function ConnectionManager:getConnectionPointPosition(block, index, isInput)
    -- Guard against nil values
    if not block or not index then return 0, 0 end
    
    if isInput then
        -- Input points go on the left side of the block
        return block.x, 
               block.y + (self.editor.blockHeight * 0.4) + 
               (index - 1) * 20
    else
        -- Output points go on the right side of the block
        return block.x + self.editor.blockWidth,
               block.y + (self.editor.blockHeight * 0.4) + 
               (index - 1) * 20
    end
end

function ConnectionManager:createConnection(sourceBlock, targetBlock, outputIndex, inputIndex)
    -- Get connection types
    local outputType = sourceBlock.config.outputs[outputIndex].type
    local inputType = targetBlock.config.inputs[inputIndex].type
    
    -- Check compatibility
    if not self:isConnectionCompatible(outputType, inputType) then
        return false
    end
    
    -- Create connection
    local connection = {
        sourceBlock = sourceBlock,
        targetBlock = targetBlock,
        outputIndex = outputIndex,
        inputIndex = inputIndex,
        type = outputType
    }
    
    table.insert(self.connections, connection)
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
        if conn.targetBlock == block and conn.inputIndex == inputIndex then
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