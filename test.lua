local u = {}
local Players = game.Players
local player = game.Players.LocalPlayer
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local byte_net_reliable = ReplicatedStorage:WaitForChild("ByteNetReliable")
local autoSubmit = false
local fruitThreshold = 10
local autoSell = false
local highlightToggle = false
local currentHighlight = nil
local currentBillboard = nil
-- local lastBiggest = nil
local noclipEnabled = false
local speedwalkEnabled = false
local speedValue = 16
local noclipConn, speedConn
local savedPosition = savedPosition
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local ItemModule = require(ReplicatedStorage:WaitForChild("Item_Module"))
local MutationHandler = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MutationHandler"))
local FormatWithCommas = require(ReplicatedStorage.Modules:WaitForChild("CommaFormatNumber"))
local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
local giftingService = require(ReplicatedStorage.Modules.PetServices.PetGiftingService)
local activePets = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)
local petRegistry = require(ReplicatedStorage.Data.PetRegistry)
local PetEggs = petRegistry.PetEggs
local MIN_DISTANCE = petRegistry.PetConfig.PET_GIFTING_CONFIG.MINIMUM_DISTANCE_FOR_GIFTING
local seedData = require(ReplicatedStorage.Data.SeedData)
local hum = character:FindFirstChildOfClass("Humanoid")
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local character = player.Character or player.CharacterAdded:Wait()
getgenv().petHungerList = getgenv().petHungerList or {}
-- local getgenv().Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yue-os/ObsidianUi/refs/heads/main/getgenv().Library.lua"))()


-- getgenv().gag = loadstring(game:HttpGet("https://raw.githubusercontent.com/yue-os/script/refs/heads/main/gag", true))()

function u.myFarm()
	local player = game:GetService("Players").LocalPlayer
	for _, farm in ipairs(workspace:WaitForChild("Farm"):GetChildren()) do
		local owner = farm:WaitForChild("Important"):WaitForChild("Data"):FindFirstChild("Owner")
		if owner and tostring(owner.Value) == tostring(player) then
			return farm
		end
	end
	return nil
end
-- local myFarm = u.myFarm()


-- ========== BASIC UTILS ==========
-- function u.getBaseName(itemName)
-- 	local base = itemName:match("^(.-) %[[^%]]+%]$")
-- 	return base or itemName
-- end

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


u.inventory_enums = {
	["OWNER"] = "a",
	["ITEM_TYPE"] = "b",
	["ITEM_UUID"] = "c",
	["Favorite"] = "d",
	["Uses"] = "e",
	["ItemName"] = "f",
	["Rarity"] = "g",
	["EggName"] = "h",
	["CrateType"] = "i",
	["PotType"] = "j",
	["LinkedPlayerID"] = "k",
	["SprayType"] = "l",
	["SprayMutationName"] = "m",
	["Type"] = "n"
}

u.item_types = {
	["Seed Pack"] = "a",
	["Trowel"] = "b",
	["PetEgg"] = "c",
	["Sprinkler"] = "d",
	["Night Staff"] = "e",
	["Harvest Tool"] = "f",
	["Pollen Radar"] = "g",
	["Favorite Tool"] = "h",
	["Lightning Rod"] = "i",
	["Holdable"] = "j",
	["Star Caller"] = "k",
	["Pet"] = "l",
	["FriendshipPot"] = "m",
	["Seed"] = "n",
	["Watering Can"] = "o",
	["Nectar Staff"] = "p",
	["Recall Wrench"] = "q",
	["CosmeticCrate"] = "r",
	["SprayBottle"] = "s"
}

u.item_codes = {}
for k, v in pairs(u.item_types) do
	u.item_codes[v] = k
end

function u.keysOf(dict)
	local list = {}
	if type(dict) ~= "table" then
		warn("keysOf: Expected table, got " .. typeof(dict))
		return list
	end
	for k, v in pairs(dict) do
		if v then
			table.insert(list, k)
		end
	end
	return list
end

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
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
    if currentBillboard then
        currentBillboard:Destroy()
        currentBillboard = nil
    end
end

