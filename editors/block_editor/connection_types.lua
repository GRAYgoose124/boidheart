local CONNECTION_TYPES = {
    flow = {
        name = "Flow",
        color = {0.8, 0.8, 0.8},
        shape = "triangle",
        size = 8
    },
    condition = {
        name = "Condition",
        color = {0.8, 0.4, 0.4},
        shape = "circle",
        radius = 4
    },
    target = {
        name = "Target",
        color = {0.4, 0.8, 0.4},
        shape = "square",
        size = 8
    },
    number = {
        name = "Number",
        color = {0.2, 0.6, 0.0},
        shape = "circle",
        radius = 4
    },
    state = {
        name = "State",
        color = {0.8, 0.4, 0.8},
        shape = "circle",
        radius = 8
    }
}

return CONNECTION_TYPES 