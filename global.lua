local u= {}

function u.getBaseName(name)
    return name:match("^(.-) %[[^%]]+%]$") or (name:gsub("%s*%b[]", ""):gsub("^%s*(.-)%s*$", "%1"))
end

return u
