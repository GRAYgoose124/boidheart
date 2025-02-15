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
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- If close enough to current waypoint, cycle to next
    if distance < 50 then
        table.remove(path, 1)
        table.insert(path, waypoint)
        return path[1]
    end
    
    return waypoint
end

return WaypointManager 