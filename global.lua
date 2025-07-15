local u= {}

function u.getBaseName(name)
    -- First try matching explicit "Name [Tag]" pattern
    local base = name:match("^(.-) %[[^%]]+%]$")
    if base then
        return base
    else
        return (name:gsub("%s*%b[]", ""):gsub("^%s*(.-)%s*$", "%1"))
    end
end


return u
