local UIManager = {}
UIManager.__index = UIManager

local EventSystem = require "block_editor.event_system"
local Dialog = require "lib.ui.dialog"
local ProgramMenu = require "lib.ui.program_menu"
local Button = require "lib.ui.button"

function UIManager.new(editor)
    local self = setmetatable({}, UIManager)
    self.editor = editor
    self.events = EventSystem.new()
    self.components = {}
    self.activeDialog = nil
    
    -- Create program menu component
    self.programMenu = ProgramMenu.new(self.events)
    table.insert(self.components, self.programMenu)
    
    -- Create toolbar buttons
    self:createToolbarButtons()
    
    -- Subscribe to events
    self.events:subscribe("program_action", function(action)
        self:handleProgramAction(action)
    end)
    
    return self
end

function UIManager:createToolbarButtons()
    local buttonWidth = 80
    local buttonHeight = 30
    local spacing = 10
    local startX = 220  -- After palette
    local startY = 10
    
    self.toolbarButtons = {
        Button.new({
            text = "New",
            x = startX,
            y = startY,
            width = buttonWidth,
            height = buttonHeight,
            onClick = function() self:handleProgramAction("new") end
        }),
        Button.new({
            text = "Load",
            x = startX + (buttonWidth + spacing),
            y = startY,
            width = buttonWidth,
            height = buttonHeight,
            onClick = function() self:handleProgramAction("load") end
        }),
        Button.new({
            text = "Save",
            x = startX + (buttonWidth + spacing) * 2,
            y = startY,
            width = buttonWidth,
            height = buttonHeight,
            onClick = function() self:handleProgramAction("save") end
        }),
        Button.new({
            text = "Clear",
            x = startX + (buttonWidth + spacing) * 3,
            y = startY,
            width = buttonWidth,
            height = buttonHeight,
            onClick = function() self:handleProgramAction("clear") end
        }),
        Button.new({
            text = "Apply",
            x = startX + (buttonWidth + spacing) * 4,
            y = startY,
            width = buttonWidth,
            height = buttonHeight,
            onClick = function() self:handleProgramAction("apply") end
        })
    }
    
    -- Add buttons to components list
    for _, button in ipairs(self.toolbarButtons) do
        table.insert(self.components, button)
    end
end

function UIManager:draw()
    if not self.editor.editorVisible then return end
    
    self:drawBackground()
    
    -- Draw all components
    for _, component in ipairs(self.components) do
        if component.visible then
            component:draw()
        end
    end
    
    -- Draw current program name if one is loaded
    if self.editor.currentProgram then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("Current Program: " .. self.editor.currentProgram,
            220, 45)  -- Position below toolbar buttons
    end
    
    -- Draw active dialog if any
    if self.activeDialog then
        self.activeDialog:draw()
    end
    
    -- Draw help overlay if enabled
    if self.editor.showHelp then
        self:drawHelp()
    end
end

function UIManager:drawBackground()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function UIManager:handleMousePressed(x, y, button)
    if not self.editor.editorVisible then return false end
    
    -- Handle active dialog first
    if self.activeDialog and self.activeDialog:handleMousePressed(x, y, button) then
        return true
    end
    
    -- Delegate to components
    for _, component in ipairs(self.components) do
        if component.visible and component:handleMousePressed(x, y, button) then
            return true
        end
    end
    return false
end

function UIManager:handleMouseReleased(x, y, button)
    if not self.editor.editorVisible then return false end
    
    for _, component in ipairs(self.components) do
        if component.visible and component:handleMouseReleased(x, y, button) then
            return true
        end
    end
    return false
end

function UIManager:handleMouseMoved(x, y, dx, dy)
    return false
end

function UIManager:handleWheelMoved(x, y)
    return false
end

function UIManager:update(dt)
    -- Update all visible components
    for _, component in ipairs(self.components) do
        if component.visible and component.update then
            component:update(dt)
        end
    end
    
    -- Update active dialog if any
    if self.activeDialog and self.activeDialog.update then
        self.activeDialog:update(dt)
    end
end

function UIManager:drawHelp()
    -- Draw semi-transparent background for help overlay
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", 100, 100, 
        love.graphics.getWidth() - 200, 
        love.graphics.getHeight() - 200)
    
    -- Draw help title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Block Editor Help", 120, 120)
    
    -- Draw help content
    local y = 160
    local helpText = {
        "Controls:",
        "- B: Toggle editor visibility",
        "- Left Click: Select/drag blocks",
        "- Left Click + Drag: Create connections",
        "- Delete: Remove selected block",
        "- Escape: Close dropdowns/dialogs",
        "",
        "Toolbar:",
        "- New: Create a new program",
        "- Load: Load an existing program",
        "- Save: Save current program",
        "- Clear: Clear all blocks",
        "- Apply: Apply program to selected boids",
        "",
        "Blocks:",
        "- Drag blocks from the palette on the left",
        "- Connect blocks by dragging from output to input points",
        "- Adjust parameters using sliders and dropdowns",
        "",
        "Press H to close help"
    }
    
    for _, line in ipairs(helpText) do
        love.graphics.print(line, 120, y)
        y = y + 25
    end
end

function UIManager:handleKeyPressed(key)
    if key == "escape" then
        self.activeDialog = nil
        self.editor.showHelp = false
        return true
    elseif key == "h" then
        self.editor.showHelp = not self.editor.showHelp
        return true
    elseif self.activeDialog then
        return self.activeDialog:handleKeyPressed(key)
    end
    return false
end

function UIManager:handleProgramAction(action)
    if action == "new" then
        self.activeDialog = Dialog.new({
            type = "input",
            title = "New Program",
            callback = function(name)
                if name and name ~= "" then
                    self.editor:newProgram(name)
                end
                self.activeDialog = nil
            end
        })
    elseif action == "save" then
        if self.editor.currentProgram then
            self.editor:saveProgram(self.editor.currentProgram)
        else
            self.activeDialog = Dialog.new({
                type = "input",
                title = "Save Program As",
                callback = function(name)
                    if name and name ~= "" then
                        self.editor:saveProgram(name)
                        self.editor.currentProgram = name
                    end
                    self.activeDialog = nil
                end
            })
        end
    elseif action == "load" then
        -- Get list of saved programs
        local files = love.filesystem.getDirectoryItems("programs")
        local programs = {}
        for _, file in ipairs(files) do
            -- Remove .lua extension
            local name = file:match("(.+)%.lua$")
            if name then
                table.insert(programs, name)
            end
        end
        
        self.activeDialog = Dialog.new({
            type = "select",
            title = "Load Program",
            options = programs,
            callback = function(name)
                if name then
                    self.editor:loadProgram(name)
                end
                self.activeDialog = nil
            end
        })
    elseif action == "clear" then
        self.editor:newProgram()
    elseif action == "apply" then
        -- Get selected boids and apply program
        local selectedBoids = self.editor.boidManager.selectionManager:getSelectedBoids()
        if #selectedBoids > 0 then
            local groupId = selectedBoids[1].groupId
            if groupId then
                self.editor:applyProgramToGroup(groupId)
            end
        end
    end
end

function UIManager:textinput(text)
    if self.activeDialog then
        return self.activeDialog:handleTextInput(text)
    end
    return false
end

return UIManager 