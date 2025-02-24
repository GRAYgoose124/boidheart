local Button = {}
Button.__index = Button

function Button.new(config)
    local self = setmetatable({}, Button)
    self.x = config.x or 0
    self.y = config.y or 0
    self.width = config.width or 80
    self.height = config.height or 30
    self.text = config.text or ""
    self.onClick = config.onClick
    self.visible = true
    self.hovered = false
    return self
end

function Button:draw()
    -- Draw button background
    if self.hovered then
        love.graphics.setColor(0.4, 0.4, 0.6)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw button outline
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- Draw button text
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text,
        self.x + (self.width - textWidth) / 2,
        self.y + (self.height - textHeight) / 2)
end

function Button:handleMousePressed(x, y, button)
    if button == 1 and self:containsPoint(x, y) then
        if self.onClick then
            self.onClick()
        end
        return true
    end
    return false
end

function Button:handleMouseMoved(x, y)
    self.hovered = self:containsPoint(x, y)
end

function Button:handleMouseReleased(x, y, button)
    return false
end

function Button:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

function Button:update(dt)
    -- Get current mouse position
    local mx, my = love.mouse.getPosition()
    -- Update hover state
    self.hovered = self:containsPoint(mx, my)
end

return Button 