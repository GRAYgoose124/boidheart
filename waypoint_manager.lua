local WaypointManager = {}
WaypointManager.__index = WaypointManager

function WaypointManager.new()
    local self = setmetatable({}, WaypointManager)
    self.paths = {}  -- Maps boid groups to their waypoint paths
    self.currentGroupId = 1
    return self
end

function WaypointManager:createPath(groupId)
    self.paths[groupId] = self.paths[groupId] or {}
end

function WaypointManager:addWaypoint(groupId, x, y)
    if not self.paths[groupId] then
        self:createPath(groupId)
    end
    table.insert(self.paths[groupId], {x = x, y = y})
end

function WaypointManager:getNextWaypoint(groupId, currentX, currentY)
    local path = self.paths[groupId]
    if not path or #path == 0 then return nil end
    
    local waypoint = path[1]
    local dx = waypoint.x - currentX
    local dy = waypoint.y - currentY
    local distance = dx * dx + dy * dy
    
    -- If close enough to current waypoint, cycle to next
    if distance < 150 then
        table.remove(path, 1)
        table.insert(path, waypoint)
        return path[1]
    end
    
    return waypoint
end

function WaypointManager:clearPath(groupId)
    self.paths[groupId] = {}
end

function WaypointManager:draw()
    for groupId, path in pairs(self.paths) do
        love.graphics.setColor(1, 1, 0, 0.5)
        for i, waypoint in ipairs(path) do
            love.graphics.circle("fill", waypoint.x, waypoint.y, 5)
            if i > 1 then
                local prev = path[i-1]
                love.graphics.line(prev.x, prev.y, waypoint.x, waypoint.y)
            end
            if self.currentGroupId == groupId then
                love.graphics.circle("line", waypoint.x, waypoint.y, 10)
            end
        end
    end
end


function WaypointManager:cycleGroupId()
    self.currentGroupId = self.currentGroupId + 1
    if self.currentGroupId > #self.paths then
        self.currentGroupId = 0
    end
end

return WaypointManager 