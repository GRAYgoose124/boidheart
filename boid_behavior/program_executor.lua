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
    
    -- First pass: compile blocks and build block index mapping
    local blockIndexMap = {} -- Maps original indices to compiled indices
    local compiledIndex = 1
    
    for i, blockData in ipairs(program.blocks) do
        -- Validate block data
        if not blockData.type then
            print(string.format("Warning: Block %d has no type", i))
            goto continue
        end
        
        -- Get executor for this block type
        local executor = BLOCK_EXECUTORS[blockData.type]
        if not executor then
            print(string.format("Warning: No executor found for block type '%s'", blockData.type))
            goto continue
        end
        
        compiled.blocks[compiledIndex] = {
            type = blockData.type,
            params = blockData.params or {},
            execute = executor
        }
        
        blockIndexMap[i] = compiledIndex
        compiledIndex = compiledIndex + 1
        
        ::continue::
    end
    
    -- Build connection maps using the index mapping
    for _, conn in ipairs(program.connections or {}) do
        local sourceIndex = blockIndexMap[conn.sourceBlock]
        local targetIndex = blockIndexMap[conn.targetBlock]
        
        -- Skip if either block was not compiled
        if not sourceIndex or not targetIndex then
            goto continue
        end
        
        -- Map inputs to their sources
        if not compiled.inputMap[targetIndex] then
            compiled.inputMap[targetIndex] = {}
        end
        compiled.inputMap[targetIndex][conn.inputIndex] = {
            block = sourceIndex,
            output = conn.outputIndex
        }
        
        -- Map outputs to their targets
        if not compiled.outputMap[sourceIndex] then
            compiled.outputMap[sourceIndex] = {}
        end
        if not compiled.outputMap[sourceIndex][conn.outputIndex] then
            compiled.outputMap[sourceIndex][conn.outputIndex] = {}
        end
        table.insert(compiled.outputMap[sourceIndex][conn.outputIndex], {
            block = targetIndex,
            input = conn.inputIndex
        })
        
        ::continue::
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
    
    -- Check if block executor exists
    if not currentBlock.execute then
        print(string.format("Warning: No executor found for block type '%s'", currentBlock.type))
        return
    end
    
    -- Prepare inputs
    local inputs = {}
    local inputMap = compiled.inputMap[state.currentBlock]
    if inputMap then
        for inputIndex, source in pairs(inputMap) do
            inputs[inputIndex] = state.variables[string.format("%d.%d", source.block, source.output)]
        end
    end
    
    -- Initialize block state if needed
    if not state.blockStates[state.currentBlock] then
        state.blockStates[state.currentBlock] = {}
    end
    
    -- Execute block with error handling
    local success, outputs = pcall(currentBlock.execute, boid, inputs, currentBlock.params, dt, state.blockStates[state.currentBlock])
    if not success then
        print(string.format("Error executing block type '%s': %s", currentBlock.type, outputs))
        return
    end
    
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