local ProgramExecutor = {}

local BLOCK_EXECUTORS = require "boid_behavior.block_executors"

-- Store compiled programs and their runtime state
local RuntimeState = {}
RuntimeState.__index = RuntimeState

function RuntimeState.new()
    return setmetatable({
        currentBlock = 1,
        variables = {},
        stack = {},
        connections = {},
        blockStates = {} -- Store per-block state (e.g., timers, counters)
    }, RuntimeState)
end

-- Compile program into executable form
function ProgramExecutor.compile(program)
    if not program or not program.blocks then return nil end
    
    local compiled = {
        blocks = {},
        connections = {},
        inputMap = {}, -- Maps block inputs to their source blocks/outputs
        outputMap = {} -- Maps block outputs to their target blocks/inputs
    }
    
    -- Compile blocks
    for i, blockData in ipairs(program.blocks) do
        compiled.blocks[i] = {
            type = blockData.type,
            params = blockData.params or {},
            execute = BLOCK_EXECUTORS[blockData.type]
        }
    end
    
    -- Build connection maps
    for _, conn in ipairs(program.connections) do
        -- Map inputs to their sources
        if not compiled.inputMap[conn.targetBlock] then
            compiled.inputMap[conn.targetBlock] = {}
        end
        compiled.inputMap[conn.targetBlock][conn.inputIndex] = {
            block = conn.sourceBlock,
            output = conn.outputIndex
        }
        
        -- Map outputs to their targets
        if not compiled.outputMap[conn.sourceBlock] then
            compiled.outputMap[conn.sourceBlock] = {}
        end
        if not compiled.outputMap[conn.sourceBlock][conn.outputIndex] then
            compiled.outputMap[conn.sourceBlock][conn.outputIndex] = {}
        end
        table.insert(compiled.outputMap[conn.sourceBlock][conn.outputIndex], {
            block = conn.targetBlock,
            input = conn.inputIndex
        })
    end
    
    return compiled
end

-- Initialize runtime state for a boid
function ProgramExecutor.initialize(boid)
    if not boid.program then return end
    
    -- Compile program if not already compiled
    if not boid.compiledProgram then
        boid.compiledProgram = ProgramExecutor.compile(boid.program)
    end
    
    -- Create runtime state
    boid.programState = RuntimeState.new()
end

-- Execute one step of the program
function ProgramExecutor.execute(boid, program, dt)
    if not boid.compiledProgram then
        ProgramExecutor.initialize(boid)
    end
    
    local compiled = boid.compiledProgram
    local state = boid.programState
    if not compiled or not state then return end
    
    -- Execute current block
    local currentBlock = compiled.blocks[state.currentBlock]
    if not currentBlock then return end
    
    -- Prepare inputs
    local inputs = {}
    local inputMap = compiled.inputMap[state.currentBlock]
    if inputMap then
        for inputIndex, source in pairs(inputMap) do
            inputs[inputIndex] = state.variables[string.format("%d.%d", source.block, source.output)]
        end
    end
    
    -- Execute block
    local outputs = currentBlock.execute(boid, inputs, currentBlock.params, dt, state.blockStates[state.currentBlock])
    
    -- Store outputs in variables
    if outputs then
        for outputIndex, value in pairs(outputs) do
            state.variables[string.format("%d.%d", state.currentBlock, outputIndex)] = value
        end
        
        -- Follow flow connections
        local outputMap = compiled.outputMap[state.currentBlock]
        if outputMap and outputMap[1] then -- Assuming output 1 is flow
            local nextBlock = outputMap[1][1] -- Take first flow connection
            if nextBlock then
                state.currentBlock = nextBlock.block
            end
        end
    end
end

-- Cleanup when boid is destroyed
function ProgramExecutor.cleanup(boid)
    boid.compiledProgram = nil
    boid.programState = nil
end

return ProgramExecutor 