function u.CalculatePlantValue(plant)
    local itemString = plant:FindFirstChild("Item_String")
    local itemName = itemString and itemString.Value or plant.Name

    local variant = plant:FindFirstChild("Variant")
    if not variant then return 0 end

    local weight = plant:FindFirstChild("Weight")
    if not weight then return 0 end

    local baseData = ItemModule.Return_Data(itemName)
    if not baseData or #baseData < 3 then
        warn("Invalid ItemData for:", itemName)
        return 0
    end

    local variantMultiplier = ItemModule.Return_Multiplier(variant.Value)
    local valueMulti = MutationHandler:CalcValueMulti(plant)
    local clamp = math.clamp(weight.Value / baseData[2], 0.95, 1e8)

    return math.round(baseData[3] * valueMulti * variantMultiplier * (clamp * clamp))
end

function u.highlightBiggestFruit()
    local farm = nil
    for _, f in ipairs(workspace.Farm:GetChildren()) do
        local important = f:FindFirstChild("Important")
        local data = important and important:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and owner.Value == player.Name then
            farm = f
            break
        end
    end
    if not farm then
        getgenv().Library:Notify("No owned farm found.")
        u.removeHighlight()
        getgenv().lastBiggest = nil
        return
    end

    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then
        getgenv().Library:Notify("No Plants_Physical found.")
        u.removeHighlight()
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
            currentHighlight = highlight

            -- Disconnect old rainbow connection if it exists
            if rainbowConnection then
                rainbowConnection:Disconnect()
            end

            -- Start rainbow animation
            rainbowConnection = RunService.RenderStepped:Connect(function()
                local hue = (tick() * 0.5) % 1 -- adjust speed here
                local color = Color3.fromHSV(hue, 1, 1)
                if currentHighlight then
                    currentHighlight.FillColor = color
                    currentHighlight.OutlineColor = color:lerp(Color3.new(1, 1, 1), 0.2) -- make outline slightly brighter
                end
            end)


            local head = biggest:FindFirstChildWhichIsA("BasePart")
            if head then
                local value = u.CalculatePlantValue(biggest)

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
                    FormatWithCommas(value)
                )
                label.Parent = bb
                currentBillboard = bb
            end
        end
    end
end

function u.savePosition()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedPosition = hrp.CFrame
        getgenv().Library:Notify("🌍 Position saved!")
    else
        getgenv().Library:Notify("❌ Could not save position (HumanoidRootPart missing).")
    end
end

function u.sellInventory()
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
    getgenv().Library:Notify("Inventory sold!")
end

function u.cleanPlantName(name)
    name = name:gsub("%s*%b[]", "") -- remove anything in brackets
    name = name:gsub("%s*Seed", "") -- remove trailing "Seed"
    return name:match("^%s*(.-)%s*$") -- trim spaces
end

function u.allPlants()
    local seeds = { "All" } 

    for _, data in pairs(seedData) do
        local cleanedName = u.cleanPlantName(data.SeedName)
        if not table.find(seeds, cleanedName) then
            table.insert(seeds, cleanedName)
        end
    end

    table.sort(seeds)
    return seeds
end


function u.teleportSellReturn()
    u.savePosition()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local cFrame = u.myFarm().Spawn_Point.CFrame
    if not hrp then return end
    hrp.CFrame = CFrame.new(86.57965850830078, 2.999999761581421, 0.4267919063568115)
    task.wait(0.25)
    u.sellInventory()
    task.wait(0.2)
    hrp.CFrame = cFrame
end

function u.parseCompactTime(str)
    if not str or str == "" then return 0 end
    local mins = tonumber(str:match("(%d+)%s*Minute")) or 0
    local secs = tonumber(str:match("(%d+)%s*Second")) or 0
    return mins * 60 + secs
end

function u.getShopSeeds()
    local seedShopGui = playerGui:WaitForChild("Seed_Shop")
    local seedsFrame = seedShopGui:WaitForChild("Frame"):WaitForChild("ScrollingFrame")

    local seedList = {}

    table.insert(seedList, "All")

    for _, seedFrame in pairs(seedsFrame:GetChildren()) do
        if seedFrame:IsA("Frame") then
            local mainFrame = seedFrame:FindFirstChild("Main_Frame")
            if mainFrame then
                local seedText = mainFrame:FindFirstChild("Seed_Text")
                if seedText and seedText:IsA("TextLabel") then
                    local rawName = seedText.Text or ""
                    
                    local cleaned = rawName:gsub("%s*[sS]eed%s*", ""):gsub("^%s*(.-)%s*$", "%1")
                    table.insert(seedList, cleaned)
                end
            end
        end
    end
    return seedList
