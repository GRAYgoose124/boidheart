local CONDITION_TYPES = {
    DISTANCE = {
        name = "Distance Check",
        color = {0.4, 0.6, 0.8},
        icon = "📏",
        inputs = {{name = "check", type = "flow"}},
        outputs = {
            {name = "true", type = "flow"},
            {name = "false", type = "flow"}
        },
        params = {
            {
                name = "target",
                type = "dropdown",
                options = {"player", "waypoint", "nearest_boid"},
                default = "player"
            },
            {
                name = "operator",
                type = "dropdown",
                options = {"<", ">", "<=", ">="},
                default = "<"
            },
            {
                name = "distance",
                type = "slider",
                min = 0,
                max = 500,
                default = 100
            }
        }
    },
    
    SPEED = {
        name = "Speed Check",
        color = {0.4, 0.6, 0.8},
        icon = "⚡",
        inputs = {{name = "check", type = "flow"}},
        outputs = {
            {name = "true", type = "flow"},
            {name = "false", type = "flow"}
        },
        params = {
            {
                name = "operator",
                type = "dropdown",
                options = {"<", ">", "<=", ">="},
                default = ">"
            },
            {
                name = "speed",
                type = "slider",
                min = 0,
                max = 200,
                default = 50
            }
        }
    },
    
    STATE = {
        name = "State Check",
        color = {0.4, 0.6, 0.8},
        icon = "🔄",
        inputs = {{name = "check", type = "flow"}},
        outputs = {
            {name = "true", type = "flow"},
            {name = "false", type = "flow"}
        },
        params = {
            {
                name = "state",
                type = "dropdown",
                options = {"flocking", "seeking", "fleeing"},
                default = "flocking"
            },
            {
                name = "operator",
                type = "dropdown",
                options = {"==", "!="},
                default = "=="
            }
        }
    },
    
    RANDOM = {
        name = "Random Chance",
        color = {0.4, 0.6, 0.8},
        icon = "🎲",
        inputs = {{name = "check", type = "flow"}},
        outputs = {
            {name = "true", type = "flow"},
            {name = "false", type = "flow"}
        },
        params = {
            {
                name = "chance",
                type = "slider",
                min = 0,
                max = 100,
                default = 50
            }
        }
    }
}

return CONDITION_TYPES 