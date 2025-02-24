local Connection = {}
Connection.__index = Connection

function Connection.new(sourceBlock, targetBlock, outputIndex, inputIndex, type)
    local self = setmetatable({}, Connection)
    self.sourceBlock = sourceBlock
    self.targetBlock = targetBlock
    self.outputIndex = outputIndex
    self.inputIndex = inputIndex
    self.type = type
    return self
end

function Connection:isValid()
    return self.sourceBlock and self.targetBlock and
           self.outputIndex and self.inputIndex
end

return Connection 