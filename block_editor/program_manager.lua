local Serde = require "lib.serde"
local ProgramExecutor = require "boid_behavior.program_executor"

local ProgramManager = {}
ProgramManager.__index = ProgramManager

function ProgramManager.new(events)
    local self = setmetatable({}, ProgramManager)
    self.events = events
    self.programs = {}
    self.currentProgram = nil
    return self
end

function ProgramManager:loadProgram(name)
    -- Try to load from memory first
    local program = self.programs[name]
    
    -- If not in memory, try to load from file
    if not program then
        local chunk, err = love.filesystem.load("programs/" .. name .. ".lua")
        if chunk then
            program = chunk()
            self.programs[name] = program
            self.events:emit("program_loaded", program)
        else
            print("Failed to load program:", err)
            self.events:emit("program_load_failed", name, err)
            return nil
        end
    end
    
    self.currentProgram = name
    return program
end

function ProgramManager:saveProgram(program, name)
    -- Create programs directory if it doesn't exist
    love.filesystem.createDirectory("programs")
    
    name = name or program.name or "unnamed_program"
    program.name = name
    
    -- Save to programs table
    self.programs[name] = program
    
    -- Serialize and save to file
    local programString = "return " .. Serde:serializeTable(program)
    local success, message = love.filesystem.write("programs/" .. name .. ".lua", programString)
    
    if not success then
        print("Failed to save program:", message)
        self.events:emit("program_save_failed", name, message)
        return false
    end
    
    self.events:emit("program_saved", name)
    return true
end

function ProgramManager:applyProgramToGroup(program, groupId, boidManager)
    if not program or not groupId then return end
    
    local boids = boidManager.selectionManager.groups[groupId]
    if not boids then return end
    
    for _, boid in ipairs(boids) do
        -- Clean up any existing program state
        if boid.program then
            self:cleanupProgram(boid)
        end
        
        -- Apply new program
        boid.program = program
        self:initializeProgram(boid)
    end
    
    self.events:emit("program_applied", groupId)
end

function ProgramManager:initializeProgram(boid)
    if not boid.program then return end
    ProgramExecutor.initialize(boid)
end

function ProgramManager:cleanupProgram(boid)
    if not boid.program then return end
    ProgramExecutor.cleanup(boid)
end

function ProgramManager:updateBoid(boid, dt)
    if not boid.program then return end
    ProgramExecutor.execute(boid, boid.program, dt)
end

return ProgramManager 