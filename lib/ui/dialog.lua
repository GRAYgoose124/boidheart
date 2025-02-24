local Component = require "lib.ui.component"
local Dialog = setmetatable({}, {__index = Component})
Dialog.__index = Dialog

function Dialog.new(config)
    local self = setmetatable(Component.new(), Dialog)
    
    self.type = config.type or "input"
    self.title = config.title or ""
    self.options = config.options or {}
    self.callback = config.callback
    self.value = ""
    self.selectedIndex = 1
    
    -- Dialog dimensions
    self.width = 400
    self.height = 300
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
    
    return self
end

function Dialog:draw()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw dialog box
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.title, self.x + 20, self.y + 20)
    
    if self.type == "select" then
        self:drawSelectDialog()
    else
        self:drawInputDialog()
    end
end

function Dialog:drawSelectDialog()
    local y = self.y + 60
    for i, option in ipairs(self.options) do
        love.graphics.setColor(i == self.selectedIndex and {0.4, 0.4, 0.6} or {0.3, 0.3, 0.3})
        love.graphics.rectangle("fill", self.x + 20, y, self.width - 40, 30)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(option, self.x + 30, y + 5)
        
        y = y + 40
    end
end

function Dialog:drawInputDialog()
    -- Draw input box
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x + 20, self.y + 60, self.width - 40, 30)
    
    -- Draw input text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.value, self.x + 30, self.y + 65)
end

function Dialog:handleKeyPressed(key)
    if key == "escape" then
        if self.callback then
            self.callback(nil)
        end
        return true
    elseif key == "return" then
        if self.callback then
            self.callback(self.type == "select" and self.options[self.selectedIndex] or self.value)
        end
        return true
    elseif self.type == "select" then
        if key == "up" then
            self.selectedIndex = math.max(1, self.selectedIndex - 1)
            return true
        elseif key == "down" then
            self.selectedIndex = math.min(#self.options, self.selectedIndex + 1)
            return true
        end
    end
    return false
end

function Dialog:handleTextInput(text)
    if self.type == "input" then
        self.value = self.value .. text
        return true
    end
    return false
end

function Dialog:handleMousePressed(x, y, button)
    if button == 1 and self.type == "select" then
        local itemY = self.y + 60
        for i, _ in ipairs(self.options) do
            if y >= itemY and y < itemY + 30 and
               x >= self.x + 20 and x <= self.x + self.width - 40 then
                self.selectedIndex = i
                if self.callback then
                    self.callback(self.options[i])
                end
                return true
            end
            itemY = itemY + 40
        end
    end
    return false
end

return Dialog 