-- main.lua
local Player = require "player"
local Boid = require "boid"
local BoidManager = require "boid_manager"

local player
local boidManager
local selecting = false

function love.load()
    love.window.setTitle("Boids Follower")
    love.window.setMode(1920, 1080)
    love.window.setFullscreen(true)
    
    player = Player.new(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    -- Max: ~1000 boids currently due to 1024 register shader limit.
    -- TODO/FIX: Could only pass boids on screen, and up to a limit, dropping the farthest from the player?
    boidManager = BoidManager.new(501)
    
    -- Create a group of boids that follow the player
    local boid_leader = nil
    for i = 1, ((boidManager.maxBoids-1)/2) do
        local x = player.x + math.random(-250, 250)
        local y = player.y + math.random(-250, 250)
        local boid = Boid.new(x, y, player, boidManager)
        if not boid_leader then
            boid_leader = boid
        end
        local boid_follower = Boid.new(x, y, boid_leader, boidManager)
        if i%3 == 0 then
            boid_leader = boid_follower
        end
        boidManager:add(boid)
        boidManager:add(boid_follower)
    end
    boidManager:add(boid_leader)

end

function love.update(dt)
    player:update(dt)
    boidManager:update(dt)
end

function love.draw()
    player:draw()
    boidManager:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print([[
Use arrow keys or WASD to move 

Controls:
WASD/Arrows: Move
Space: Toggle selection mode
Left click: Place waypoint for selected boids
    ]], 10, 10)
end

function love.resize(w, h)
    if boidManager then
        boidManager.shader:send("resolution", {w, h})
        boidManager.canvas = love.graphics.newCanvas()  -- Recreate canvas at new size
    end
end 

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        selecting = not selecting
        if selecting then
            local x, y = love.mouse.getPosition()
            boidManager:startSelection(x, y)
        else
            boidManager:endSelection()
        end
    end
end

function love.mousemoved(x, y)
    if selecting then
        boidManager.selectionX = x
        boidManager.selectionY = y
        boidManager:updateSelection(x, y)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and not selecting then
        -- Add waypoint for selected boids
        for _, boid in ipairs(boidManager.boids) do
            if boid.selected and boid.groupId then
                boidManager.waypointManager:addWaypoint(boid.groupId, x, y)
            end
        end
    end
end