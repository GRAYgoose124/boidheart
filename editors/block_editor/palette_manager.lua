local PaletteManager = {}
PaletteManager.__index = PaletteManager

local BLOCK_TYPES = require "editors.block_editor.block_types"
local CONNECTION_TYPES = require "editors.block_editor.connection_types"

function PaletteManager.new(editor)
    local self = setmetatable({}, PaletteManager)
    self.editor = editor
    self.scrollY = 0
    self.maxScrollY = 0
    self.scrollSpeed = 50
    self.paletteWidth = 200
    self.paletteX = 10
    self.paletteY = 10
    self.paletteSpacing = 5
    return self
end

function PaletteManager:draw()
    -- Set up clipping for palette
    love.graphics.setScissor(0, 0, self.paletteWidth + self.paletteX*2, love.graphics.getHeight())
    
    -- Draw palette background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, self.paletteWidth + self.paletteX*2, love.graphics.getHeight())
    
    -- Draw blocks in palette with scrolling
    local y = self.paletteY - self.scrollY
    for category, blocks in pairs(BLOCK_TYPES) do
        -- Draw category header
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(category, self.paletteX, y)
        y = y + 25
        
        -- Draw block previews
        for blockType, config in pairs(blocks) do
            if y + self.editor.blockHeight > 0 and y < love.graphics.getHeight() then
                self:drawBlockPreview(config, y)
            end
            y = y + self.editor.blockHeight + self.paletteSpacing
        end
        y = y + self.paletteSpacing * 2
    end
    
    -- Update maxScrollY
    self.maxScrollY = math.max(0, y - love.graphics.getHeight())
    
    -- Reset scissor
    love.graphics.setScissor()
end

function PaletteManager:drawBlockPreview(config, y)
    -- Draw block preview
    love.graphics.setColor(unpack(config.color))
    love.graphics.rectangle("fill", self.paletteX, y, 
        self.editor.blockWidth * 0.8, self.editor.blockHeight * 0.8)
    
    -- Draw block name and icon
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(config.name, self.paletteX + 5, y + 5)
    if config.icon then
        love.graphics.print(config.icon, 
            self.paletteX + self.editor.blockWidth * 0.7, y + 5)
    end
    
    -- Draw connection points preview with proper types
    if config.inputs then
        for i, input in ipairs(config.inputs) do
            local x = self.paletteX
            local y = y + self.editor.blockHeight * 0.4 + (i-1) * 15
            self.editor.connectionManager:drawConnectionPoint(x, y, input.type or "flow", true)
        end
    end
    if config.outputs then
        for i, output in ipairs(config.outputs) do
            local x = self.paletteX + self.editor.blockWidth * 0.8
            local y = y + self.editor.blockHeight * 0.4 + (i-1) * 15
            self.editor.connectionManager:drawConnectionPoint(x, y, output.type or "flow", false)
        end
    end
end

function PaletteManager:handleMousePressed(x, y, button)
    if x >= self.paletteX and x <= self.paletteX + self.paletteWidth then
        local blockType = self:findBlockAtPosition(x, y)
        if blockType then
            -- Create new block instance at mouse position
            local block = {
                config = blockType,
                x = x - self.paletteX,  -- Adjust x position relative to palette
                y = y,
                params = {}
            }
            -- Initialize default parameter values
            if blockType.params then
                for _, param in ipairs(blockType.params) do
                    block.params[param.name] = param.default
                end
            end
            self.editor.blockManager.draggingBlock = block
            self.editor.blockManager.draggingOffset = {x = self.paletteX, y = 0}
            return true
        end
    end
    return false
end

function PaletteManager:handleWheelMoved(x, y)
    if x < self.paletteWidth + self.paletteX * 2 then
        -- Adjust scroll speed and direction
        local newScrollY = self.scrollY - y * self.scrollSpeed
        self.scrollY = math.max(0, math.min(self.maxScrollY, newScrollY))
        return true
    end
    return false
end

function PaletteManager:findBlockAtPosition(x, y)
    -- Adjust x position to be relative to palette
    local relativeX = x - self.paletteX
    if relativeX < 0 or relativeX > self.paletteWidth then
        return nil
    end

    -- Adjust y position for scrolling
    local adjustedY = y + self.scrollY
    local currentY = self.paletteY
    
    for category, blocks in pairs(BLOCK_TYPES) do
        -- Category header height
        currentY = currentY + 25
        
        for name, config in pairs(blocks) do
            local blockHeight = self.editor.blockHeight * 0.8
            if adjustedY >= currentY and adjustedY <= currentY + blockHeight then
                -- Create a deep copy of the config
                local blockConfig = {}
                for k, v in pairs(config) do
                    if type(v) == "table" then
                        blockConfig[k] = table.deepcopy(v)
                    else
                        blockConfig[k] = v
                    end
                end
                return blockConfig
            end
            currentY = currentY + blockHeight + self.paletteSpacing
        end
        currentY = currentY + self.paletteSpacing * 2
    end
    return nil
end

function PaletteManager:handleMouseMoved(x, y, dx, dy)
    -- If we're dragging a block from the palette, let BlockManager handle it
    if self.editor.blockManager.draggingBlock then
        return false
    end
    
    -- Check if mouse is in palette area
    if x < self.paletteWidth + self.paletteX * 2 then
        return true -- Consume the event if we're in the palette area
    end
    
    return false
end

function PaletteManager:handleMouseReleased(x, y, button)
    -- Add if needed for consistency
    return false
end

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

return PaletteManager 