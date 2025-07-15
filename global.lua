local u= {}

function u.getBaseName(name)
    -- First try matching explicit "Name [Tag]" pattern
    local base = name:match("^(.-) %[[^%]]+%]$")
    if base then
        return base
    end
    -- Fallback: remove all bracketed sections and trim
    return (name:gsub("%s*%b[]", ""):gsub("^%s*(.-)%s*$", "%1"))
end


return u
