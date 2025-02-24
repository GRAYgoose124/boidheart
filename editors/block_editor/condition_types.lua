local CONDITION_TYPES = {
    DISTANCE = {
        name = "Distance to...",
        options = {"player", "waypoint", "nearest_boid"},
        operators = {"<", ">", "<=", ">="},
        defaultValue = 100
    },
    SPEED = {
        name = "Current Speed",
        operators = {"<", ">", "<=", ">="},
        defaultValue = 50
    },
    STATE = {
        name = "State Check",
        options = {"flocking", "seeking", "fleeing"},
        operators = {"==", "!="},
        defaultValue = "flocking"
    },
    RANDOM = {
        name = "Random Chance",
        operators = {"%"},
        defaultValue = 50
    }
}

return CONDITION_TYPES 