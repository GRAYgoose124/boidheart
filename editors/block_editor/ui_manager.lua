local UIManager = {}
UIManager.__index = UIManager

local UI = require "lib.ui"

function UIManager.new(editor)
    local self = setmetatable({}, UIManager)
    self.editor = editor
    self.activeDropdown = nil
    self.activeDialog = nil
    self.showProgramMenu = false
    self.programMenuX = love.graphics.getWidth() - 200
    self.programMenuY = 10
    self.programMenuWidth = 180
    self.buttonHeight = 30
    self.buttonSpacing = 5
    return self
end

function UIManager:drawBackground()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function UIManager:drawOverlay()
    -- Draw program management menu
    if self.editor.editorVisible then
        self:drawProgramMenu()
    end

    -- Draw active dropdown if any
    if self.activeDropdown then
        self:drawDropdownMenu(self.activeDropdown)
    end
    
    -- Draw active dialog if any
    if self.activeDialog then
        self:drawDialog(self.activeDialog)
    end
    
    -- Draw help overlay if enabled
    if self.editor.showHelp then
        self:drawHelp()
    end
end

function UIManager:drawDropdownMenu(dropdown)
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw dropdown background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", 
        dropdown.x, 
        dropdown.y, 
        dropdown.width, 
        #dropdown.options * 20)
    
    -- Draw options
    local mx, my = love.mouse.getPosition()
    for i, option in ipairs(dropdown.options) do
        local y = dropdown.y + (i-1) * 20
        
        -- Highlight hovered option
        if mx >= dropdown.x and mx <= dropdown.x + dropdown.width and
           my >= y and my <= y + 20 then
            love.graphics.setColor(0.4, 0.4, 0.6)
            love.graphics.rectangle("fill", dropdown.x, y, dropdown.width, 20)
        -- Highlight current value
        elseif option == dropdown.currentValue then
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", dropdown.x, y, dropdown.width, 20)
        end
        
        -- Draw option text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(option, dropdown.x + 5, y + 2)
    end
end

function UIManager:drawProgramMenu()
    -- Draw menu background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", 
        self.programMenuX, 
        self.programMenuY, 
        self.programMenuWidth, 
        self.buttonHeight * 5 + self.buttonSpacing * 4)

    -- Create and draw buttons
    local y = self.programMenuY
    local buttons = {
        UI.Button.new(
            self.programMenuX + 5,
            y + 2,
            self.programMenuWidth - 10,
            self.buttonHeight - 4,
            "Load Program",
            function() self:handleProgramAction("load") end
        ),
        UI.Button.new(
            self.programMenuX + 5,
            y + 2 + self.buttonHeight + self.buttonSpacing,
            self.programMenuWidth - 10,
            self.buttonHeight - 4,
            "Save Program",
            function() self:handleProgramAction("save") end
        ),
        UI.Button.new(
            self.programMenuX + 5,
            y + 2 + 2 * (self.buttonHeight + self.buttonSpacing),
            self.programMenuWidth - 10,
            self.buttonHeight - 4,
            "Apply to Group",
            function() self:handleProgramAction("apply") end
        ),
        UI.Button.new(
            self.programMenuX + 5,
            y + 2 + 3 * (self.buttonHeight + self.buttonSpacing),
            self.programMenuWidth - 10,
            self.buttonHeight - 4,
            "Clear Program",
            function() self:handleProgramAction("clear") end
        ),
        UI.Button.new(
            self.programMenuX + 5,
            y + 2 + 4 * (self.buttonHeight + self.buttonSpacing),
            self.programMenuWidth - 10,
            self.buttonHeight - 4,
            "Run Program",
            function() self:handleProgramAction("run") end
        )
    }
    
    for _, button in ipairs(buttons) do
        button:draw()
        y = y + self.buttonHeight + self.buttonSpacing
    end
end

function UIManager:isMouseOverButton(button, y)
    local mx, my = love.mouse.getPosition()
    return mx >= self.programMenuX + 5 and
           mx <= self.programMenuX + self.programMenuWidth - 5 and
           my >= y + 2 and
           my <= y + self.buttonHeight - 2
end

