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

return Serde