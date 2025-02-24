local Entity = require "entity"
local BLOCK_TYPES = require "editors.block_editor.block_types"

local Boid = setmetatable({}, {__index = Entity})
Boid.__index = Boid

function Boid.new(x, y, leader, manager)
    local self = Entity.new(x, y)
    setmetatable(self, Boid)
    self.leader = leader
    self.boidManager = manager
    self.groupId = nil  -- For waypoint following
    self.selected = false

    -- physics
    self.maxSpeed = 150
    self.maxForce = 300
    self.vx = math.random(-50, 50)
    self.vy = math.random(-50, 50)
    
    -- Flocking parameters
    self.separationRadius = 30
    self.separationWeight = 1.0
    self.neighborRadius = 150
    self.cohesionWeight = 0.5
    self.alignmentWeight = 0.5

    self.behaviors = {}

    return self
end

function Boid:update(dt)
    if self.program then
        self:executeProgram(dt)
    end
    -- Execute behaviors with cooldown and state management
    for triggerType, behaviorData in pairs(self.behaviors or {}) do
        local state = behaviorData.state
        local actions = behaviorData.actions
        
        -- Skip if waiting
        if state.waitUntil > state.currentTime then
            state.currentTime = state.currentTime + dt
            goto continue
        end
        
        -- Check cooldowns
        if state.cooldown > 0 then
            state.cooldown = state.cooldown - dt
            goto continue
        end
        
        local shouldExecute = false
        
        if triggerType == "ALWAYS" then
            shouldExecute = true
        elseif triggerType == "ON_WAYPOINT" then
            -- Check if near current waypoint
            if self.groupId then
                local waypoint = self.boidManager.waypointManager:getNextWaypoint(self.groupId, self.x, self.y)
                if waypoint then
                    local dx = waypoint.x - self.x
                    local dy = waypoint.y - self.y
                    shouldExecute = (dx * dx + dy * dy) < 150
                end
            end
        elseif triggerType == "NEAR_PLAYER" then
            local dx = self.boidManager.player.x - self.x
            local dy = self.boidManager.player.y - self.y
            local distSq = dx * dx + dy * dy
            -- Fix: Check if actions[1] and its params exist before accessing
            local targetDist = (actions[1] and actions[1].params and actions[1].params.distance) or 100
            shouldExecute = distSq < (targetDist * targetDist)
        end
        
        if shouldExecute and state.active then
            local cooldown = nil
            for _, action in ipairs(actions) do
                if action.type == "RANDOM" then
                    -- Handle random path selection
                    local weights = action.params.weights or "1,1,1"
                    state.currentPath = "RANDOM:" .. weights
                elseif action.type == "BRANCH" then
                    -- Existing branch handling
                    state.currentPath = self.boidManager.blockEditor:evaluateCondition(action.params.condition, self)
                elseif action.type == "WAIT" then
                    state.waitUntil = state.currentTime + (action.params.duration or 1.0)
                    break
                elseif action.type == "TOGGLE_BEHAVIOR" then
                    local targetState = self.behaviors[action.params.behavior]
                    if targetState then
                        targetState.state.active = action.params.enabled
                    end
                else
                    self:executeAction(action)
                    cooldown = action.cooldown or 0
                end
            end
            
            state.cooldown = cooldown
        end
        
        ::continue::
    end

    local targetX, targetY
    
    -- Check for waypoints first
    if self.groupId and self.boidManager.waypointManager then
        local waypoint = self.boidManager.waypointManager:getNextWaypoint(self.groupId, self.x, self.y)
        if waypoint then
            targetX, targetY = waypoint.x, waypoint.y
        end
    end
    
    -- If no waypoint, follow leader
    if not targetX and self.leader then
        targetX, targetY = self.leader.x, self.leader.y
    end
    
    if not targetX then return end -- No target to follow

    -- Update steering behavior using targetX, targetY instead of leader position
    local desiredX = targetX - self.x
    local desiredY = targetY - self.y
    local distance = math.sqrt(desiredX^2 + desiredY^2)
    
    if distance > 0 then
        desiredX = desiredX / distance * self.maxSpeed
        desiredY = desiredY / distance * self.maxSpeed
    end

    local steerX = desiredX - self.vx
    local steerY = desiredY - self.vy

    -- Add flocking behaviors
    local sepX, sepY = 0, 0
    local cohX, cohY = 0, 0
    local aliX, aliY = 0, 0
    local neighborCount = 0

    for _, other in ipairs(self.boidManager.boids) do
        if other ~= self then
            local d, dx, dy = self:getDistance(other)
            
            -- Separation
            if d < self.separationRadius then
                sepX = sepX - dx*d
                sepY = sepY - dy*d
            end
            
            -- Cohesion and Alignment
            if d < self.neighborRadius then
                cohX = cohX + other.x
                cohY = cohY + other.y
                aliX = aliX + other.vx
                aliY = aliY + other.vy
                neighborCount = neighborCount + 1
            end
        end
    end

    -- Apply flocking forces
    if neighborCount > 0 then
        -- Cohesion
        cohX = (cohX / neighborCount - self.x) * self.cohesionWeight
        cohY = (cohY / neighborCount - self.y) * self.cohesionWeight
        
        -- Alignment
        aliX = (aliX / neighborCount - self.vx) * self.alignmentWeight
        aliY = (aliY / neighborCount - self.vy) * self.alignmentWeight
        
        steerX = steerX + cohX + aliX
        steerY = steerY + cohY + aliY
    end

    -- Apply separation
    steerX = steerX + sepX * self.separationWeight
    steerY = steerY + sepY * self.separationWeight

    -- Limit steering force
    local steerMag = math.sqrt(steerX^2 + steerY^2)
    if steerMag > self.maxForce then
        steerX = steerX / steerMag * self.maxForce
        steerY = steerY / steerMag * self.maxForce
    end

    -- Apply steering force
    self:applyForce(steerX * dt, steerY * dt)
    self:limitVelocity()
    self:move(dt)
