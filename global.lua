-- ReplicatedStorage > ToolUtils (ModuleScript)

local u = {}

function u.getBaseName(name)
    name = name:gsub("%s*%b[]", "")
    name = name:gsub("%s[xX]%d+$", "")
    name = name:gsub("%sSeed$", "") -- Remove "Seed" only if at the end
    return name:match("^%s*(.-)%s*$")
end

function u.isSeed(toolName)
    return toolName:lower():find("seed") ~= nil
end

function u.isSprinkler(toolName)
    return u.getBaseName(toolName):lower():find("sprinkler") ~= nil
end


function u.keysOf(dict)
    local list = {}
    if type(dict) ~= "table" then
        warn("util.keysOf: Expected table, got " .. typeof(dict))
        return list
    end
    for k, v in pairs(dict) do
        if v then
            table.insert(list, k)
        end
    end
    return list
end

return u
