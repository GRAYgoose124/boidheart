-- Main block editor class
local BlockEditor = {}
BlockEditor.__index = BlockEditor

local BLOCK_TYPES = require "block_editor.block_types"

local ConnectionManager = require "block_editor.connection_manager"
local PaletteManager = require "block_editor.palette_manager"
local BlockManager = require "block_editor.block_manager"
local UIManager = require "block_editor.ui_manager"

function BlockEditor.new(boidManager)
    local self = setmetatable({}, BlockEditor)
    
    -- Store boid manager reference
    self.boidManager = boidManager
    
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
    
    -- Program management
    self.programs = {}
    self.currentProgram = nil
    
    -- Layout parameters
    self.gridSize = 20
    self.blockWidth = 160
    self.blockHeight = 80
    self.workspaceX = 220
    
    return self
end

-- Program Management Methods
function BlockEditor:compileProgram()
    local program = {
        blocks = {},
        connections = {}
    }
    
    -- Copy blocks with their configurations and parameters
    for _, block in ipairs(self.blockManager.blocks) do
        table.insert(program.blocks, {
            type = block.config.type,
            params = table.deepcopy(block.params),
            x = block.x,
            y = block.y
        })
    end
    
    -- Copy connections with block references converted to indices
    for _, conn in ipairs(self.connectionManager.connections) do
        local sourceIndex = self:findBlockIndex(conn.source)
        local targetIndex = self:findBlockIndex(conn.target)
        if sourceIndex and targetIndex then
            table.insert(program.connections, {
                sourceBlock = sourceIndex,
                targetBlock = targetIndex,
                outputIndex = conn.outputIndex,
                inputIndex = conn.inputIndex
            })
        end
    end
    
    return program
end

function BlockEditor:loadProgram(name)
    -- Try to load from memory first
    local program = self.programs[name]
    
    -- If not in memory, try to load from file
    if not program then
        local chunk, err = love.filesystem.load("programs/" .. name .. ".lua")
        if chunk then
            program = chunk()
            self.programs[name] = program
        else
            print("Failed to load program:", err)
            return
        end
    end
    
    -- Clear current program
    self.blockManager.blocks = {}
    self.connectionManager.connections = {}
    
    -- Load blocks
    local blockRefs = {}
    for i, blockData in ipairs(program.blocks) do
        local block = {
            config = BLOCK_TYPES[blockData.type],
            params = blockData.params or {},
            x = blockData.x,
            y = blockData.y
        }
        table.insert(self.blockManager.blocks, block)
        blockRefs[i] = block
    end
    
    -- Load connections
    for _, conn in ipairs(program.connections) do
        self.connectionManager:createConnection(
            blockRefs[conn.sourceBlock],
            blockRefs[conn.targetBlock],
            conn.outputIndex,
            conn.inputIndex
        )
    end
    
    self.currentProgram = name
end

function BlockEditor:applyProgramToGroup(groupId)
    if not groupId then return end
    
    local program = self:compileProgram()
    local boids = self.boidManager.selectionManager.groups[groupId]
    
    if boids then
        for _, boid in ipairs(boids) do
            boid.program = program
        end
    end
end

function BlockEditor:findBlockIndex(block)
    for i, b in ipairs(self.blockManager.blocks) do
        if b == block then
            return i
        end
    end
    return nil
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
    
    if key == "return" or key == "kpenter" then
        -- Apply program to currently selected group
        local selectedBoids = self.boidManager.selectionManager:getSelectedBoids()
        if #selectedBoids > 0 then
            local groupId = selectedBoids[1].groupId
            self:applyProgramToGroup(groupId)
        end
        return true
    end
    
    if self.uiManager:handleKeyPressed(key) then return true end
    if self.blockManager:handleKeyPressed(key) then return true end
    return false
end

function BlockEditor:saveProgram(name)
    -- Create programs directory if it doesn't exist
    love.filesystem.createDirectory("programs")
    
    local program = self:compileProgram()
    program.name = name or "unnamed_program"
    
    -- Save to programs table and file
    self.programs[program.name] = program
    
    -- Serialize and save to file
    local programString = "return " .. self.uiManager:serializeTable(program)
    local success, message = love.filesystem.write("programs/" .. program.name .. ".lua", programString)
    
    if not success then
        print("Failed to save program:", message)
    end
end

function BlockEditor:newProgram(name)
    -- Clear current program
    self.blockManager.blocks = {}
    self.connectionManager.connections = {}
    self.currentProgram = name
end

return BlockEditor 