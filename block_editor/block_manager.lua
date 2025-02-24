local BlockManager = {}
BlockManager.__index = BlockManager

-- Import block types and conditions
local BLOCK_TYPES = require "block_editor.block_types"
local CONDITION_TYPES = require "block_editor.condition_types"
local PARAMETER_TYPES = require "block_editor.parameter_types"
local UI = require "lib.ui"

function BlockManager.new(editor)
    local self = setmetatable({}, BlockManager)
    self.editor = editor
    self.blocks = {}
    self.draggingBlock = nil
    self.draggingOffset = nil
    self.selectedBlock = nil
    return self
end

function BlockManager:draw()
    -- Draw all blocks
    self:drawBlocks()
    
    -- Draw any dragged block
    if self.draggingBlock then
        self:drawBlock(self.draggingBlock)
    end
end

function BlockManager:drawBlocks()
    for _, block in ipairs(self.blocks) do
        self:drawBlock(block)
    end
end

function BlockManager:drawBlock(block)
    -- Draw block background
    love.graphics.setColor(unpack(block.config.color))
    love.graphics.rectangle("fill", block.x, block.y, 
        self.editor.blockWidth, self.editor.blockHeight)
    
    -- Draw selection highlight if this is the selected block
    if block == self.selectedBlock then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line", block.x - 2, block.y - 2,
            self.editor.blockWidth + 4, self.editor.blockHeight + 4)
    end
    
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
    -- Get parameter type configuration
    local paramType = PARAMETER_TYPES[param.type]
    if not paramType then return end
    
    -- Draw parameter label
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(param.name .. ":", x, y)
    
    -- Draw parameter value using type-specific drawing function
    if paramType.draw then
        paramType.draw(param, value, x + 80, y, 
            self.editor.blockWidth - 100, self.editor)
    end
end

function BlockManager:drawConnectionPoints(block)
    -- Draw input connection points
    if block.config.inputs then
        for i, input in ipairs(block.config.inputs) do
            local px, py = self:getConnectionPointPosition(block, i, true)
            self:drawConnectionPoint(px, py, input.type, true)
        end
    end
    
    -- Draw output connection points
    if block.config.outputs then
        for i, output in ipairs(block.config.outputs) do
            local px, py = self:getConnectionPointPosition(block, i, false)
            self:drawConnectionPoint(px, py, output.type, false)
        end
    end
end

function BlockManager:drawConnectionPoint(x, y, type, isInput)
    -- Get connection type configuration
    local typeInfo = self.editor.connectionManager.CONNECTION_TYPES[type] or 
                    self.editor.connectionManager.CONNECTION_TYPES.any
    
    -- Draw connection point with type-specific shape
    love.graphics.setColor(unpack(typeInfo.color))
    
    -- Draw the connection point based on its type's shape
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
    elseif typeInfo.shape == "circle" then
        local radius = typeInfo.radius or 4
        love.graphics.circle("fill", x, y, radius)
    elseif typeInfo.shape == "square" then
        local size = typeInfo.size or 8
        love.graphics.rectangle("fill", x - size/2, y - size/2, size, size)
    end
    
    -- Draw outline
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("line", x, y, 5)
end

function BlockManager:getConnectionPointPosition(block, index, isInput)
    if not block then return 0, 0 end -- Guard against nil block
    
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

function BlockManager:handleMousePressed(x, y, button)
    -- Check for block selection and parameter interaction
    for _, block in ipairs(self.blocks) do
        if x >= block.x and x <= block.x + self.editor.blockWidth and
           y >= block.y and y <= block.y + self.editor.blockHeight then
            
            -- Set selected block before checking parameters
            self.selectedBlock = block
            
            -- Check for parameter interaction first
            if block.config.params then
                local paramY = block.y + 30
                for _, param in ipairs(block.config.params) do
                    local paramType = PARAMETER_TYPES[param.type]  -- Get the parameter type
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
            return true
        end
    end
    
    -- Close any open dropdowns when clicking outside
    if self.selectedBlock and self.selectedBlock.config.params then
        for _, param in ipairs(self.selectedBlock.config.params) do
            if param.type == "dropdown" and param.ui then
                param.ui.isOpen = false
            end
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

function BlockManager:update(dt) end

return BlockManager 