end

function Boid:draw()
    if self.selected then
        love.graphics.setColor(0, 1, 1)
        love.graphics.circle("line", self.x, self.y, 8)
        if self.groupId then
            love.graphics.print(tostring(self.groupId), self.x, self.y)
        end
    end
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", self.x, self.y, 5)
end

function Boid:executeAction(action)
    if action.type == "FOLLOW_PLAYER" then
        local weight = action.params.weight or 1.0
        local dx = self.boidManager.player.x - self.x
        local dy = self.boidManager.player.y - self.y
        self:applyForce(dx * weight, dy * weight)
    
    elseif action.type == "FLOCK" then
        local sep = action.params.separation or 1.0
        local coh = action.params.cohesion or 1.0
        local ali = action.params.alignment or 1.0
        
        self.separationWeight = sep
        self.cohesionWeight = coh
        self.alignmentWeight = ali
    
    elseif action.type == "SET_SPEED" then
        self.maxSpeed = action.params.speed or 150
    end
end

function Boid:evaluateCondition(condition)
    if type(condition) ~= "table" then return false end
    
    if condition.type == "DISTANCE" then
        local target
        if condition.target == "player" then
            target = self.boidManager.player
        elseif condition.target == "waypoint" then
            target = self.boidManager.waypointManager:getNextWaypoint(self.groupId, self.x, self.y)
        elseif condition.target == "nearest_boid" then
            target = self:findNearestBoid()
        end
        
        if target then
            local dist = math.sqrt((target.x - self.x)^2 + (target.y - self.y)^2)
            return self:compareValue(dist, condition.op, tonumber(condition.value) or 100)
        end
    elseif condition.type == "SPEED" then
        local speed = math.sqrt(self.vx^2 + self.vy^2)
        return self:compareValue(speed, condition.op, condition.value)
        
    elseif condition.type == "STATE" then
        local state = self:getState(condition.options)
        return self:compareValue(state, condition.op, condition.value)
        
    elseif condition.type == "RANDOM" then
        return math.random() * 100 < condition.value
    end
    return false
end

function Boid:executeProgram(dt)
    if not self.program then return end
    
    -- Create a map of block results
    local blockResults = {}
    
    -- Execute blocks and store their results
    for i, block in ipairs(self.program.blocks) do
        local blockType = BLOCK_TYPES[block.type]
        if blockType and blockType.execute then
            blockResults[i] = blockType.execute(self, block.params, dt)
        end
    end
    
    -- Process connections
    for _, conn in ipairs(self.program.connections) do
        local sourceResult = blockResults[conn.sourceBlock]
        local targetBlock = self.program.blocks[conn.targetBlock]
        
        -- Only execute target if source condition is met
        if sourceResult and targetBlock then
            local blockType = BLOCK_TYPES[targetBlock.type]
            if blockType and blockType.execute then
                blockType.execute(self, targetBlock.params, dt)
            end
        end
    end
end

return Boid 