end

function u.getMerchantShop()
    local merchantTbl = require(ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData)

    local result = { "All" }
    local seen   = {}

    for _, merchantInfo in pairs(merchantTbl) do
        local shopData = merchantInfo.ShopData
        if typeof(shopData) == "Instance" and shopData:IsA("ModuleScript") then
            shopData = require(shopData)
        end
        if type(shopData) == "table" then
            for rawName, entry in pairs(shopData) do
                local name = entry.SeedName or entry.ItemName or rawName
                if not seen[name] then
                    seen[name] = true
                    table.insert(result, name)
                end
            end
        end
    end

    table.sort(result, function(a,b)
        if a == "All" then return true  end
        if b == "All" then return false end
        return a < b
    end)

    return result
end

function u.getGearShop()
    local gearShopGui = playerGui:WaitForChild("Gear_Shop")
    local gearsFrame = gearShopGui:WaitForChild("Frame"):WaitForChild("ScrollingFrame")

    local gearList = {}

    table.insert(gearList, "All")

    for _, gearFrame in pairs(gearsFrame:GetChildren()) do
        if gearFrame:IsA("Frame") then
            local mainFrame = gearFrame:FindFirstChild("Main_Frame")
            if mainFrame then
                local gearText = mainFrame:FindFirstChild("Gear_Text")
                if gearText and gearText:IsA("TextLabel") then
                    table.insert(gearList, gearText.Text)
                end
            end
        end
    end

    return gearList
end


function u.getallegg()
    local eggpath = game:GetService("ReplicatedStorage").Assets.Models.EggModels
    local egglist = {}
    table.insert(egglist, "All")
    for _, egg in pairs(eggpath:GetChildren()) do
        local eggName = egg.Name
        table.insert(egglist, eggName)
    end
    return egglist
end

task.wait(1)

local p = game:GetService("Players").LocalPlayer
local g = p.PlayerGui.Teleport_UI.Frame
local gear = g:WaitForChild("Gear")

local gui = Instance.new("ScreenGui")
gui.Name = "GearTeleportGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = g

local btn = Instance.new("ImageButton")
btn.Name = "GearButton"
btn.Size = UDim2.new(0, 95, 0, 35)
btn.AnchorPoint = Vector2.new(0.5, 1)
btn.BackgroundColor3 = Color3.fromRGB(97, 226, 51)
btn.BorderColor3 = Color3.new(0,0,0)
btn.BorderMode = "Outline"
btn.BorderSizePixel = 1
btn.LayoutOrder = -5
btn.Image = ""
btn.ZIndex = 100
btn.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "Gear"
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0.5
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.ZIndex = 101
label.Parent = btn

game:GetService("RunService").RenderStepped:Connect(function()
    local pos = gear.AbsolutePosition
    local size = gear.AbsoluteSize
    btn.Position = UDim2.fromOffset(pos.X + size.X/3, pos.Y + size.Y + 73)
    -- btn.Position = UDim2.new(0.688038409, 0, 0.114772804, 0)
end)

btn.MouseButton1Click:Connect(function()
    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(-285.41, 3.00, -13.98)
    end
end)

function u.harvestFilter(item, minW, maxW)
    if not item then return false end
    local weightObj = item:FindFirstChild("Weight")
    if not weightObj then return false end
    local weight = tonumber(weightObj.Value)
    if not weight then return false end

    local baseName = u.getBaseName(item.Name)

    if #getgenv().selectedPlants == 0 then
        return weight >= minW and weight <= maxW
    end

    return table.find(getgenv().selectedPlants, baseName) and weight >= minW and weight <= maxW
end


function u.getTrowel()
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:match("^Trowel") then
			return tool
		end
	end
end

