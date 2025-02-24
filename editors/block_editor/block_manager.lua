local BlockManager = {}
BlockManager.__index = BlockManager

-- Import block types and conditions
local BLOCK_TYPES = require "editors.block_editor.block_types"
local CONDITION_TYPES = require "editors.block_editor.condition_types"
local PARAMETER_TYPES = require "editors.block_editor.parameter_types"

function BlockManager.new(editor)
    local self = setmetatable({}, BlockManager)
    self.editor = editor
    self.blocks = {}
    self.draggingBlock = nil
    self.draggingOffset = nil
    self.selectedBlock = nil
    return self
end

function BlockManager:drawBlocks()
    for _, block in ipairs(self.blocks) do
        self:drawBlock(block)
    end
    
    if self.draggingBlock then
        self:drawBlock(self.draggingBlock)
    end
end

function BlockManager:drawBlock(block)
    -- Draw block background
    love.graphics.setColor(unpack(block.config.color))
    love.graphics.rectangle("fill", block.x, block.y, 
        self.editor.blockWidth, self.editor.blockHeight)
    
    -- Draw block name and icon
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(block.config.name, block.x + 5, block.y + 5)
    if block.config.icon then
        love.graphics.print(block.config.icon, 
            block.x + self.editor.blockWidth - 20, block.y + 5)
    end
    
    -- Draw parameters
    if block.config.params then
        local paramY = block.y + 30
        for _, param in ipairs(block.config.params) do
            self:drawParameter(param, block.params[param.name], 
                block.x + 10, paramY)
            paramY = paramY + 25
        end
    end
    
    -- Draw connection points
    self:drawConnectionPoints(block)
end

function BlockManager:drawParameter(param, value, x, y)
    local paramType = PARAMETER_TYPES[param.type]
    if paramType and paramType.draw then
        paramType.draw(param, value, x, y, self.editor.blockWidth - 20)
    end
end

function BlockManager:drawConnectionPoints(block)
    -- Draw input connection points
    if block.config.inputs then
        love.graphics.setColor(0.8, 0.8, 0.8)
        for i, _ in ipairs(block.config.inputs) do
            local px, py = self:getConnectionPointPosition(block, i, true)
            love.graphics.circle("fill", px, py, 4)
        end
    end
    
    -- Draw output connection points
    if block.config.outputs then
        love.graphics.setColor(0.8, 0.8, 0.8)
        for i, _ in ipairs(block.config.outputs) do
            local px, py = self:getConnectionPointPosition(block, i, false)
            love.graphics.circle("fill", px, py, 4)
        end
    end
end

function BlockManager:getConnectionPointPosition(block, index, isInput)
    local x = block.x + (isInput and 0 or self.editor.blockWidth)
    local y = block.y + 30 + (index - 1) * 20
    return x, y
end

function BlockManager:handleMousePressed(x, y, button)
    -- Check for block selection and parameter interaction
    for _, block in ipairs(self.blocks) do
        if x >= block.x and x <= block.x + self.editor.blockWidth and
           y >= block.y and y <= block.y + self.editor.blockHeight then
            
            -- Check for parameter interaction
            if block.config.params then
                local paramY = block.y + 30
                for _, param in ipairs(block.config.params) do
                    local paramType = PARAMETER_TYPES[param.type]
                    if paramType and paramType.handleInput then
                        local newValue = paramType.handleInput(param, 
                            block.params[param.name], 
                            block.x + 10, paramY, 
                            self.editor.blockWidth - 20,
                            self.editor)
                        if newValue ~= block.params[param.name] then
                            block.params[param.name] = newValue
                            return true
                        end
                    end
                    paramY = paramY + 25
                end
            end
            
            -- Start dragging if no parameter was clicked
            self.draggingBlock = block
            self.draggingOffset = {x = x - block.x, y = y - block.y}
            self.selectedBlock = block
            return true
        end
    end
    self.selectedBlock = nil
    return false
end

function BlockManager:handleMouseReleased(x, y, button)
    if self.draggingBlock then
        -- Snap to grid
        self.draggingBlock.x = math.floor((self.draggingBlock.x - self.editor.workspaceX) / 
            self.editor.gridSize) * self.editor.gridSize + self.editor.workspaceX
        self.draggingBlock.y = math.floor(self.draggingBlock.y / 
            self.editor.gridSize) * self.editor.gridSize
        
        -- Add block to blocks list if it's new
        if not self:isBlockInList(self.draggingBlock) then
            table.insert(self.blocks, self.draggingBlock)
        end
        
        self.draggingBlock = nil
        self.draggingOffset = nil
        return true
    end
    return false
end

function BlockManager:isBlockInList(block)
    for _, b in ipairs(self.blocks) do
        if b == block then
            return true
        end
    end
    return false
end

function BlockManager:handleMouseMoved(x, y, dx, dy)
    if self.draggingBlock and self.draggingOffset then
        self.draggingBlock.x = x - self.draggingOffset.x
        self.draggingBlock.y = y - self.draggingOffset.y
        return true
    end
    return false
end

function BlockManager:handleKeyPressed(key)
    if key == "delete" and self.selectedBlock then
        -- Remove selected block
        for i, block in ipairs(self.blocks) do
            if block == self.selectedBlock then
                table.remove(self.blocks, i)
                self.selectedBlock = nil
                return true
            end
        end
    end
    return false
end

function BlockManager:update(dt)
    -- Add any necessary update logic
end

return BlockManager 