-- main.lua
local Player = require "player"
local Boid = require "boid"
local BoidManager = require "boid_manager"

local player
local boidManager

function love.load()
    love.window.setTitle("Boids Follower")
    love.window.setMode(1920, 1080)
    love.window.setFullscreen(true)
    
    player = Player.new(400, 300)
    boidManager = BoidManager.new()
    
    -- Create a group of boids that follow the player
    local boid_leader = nil
    for i = 1, 200 do
        local x = player.x + math.random(-50, 50)
        local y = player.y + math.random(-50, 50)
        local boid = Boid.new(x, y, player, boidManager)
        if not boid_leader then
            boid_leader = boid
        end
        local boid_follower = Boid.new(x, y, boid_leader, boidManager)
        boid_leader = boid_follower
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
    love.graphics.print("Use arrow keys or WASD to move", 10, 10)
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
    end
end