local plantFolder = u.myFarm():FindFirstChild("Important") and u.myFarm().Important:FindFirstChild("Plants_Physical")
function u.moveSelectedPlantType()
	if not savedPosition then
		getgenv().Library:Notify("⚠️ Please save a position first!")
		return
	end

	local trowel = u.getTrowel()
	if not trowel then
		getgenv().Library:Notify("🛠️ Trowel not found in backpack.")
		return
	end

	local selected = getgenv().selectedPlantss[1]
	if not selected then
		getgenv().Library:Notify("🔍 No plant selected from dropdown.")
		return
	end

	local trowelRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("TrowelRemote")
	
	if not plantFolder then
		warn("❌ Could not find Plants_Physical.")
		return
	end

	for _, plant in ipairs(plantFolder:GetChildren()) do
		if plant:IsA("Model") and plant.Name == selected then
			local success, err = pcall(function()
				-- Pick up
				trowelRemote:InvokeServer("Pickup", trowel, plant)
				task.wait(0.2)

				-- Place at saved position
				trowelRemote:InvokeServer("Place", trowel, plant, savedPosition)
				task.wait(0.1)
			end)

			if not success then
				warn("❌ Error moving plant:", plant.Name, err)
			end
		end
	end
end


function u.hatchSelectedEggs()
    for _, egg in ipairs(workspace:GetDescendants()) do
        if egg:IsA("Model") and egg:GetAttribute("OWNER") == player.Name and egg:GetAttribute("READY") then
            local eggName = egg:GetAttribute("EggName")
            if eggName and table.find(getgenv().selectedeggs, eggName) then
                PetEggService:FireServer("HatchPet", egg)
                task.wait(0.1)
            end
        end
    end
end

local autoPlaceEggs = getgenv().autoPlaceEggs or false
local place_egg_method = getgenv().place_egg_method
getgenv().selected_position_egg = player.Character:GetPivot().Position
local EggRE          = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("PetEggService")        -- "CreateEgg" remote
local shovelName     = "Shovel [Destroy Plants]"                          -- only needed for equip helper
local auto_place_eggs, placingEggs = false, false
local object_physical = u.myFarm().Important:FindFirstChild("Objects_Physical")
local plant_locations = u.myFarm().Important.Plant_Locations
-- persistent place-eggs loop
task.spawn(function()
  while not getgenv().Library.Unloaded do
    if getgenv().autoPlaceEggs then
      ----------------------------------------------------------
      -- any pre-checks (method selected, position saved, eggs chosen)
      ----------------------------------------------------------
      if place_egg_method == "" then
        getgenv().Library:Notify("⚠️  Select a placement method first!")
      elseif place_egg_method == "Selected Position" and not getgenv().selected_position_egg then
        getgenv().Library:Notify("⚠️  Save a position first!")
      elseif #getgenv().selectedeggs == 0 then
        getgenv().Library:Notify("⚠️  Pick at least one egg!")
      else
        ----------------------------------------------------------
        -- your existing “while garden has room, loop through eggs” logic
        ----------------------------------------------------------
		local data = require(game:GetService("ReplicatedStorage").Modules.DataService):GetData()
		local totalEgg = data.PetsData.PurchasedEggSlots + 3
        local gardenHasRoom = #object_physical:GetChildren() < totalEgg
        if gardenHasRoom then
          for _, tool in ipairs(backpack:GetChildren()) do
            if not autoPlaceEggs then break end
            if tool:IsA("Tool")
				and tool:GetAttribute(u.inventory_enums.ITEM_TYPE) == u.item_types.PetEgg
				and table.find(getgenv().selectedeggs, tool:GetAttribute(u.inventory_enums.EggName))
            then
              if not u.equipTool(tool) then 
				    getgenv().Library:Notify(string.format("NO: ", selectedeggs), 3)
				break 
			end

              local uses = tool:GetAttribute(u.inventory_enums.Uses) or 1
              for i = 1, uses do
                if not autoPlaceEggs then break end

                local pos
				if place_egg_method == "Random Place Position" then
					pos = u.nextRandomPos()
				elseif place_egg_method == "Player Position" then
					pos = player.Character:GetPivot().Position
				else
					pos = getgenv().selected_position_egg
				end
				if not pos then break end

                EggRE:FireServer("CreateEgg", pos)
                task.wait(0.25)
				
                if #object_physical:GetChildren() > totalEgg then
                  break
                end
              end

              player.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
              if #object_physical:GetChildren() > totalEgg then
                break
              end
            end
          end
        end
      end
    end

    task.wait( autoPlaceEggs and 0.5 or 1 )
  end
end)

