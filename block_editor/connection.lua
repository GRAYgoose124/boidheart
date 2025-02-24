local Connection = {}
Connection.__index = Connection

function Connection.new(sourceBlock, targetBlock, outputIndex, inputIndex, type)
    local self = setmetatable({}, Connection)
    self.source = sourceBlock
    self.target = targetBlock
    self.outputIndex = outputIndex
    self.inputIndex = inputIndex
    self.type = type
    return self
end

function Connection:isValid()
    return self.source and self.target and
           self.outputIndex and self.inputIndex
end

-- Add helper method to get connection points
function Connection:getPoints(connectionManager)
    local startX, startY = connectionManager:getConnectionPointPosition(self.source, self.outputIndex, false)
    local endX, endY = connectionManager:getConnectionPointPosition(self.target, self.inputIndex, true)
    return startX, startY, endX, endY
end

return Connection 