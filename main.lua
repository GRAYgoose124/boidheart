-- main.lua
local Player = require "player"
local Boid = require "boid"
local BoidManager = require "boid_manager"

local player
local boidManager

function love.load()
    love.window.setTitle("Boids Follower")
    love.window.setMode(800, 600)
    
    player = Player.new(400, 300)
    boidManager = BoidManager.new()
    
    -- Create a group of boids that follow the player
    for i = 1, 20 do
        local x = player.x + math.random(-50, 50)
        local y = player.y + math.random(-50, 50)
        local boid = Boid.new(x, y, player, boidManager)
        boidManager:add(boid)
    end
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