function u.equipTool(tool)
    local char     = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or not tool then return false end

    -- already holding?
    if char:FindFirstChild(tool.Name) == tool then return true end

    humanoid:UnequipTools()
    humanoid:EquipTool(tool)

    -- wait up to ½ s for server replication
    for i = 1, 10 do
        if char:FindFirstChild(tool.Name) then return true end
        task.wait(0.05)
    end
    return false
end

function u.nextRandomPos()
    local canPlant = plant_locations:FindFirstChild("Can_Plant")
    if not (canPlant and canPlant:IsA("BasePart")) then
        Library:Notify("❌  Missing Can_Plant part!", 3)
        return nil
    end

    -- uniform rectangle sampling
    local halfX, halfZ = canPlant.Size.X * 0.5, canPlant.Size.Z * 0.5
    local dx = (math.random() * 2 - 1) * halfX      --  ∈ [-halfX … +halfX]
    local dz = (math.random() * 2 - 1) * halfZ

    return vcreate(canPlant.Position.X + dx,
                   canPlant.Position.Y + 0.1,   -- 1 stud above ground
                   canPlant.Position.Z + dz)
end

function u.getNextPlantPosition()
    if getgenv().plantMode == "Selected Position" and getgenv().plantPos then
        return getgenv().plantPos
    end

    local canPlant = plant_locations:FindFirstChild("Can_Plant")
    if not (canPlant and canPlant:IsA("BasePart")) then
        Library:Notify("❌ Missing Can_Plant part!", 3)
        return nil
    end

    local halfX, halfZ = canPlant.Size.X * 0.5, canPlant.Size.Z * 0.5
    local dx = (math.random() * 2 - 1) * halfX
    local dz = (math.random() * 2 - 1) * halfZ

    return Vector3.new(
        canPlant.Position.X + dx,
        canPlant.Position.Y + 0.1,
        canPlant.Position.Z + dz
    )
end

function u.equipFruitTool(fruitName)
	local backpack = game.Players.LocalPlayer:WaitForChild("Backpack")
	local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

	-- Check if already equipped
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") and item.Name:lower():find(fruitName:lower()) then
			return true -- already equipped
		end
	end

	-- Look in backpack
	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item.Name:lower():find(fruitName:lower()) and not item.Name:lower():find("seed") and not item:GetAttribute("d")then
			item.Parent = character
			task.wait(0.1) -- Let the server see it
			return true
		end
	end

	-- Not found
	return false
end

function u.getFirstEquippableFruit()
	local selected = getgenv().selectedPlantsss or {}
	for _, fruit in ipairs(selected) do
		if not fruit:lower():find("seed") then
			if u.equipFruitTool(fruit) then
				return fruit -- success
			end
		end
	end
	return nil -- none found
end


function u.scanPetHunger()
	table.clear(getgenv().petHungerList)

	for _, container in pairs(workspace.PetsPhysical:GetChildren()) do
		if container:IsA("Part") then
			for _, model in pairs(container:GetChildren()) do
				if model:IsA("Model") then
					local uuid = model.Name
					local data = getgenv().PetModule:GetPetData(game.Players.LocalPlayer.Name, uuid)
					if data and data.PetData then
						getgenv().petHungerList[uuid] = data.PetData.Hunger or 0
					end
				end
			end
		end
	end
end

function u.isHungry(uuid)
	return getgenv().petHungerList[uuid] < 10
end

function u.feed()
    function u.feed()
        task.spawn(function()
            while getgenv().autoFeed and not Library.Unloaded do
                u.scanPetHunger()

                for uuid, hunger in pairs(getgenv().petHungerList) do
                    if u.isHungry(uuid) then
                        local fruitToUse = u.getFirstEquippableFruit()
                        if not fruitToUse then
                            break -- exit entire loop if no plant was ever selected
                        end

                        local equipped = u.equipFruitTool(fruitToUse)
                        if not equipped then
                            warn("❌ Couldn't equip fruit:", fruitToUse)
                            continue -- skip to next pet
                        end

                        task.wait(0.2)
                        game.ReplicatedStorage.GameEvents.ActivePetService:FireServer("Feed", uuid)
                        print("✅ Fed pet:", uuid, "with:", fruitToUse)
                        task.wait(0.3)
                    end
                end

                task.wait(2)
            end
        end)
    end
end

return u
