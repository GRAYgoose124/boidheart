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
            -- Draw dropdown box
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", x, y, width, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(param.name .. ": " .. tostring(value), x + 5, y + 2)
        end,
        
        handleInput = function(param, value, x, y, width, editor)
            local mx, my = love.mouse.getPosition()
            if my >= y and my <= y + 20 and mx >= x and mx <= x + width then
                if love.mouse.isDown(1) and not editor.activeDropdown then
                    editor.activeDropdown = {
                        param = param,
                        x = x,
                        y = y + 20,
                        width = width,
                        options = param.options,
                        currentValue = value,
                        callback = function(selected) return selected end
                    }
                end
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