function UIManager:handleMousePressed(x, y, button)
    if button ~= 1 then return false end
    
    -- Check program menu buttons
    if self.editor.editorVisible then
        local y = self.programMenuY
        local buttons = {
            UI.Button.new(
                self.programMenuX + 5,
                y + 2,
                self.programMenuWidth - 10,
                self.buttonHeight - 4,
                "Load Program",
                function() self:handleProgramAction("load") end
            ),
            UI.Button.new(
                self.programMenuX + 5,
                y + 2 + self.buttonHeight + self.buttonSpacing,
                self.programMenuWidth - 10,
                self.buttonHeight - 4,
                "Save Program",
                function() self:handleProgramAction("save") end
            ),
            UI.Button.new(
                self.programMenuX + 5,
                y + 2 + 2 * (self.buttonHeight + self.buttonSpacing),
                self.programMenuWidth - 10,
                self.buttonHeight - 4,
                "Apply to Group",
                function() self:handleProgramAction("apply") end
            ),
            UI.Button.new(
                self.programMenuX + 5,
                y + 2 + 3 * (self.buttonHeight + self.buttonSpacing),
                self.programMenuWidth - 10,
                self.buttonHeight - 4,
                "Clear Program",
                function() self:handleProgramAction("clear") end
            ),
            UI.Button.new(
                self.programMenuX + 5,
                y + 2 + 4 * (self.buttonHeight + self.buttonSpacing),
                self.programMenuWidth - 10,
                self.buttonHeight - 4,
                "Run Program",
                function() self:handleProgramAction("run") end
            )
        }
        
        for _, btn in ipairs(buttons) do
            if btn:isHovered(x, y) then
                btn.action()
                return true
            end
            y = y + self.buttonHeight + self.buttonSpacing
        end
    end

    -- Handle active dropdown
    if self.activeDropdown then
        return self.activeDropdown:handleClick(x, y)
    end
    
    return false
end

function UIManager:handleMouseReleased(x, y, button)
    return false
end

function UIManager:handleMouseMoved(x, y, dx, dy)
    return false
end

function UIManager:handleWheelMoved(x, y)
    return false
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
        self.activeDropdown = nil
        self.activeDialog = nil
        self.editor.showHelp = false
        return true
    elseif key == "h" then
        self.editor.showHelp = not self.editor.showHelp
        return true
    end
    return false
end

function UIManager:update(dt)
    -- Add any necessary update logic
end

function UIManager:handleProgramAction(action)
    if action == "load" then
        -- Show program selection dialog
        local files = love.filesystem.getDirectoryItems("programs")
        local programs = {}
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                table.insert(programs, file:gsub("%.lua$", ""))
            end
        end
        
        if #programs > 0 then
            -- For now, just load the first program
            -- TODO: Add proper program selection UI
            self.editor:loadProgram(programs[1])
        end
        
    elseif action == "save" then
        local name = self.editor.currentProgram or "program_" .. os.time()
        self.editor:saveProgram(name)
        
    elseif action == "apply" then
        -- Get selected boids and apply program
        local selectedBoids = self.editor.boidManager.selectionManager:getSelectedBoids()
        if #selectedBoids > 0 then
            local groupId = selectedBoids[1].groupId
            if groupId then
                self.editor:applyProgramToGroup(groupId)
            end
        end
        
    elseif action == "clear" then
        self.editor:newProgram()
        
    elseif action == "run" then
        -- Run is the same as apply for now
        local selectedBoids = self.editor.boidManager.selectionManager:getSelectedBoids()
        if #selectedBoids > 0 then
            local groupId = selectedBoids[1].groupId
            if groupId then
                self.editor:applyProgramToGroup(groupId)
            end
        end
    end
end

function UIManager:serializeTable(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        local key = type(k) == "number" and k or string.format("[%q]", k)
        if type(v) == "table" then
            result = result .. string.format("%s=%s,", key, self:serializeTable(v))
        elseif type(v) == "string" then
            result = result .. string.format("%s=%q,", key, v)
        else
            result = result .. string.format("%s=%s,", key, tostring(v))
        end
    end
    return result .. "}"
end

return UIManager 