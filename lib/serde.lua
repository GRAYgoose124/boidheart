local Serde = {}
Serde.__index = Serde

function Serde:serializeTable(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        local key = type(k) == "number" and k or string.format("[%q]", k)
        if type(v) == "table" then
            result = result .. string.format("%s=%s,", key, self:serializeTable(v))
        elseif type(v) == "string" then
            result = result .. string.format("%s=%q,", key, v)
        else
            result = result .. string.format("%s=%s,", key, tostring(v))
        end
    end
    return result .. "}"
end

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end


return Serde