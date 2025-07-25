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


function u.highlightBiggestFruit()
	-- local farm = nil
	-- for _, f in ipairs(workspace.Farm:GetChildren()) do
	-- 	local important = f:FindFirstChild("Important")
	-- 	local data = important and important:FindFirstChild("Data")
	-- 	local owner = data and data:FindFirstChild("Owner")
	-- 	if owner and owner.Value == player.Name then
	-- 		farm = f
	-- 		break
	-- 	end
	-- end
	if not getgenv().myFarm then
		Library:Notify("No owned farm found.")
		u.removeHighlight()
		getgenv().lastBiggest = nil
		return
	end

	local plants = getgenv().myFarm:FindFirstChild("Important") and getgenv().myFarm.Important:FindFirstChild("Plants_Physical")
	if not plants then
		Library:Notify("No Plants_Physical found.")
		util.removeHighlight()
		getgenv().lastBiggest = nil
		return
	end

	local biggest, maxWeight = nil, -math.huge
	for _, plant in ipairs(plants:GetChildren()) do
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                local weightObj = fruit:FindFirstChild("Weight")
                if weightObj and tonumber(weightObj.Value) and tonumber(weightObj.Value) > maxWeight then
                    biggest = fruit
                    maxWeight = tonumber(weightObj.Value)
                end
            end
        else
            local weightObj = plant:FindFirstChild("Weight")
            if weightObj and tonumber(weightObj.Value) and tonumber(weightObj.Value) > maxWeight then
                    biggest = plant
                    maxWeight = tonumber(weightObj.Value)
                end
        end
    end


	if biggest ~= getgenv().lastBiggest then
		u.removeHighlight()
		getgenv().lastBiggest = biggest
		if biggest and biggest:IsA("Model") then
			
			local highlight = Instance.new("Highlight")
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.Adornee = biggest
            highlight.Parent = biggest
            getgenv().currentHighlight = highlight

            -- Disconnect old rainbow connection if it exists
            if rainbowConnection then
                rainbowConnection:Disconnect()
            end

            -- Start rainbow animation
            rainbowConnection = getgenv().RunService.RenderStepped:Connect(function()
                local hue = (tick() * 0.5) % 1 -- adjust speed here
                local color = Color3.fromHSV(hue, 1, 1)
                if getgenv().currentHighlight then
                    getgenv().currentHighlight.FillColor = color
                    getgenv().currentHighlight.OutlineColor = color:lerp(Color3.new(1, 1, 1), 0.2) -- make outline slightly brighter
                end
            end)


			local head = biggest:FindFirstChildWhichIsA("BasePart")
			if head then
				local value = util.CalculatePlantValue(biggest)

				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 160, 0, 60)
				bb.AlwaysOnTop = true
				bb.StudsOffset = Vector3.new(0, 3, 0)
				bb.Adornee = head
				bb.Parent = head

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255, 255, 255) -- fallback
                label.TextStrokeTransparency = 0.2
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.TextScaled = true
                label.Font = Enum.Font.FredokaOne
                label.RichText = true
                label.Text = string.format(
                    "<font color='rgb(255,255,255)'>Weight: %.2fkg</font>\n<font color='rgb(255,200,0)'>Value: %s ¢</font>",
                    maxWeight,
                    getgenv().FormatWithCommas(value)
                )
				label.Parent = bb
				getgenv().currentBillboard = bb
			end
		end
	end
end


return u
