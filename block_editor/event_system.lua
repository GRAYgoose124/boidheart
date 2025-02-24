local EventSystem = {}
EventSystem.__index = EventSystem

function EventSystem.new()
    local self = setmetatable({}, EventSystem)
    self.handlers = {}
    return self
end

function EventSystem:subscribe(eventName, handler)
    self.handlers[eventName] = self.handlers[eventName] or {}
    table.insert(self.handlers[eventName], handler)
end

function EventSystem:emit(eventName, ...)
    if not self.handlers[eventName] then return end
    for _, handler in ipairs(self.handlers[eventName]) do
        handler(...)
    end
end

return EventSystem 