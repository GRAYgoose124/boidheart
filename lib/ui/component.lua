-- Move from block_editor/ui/component.lua
local Component = {}
Component.__index = Component

function Component.new()
    local self = setmetatable({}, Component)
    self.visible = true
    self.children = {}
    return self
end

function Component:draw() end
function Component:update(dt) end
function Component:handleMousePressed(x, y, button) return false end
function Component:handleMouseReleased(x, y, button) return false end
function Component:handleMouseMoved(x, y, dx, dy) return false end
function Component:handleKeyPressed(key) return false end
function Component:handleTextInput(text) return false end

return Component 