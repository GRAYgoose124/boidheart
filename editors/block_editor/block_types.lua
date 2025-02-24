local BLOCK_TYPES = {
    Triggers = {
        ON_START = {
            name = "On Start",
            color = {0.2, 0.6, 0.2},
            icon = "▶",
            outputs = {"start"},
            params = {}
        },
        ON_COLLISION = {
            name = "On Collision",
            color = {0.2, 0.6, 0.2},
            icon = "⚡",
            outputs = {"collision"},
            params = {
                {
                    name = "with",
                    type = "dropdown",
                    options = {"player", "wall", "other_boid"},
                    default = "player"
                }
            }
        },
        ON_TIMER = {
            name = "On Timer",
            color = {0.2, 0.6, 0.2},
            icon = "⏲",
            outputs = {"tick"},
            params = {
                {
                    name = "interval",
                    type = "slider",
                    min = 0.1,
                    max = 10,
                    default = 1
                }
            }
        }
    },
    
    Control = {
        IF = {
            name = "If Condition",
            color = {0.4, 0.6, 0.8},
            icon = "?",
            inputs = {"condition", "true"},
            outputs = {"false"},
            params = {
                {
                    name = "condition",
                    type = "dropdown",
                    options = {"DISTANCE", "SPEED", "STATE", "RANDOM"},
                    default = "DISTANCE"
                }
            }
        },
        LOOP = {
            name = "Loop",
            color = {0.4, 0.6, 0.8},
            icon = "↻",
            inputs = {"in"},
            outputs = {"out"},
            params = {
                {
                    name = "iterations",
                    type = "slider",
                    min = 1,
                    max = 100,
                    default = 10
                }
            }
        }
    },
    
    Movement = {
        SEEK = {
            name = "Seek Target",
            color = {0.8, 0.4, 0.4},
            icon = "→",
            inputs = {"target"},
            outputs = {"next"},
            params = {
                {
                    name = "speed",
                    type = "slider",
                    min = 0,
                    max = 300,
                    default = 150
                }
            }
        },
        FLEE = {
            name = "Flee From",
            color = {0.8, 0.4, 0.4},
            icon = "←",
            inputs = {"target"},
            outputs = {"next"},
            params = {
                {
                    name = "speed",
                    type = "slider",
                    min = 0,
                    max = 300,
                    default = 150
                }
            }
        },
        WANDER = {
            name = "Wander",
            color = {0.8, 0.4, 0.4},
            icon = "~",
            inputs = {"in"},
            outputs = {"out"},
            params = {
                {
                    name = "speed",
                    type = "slider",
                    min = 0,
                    max = 300,
                    default = 100
                },
                {
                    name = "radius",
                    type = "slider",
                    min = 10,
                    max = 200,
                    default = 50
                }
            }
        }
    },
    
    Behavior = {
        FLOCK = {
            name = "Flock",
            color = {0.4, 0.8, 0.4},
            icon = "⋈",
            inputs = {"in"},
            outputs = {"out"},
            params = {
                {
                    name = "cohesion",
                    type = "slider",
                    min = 0,
                    max = 2,
                    default = 1
                },
                {
                    name = "separation",
                    type = "slider",
                    min = 0,
                    max = 2,
                    default = 1
                },
                {
                    name = "alignment",
                    type = "slider",
                    min = 0,
                    max = 2,
                    default = 1
                }
            }
        },
        AVOID = {
            name = "Avoid Obstacles",
            color = {0.4, 0.8, 0.4},
            icon = "↯",
            inputs = {"in"},
            outputs = {"out"},
            params = {
                {
                    name = "radius",
                    type = "slider",
                    min = 10,
                    max = 200,
                    default = 50
                },
                {
                    name = "force",
                    type = "slider",
                    min = 0,
                    max = 2,
                    default = 1
                }
            }
        }
    },

    State = {
        SET_STATE = {
            name = "Set State",
            color = {0.6, 0.4, 0.8},
            icon = "S",
            inputs = {"in"},
            outputs = {"out"},
            params = {
                {
                    name = "state",
                    type = "dropdown",
                    options = {"flocking", "seeking", "fleeing", "wandering"},
                    default = "flocking"
                }
            }
        },
        WAIT = {
            name = "Wait",
            color = {0.6, 0.4, 0.8},
            icon = "⌛",
            inputs = {"in"},
            outputs = {"out"},
            params = {
                {
                    name = "duration",
                    type = "slider",
                    min = 0.1,
                    max = 10,
                    default = 1
                }
            }
        }
    }
}

return BLOCK_TYPES 