local Component = require "lib.ui.component"
local ProgramMenu = setmetatable({}, {__index = Component})
ProgramMenu.__index = ProgramMenu

function ProgramMenu.new(events)
    local self = setmetatable(Component.new(), ProgramMenu)
    self.events = events
    
    -- Menu dimensions and styling
    self.x = 10
    self.y = 10
    self.width = 200
    self.buttonHeight = 30
    self.buttonSpacing = 5
    
    -- Create buttons
    self.buttons = {
        {text = "New Program", action = "new"},
        {text = "Load Program", action = "load"},
        {text = "Save Program", action = "save"},
        {text = "Clear Program", action = "clear"},
        {text = "Apply to Boids", action = "apply"}
    }
    
    return self
end

function ProgramMenu:draw()
    -- Draw menu background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", 
        self.x, 
        self.y, 
        self.width, 
        #self.buttons * (self.buttonHeight + self.buttonSpacing))

    -- Draw buttons
    local buttonY = self.y
    for _, button in ipairs(self.buttons) do
        -- Check if mouse is over button
        local isHovered = self:isMouseOverButton(buttonY)
        
        -- Draw button background
        love.graphics.setColor(isHovered and {0.4, 0.4, 0.6} or {0.3, 0.3, 0.3})
        love.graphics.rectangle("fill",
            self.x + 5,
            buttonY + 2,
            self.width - 10,
            self.buttonHeight - 4)
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(button.text,
            self.x + 10,
            buttonY + (self.buttonHeight - love.graphics.getFont():getHeight()) / 2)
        
        buttonY = buttonY + self.buttonHeight + self.buttonSpacing
    end
end

function ProgramMenu:isMouseOverButton(buttonY)
    local mx, my = love.mouse.getPosition()
    return mx >= self.x + 5 and
           mx <= self.x + self.width - 5 and
           my >= buttonY + 2 and
           my <= buttonY + self.buttonHeight - 2
end

function ProgramMenu:handleMousePressed(x, y, button)
    if button ~= 1 then return false end
    
    local buttonY = self.y
    for _, btn in ipairs(self.buttons) do
        if self:isMouseOverButton(buttonY) then
            self.events:emit("program_action", btn.action)
            return true
        end
        buttonY = buttonY + self.buttonHeight + self.buttonSpacing
    end
    
    return false
end

return ProgramMenu 