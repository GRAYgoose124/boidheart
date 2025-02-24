local SelectionManager = {}
SelectionManager.__index = SelectionManager

function SelectionManager.new(boidManager)
    local self = setmetatable({}, SelectionManager)
    self.selecting = false
    self.selectionX = 0
    self.selectionY = 0
    self.selectionRadius = 100
    self.currentGroupId = 1
    self.groups = {} -- Maps groupId to array of boids
    self.boidManager = boidManager  -- Store reference to boidManager
    return self
end

function SelectionManager:startSelection(x, y)
    self.selecting = true
    self.selectionX = x
    self.selectionY = y
end

function SelectionManager:endSelection()
    self.selecting = false
    local selectedBoids = self:getSelectedBoids()
    
    if #selectedBoids > 0 then
        local newGroupId = self:createNewGroup(selectedBoids)
        return newGroupId
    end
    return nil
end

function SelectionManager:updateSelection(x, y, boids)
    self.selectionX = x
    self.selectionY = y
    
    for _, boid in ipairs(boids) do
        local dx = boid.x - x
        local dy = boid.y - y
        local distance = math.sqrt(dx * dx + dy * dy)
        boid.selected = distance <= self.selectionRadius
    end
end

function SelectionManager:createNewGroup(boids)
    local newGroupId = #self.groups + 1
    self.groups[newGroupId] = {}
    
    for _, boid in ipairs(boids) do
        boid.groupId = newGroupId
        table.insert(self.groups[newGroupId], boid)
    end
    
    self.currentGroupId = newGroupId
    return newGroupId
end

function SelectionManager:cycleGroupSelection(boids)
    self.currentGroupId = self.currentGroupId + 1
    if self.currentGroupId > #self.groups then
        self.currentGroupId = 0
    end
    
    -- Update boid selections
    for _, boid in ipairs(boids) do
        boid.selected = (boid.groupId == self.currentGroupId)
    end
    
    return self.currentGroupId
end

function SelectionManager:getSelectedBoids()
    local selected = {}
    -- First check boids in existing groups
    for groupId, boids in pairs(self.groups) do
        for _, boid in ipairs(boids) do
            if boid.selected then
                table.insert(selected, boid)
            end
        end
    end
    
    -- If no selected boids found in groups, check all boids
    -- This handles boids selected via Tab cycling
    if #selected == 0 then
        local allBoids = self.boidManager.boids  -- We'll need to pass boidManager in new()
        for _, boid in ipairs(allBoids) do
            if boid.selected then
                table.insert(selected, boid)
            end
        end
    end
    
    return selected
end

function SelectionManager:draw()
    if self.selecting then
        love.graphics.setColor(0, 1, 1, 0.3)
        love.graphics.circle("line", self.selectionX, self.selectionY, self.selectionRadius)
    end
end

return SelectionManager 