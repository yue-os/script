local u= {}

function u.getBaseName(name)
    -- Remove all bracketed info like [X1], [Age 16], [2.78 KG]
    name = name:gsub("%s*%b[]", "")
    
    -- Remove trailing inline quantity like " x7", " x5"
    name = name:gsub("%s[xX]%d+$", "")

    -- Final trim
    return name:match("^%s*(.-)%s*$")
end

function u.isSeed(toolName)
    local base = u.getBaseName(toolName)
    return base:lower():find("seed") ~= nil
end

function u.isSprinkler(toolName)
    local base = u.getBaseName(toolName)
    return base:lower():find("sprinkler") ~= nil
end

return u
