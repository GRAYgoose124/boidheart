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

function ConnectionManager:drawConnections()
    -- Draw existing connections
    for _, connection in ipairs(self.connections) do
        self:drawConnection(connection)
    end
    
    -- Draw connection being dragged
    if self.draggingConnection then
        local mx, my = love.mouse.getPosition()
        
        -- Find potential snap target
        local snapTarget = nil
        for _, block in ipairs(self.editor.blockManager.blocks) do
            if block ~= self.draggingConnection.source then
                local connectionPoint = self:findConnectionPoint(block, mx, my)
                if connectionPoint then
                    -- Check if we're dragging from input to output or vice versa
                    local isValidConnection = self.draggingConnection.isInput and 
                        (not connectionPoint.isInput) or
                        (not self.draggingConnection.isInput and connectionPoint.isInput)
                    
                    if isValidConnection then
                        -- Check type compatibility
                        local sourceType = self.draggingConnection.isInput and
                            block.config.outputs[connectionPoint.index].type or
                            self.draggingConnection.source.config.outputs[self.draggingConnection.outputIndex].type
                        local targetType = self.draggingConnection.isInput and
                            self.draggingConnection.source.config.inputs[self.draggingConnection.outputIndex].type or
                            block.config.inputs[connectionPoint.index].type
                            
                        if self:isConnectionCompatible(sourceType, targetType) then
                            snapTarget = {
                                block = block,
                                point = connectionPoint,
                                x = connectionPoint.x,
                                y = connectionPoint.y
                            }
                            break
                        end
                    end
                end
            end
        end
        
        -- Draw the connection line
        local sourceX, sourceY, targetX, targetY
        if self.draggingConnection.isInput then
            -- Dragging from input to output
            targetX, targetY = snapTarget and snapTarget.x or mx, snapTarget and snapTarget.y or my
            sourceX, sourceY = self:getConnectionPointPosition(
                self.draggingConnection.source, 
                self.draggingConnection.outputIndex, 
                true)
        else
            -- Dragging from output to input
            sourceX, sourceY = self:getConnectionPointPosition(
                self.draggingConnection.source, 
                self.draggingConnection.outputIndex, 
                false)
            targetX, targetY = snapTarget and snapTarget.x or mx, snapTarget and snapTarget.y or my
        end
        
        -- Draw the connection line
        local typeInfo = CONNECTION_TYPES[self.draggingConnection.type] or CONNECTION_TYPES.any
        love.graphics.setColor(unpack(typeInfo.color))
        self:drawBezierConnection(sourceX, sourceY, targetX, targetY)
        
        -- Draw snap preview
        if snapTarget then
            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.circle("fill", snapTarget.x, snapTarget.y, 8)
        end
    end
end

function ConnectionManager:drawConnectionPoints(block)
    -- Draw input points
    if block.config.inputs then
        for i, input in ipairs(block.config.inputs) do
            local x, y = self:getConnectionPointPosition(block, i, true)
            self:drawConnectionPoint(x, y, input.type or "flow", true)
        end
    end
    
    -- Draw output points
    if block.config.outputs then
        for i, output in ipairs(block.config.outputs) do
            local x, y = self:getConnectionPointPosition(block, i, false)
            self:drawConnectionPoint(x, y, output.type or "flow", false)
        end
    end
end

function ConnectionManager:drawConnection(conn)
    -- Early return if connection is invalid
    if not conn or not conn.sourceBlock or not conn.targetBlock then return end
    
    -- Get source position
    local sourceX, sourceY = self:getConnectionPointPosition(
        conn.sourceBlock, conn.outputIndex, false)
    
    -- Get target position (might be mouse position for dragging)
    local targetX, targetY
    if type(conn.target) == "table" and conn.target.x and conn.target.y then
        -- Use direct coordinates for dragging
        targetX, targetY = conn.target.x, conn.target.y
    else
        -- Use block position for normal connections
        targetX, targetY = self:getConnectionPointPosition(
            conn.targetBlock, conn.inputIndex, true)
    end
    
    -- Get connection type info
    local sourceType = conn.sourceBlock.config.outputs[conn.outputIndex].type
    local typeInfo = CONNECTION_TYPES[sourceType] or CONNECTION_TYPES.any
    
    -- Draw connection line with type color
    love.graphics.setColor(unpack(typeInfo.color))
    self:drawBezierConnection(sourceX, sourceY, targetX, targetY)
end

function ConnectionManager:drawBezierConnection(x1, y1, x2, y2)
    local controlX = math.abs(x2 - x1) * 0.5
    local points = {}
    for t = 0, 1, 0.1 do
        local px = self:bezierPoint(x1, x1 + controlX, x2 - controlX, x2, t)
        local py = self:bezierPoint(y1, y1, y2, y2, t)
        table.insert(points, px)
        table.insert(points, py)
    end
    love.graphics.setLineWidth(2)
    love.graphics.line(points)
    love.graphics.setLineWidth(1)
end

function ConnectionManager:bezierPoint(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t
    return (1 - t)^3 * p0 + 3 * (1 - t)^2 * t * p1 + 
           3 * (1 - t) * t2 * p2 + t3 * p3
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
    -- Currently we don't need any per-frame updates for the connection manager
    -- but we need the method to exist since it's called from BlockEditor:update()
    return
end

return ConnectionManager 