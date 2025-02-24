local UI = {}

-- Button class
local Button = {}
Button.__index = Button

function Button.new(x, y, width, height, text, action)
    local self = setmetatable({}, Button)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.text = text
    self.action = action
    return self
end

function Button:isHovered(mx, my)
    return mx >= self.x and mx <= self.x + self.width and
           my >= self.y and my <= self.y + self.height
end

function Button:draw(colors)
    colors = colors or {
        normal = {0.3, 0.3, 0.3},
        hover = {0.4, 0.4, 0.6},
        text = {1, 1, 1}
    }
    
    local mx, my = love.mouse.getPosition()
    local hover = self:isHovered(mx, my)
    
    -- Draw button background
    love.graphics.setColor(hover and colors.hover or colors.normal)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw text
    love.graphics.setColor(colors.text)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text,
        self.x + (self.width - textWidth) / 2,
        self.y + (self.height - textHeight) / 2)
end

-- Dropdown class
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(x, y, width, options, currentValue, onChange)
    local self = setmetatable({}, Dropdown)
    self.x = x
    self.y = y
    self.width = width
    self.options = options
    self.currentValue = currentValue
    self.onChange = onChange
    self.isOpen = false
    self.itemHeight = 20
    return self
end

function Dropdown:draw()
    -- Draw closed dropdown
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.itemHeight)
    
    -- Draw current value and label
    love.graphics.setColor(1, 1, 1)
    if self.label then
        love.graphics.print(self.label .. ": " .. tostring(self.currentValue), 
            self.x + 5, self.y + 2)
    else
        love.graphics.print(tostring(self.currentValue), self.x + 5, self.y + 2)
    end
    
    -- Draw arrow
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.polygon("fill",
        self.x + self.width - 15, self.y + 5,
        self.x + self.width - 5, self.y + 5,
        self.x + self.width - 10, self.y + 15)
    
    -- Draw options if open
    if self.isOpen then
        -- Draw options background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
        love.graphics.rectangle("fill", 
            self.x, 
            self.y + self.itemHeight, 
            self.width, 
            #self.options * self.itemHeight)
        
        -- Draw options
        local mx, my = love.mouse.getPosition()
        for i, option in ipairs(self.options) do
            local optionY = self.y + self.itemHeight + (i-1) * self.itemHeight
            
            -- Highlight hovered/selected option
            if mx >= self.x and mx <= self.x + self.width and
               my >= optionY and my <= optionY + self.itemHeight then
                love.graphics.setColor(0.4, 0.4, 0.6)
                love.graphics.rectangle("fill", self.x, optionY, self.width, self.itemHeight)
            elseif option == self.currentValue then
                love.graphics.setColor(0.3, 0.3, 0.4)
                love.graphics.rectangle("fill", self.x, optionY, self.width, self.itemHeight)
            end
            
            -- Draw option text
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(option), self.x + 5, optionY + 2)
        end
    end
end

function Dropdown:handleClick(x, y)
    if not self.isOpen then
        -- Check if clicking on the dropdown header
        if x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.itemHeight then
            self.isOpen = true
            return true
        end
        return false
    end
    
    -- Check if clicking on an option
    if x >= self.x and x <= self.x + self.width then
        local optionY = self.y + self.itemHeight
        for i, option in ipairs(self.options) do
            if y >= optionY and y <= optionY + self.itemHeight then
                self.currentValue = option
                self.isOpen = false
                return true
            end
            optionY = optionY + self.itemHeight
        end
    end
    
    -- Close dropdown if clicking outside
    self.isOpen = false
    return false
end

-- Add classes to UI library
UI.Button = Button
UI.Dropdown = Dropdown

return UI 