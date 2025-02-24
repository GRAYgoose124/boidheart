local UIManager = {}
UIManager.__index = UIManager

function UIManager.new(editor)
    local self = setmetatable({}, UIManager)
    self.editor = editor
    self.activeDropdown = nil
    self.activeDialog = nil
    return self
end

function UIManager:drawBackground()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function UIManager:drawOverlay()
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
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", dropdown.x, dropdown.y, 
        dropdown.width, #dropdown.options * 20)
    
    for i, option in ipairs(dropdown.options) do
        local y = dropdown.y + (i-1) * 20
        -- Highlight on hover
        local mx, my = love.mouse.getPosition()
        if my >= y and my <= y + 20 and 
           mx >= dropdown.x and mx <= dropdown.x + dropdown.width then
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", dropdown.x, y, dropdown.width, 20)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(option, dropdown.x + 5, y + 2)
    end
end

function UIManager:handleMousePressed(x, y, button)
    if self.activeDropdown then
        -- Handle dropdown selection
        for i, option in ipairs(self.activeDropdown.options) do
            local optionY = self.activeDropdown.y + (i-1) * 20
            if y >= optionY and y <= optionY + 20 and
               x >= self.activeDropdown.x and x <= self.activeDropdown.x + self.activeDropdown.width then
                self.activeDropdown.callback(option)
                self.activeDropdown = nil
                return true
            end
        end
        self.activeDropdown = nil
        return true
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
        "- Tab: Toggle editor visibility",
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

return UIManager 