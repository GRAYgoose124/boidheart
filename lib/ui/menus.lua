local Menus = {}
Menus.__index = Menus

function Menus:drawDropdownMenu(dropdown)
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

return Menus
