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

local backpack = game.Players.LocalPlayer:WaitForChild("Backpack")
function u.getFruitCount()
    local count = 0
    for _, v in pairs(backpack:GetChildren()) do
        if v:FindFirstChild("Weight") and v:FindFirstChild("Variant") then
            count = count + 1
        end
    end
    return count
end


function u.removeHighlight()
    if getgenv().currentHighlight then
        getgenv().currentHighlight:Destroy()
        getgenv().currentHighlight = nil
    end
    if getgenv().currentBillboard then
        getgenv().currentBillboard:Destroy()
        getgenv().currentBillboard = nil
    end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local MutationHandler = require(ReplicatedStorage:WaitForChild("Mutation_Handler"))
-- local ItemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Item_Module"))
function u.CalculatePlantValue(plant)
	local itemString = plant:FindFirstChild("Item_String")
	local itemName = itemString and itemString.Value or plant.Name

	local variant = plant:FindFirstChild("Variant")
	if not variant then return 0 end

	local weight = plant:FindFirstChild("Weight")
	if not weight then return 0 end

	local baseData = getgenv().ItemModule.Return_Data(itemName)
	if not baseData or #baseData < 3 then
		warn("Invalid ItemData for:", itemName)
		return 0
	end

	local variantMultiplier = getgenv().ItemModule.Return_Multiplier(variant.Value)
	local valueMulti = getgenv().MutationHandler:CalcValueMulti(plant)
	local clamp = math.clamp(weight.Value / baseData[2], 0.95, 1e8)

	return math.round(baseData[3] * valueMulti * variantMultiplier * (clamp * clamp))
end

return u
