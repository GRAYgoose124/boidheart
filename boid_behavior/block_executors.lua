local BlockExecutors = {
    -- Movement blocks
    move = function(boid, inputs, params, dt, state)
        local speed = inputs[1] or params.speed or 100
        boid.velocity.x = boid.velocity.x + math.cos(boid.rotation) * speed * dt
        boid.velocity.y = boid.velocity.y + math.sin(boid.rotation) * speed * dt
        return {[1] = true} -- Continue flow
    end,

    turn = function(boid, inputs, params, dt, state)
        local angle = inputs[1] or params.angle or 0
        boid.rotation = boid.rotation + angle * dt
        return {[1] = true} -- Continue flow
    end,

    -- Condition blocks
    if_condition = function(boid, inputs, params, dt, state)
        local condition = inputs[1] or false
        return {
            [1] = condition,  -- True branch (flow)
            [2] = not condition  -- False branch (flow)
        }
    end,

    -- Sensor blocks
    get_distance = function(boid, inputs, params, dt, state)
        -- Get distance to nearest boid or target
        local nearestDist = math.huge
        for _, other in ipairs(boid.boidManager.boids) do
            if other ~= boid then
                local dx = other.x - boid.x
                local dy = other.y - boid.y
                local dist = math.sqrt(dx * dx + dy * dy)
                nearestDist = math.min(nearestDist, dist)
            end
        end
        return {
            [1] = true,  -- Flow
            [2] = nearestDist  -- Distance output
        }
    end,

    get_velocity = function(boid, inputs, params, dt, state)
        local speed = math.sqrt(boid.velocity.x * boid.velocity.x + boid.velocity.y * boid.velocity.y)
        return {
            [1] = true,  -- Flow
            [2] = speed  -- Speed output
        }
    end
}

return BlockExecutors