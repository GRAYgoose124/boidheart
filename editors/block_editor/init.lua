-- Main block editor class
local BlockEditor = {}
BlockEditor.__index = BlockEditor

local ConnectionManager = require "editors.block_editor.connection_manager"
local PaletteManager = require "editors.block_editor.palette_manager"
local BlockManager = require "editors.block_editor.block_manager"
local UIManager = require "editors.block_editor.ui_manager"

function BlockEditor.new()
    local self = setmetatable({}, BlockEditor)
    
    -- Initialize managers
    self.connectionManager = ConnectionManager.new(self)
    self.paletteManager = PaletteManager.new(self)
    self.blockManager = BlockManager.new(self)
    self.uiManager = UIManager.new(self)
    
    -- UI state
    self.editorVisible = false
    self.draggingBlock = nil
    self.draggingOffset = nil
    self.draggingConnection = nil
    self.draggingParam = nil
    self.activeDropdown = nil
    self.activeDialog = nil
    self.showHelp = false
    
    -- Layout parameters
    self.gridSize = 20
    self.blockWidth = 160
    self.blockHeight = 80
    self.workspaceX = 220
    
    return self
end

-- Delegate methods to appropriate managers
function BlockEditor:draw()
    if not self.editorVisible then return end
    
    self.uiManager:drawBackground()
    self:drawGrid()
    self.paletteManager:draw()
    self.blockManager:drawBlocks()
    self.connectionManager:drawConnections()
    self.uiManager:drawOverlay()
end

-- Add the drawGrid method here
function BlockEditor:drawGrid()
    love.graphics.setColor(0.2, 0.2, 0.2)
    local width, height = love.graphics.getDimensions()
    
    for x = self.workspaceX, width, self.gridSize do
        love.graphics.line(x, 0, x, height)
    end
    
    for y = 0, height, self.gridSize do
        love.graphics.line(self.workspaceX, y, width, y)
    end
end

-- Add these methods to the BlockEditor class

function BlockEditor:update(dt)
    if not self.editorVisible then return end
    
    -- Update managers
    self.connectionManager:update(dt)
    self.blockManager:update(dt)
    self.uiManager:update(dt)
end

function BlockEditor:mousepressed(x, y, button)
    if not self.editorVisible then return end
    
    if self.uiManager:handleMousePressed(x, y, button) then return end
    if self.paletteManager:handleMousePressed(x, y, button) then return end
    if self.blockManager:handleMousePressed(x, y, button) then return end
    if self.connectionManager:handleMousePressed(x, y, button) then return end
end

function BlockEditor:mousereleased(x, y, button)
    if not self.editorVisible then return end
    
    if self.uiManager:handleMouseReleased(x, y, button) then return end
    if self.paletteManager:handleMouseReleased(x, y, button) then return end
    if self.blockManager:handleMouseReleased(x, y, button) then return end
    if self.connectionManager:handleMouseReleased(x, y, button) then return end
end

function BlockEditor:mousemoved(x, y, dx, dy)
    if not self.editorVisible then return end
    
    if self.uiManager:handleMouseMoved(x, y, dx, dy) then return end
    if self.paletteManager:handleMouseMoved(x, y, dx, dy) then return end
    if self.blockManager:handleMouseMoved(x, y, dx, dy) then return end
    if self.connectionManager:handleMouseMoved(x, y, dx, dy) then return end
end

function BlockEditor:wheelmoved(x, y)
    if not self.editorVisible then return end
    
    if self.uiManager:handleWheelMoved(x, y) then return end
    if self.paletteManager:handleWheelMoved(x, y) then return end
    if self.blockManager:handleWheelMoved(x, y) then return end
end

function BlockEditor:toggle()
    self.editorVisible = not self.editorVisible
end

function BlockEditor:isVisible()
    return self.editorVisible
end

function BlockEditor:keypressed(key)
    if key == "tab" then
        self:toggle()
        return true
    end
    
    if not self.editorVisible then return false end
    
    if self.uiManager:handleKeyPressed(key) then return true end
    if self.blockManager:handleKeyPressed(key) then return true end
    return false
end

return BlockEditor 