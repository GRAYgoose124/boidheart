local Dialogs = {}
Dialogs.__index = Dialogs

function Dialogs:drawDialog(dialog)
    if not dialog then return end
    
    -- Draw dialog background
    local width = 300
    local height = 150
    local x = (love.graphics.getWidth() - width) / 2
    local y = (love.graphics.getHeight() - height) / 2
    
    -- Draw semi-transparent background overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw dialog box
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(dialog.title, x + 10, y + 10)
    
    if dialog.type == "input" then
        self:drawInputDialog(dialog, x, y, width, height)
    elseif dialog.type == "select" then
        self:drawSelectDialog(dialog, x, y, width, height)
    end
end

function Dialogs:drawInputDialog(dialog, x, y, width, height)
    -- Draw input box
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 10, y + 40, width - 20, 30)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", x + 10, y + 40, width - 20, 30)
    
    -- Draw input text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(dialog.input or "", x + 15, y + 45)
    
    -- Draw OK button
    local buttonWidth = 60
    local buttonHeight = 30
    local buttonX = x + (width - buttonWidth) / 2
    local buttonY = y + height - buttonHeight - 10
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("OK", buttonX + 20, buttonY + 5)
end

function Dialogs:drawSelectDialog(dialog, x, y, width, height)
    -- Draw options
    love.graphics.setColor(1, 1, 1)
    local optionHeight = 25
    local startY = y + 40
    
    for i, option in ipairs(dialog.options or {}) do
        local optionY = startY + (i-1) * optionHeight
        if optionY + optionHeight < y + height - 10 then
            if dialog.selectedOption == i then
                love.graphics.setColor(0.3, 0.5, 0.3)
                love.graphics.rectangle("fill", x + 10, optionY, width - 20, optionHeight)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(option, x + 15, optionY + 5)
        end
    end
end

return Dialogs