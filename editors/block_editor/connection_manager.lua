local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

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

function ConnectionManager:drawConnection(connection)
    love.graphics.setColor(0.5, 0.5, 0.5)
    local startX = connection.source.x + self.editor.blockWidth
    local startY = connection.source.y + (connection.outputIndex * self.editor.blockHeight/2)
    local endX = connection.target.x
    local endY = connection.target.y + (connection.inputIndex * self.editor.blockHeight/2)
    
    -- Draw bezier curve
    local points = {}
    local segments = 20
    local controlX1 = startX + (endX - startX) * 0.5
    local controlX2 = controlX1
    
    for i = 0, segments do
        local t = i / segments
        local px = self:cubicBezier(startX, controlX1, controlX2, endX, t)
        local py = self:cubicBezier(startY, startY, endY, endY, t)
        table.insert(points, px)
        table.insert(points, py)
    end
    love.graphics.line(points)
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
    -- Check for connection dragging
    for _, block in ipairs(self.editor.blockManager.blocks) do
        local connectionPoint = self:findConnectionPoint(block, x, y)
        if connectionPoint then
            self.draggingConnection = {
                source = block,
                outputIndex = connectionPoint.index
            }
            return true
        end
    end
    return false
end

function ConnectionManager:handleMouseReleased(x, y, button)
    if self.draggingConnection then
        -- Check if we're over a valid input connection point
        for _, block in ipairs(self.editor.blockManager.blocks) do
            local connectionPoint = self:findConnectionPoint(block, x, y, true)
            if connectionPoint then
                self:createConnection(self.draggingConnection.source, 
                    block, self.draggingConnection.outputIndex, 
                    connectionPoint.index)
            end
        end
        self.draggingConnection = nil
        return true
    end
    return false
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

return ConnectionManager 