local PARAMETER_TYPES = {
    slider = {
        draw = function(param, value, x, y, width)
            -- Draw slider background
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", x, y, width, 10)
            
            -- Draw slider value
            local percentage = (value - param.min) / (param.max - param.min)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("fill", x, y, width * percentage, 10)
            
            -- Draw label
            love.graphics.print(string.format("%s: %.1f", param.name, value), x, y - 15)
        end,
        
        handleInput = function(param, value, x, y, width)
            local mx, my = love.mouse.getPosition()
            if my >= y and my <= y + 10 and mx >= x and mx <= x + width then
                if love.mouse.isDown(1) then
                    local percentage = (mx - x) / width
                    return param.min + (percentage * (param.max - param.min))
                end
            end
            return value
        end
    },
    
    dropdown = {
        draw = function(param, value, x, y, width)
            -- Draw dropdown background
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", x, y, width, 20)
            
            -- Draw current value and label
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(param.name .. ": " .. tostring(value), x + 5, y + 2)
            
            -- Draw dropdown arrow
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.polygon("fill",
                x + width - 15, y + 5,
                x + width - 5, y + 5,
                x + width - 10, y + 15)
        end,
        
        handleInput = function(param, value, x, y, width, editor)
            local mx, my = love.mouse.getPosition()
            
            -- Toggle dropdown on click
            if my >= y and my <= y + 20 and mx >= x and mx <= x + width then
                if love.mouse.isDown(1) and not param.clicked then
                    param.clicked = true
                    -- Toggle dropdown
                    if editor.uiManager.activeDropdown and editor.uiManager.activeDropdown.param == param then
                        editor.uiManager.activeDropdown = nil
                    else
                        editor.uiManager.activeDropdown = {
                            x = x,
                            y = y + 20,
                            width = width,
                            options = param.options,
                            currentValue = value,
                            param = param
                        }
                    end
                end
            elseif editor.uiManager.activeDropdown and editor.uiManager.activeDropdown.param == param then
                -- Handle dropdown selection
                local handled, newValue = editor.uiManager:handleMousePressed(mx, my, 1)
                if handled and newValue then
                    return newValue
                end
            end
            
            if not love.mouse.isDown(1) then
                param.clicked = false
            end
            
            return value
        end
    },
    
    boolean = {
        draw = function(param, value, x, y, width)
            -- Draw checkbox
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", x, y, 20, 20)
            if value then
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.rectangle("fill", x + 4, y + 4, 12, 12)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(param.name, x + 25, y + 2)
        end,
        
        handleInput = function(param, value, x, y)
            local mx, my = love.mouse.getPosition()
            if my >= y and my <= y + 20 and mx >= x and mx <= x + 20 then
                if love.mouse.isDown(1) and not param.clicked then
                    param.clicked = true
                    return not value
                end
            elseif not love.mouse.isDown(1) then
                param.clicked = false
            end
            return value
        end
    }
}

return PARAMETER_TYPES 