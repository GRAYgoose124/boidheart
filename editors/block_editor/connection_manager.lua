local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

local CONNECTION_TYPES = require "editors.block_editor.connection_types"

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
        self:drawConnection({
            source = self.draggingConnection.source,
            target = {x = mx, y = my},
            outputIndex = self.draggingConnection.outputIndex,
            inputIndex = 1
        })
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

function ConnectionManager:drawConnection(connection)
    if not connection.source then return end
    
    -- Get connection type from source output
    local sourceType = "flow"
    if connection.outputIndex and connection.source.config.outputs then
        local output = connection.source.config.outputs[connection.outputIndex]
        sourceType = output.type or "flow"
    end
    
    local connType = CONNECTION_TYPES[sourceType]
    love.graphics.setColor(unpack(connType.color))
    
    local startX, startY = self:getConnectionPointPosition(
        connection.source, connection.outputIndex, false)
    local endX, endY
    
    if connection.target then
        if type(connection.target) == "table" and connection.target.x then
            -- Mouse position during dragging
            endX, endY = connection.target.x, connection.target.y
        else
            -- Connected block
            endX, endY = self:getConnectionPointPosition(
                connection.target, connection.inputIndex, true)
        end
    else
        -- Mouse position during dragging
        endX, endY = love.mouse.getPosition()
    end
    
    -- Draw bezier curve
    local controlX1 = startX + 50
    local controlX2 = endX - 50
    
    local points = {}
    local segments = 20
    for i = 0, segments do
        local t = i / segments
        local px = self:cubicBezier(startX, controlX1, controlX2, endX, t)
        local py = self:cubicBezier(startY, startY, endY, endY, t)
        table.insert(points, px)
        table.insert(points, py)
    end
    
    love.graphics.setLineWidth(2)
    love.graphics.line(points)
    love.graphics.setLineWidth(1)
end

function ConnectionManager:cubicBezier(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t
    return (1 - t)^3 * p0 +
           3 * (1 - t)^2 * t * p1 +
           3 * (1 - t) * t2 * p2 +
           t3 * p3
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
            self.draggingConnection = {
                source = block,
                outputIndex = connectionPoint.index,
                isInput = connectionPoint.isInput
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
            
            if self:areTypesCompatible(sourceType, targetType) then
                if self.draggingConnection.isInput then
                    -- Swap source and target for input dragging
                    self:createConnection(block, sourceBlock, 
                        connectionPoint.index, sourceIndex)
                else
                    self:createConnection(sourceBlock, block,
                        sourceIndex, connectionPoint.index)
                end
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

function ConnectionManager:findConnectionPoint(block, x, y, isInput)
    -- Helper to find connection point under mouse
    local points = isInput and block.config.inputs or block.config.outputs
    if not points then return nil end
    
    for i, _ in ipairs(points) do
        local px, py = self:getConnectionPointPosition(block, i, isInput)
        local dist = math.sqrt((x - px)^2 + (y - py)^2)
        if dist < 10 then
            return {index = i, x = px, y = py}
        end
    end
    return nil
end

function ConnectionManager:getConnectionPointPosition(block, index, isInput)
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
    -- Check if connection already exists
    for _, conn in ipairs(self.connections) do
        if conn.source == sourceBlock and conn.target == targetBlock and
           conn.outputIndex == outputIndex and conn.inputIndex == inputIndex then
            return
        end
    end
    
    -- Create new connection
    table.insert(self.connections, {
        source = sourceBlock,
        target = targetBlock,
        outputIndex = outputIndex,
        inputIndex = inputIndex,
        type = sourceBlock.config.outputs[outputIndex].type or "flow"
    })
end

function ConnectionManager:drawConnectionPoint(x, y, type, isInput)
    local connType = CONNECTION_TYPES[type or "flow"]
    if not connType then return end -- Skip if type not found
    
    love.graphics.setColor(unpack(connType.color))
    
    if connType.shape == "triangle" then
        local size = connType.size or 8
        if isInput then
            love.graphics.polygon("fill", 
                x, y,
                x - size, y - size,
                x - size, y + size)
        else
            love.graphics.polygon("fill", 
                x, y,
                x + size, y - size,
                x + size, y + size)
        end
    elseif connType.shape == "square" then
        local size = connType.size or 8
        love.graphics.rectangle("fill", 
            x - size/2, y - size/2, 
            size, size)
    else -- Default to circle
        local radius = connType.radius or 4
        love.graphics.circle("fill", x, y, radius)
    end
end

function ConnectionManager:areTypesCompatible(sourceType, targetType)
    -- Define type compatibility rules
    local compatibility = {
        flow = {"flow"},
        condition = {"condition"},
        target = {"target"},
        number = {"number"},
        state = {"state"},
        trigger = {"trigger", "flow"}
    }
    
    sourceType = sourceType or "flow"
    targetType = targetType or "flow"
    
    local allowedTypes = compatibility[sourceType]
    if not allowedTypes then return false end
    
    for _, allowedType in ipairs(allowedTypes) do
        if allowedType == targetType then
            return true
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

return ConnectionManager 