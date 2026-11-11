--!nonstrict

local util = {}

local romanMap = {
    {50, "L"},
    {40, "xL"},
    {10, "X"},
    {9, "IX"},
    {5, "V"},
    {4, "IV"},
    {1, "I"},
}

function util.toRoman(n)
    n = tonumber(n)
    if not n then
    return tostring(n or "--")
end

    n = math.floor(n)
    if n <= 0 then 
        return tostring(n)
    end
    
    if n > 50 then 
        return tostring(n)
    end 

    local result = {}
    local remaining = n

    for _, entry in ipairs(romanMap) do 
        local value = entry[1]
        local symbol = entry [2]
        while remaining >= value do 
            table.insert(result, symbol)
            remaining -= value 
        end
    end
    return table.concat(result)
end

function util.clearClones(parent, name)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name then
            child:Destroy()
        end
    end
end

return util
