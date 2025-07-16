
local function removeGui()
	for _, v in ipairs(game:GetService("CoreGui"):GetDescendants()) do
		if v:IsA("ScreenGui") and v.Name == "Obsidian" then
			-- Library.Unloaded = true
			v:Destroy()
			for _, v2 in ipairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
				if v2:isA("ScreenGui") and v2.Name == "GearTeleportGui" then
					v2:Destroy()
				end
			end
		end
	end
end
removeGui()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yue-os/ObsidianUi/refs/heads/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/yue-os/ObsidianUi/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/yue-os/ObsidianUi/refs/heads/main/addons/ThemeManager.lua"))()
local player = game.Players.LocalPlayer
local character = player.Character
-- local backpack = player.Backpack
local Players = game.Players
-- local player = game.Players.LocalPlayer
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
local setclipboard = setclipboard or function(text)
    if syn then
        syn.write_clipboard(text)
    elseif clipboard_set then
        clipboard_set(text)
    else
        print("Clipboard not supported. Link: https://discord.gg/WswepWXvr9")
    end
end

setclipboard("https://discord.gg/WswepWXvr9")
Library:Notify("Discord link copied to clipboard! Paste it in your browser to join.")
getgenv().util = loadstring(game:HttpGet("https://raw.githubusercontent.com/yue-os/script/refs/heads/main/util.lua", true))()


local inventory_enums = {
    ["OWNER"]             = "a",
    ["ITEM_TYPE"]         = "b",
    ["ITEM_UUID"]         = "c",
    ["Favorite"]          = "d",
    ["Uses"]              = "e",
    ["ItemName"]          = "f",
    ["Rarity"]            = "g",
    ["EggName"]           = "h",
    ["CrateType"]         = "i",
    ["PotType"]           = "j",
    ["LinkedPlayerID"]    = "k",
    ["SprayType"]         = "l",
    ["SprayMutationName"] = "m",
    ["Type"]              = "n"
}

local item_types = {
    ["Seed Pack"]         = "a",
    ["Trowel"]            = "b",
    ["PetEgg"]            = "c",
    ["Sprinkler"]         = "d",
    ["Night Staff"]       = "e",
    ["Harvest Tool"]      = "f",
    ["Pollen Radar"]      = "g",
    ["Favorite Tool"]     = "h",
    ["Lightning Rod"]     = "i",
    ["Holdable"]          = "j",
    ["Star Caller"]       = "k",
    ["Pet"]               = "l",
    ["FriendshipPot"]     = "m",
    ["Seed"]              = "n",
    ["Watering Can"]      = "o",
    ["Nectar Staff"]      = "p",
    ["Recall Wrench"]     = "q",
    ["CosmeticCrate"]     = "r",
    ["SprayBottle"]       = "s"
}


local function savePosition()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		savedPosition = hrp.CFrame
		Library:Notify("🌍 Position saved!")
	else
		Library:Notify("❌ Could not save position (HumanoidRootPart missing).")
	end
end

local function sellInventory()
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
    Library:Notify("Inventory sold!")
end

local function cleanPlantName(name)
	name = name:gsub("%s*%b[]", "") -- remove anything in brackets
	name = name:gsub("%s*Seed", "") -- remove trailing "Seed"
	return name:match("^%s*(.-)%s*$") -- trim spaces
end

local function allPlants()
    local seeds = { "All" } 

    for _, data in pairs(seedData) do
        local cleanedName = cleanPlantName(data.SeedName)
        if not table.find(seeds, cleanedName) then
            table.insert(seeds, cleanedName)
        end
    end

    table.sort(seeds)
    return seeds
end


local function teleportSellReturn()
    savePosition()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local cFrame = myFarm.Spawn_Point.CFrame
    if not hrp then return end
    hrp.CFrame = CFrame.new(86.57965850830078, 2.999999761581421, 0.4267919063568115)
    task.wait(0.25)
    sellInventory()
    task.wait(0.2)
    hrp.CFrame = cFrame
end

local function parseCompactTime(str)
    if not str or str == "" then return 0 end
    local mins = tonumber(str:match("(%d+)%s*Minute")) or 0
    local secs = tonumber(str:match("(%d+)%s*Second")) or 0
    return mins * 60 + secs
end

local function getShopSeeds()
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

local function getMerchantShop()
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

local function getGearShop()
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


local function getallegg()
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

local item_codes = {}
for k, v in pairs(item_types) do
	item_codes[v] = k
end


task.wait(2)

local window = Library:CreateWindow({
    Title = "Y-Hub",
    Center = true,
    Icon = 128171209017859,
    AutoShow = true,
    Size = UDim2.fromOffset(650, 460),
    ShowCustomCursor = false,
    ToggleKeybind = Enum.KeyCode.LeftControl
})

local creditsTab = window:AddTab("Misc", "accessibility")
local mainTab = window:AddTab("Main", "book-user")
-- local seed = window:AddTab("Seed", "seed")
local shopTab = window:AddTab("Shop", "shopping-cart")
local eventTab = window:AddTab("Event", "sparkle")
local playerTab = window:AddTab("Player", "user")
local petTab = window:AddTab("Pet", "egg")


local group = mainTab:AddLeftGroupbox("Fruit/Sell")
local group2 = mainTab:AddRightGroupbox("Auto Harvest")
local trowel = mainTab:AddRightGroupbox("Move Plant")
local plant = mainTab:AddLeftGroupbox("Plant")
local rShop = shopTab:AddRightGroupbox("UI")
local seedShop = shopTab:AddLeftGroupbox("Seed Shop")
local gearShop = shopTab:AddLeftGroupbox("Gear Shop")
local petGroup = shopTab:AddRightGroupbox("Egg Shop")
local craft = eventTab:AddRightGroupbox("Crafting")
local dino = eventTab:AddLeftGroupbox("Dino Event")
local antiAfkGroup = playerTab:AddRightGroupbox("Anti-AFK")
local lPlayer = playerTab:AddLeftGroupbox("Player")
local pet = petTab:AddLeftGroupbox("Pets")
local hatch = petTab:AddRightGroupbox("Hatch")
local merchantShop = shopTab:AddLeftGroupbox("Merchant Shop")
local creditsGroup = creditsTab:AddLeftGroupbox("Discord")
local setting = {
    ["UI Settings"] = window:AddTab("UI Settings", "settings")
}
group:AddInput("fruit_input", {
    Text = "Fruit Threshold",
    Default = "10",
    Numeric = true, -- optional: restrict to numeric input only
    Callback = function(val)
        fruitThreshold = tonumber(val) or 0
    end
})

group:AddToggle("auto_sell_toggle", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(state)
        autoSell = state
        if autoSell then
            Library:Notify("Auto TP & Sell enabled.")
            task.spawn(function()
                while autoSell and not Library.Unloaded do
                    if util.getFruitCount() >= fruitThreshold then
                        util.teleportSellReturn()
                        task.wait(2)
                    end
                    task.wait(1)
                end
            end)
        else
            Library:Notify("Auto TP & Sell disabled.")
        end
    end
})

group:AddToggle("highlight_biggest_toggle", {
    Text = "Show Biggest",
    Tooltip = "ESP biggest fruit with weight and value ¢",
    Default = false,
    Callback = function(state)
        highlightToggle = state
        if highlightToggle then
            util.highlightBiggestFruit()
            conn = game:GetService("RunService").RenderStepped:Connect(function()
                if highlightToggle then
                    util.highlightBiggestFruit()
                end
            end)
        else
            if conn then conn:Disconnect() end
            util.removeHighlight()
            getgenv().lastBiggest = nil
        end
    end
})

lPlayer:AddToggle("noclip_toggle", {
    Text = "Noclip",
    Default = false,
    Callback = function(state)
        noclipEnabled = state
        if noclipEnabled then
            noclipConn = RunService.Stepped:Connect(function()
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            Library:Notify("Noclip enabled.")
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            Library:Notify("Noclip disabled.")
        end
    end
})

lPlayer:AddSlider("speed_slider", {
    Text = "Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Rounding = 0,
    Callback = function(val)
        speedValue = val
        if speedwalkEnabled then
            local char = player.Character or player.CharacterAdded:Wait()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = speedValue
            end
        end
    end
})

lPlayer:AddToggle("speedwalk_toggle", {
    Text = "Speedwalk",
    Default = false,
    Callback = function(state)
        speedwalkEnabled = state
        local char = player.Character or player.CharacterAdded:Wait()
        if speedwalkEnabled and hum then
            hum.WalkSpeed = speedValue
            speedConn = char.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                    child.WalkSpeed = speedValue
                end
            end)
            Library:Notify("Speedwalk enabled.")
        else
            if hum then hum.WalkSpeed = 16 end
            if speedConn then speedConn:Disconnect() speedConn = nil end
            Library:Notify("Speedwalk disabled.")
        end
    end
})

local seedList = util.getShopSeeds()
getgenv().selectedSeeds = {}
seedShop:AddDropdown("seed_dropdown", {
    Values = seedList,
    Multi = true,
    Searchable = true,
    Text = "Seeds Available",
    Default = {},               
    Callback = function(selected)
        local rawSelected = util.keysOf(selected)

        
        if table.find(rawSelected, "All") then
            getgenv().selectedSeeds = {}
            for _, name in ipairs(seedList) do
                if name ~= "All" then
                    table.insert(getgenv().selectedSeeds, name)
                end
            end
        else
            getgenv().selectedSeeds = rawSelected
        end

        Library:Notify("Selected seeds: " .. table.concat(getgenv().selectedSeeds, ", "))
    end
})

seedShop:AddToggle("auto_buy_selected_seeds", {
    Text = "Auto Buy",
    Default = false,
    Callback = function(value)
        autoBuySeeds = value
        if autoBuySeeds then
            Library:Notify("Auto-buy enabled!")
            task.spawn(function()
                local event = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuySeedStock")

                while autoBuySeeds and not Library.Unloaded do
                    if #getgenv().selectedSeeds > 0 then
                        for _, seedName in ipairs(getgenv().selectedSeeds) do
                            event:FireServer(seedName)
                        end
                        -- Library:Notify("Bought " .. seedName)
                    end
                    task.wait(0.5)
                end
                Library:Notify("Auto-buy disabled!")
            end)
        else
            Library:Notify("Auto-buy disabled!")
        end
    end
})


trowel:AddButton("Save Position", util.savePosition)
trowel:AddButton("Reset Saved Position", function()
	getgenv().savedPosition = nil
	Library:Notify("Saved position has been reset. Please save a new one.")
end)

group:AddButton("Sell Inventory", util.teleportSellReturn)

local egglist = util.getallegg()
hatch:AddDropdown("egg_dropdown", {
    Text = "Eggs",
    Default = {},
    Values = egglist,
    Multi = true,
    Searchable = true,
    Callback = function(selected)
        local eggselected = util.keysOf(selected)

        if table.find(eggselected, "All") then
            getgenv().selectedeggs = {}
            for _, name in ipairs(egglist) do
                if name ~= "All" then
                    table.insert(getgenv().selectedeggs, name)
                end
            end
        else
            getgenv().selectedeggs = eggselected
        end

        Library:Notify("Selected eggs: " .. table.concat(getgenv().selectedeggs, ", "))
    end
})

function get_tool()
    return player.Character:FindFirstChildOfClass("Tool")
end

local myFarm = util.myFarm()
getgenv().place_egg_method = ""
local object_physical = myFarm.Important:FindFirstChild("Objects_Physical")
local plant_locations = myFarm.Important.Plant_Locations
local EggRE          = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("PetEggService")        -- "CreateEgg" remote
local shovelName     = "Shovel [Destroy Plants]"                          -- only needed for equip helper
local auto_place_eggs, placingEggs = false, false

------------------------------------------------------------------ helpers
local function equipTool(tool)
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

local vcreate = vector.create   -- keep the call short

--------------------------------------------------------------
-- random position inside the Can_Plant part
--------------------------------------------------------------
local function nextRandomPos()
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

local autoPlaceEggs = false
hatch:AddToggle("auto_place_eggs", {
  Text    = "Auto Place Eggs",
  Default = false,
  Callback = function(val)
	autoPlaceEggs = val
  end
})

local setPositionButton -- define ahead so we can reuse
hatch:AddDropdown('place_egg_method', {
    Values = { 'Player Position', 'Selected Position', 'Random Place Position' },
    Default = place_egg_method,
    Multi = false,
    Text = 'Select Auto Place Egg Method:',
    Tooltip = 'Auto places eggs with selected method',
    Callback = function(Value)
        getgenv().place_egg_method = Value

        if setPositionButton then
            setPositionButton:SetVisible(Value == "Selected Position")
        end
    end
})

setPositionButton = hatch:AddButton({
    Text = 'Set Position',
    Func = function()
        if game.Players.LocalPlayer.Character then
            getgenv().selected_position_egg = game.Players.LocalPlayer.Character:GetPivot().Position
            Library:Notify("Set player position!")
        else
            Library:Notify("Character not found!", 3)
        end
    end,
    DoubleClick = false,
    Tooltip = 'Sets player position to use for auto place eggs'
})

-- Hide initially if default is not "Selected Position"
if place_egg_method ~= "Selected Position" then
    setPositionButton:SetVisible(false)
end

local autoHatch = false

hatch:AddToggle("autohatchtoggle", {
  Text    = "Auto Hatch",
  Default = false,
  Callback = function(state)
    autoHatch = state
  end
})

-- persistent place-eggs loop
task.spawn(function()
  while not Library.Unloaded do
    if autoPlaceEggs then
      ----------------------------------------------------------
      -- any pre-checks (method selected, position saved, eggs chosen)
      ----------------------------------------------------------
      if place_egg_method == "" then
        Library:Notify("⚠️  Select a placement method first!")
      elseif place_egg_method == "Selected Position" and not selected_position_egg then
        Library:Notify("⚠️  Save a position first!")
      elseif #selectedeggs == 0 then
        Library:Notify("⚠️  Tick at least one egg!")
      else
        ----------------------------------------------------------
        -- your existing “while garden has room, loop through eggs” logic
        ----------------------------------------------------------
		local data = require(ReplicatedStorage.Modules.DataService):GetData()
		local totalEgg = data.PetsData.PurchasedEggSlots + 3
        local gardenHasRoom = #object_physical:GetChildren() < totalEgg
        if gardenHasRoom then
          for _, tool in ipairs(backpack:GetChildren()) do
            if not autoPlaceEggs then break end
            if tool:IsA("Tool")
				and tool:GetAttribute(inventory_enums.ITEM_TYPE) == item_types.PetEgg
				and table.find(selectedeggs, tool:GetAttribute(inventory_enums.EggName))
            then
              if not equipTool(tool) then 
				-- print("NO: ", selectedeggs)
				break 
			end

              local uses = tool:GetAttribute(inventory_enums.Uses) or 1
              for i = 1, uses do
                if not autoPlaceEggs then break end

                local pos
				if place_egg_method == "Random Place Position" then
					pos = nextRandomPos()
				elseif place_egg_method == "Player Position" then
					pos = player.Character:GetPivot().Position
				else
					pos = selected_position_egg
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
-- persistent hatch loop
task.spawn(function()
  while not Library.Unloaded do
    if autoHatch then
      util.hatchSelectedEggs()
    end
    task.wait(1)  -- run every second (tweak as you like)
  end
end)

local function setRecipe(itemName)
    -- local interactionFolder = workspace:WaitForChild("Interaction")
    -- local updateItems = interactionFolder:WaitForChild("UpdateItems")
    -- local dinoEvent = updateItems:WaitForChild("DinoEvent")
    local craftingTable = workspace.DinoEvent.DinoCraftingTable

    local remote = game:GetService("ReplicatedStorage")
        :WaitForChild("GameEvents")
        :WaitForChild("CraftingGlobalObjectService")

    remote:FireServer("SetRecipe", craftingTable, "DinoEventWorkbench", itemName)
end

local dlist = {
    "Ancient Seed Pack",
    "Dino Crate",
    "Mutation Spray Amber"
}
if #dlist == 0 then
    table.insert(dlist, "No Recipes Found")
end

local selectedRecipe = nil

dino:AddDropdown("dino_dropdown", {
    Values = dlist,
    Searchable = true,
    Text = "Recipes Available",
    Default = nil,
    Callback = function(selected)
        selectedRecipe = selected
        if selected then
            Library:Notify("Selected recipe: " .. selected)
        else
            Library:Notify("No recipe selected.")
        end
    end
})

local autoCraftEnabled = false

dino:AddToggle("auto_craft_toggle", {
    Text = "Auto Set Recipe",
    Default = false,
    Callback = function(val)
        autoCraftEnabled = val
    end
})

-- Auto Craft Loop (Lightweight, safe)
task.spawn(function()
    while not Library.Unloaded do
        if autoCraftEnabled and selectedRecipe and selectedRecipe ~= "All" then
            pcall(function()
                setRecipe(selectedRecipe)
            end)
        end
        task.wait(2) -- Craft interval (adjust as needed)
    end
end)

local CraftingRemote = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("CraftingGlobalObjectService")
local craftingTable = workspace.DinoEvent.DinoCraftingTable

-- 🧬 Dino Recipe to Slot Map
local recipeSlotMap = {
	["Ancient Seed Pack"] = {
		{ name = "Dinosaur Egg", itemType = "PetEgg", slot = 1 }
	},
	["Dino Crate"] = {
		{ name = "Dinosaur Egg", itemType = "PetEgg", slot = 1 }
	},
	["Mutation Spray Amber"] = {
		{ name = "Cleaning Spray", itemType = "SprayBottle", slot = 1 },
		{ name = "Dinosaur Egg", itemType = "PetEgg", slot = 2 }
	}
}


-- 🧬 ItemType Enum
local ItemTypeEnum = {
	["Seed Pack"] = "a",
	["Trowel"] = "b",
	["PetEgg"] = "c", -- Used for Dinosaur Egg
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

-- 🔄 Submission Logic
local function findAndSubmit(toolMatchName, itemTypeKey, slot)
	local itemType = ItemTypeEnum[itemTypeKey]
	if not itemType then
		warn("❌ Invalid ItemType: " .. tostring(itemTypeKey))
		return false
	end

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:find(toolMatchName) then
            -- print(tool.Name)
			local uuid = tool:GetAttribute("c") or tool:GetAttribute("UUID")
			if uuid then
				tool.Parent = character
				task.wait(0.2)

				CraftingRemote:FireServer("InputItem", craftingTable, "DinoEventWorkbench", slot, {
					ItemType = itemTypeKey,
					ItemData = { UUID = uuid }
				})
				return true
			end
		end
	end
	return false
end

local function submitValidItems()
	if not selectedRecipe or not recipeSlotMap[selectedRecipe] then return end

	local requiredItems = recipeSlotMap[selectedRecipe]

	for _, requirement in ipairs(requiredItems) do
		findAndSubmit(requirement.name, requirement.itemType, requirement.slot)
	end

	CraftingRemote:FireServer("Craft", craftingTable, "DinoEventWorkbench")
	hum:UnequipTools()
end


-- 🔘 Toggle UI
dino:AddToggle("autosubmit_dino", {
	Text = "Auto Submit Dino Items",
	Default = false,
	Callback = function(v)
		autoSubmit = v
		Library:Notify("Auto Submit " .. (v and "✅ Enabled" or "❌ Disabled"))
	end
})

local function findTableTopLabel()
	local craftingTable = workspace.DinoEvent.DinoCraftingTable

	for _, descendant in ipairs(craftingTable:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Name == "TextLabel" then
			local parentGui = descendant.Parent
			local tableTop = parentGui and parentGui.Parent

			if tableTop and tableTop:IsA("BasePart") and tableTop.Name == "TableTop" then
				return descendant
			end
		end
	end

	return nil
end

task.spawn(function()
	while not Library.Unloaded do
		local timerLabel = findTableTopLabel()
        if autoSubmit then
            pcall(submitValidItems)
        end
		task.wait(3)
	end
end)


dino:AddToggle("auto_craft", {
    Text = "Auto Start",
    Default = false,
    Callback = function(state)
        autoSubmit = state
        local craftingTable = workspace.DinoEvent.DinoCraftingTable
        if autoSubmit then
            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("CraftingGlobalObjectService"):FireServer("Craft", craftingTable, "DinoEventWorkbench")
        end
    end
})
-- ▶️ Toggle only flips the flag
dino:AddToggle("claim_craft", {
    Text    = "Auto Claim",
    Default = false,
    Callback = function(state)
        auto_claim_craft = state
    end
})

-- ▶️ Single background task that always runs
task.spawn(function()
    while not Library.Unloaded do
        if auto_claim_craft then
            -- fire a Claim on your Dino bench every 5s
            CraftingRemote:FireServer(
                "Claim",
                crafting_table,
                "DinoEventWorkbench",
                1
            )
        end
        task.wait(5)
    end
end)

local merchlist = util.getMerchantShop()
local selectedMerchantItem = {}
merchantShop:AddDropdown("merch_dropdown", {
    Values = merchlist,
    Multi = true,
    Searchable = true,
    Text = "Merchant Items Available",
    Default = {},
    Callback = function(selected)
        local merchselected = util.keysOf(selected)

        
        if table.find(merchselected, "All") then
            selectedMerchantItem = {}
            for _, name in ipairs(merchlist) do
                if name ~= "All" then
                    table.insert(selectedMerchantItem, name)
                end
            end
        else
            selectedMerchantItem = merchselected
        end

        Library:Notify("Selected items: " .. table.concat(selectedMerchantItem, ", "))
    end
})



local autoBuyMerch = false
merchantShop:AddToggle("auto_buy_selected_merch", {
    Text = "Auto Buy",
    Default = false,
    Callback = function(value)
        autoBuyMerch = value
        if autoBuyMerch then
            Library:Notify("Auto-buy merch enabled!")
            task.spawn(function()
                local event = game:GetService("ReplicatedStorage").GameEvents:WaitForChild("BuyTravelingMerchantShopStock")

                while autoBuyMerch and not Library.Unloaded do
                    if #selectedMerchantItem > 0 then
                        local toBuy = {}

                        if table.find(selectedMerchantItem, "All") then
                            
                            for _, merchName in ipairs(merchlist) do
                                if merchName ~= "All" then
                                    table.insert(toBuy, merchName)
                                end
                            end
                        else
                            toBuy = selectedMerchantItem
                        end

                        
                        for _, merchName in ipairs(toBuy) do
                            event:FireServer(merchName)
                        end
                    end
                    task.wait(0.5)
                end
                Library:Notify("Auto-buy merch disabled!")
            end)
        else
            Library:Notify("Auto-buy merch disabled!")
        end
    end
})

local gearList = util.getGearShop()
local selectedGears = {}
gearShop:AddDropdown("gear_dropdown", {
    Values = gearList,
    Multi = true,
    Searchable = true,
    Text = "Gears Available",
    Default = {},
    Callback = function(selected)
        local rawSelectedd = util.keysOf(selected)

        
        if table.find(rawSelectedd, "All") then
            selectedGears = {}
            for _, name in ipairs(gearList) do
                if name ~= "All" then
                    table.insert(selectedGears, name)
                end
            end
        else
            selectedGears = rawSelectedd
        end

        Library:Notify("Selected gears: " .. table.concat(selectedGears, ", "))
    end
})

local autoBuyGears = false
gearShop:AddToggle("auto_buy_selected_gears", {
    Text = "Auto Buy",
    Default = false,
    Callback = function(value)
        autoBuyGears = value
        if autoBuyGears then
            Library:Notify("Auto-buy gears enabled!")
            task.spawn(function()
                local event = game:GetService("ReplicatedStorage").GameEvents:WaitForChild("BuyGearStock")

                while autoBuyGears and not Library.Unloaded do
                    if #selectedGears > 0 then
                        local toBuy = {}

                        if table.find(selectedGears, "All") then
                            
                            for _, gearName in ipairs(gearList) do
                                if gearName ~= "All" then
                                    table.insert(toBuy, gearName)
                                end
                            end
                        else
                            toBuy = selectedGears
                        end

                        
                        for _, gearName in ipairs(toBuy) do
                            event:FireServer(gearName)
                        end
                    end
                    task.wait(0.5)
                end
                Library:Notify("Auto-buy gears disabled!")
            end)
        else
            Library:Notify("Auto-buy gears disabled!")
        end
    end
})


-- local autoBuyPetsToggle = false
-- petGroup:AddToggle("auto_buy_pets_toggle", {
--     Text = "Auto Buy All Eggs",
--     Default = false,
--     Callback = function(val)
--         autoBuyPetsToggle = val
--         if val then
--             Library:Notify("Auto buy all eggs enabled.")
--             task.spawn(function()
--                 while autoBuyPetsToggle and not Library.Unloaded do
--                     for i = 1, 3 do
--                         for _, pet in ipairs({1, 2, 3}) do
--                             ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(pet)
--                             task.wait()
--                         end
--                     end
--                     task.wait(60)
--                 end
--             end)
--         else
--             Library:Notify("Auto buy all eggs disabled.")
--         end
--     end
-- })

-- local rs            = game.ReplicatedStorage
-- local egg_data      = require(rs.Data.PetEggData)
-- local selected_eggs = { "All" }

-- local function get_shop_eggs()
--     local eggs = { "All" }
--     for _, info in pairs(egg_data) do
--         table.insert(eggs, info.EggName)
--     end
--     table.sort(eggs)
--     return eggs
-- end


local eggData = require(game:GetService("ReplicatedStorage").Data.PetEggData) -- add require
local function getShopEggs()
	local eggs = {"All"} -- don't reuse the global 'egg' name
	for _, v in pairs(eggData) do
		table.insert(eggs, v.EggName)
	end
	table.sort(eggs)
	return eggs
end

local eggs = getShopEggs()

petGroup:AddDropdown("eggsd", {
	Text       = "Egg List",
	Default    = selected_eggs,
	Values     = eggs,
	Multi      = true,
	Searchable = true,
	Callback   = function(sel)
		selected_eggs = util.keysOf(sel) 
	end
})

petGroup:AddToggle("auto_buy_egg", {
	Text = "Auto Buy",
	Default = false,
	Callback = function(state)
		autoBuyPets = state

		if autoBuyPets then
			Library:Notify("🚀 Auto-buy enabled.")
			task.spawn(function()
				while autoBuyPets and not Library.Unloaded do
					local targets = selected_eggs
					if not targets or #targets == 0 then
						targets = {"All"} -- fallback if empty
					end

					if table.find(targets, "All") then
						-- print("🧪 Buying all eggs...")
						for _, data in pairs(eggData) do
							local eggName = data.EggName
							-- print("🐣 Buying:", eggName)
							pcall(function()
								game:GetService("ReplicatedStorage").GameEvents:WaitForChild("BuyPetEgg"):FireServer(eggName)
							end)
							task.wait(0.5)
						end
					else
						-- print("🧪 Buying selected eggs...")
						for _, eggName in ipairs(targets) do
							-- print("🐣 Buying:", eggName)
							pcall(function()
								game:GetService("ReplicatedStorage").GameEvents:WaitForChild("BuyPetEgg"):FireServer(eggName)
							end)
							task.wait(0.5)
						end
					end

					task.wait(1) -- cooldown
				end
			end)
		else
			Library:Notify("🛑 Auto-buy disabled.")
		end
	end
})


local cosmeticUI = rShop:AddToggle("cosmetic_toggle", {
    Text = "Cosmetic Shop",
    Default = false,
    Callback = function(state)
        cosmeticToggle = state
        local ui = player.PlayerGui:FindFirstChild("CosmeticShop_UI")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Cosmetic Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})

local dinoUi = dino:AddToggle("dino_quest_toggle", {
    Text = "Dino Quest UI",
    Default = false,
    Callback = function(state)
        cosmeticToggle = state
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("DinoQuests_UI")
        if ui then
            ui.Enabled = not ui.Enabled
            -- Library:Notify("Cosmetic Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})

cosmeticUI:AddKeyPicker("cosmetic_keybind", {
    Text = "Cosmetic Shop",
    Default = "R",
    Mode = "Toggle",
    Callback = function(state)
        cosmeticPicker = state
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("CosmeticShop_UI")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Cosmetic Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})

local gearShop = rShop:AddToggle("gear_toggle", {
    Text = "Gear Shop",
    Default = false,
    Callback = function(state)
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Gear_Shop")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Gear Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})

gearShop:AddKeyPicker("gear_keybind", {
    Text = "Gear Shop",
    Default = "G",
    Mode = "Toggle",
    Callback = function(state)
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Gear_Shop")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Gear Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})

local seedUI = rShop:AddToggle("seed_toggle", {
    Text = "Seed Shop",
    Default = false,
    Callback = function(state)
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Seed Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})

seedUI:AddKeyPicker("seed_keybind", {
    Text = "Seed Shop",
    Default = "T",
    Mode = "Toggle",
    Callback = function(state)
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Seed Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})
local harvestShop = rShop:AddToggle("harvestshop_toggle", {
    Text = "Harvest Shop",
    Default = false,
    Callback = function(state)
        local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("EventShop_UI")
        if ui then
            ui.Enabled = not ui.Enabled
            Library:Notify("Harvest Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
        end
    end
})
-- harvestShop:AddKeyPicker("harvestshop_keybind", {
--     Text = "Harvest Shop",
--     Default = "C",
--     Mode = "Toggle",
--     Callback = function(state)
--         local ui = player.PlayerGui:FindFirstChild("EventShop_UI")
--         if ui then
--             ui.Enabled = not ui.Enabled
--             Library:Notify("Harvest Shop UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
--         end
--     end
-- })


rShop:AddButton("Daily Quest", function()
    local ui = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if ui then
        ui.Enabled = not ui.Enabled
        Library:Notify("Daily Quest UI: " .. (ui.Enabled and "Enabled" or "Disabled"))
    end
end)

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

local minWeight, maxWeight = 0, 9999
local harvestFruitNames = {}

getgenv().selectedPlants = {} -- assume table for Multi=true dropdown
local allPlant = util.allPlants()
-- Dropdown handler
group2:AddDropdown("plant_dropdown", {
	Text = "Plant List",
	Values = allPlant,
	Tooltip = "Select plants to Harvest",
	Multi = true,
	Searchable = true,
	Callback = function(values)
		getgenv().selectedPlants = util.keysOf(values)
	end
})

-- group2:AddInput("harvest_fruit_input", {
--     Text = "Fruit Names (Leave blank if all)",
--     Default = "",
--     Tooltip = "Use comma(,) to seperate fruits",
--     Callback = function(val)
--         harvestFruitNames = {}
--         for fruit in string.gmatch(val, "([^,]+)") do
--             fruit = fruit:match("^%s*(.-)%s*$") 
--             if fruit ~= "" then
--                 harvestFruitNames[fruit] = true
--             end
--         end
--         Library:Notify("Harvest fruit filter set!")
--     end
-- })

group2:AddInput("min_weight_input", {
    Text = "Min Weight (kg)",
    Default = "0",
    Callback = function(val)
        minWeight = tonumber(val) or 0
        Library:Notify("Min Weight set to: " .. tostring(minWeight))
    end
})

group2:AddInput("max_weight_input", {
    Text = "Max Weight (kg)",
    Default = "9999",
    Callback = function(val)
        maxWeight = tonumber(val) or 9999
        Library:Notify("Max Weight set to: " .. tostring(maxWeight))
    end
})

function backPackCount()
	local n = 0
	for _,t in ipairs(player.Backpack:GetChildren()) do
		if t:FindFirstChild("Weight") and t:FindFirstChild("Variant") then n += 1 end
	end
	return n
end

local autoCollect = false
group2:AddToggle("auto_collect_toggle", {
    Text = "Auto Collect",
    Default = false,
    Callback = function(state)
        autoCollect = state
        if autoCollect then
            Library:Notify("Auto Collect enabled!")
            task.spawn(function()
                while autoCollect and not Library.Unloaded do
					if backPackCount()>=200 then 
						Library:Notify("Sell some fruits first.")
						repeat task.wait(2) until backPackCount()<200
					end
                    local buffer = buffer.fromstring("\1\1\0\1")

                    for _, v in next, myFarm.Important.Plants_Physical:GetChildren() do
                        
                        if util.harvestFilter(v, minWeight, maxWeight) then
                            game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(buffer, { v })
                        end
                        if v:FindFirstChild("Fruits", true) then
                            if not autoCollect then break end
                            for _, i in next, v.Fruits:GetChildren() do
                                if util.harvestFilter(i, minWeight, maxWeight) then
                                    game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(buffer, { i })
                                end
                            end
                            task.wait(0.2)
                        end
                    end
                    task.wait(2)
                end
                Library:Notify("Auto Collect disabled!")
            end)
        else
            Library:Notify("Auto Collect disabled!")
        end
    end
})

local module = require(game:GetService("ReplicatedStorage").Modules.PlantTraitsData)
local summerPlants = module.Summer

local targetFruits = {}
for plant, _ in pairs(summerPlants) do
    targetFruits[plant] = true
end

local function isTargetFruit(item)
    if not item then return false end
    local baseName = item.Name:match("^(.-) %[[^%]]+%]$") or item.Name
    return targetFruits[baseName] == true
end


local infiniteJump = false

lPlayer:AddToggle("infinite_jump_toggle", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(enabled)
        infiniteJump = enabled
    end
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infiniteJump then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- local seedPack = creditsTab:AddRightGroupbox("Seed Pack")
creditsGroup:AddButton({
    Text = "Join Discord Server",
    Func = function()
        setclipboard("https://discord.gg/WswepWXvr9")
        Library:Notify("Discord link copied! Paste in browser to join.")
        pcall(function()
            if syn and syn.request then
                syn.request({Url = "https://discord.gg/WswepWXvr9", Method = "GET"})
            else
                game:HttpGet("https://discord.gg/WswepWXvr9")
            end
        end)
    end
})


local function allSeed()
    local seeds = { "All" } 
    for _, data in pairs(require(game:GetService("ReplicatedStorage").Data.SeedData)) do
        table.insert(seeds, data.SeedName)
        table.sort(seeds)
    end
    return seeds
end

local seedLists = allSeed()
local selectedSeeds = {}

plant:AddDropdown("seed_dropdown", {
    Values = seedLists,
    Multi = true,
    Searchable = true,
    Text = "Seeds",
    Default = {},               
    Callback = function(selected)
        local rawSelected = util.keysOf(selected)

        
        if table.find(rawSelected, "All") then
            selectedSeeds = {}
            for _, name in ipairs(seedLists) do
                if name ~= "All" then
                    table.insert(selectedSeeds, name)
                end
            end
        else
            selectedSeeds = rawSelected
        end

        Library:Notify("Selected seeds: " .. table.concat(selectedSeeds, ", "))
    end
})

local plantMode = "Random Position"
getgenv().plantPos = nil
local sPos
getgenv().plantMode = ""
plant:AddDropdown("plant_placement_mode", {
    Text = "Plant Mode",
    Values = { "Random Position", "Selected Position" },
    Default = "Random Position",
    Callback = function(selected)
        getgenv().plantMode = selected
        Library:Notify("🌱 Plant mode set to: " .. selected)

		if sPos then
			sPos:SetVisible(selected == "Selected Position")
		end
    end
})

sPos = plant:AddButton({
	Text = "Set Position", 
	Func = function()
		local char = game.Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			getgenv().plantPos = hrp.Position
			Library:Notify(("[AutoPlant] Saved at (%.1f, %.1f, %.1f)"):format(
				getgenv().plantPos.X, getgenv().plantPos.Y, getgenv().plantPos.Z
			))
		else
			Library:Notify("[AutoPlant] ❌ Couldn’t find HumanoidRootPart!", 3)
		end
	end,
	DoubleClick = false,
    Tooltip = 'Sets player position to use for auto plant'
})

if getgenv().plantMode ~= "Selected Position" then
    sPos:SetVisible(false)
end

local autoPlant = false
local seedIndex = 1
plant:AddToggle("auto_plant_toggle", {
    Text = "Auto Plant",
    Tooltip = "Stand at the place where you want to auto plant.",
    Default = false,
    Callback = function(state)
        autoPlant = state
        if autoPlant then
            if #selectedSeeds == 0 then
                Library:Notify("No seeds selected!")
                autoPlant = false
                return
            end

            Library:Notify("Auto Plant enabled!")
            task.spawn(function()
                while autoPlant and not Library.Unloaded do
					local character = game.Players.LocalPlayer.Character
                    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                    if hrp and #selectedSeeds > 0 then
                        local fullSeedName = selectedSeeds[seedIndex]
                        seedIndex += 1
                        if seedIndex > #selectedSeeds then
                            seedIndex = 1
                        end

                        
                        local function findSeedTool(name)
                            for _, container in ipairs({game.Players.LocalPlayer:WaitForChild("Backpack"), game.Players.LocalPlayer.Character}) do
                                for _, item in ipairs(container:GetChildren()) do
                                    if item:IsA("Tool") and item.Name:match("^" .. name) then
                                        return item
                                    end
                                end
                            end
                            return nil
                        end

                        local tool = findSeedTool(fullSeedName)

                        if tool and tool.Parent ~= character then
                            tool.Parent = character
                            task.wait(0.3)
                        end

                        
                        if findSeedTool(fullSeedName) then
                            local cropName = fullSeedName:gsub(" Seed", "")
                            local pos = util.getNextPlantPosition()
							if pos then
								local args = {
									vector.create(pos.X, pos.Y, pos.Z),
									cropName
								}

								game:GetService("ReplicatedStorage")
									:WaitForChild("GameEvents")
									:WaitForChild("Plant_RE")
									:FireServer(unpack(args))
							end
                        end
                    end

                    task.wait(0.1)
                end
                Library:Notify("Auto Plant disabled!")
            end)
        else
            Library:Notify("Auto Plant disabled!")
        end
    end
})

local function equip_tool_reliable(tool)
    for _ = 1, 15 do
        local char = player.Character or player.CharacterAdded:Wait()
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if tool.Parent == char then
            return true
        end
        hum:EquipTool(tool)
        task.wait(0.1)
    end
    return false
end

local CS   = require(ReplicatedStorage.Modules.CraftingService.CraftingGlobalObjectService)

local function isOnCooldown(bench)
    local data = CS:GetIndividualCraftingMachineData(
        bench,
        bench:GetAttribute("CraftingObjectType")
    )
    if data and data.CraftingItems and data.CraftingItems[1] then
		-- print(bench, "is Running | Timer: ", data.CraftingItems[1].TimeRemaining)
        return data.CraftingItems[1].TimeRemaining > 0
    end
    return false
end

do
	local DataService    = require(game:GetService("ReplicatedStorage").Modules.DataService)
    local RecipeRegistry = require(game:GetService("ReplicatedStorage").Data.CraftingData.CraftingRecipeRegistry)
	local questData = DataService:GetData()
	local containers = questData and questData.QuestContainers or {}
    local buffer   = buffer.fromstring("\001\001\000\001")
    local PetsRE   = game:GetService("ReplicatedStorage").GameEvents.PetsService
    

    local STALL_TIME = 5       -- seconds with 0 progress → abandon quest

    -------------------------------------------------------------- tiny helpers
    local function goal(q)
        return q.Required or q.Amount or q.Target
               or ((q.Arguments or q.Args or {})[#(q.Arguments or q.Args or {})]) or 1
    end
    
    local function progress(kind, key)
		task.wait()
		for _, cont in pairs(containers) do
			local name = (cont.Name or cont.Container or cont.Type or ""):lower()
			if name:find("dino") then
				for _, q in ipairs(cont.Quests or {}) do
					local args = q.Arguments or q.Args or {}
					-- print(string.format("➡️ Quest Type: %s | Target: %s | Args[1]: %s", tostring(q.Type), tostring(q.Target), tostring(args[1]))) -- matches "dino", "dinofrequent", etc.
					if q.Type == kind and (args[1] == key or args[2] == key) then
						return q.Progress or 0, goal(q)
					end
				end
			end
		end
		return 0, 1
	end
	
    

    local harvesting = false
    local function harvestCrop(crop)
	-- print(crop)
        if harvesting then return end
        harvesting = true
        local lastProg, stallT = progress("Harvest",crop)
        local t0 = os.clock()

        local function bagCnt() 
			local n = 0
            for _,it in ipairs(player.Backpack:GetChildren()) do
                if it:FindFirstChild("Weight") and it:FindFirstChild("Variant") then n+=1 end
            end; return n
        end

        while _G.autoDinoQuest and not Library.Unloaded do
            if bagCnt()>=200 then 
				Library:Notify("Sell some fruits first.")
				repeat task.wait(2) until bagCnt()<150 or not _G.autoDinoQuest 
			end
            if not _G.autoDinoQuest then break end

            -- one sweep
            local pf = myFarm and myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
            if pf then
				local found = false
                for _,pl in ipairs(pf:GetChildren()) do
                    if (pl.Name:match("^(.-) %[[^%]]+%]$") or pl.Name) == crop then
						found = true
                        game:GetService("ReplicatedStorage").ByteNetReliable:FireServer(buffer,{pl})
                        local fr = pl:FindFirstChild("Fruits")
                        if fr then for _,f in ipairs(fr:GetChildren()) do game:GetService("ReplicatedStorage").ByteNetReliable:FireServer(buffer,{f}) end end
                    end
                end
            end
			-- if not found then
			-- 	Library:Notify("No " .. crop .. " to harvest for quest", 1)
			-- end
            -- progress check / stall logic
            local prog,target = progress("Harvest",crop)
            if prog>=target then break end
            if prog>lastProg then lastProg,t0 = prog,os.clock() end      -- reset stall timer
            if os.clock()-t0>STALL_TIME then break end                  -- 🔴 stalled
            task.wait(1.5)
        end
        harvesting=false
    end

    local plantPos = nil            -- Vector3 | nil

    dino:AddButton("Save Position", function()
        local char = game.Players.LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            plantPos = hrp.Position
            Library:Notify(
                ("[AutoPlant] Position saved  (%.1f, %.1f, %.1f)")
                :format(plantPos.X, plantPos.Y, plantPos.Z)
            )
        else
            Library:Notify("[AutoPlant] Couldn’t find HumanoidRootPart!", 3)
        end
    end)

    local planting = false
    local function plantSeed(seed)
        if planting or not _G.autoDinoQuest then return end

        if not plantPos then
            Library:Notify("[AutoPlant] No position saved – click “Save Plant Position” first!", 4)
            return
        end

        planting = true
        local char   = player.Character or player.CharacterAdded:Wait()
        local bp     = player.Backpack

        local lastProg, t0 = progress("Plant", seed)
        local warnedMissing = false             -- so we don’t spam

        -- helper: locate the seed tool in backpack or character
        local function findTool()
            for _, container in ipairs({ bp, char }) do
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and item.Name:match("^" .. seed .. " Seed") then
                        return item
                    end
                end
            end
        end

        while _G.autoDinoQuest and not Library.Unloaded do
            local tool = findTool()

            if not tool then
                if not warnedMissing then
                    -- Library:Notify("[AutoPlant] Missing \"" .. seed .. " Seed\" – equip / buy more to continue.", 4)
                    warnedMissing = true
                end
            else
                if warnedMissing then warnedMissing = false end   -- reset flag

                -- make sure tool is equipped to character
                if tool.Parent ~= char then
                    tool.Parent = char
                    task.wait(0.05)         -- let server see it
                end

                -- fire Plant_RE at saved position
                game:GetService("ReplicatedStorage").GameEvents.Plant_RE:FireServer(
                    vector.create(plantPos.X, plantPos.Y, plantPos.Z),
                    seed
                )
            end

            local prog, target = progress("Plant", seed)
            if prog >= target then break end
            if prog > lastProg then lastProg, t0 = prog, os.clock() end
            if os.clock() - t0 > STALL_TIME then break end

            task.wait(0.15)
        end

        planting = false
    end

    local growing = false
	local Players = game:GetService("Players")
    local function growPet(pname)
        if growing then return end
        growing = true
        local PetsRE     = game:GetService("ReplicatedStorage").GameEvents.PetsService
        local player     = Players.LocalPlayer
        local bp         = player.Backpack
        local char       = player.Character or player.CharacterAdded:Wait()
        local lastProg, t0 = progress("GrowPetToAge", pname)

        local function unequipOthers()
            for _, mdl in ipairs(workspace:GetDescendants()) do
                if mdl:IsA("Model") and mdl:GetAttribute("OWNER") == player.Name then
                    local n = mdl:GetAttribute("PetName") or mdl.Name
                    if n ~= pname then
                        local uuid = mdl:GetAttribute("PET_UUID") or mdl:GetAttribute("c")
                        if uuid then
                            PetsRE:FireServer("UnequipPet", uuid)
                        end
                    end
                end
            end
        end

        local function equipOne()
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "Pet" then
                    local base = tool.Name:match("^(.-)%s*%[") or tool.Name
                    if base == pname then
                        local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("c")
                        if uuid then
                            -- move tool to character before firing EquipPet
                            if tool.Parent ~= char then
                                tool.Parent = char
                                task.wait(0.15)
                            end
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            PetsRE:FireServer("EquipPet", uuid, hrp and hrp.CFrame or CFrame.new())
                            return
                        end
                    end
                end
            end
        end

        unequipOthers()
        equipOne()

        while _G.autoDinoQuest and not Library.Unloaded do
            local prog, target = progress("GrowPetToAge", pname)
            if prog >= target then break end
            if prog > lastProg then lastProg, t0 = prog, os.clock() end
            if os.clock() - t0 > STALL_TIME then break end
            equipOne()
            task.wait(5)
        end

        growing = false
    end

	local RecipeRegistry = require(game:GetService("ReplicatedStorage").Data.CraftingData.CraftingRecipeRegistry)
	local craftingRemote = game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService

	local function baseName(toolName)
		local noBrackets = toolName:gsub("%s*%b[]", "")        -- remove “[…]”
		return (noBrackets
		:gsub("%s*[xX]%d+$", "")                            -- strip “ xN”
		:gsub("%s+$",""))                                   -- trim end spaces
	end

	local ReversedItemTypeEnums = require(game:GetService("ReplicatedStorage").Data.EnumRegistry.ReversedItemTypeEnums)
	local inventory_enums = {
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
	function equipTool(tool)
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
	local item_codes = {}
	for k, v in pairs(util.item_types) do
		item_codes[v] = k
	end
	local function fetchInput(req)
		-- print("🎯 Looking for input:")
		-- print("   ItemType →", tostring(req.ItemType))
		-- print("   ItemName →", tostring(req.ItemData and req.ItemData.ItemName))
		local player = game:GetService("Players").LocalPlayer
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if not tool:IsA("Tool") then continue end

			local toolName = baseName(tool.Name)
			local attrItemType = tool:GetAttribute("b")
			local attrItemName = tool:GetAttribute("f") or tool:GetAttribute("l") or toolName
			local attrUUIDKey = inventory_enums["ITEM_UUID"]
			local decodedType = item_codes[attrItemType] or "???"
			local base = baseName(toolName)

			-- print(string.format("🧰 Tool: %s | TypeAttr: %s (%s) | NameAttr: %s | Base: %s",
			-- 	toolName, tostring(attrItemType), decodedType, tostring(attrItemName), base))

			-- Type/Name fallback logic
			local matchesType = (not req.ItemType) or (decodedType == req.ItemType)
			local matchesName = attrItemName and req.ItemData and string.lower(attrItemName) == string.lower(req.ItemData.ItemName)

			if matchesType and matchesName then
				tool.Parent = player.Character
				equipTool(tool)
				return tool:GetAttribute(attrUUIDKey) or tool:GetAttribute("c")
			end
		end

		warn("❌ No match for → Type:", req.ItemType, "Name:", req.ItemData.ItemName)
		return nil
	end


	local function modelFor(machineType)
		if machineType == "GearEventWorkbench" then
			return workspace.CraftingTables.EventCraftingWorkBench
		elseif machineType == "DinoEventWorkbench" then
			return workspace.DinoEvent.DinoCraftingTable
		elseif machineType == "SeedEventWorkbench" then
			return workspace.CraftingTables.SeedEventCraftingWorkBench
		end
	end

	local crafting = false
	local function craftItem(itemName)
		if crafting then return end
		crafting = true

		local recipe = RecipeRegistry.ItemRecipes[itemName]
		if not recipe then
			Library:Notify("[AutoCraft] No recipe for "..itemName, 3)
			crafting = false
			return
		end

		local machineType = recipe.MachineTypes[1]
		local bench = modelFor(machineType)
		-- print("IsRunning:", bench:GetAttribute("IsRunning"))
		if not bench then
			Library:Notify("[AutoCraft] Missing bench for "..machineType, 3)
			crafting = false
			return
		end
		
		local lastProg, t0 = progress("Craft", itemName), os.clock()

		while _G.autoDinoQuest and not Library.Unloaded do
			if isOnCooldown(bench) then
                task.wait(2)
                continue
			else
				craftingRemote:FireServer("Claim", bench, machineType, 1)
				craftingRemote:FireServer("SetRecipe", bench, machineType, itemName)
				task.wait(0.25)
				
				local missing = false
				for slot, req in ipairs(recipe.Inputs or {}) do
					local uuid = fetchInput(req)
					if not uuid then
						Library:Notify("[AutoCraft] Need "..req.ItemData.ItemName, 3)
						missing = true
						break
					end
					task.wait(1)
					craftingRemote:FireServer(
						"InputItem",
						bench, machineType, slot,
						{ ItemType = req.ItemType, ItemData = { UUID = uuid } }
					)
					task.wait(0.15)
				end
				if missing then break end

				-- 3) craft
				craftingRemote:FireServer("Craft", bench, machineType)

				-- 4) stall-aware completion
				repeat
					local prog, tgt = progress("Craft", itemName)
					if prog > lastProg then lastProg, t0 = prog, os.clock() end
					if os.clock() - t0 > STALL_TIME then break end
					task.wait(1)
				until prog >= tgt

				break  -- done crafting this batch
			end
		end

		crafting = false
	end
	
	local stalledTasks = {}
    local function supervisor()
        task.spawn(function()
            while _G.autoDinoQuest and not Library.Unloaded do
                for _,cont in pairs(containers) do
                    local name = (cont.Name or cont.Container or cont.Type or ""):lower()
					if name:find("dino") then
                        for _,q in ipairs(cont.Quests or {}) do
                            local prog, tgt = q.Progress or 0, goal(q)
                            if prog >= tgt then continue end
							local key = tostring(q.Type) .. "_" .. tostring((q.Arguments or q.Args or {})[1])
							if stalledTasks[key] and os.clock() - stalledTasks[key] < 5 then continue end

							local arg1 = (q.Arguments or q.Args or {})[1]
							local before = prog

							if q.Type == "Harvest" then
								harvestCrop(arg1)
							elseif q.Type == "Plant" then
								plantSeed(arg1)
							elseif q.Type == "GrowPetToAge" then
								growPet(arg1)
							elseif q.Type == "Craft" then
								local itemName = (q.Arguments or q.Args or {})[2]
								if itemName then craftItem(itemName) end
							end

							if (q.Progress or 0) == before then
								stalledTasks[key] = os.clock()
							end
							task.wait(0.15)
                        end
                    end
                end
                task.wait(1.5)
            end
        end)
    end

    _G.autoDinoQuest = false
    dino:AddToggle("auto_dino_quest", {
        Text = "Auto Dino Quest",
        Tooltip = "Save Position first before you toggle this.",
        Default = false,
        Callback = function(v)
            _G.autoDinoQuest = v
            if v then Library:Notify("[AutoDinoQuest] Enabled") supervisor()
            else     Library:Notify("[AutoDinoQuest] Disabled") end
        end
    })
end

dino:AddToggle("auto_claimq", {
	Text = "Auto Claim Quest",
	Default = false,
	Callback = function(state)
		claimQ = state
		local questSlot = {1, 2, 3, 4, 5}

		task.spawn(function()
			while claimQ and not Library.Unloaded do
				for _, v in ipairs(questSlot) do
					pcall(function()
						game:GetService("ReplicatedStorage").GameEvents.ClaimDinoQuest:InvokeServer(v)
						-- print("Tried claiming quest", v)
					end)
					task.wait(0.25)
				end
				task.wait(2) -- Wait before repeating the claim cycle
			end
		end)
	end
})



local autoRemove = false
local selectedFruits = {}
-- Dropdown handler
plant:AddDropdown("plant_dropdown", {
	Text = "Plant List",
	Values = allPlant,
	Tooltip = "Select plants to shovel",
	Multi = true,
	Searchable = true,
	Callback = function(values)
		selectedFruits = util.keysOf(values)
	end
})

local function isSelected(name)
	return selectedFruits["All"] or selectedFruits[name]
end


local reclaimRemote = game:GetService("ReplicatedStorage").GameEvents:WaitForChild("ReclaimerService_RE")
local plantsFolder = util.myFarm():FindFirstChild("Important"):FindFirstChild("Plants_Physical")
plant:AddToggle("auto_reclaim", {
	Text = "Auto Reclaim",
	Default = false,
	Callback = function(state)
		autoReclaim = state
		if not state then return end

		task.spawn(function()
			while autoReclaim and not Library.Unloaded do
				local didReclaim = false

				if plantsFolder then
					-- print("Done")
					for _, plant in ipairs(plantsFolder:GetChildren()) do
						if not autoReclaim then break end
						if not plant:IsA("Model") then continue end

						local baseName = util.cleanPlantName(plant.Name)
						if not isSelected(baseName) then continue end

						reclaimRemote:FireServer("TryReclaim", plant)
						didReclaim = true
						-- print("✅ Reclaimed", plant.Name)
						task.wait(0.1)
					end
				end

				task.wait(didReclaim and 0.3 or 1)
			end
		end)
	end
})

local RemoveItemRemote = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Remove_Item")

local shovelActive = false
local autoShovelToggle

local plantsFolder = myFarm:WaitForChild("Important"):WaitForChild("Plants_Physical")

local maxFruitWeight = math.huge

plant:AddInput("max_weight_input", {
	Text = "Max Fruit Weight",
	Tooltip = "Only shovel fruits with weight less than or equal to this value",
	Placeholder = "e.g. 2.5",
	Numeric = true,
	Callback = function(value)
		local num = tonumber(value)
		if num then
			maxFruitWeight = num
			Library:Notify("Max fruit weight set to: " .. num)
		else
			Library:Notify("Invalid weight value.")
		end
	end
})
------------------------------------------------------------------
--  🗑️  Auto Shovel
--       • If the plant has a “Fruits” folder → only removes those fruits
--       • Otherwise removes the plant model itself
------------------------------------------------------------------
local RemoveItemRemote = game:GetService("ReplicatedStorage").GameEvents.Remove_Item   -- adjust if your remote is named differently
local shovelName       = "Shovel [Destroy Plants]"

------------------------------------------------------------------
-- helper —— equip shovel, return true on success
------------------------------------------------------------------
local function equipShovel()
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    if not character:FindFirstChild(shovelName) then
        local shovel = backpack:FindFirstChild(shovelName)
        if shovel then hum:EquipTool(shovel) end
    end
    for i = 1,10 do                                            -- ≤0.5 s
        if character:FindFirstChild(shovelName) then return true end
        task.wait(0.05)
    end
    return false
end

------------------------------------------------------------------
-- helper —— unequip *any* tool when we want to pause
------------------------------------------------------------------
local function unequip()
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then hum:UnequipTools() end
end


plant:AddToggle("auto_shovel_toggle", {
    Text = "Auto Shovel",
    Tooltip = "Destroys fruits (or whole plant if no Fruits folder)",
    Default = false,
    Callback = function(state)
        autoRemove = state
        if not state then unequip(); return end                -- 🔹 toggle-off

        task.spawn(function()
            while autoRemove and not Library.Unloaded do
                local didSomething = false

                -------------------------------------------------- main sweep
                for _, plant in ipairs(plantsFolder:GetChildren()) do
                    if not autoRemove then break end

                    local base = util.cleanPlantName(plant.Name)
                    if not (table.find(selectedFruits,"All") or table.find(selectedFruits,base)) then
                        continue
                    end

                    ------------------------------------------------ Fruits?
                    local bucket = plant:FindFirstChild("Fruits") and plant.Fruits:GetChildren() or {plant}

                    for _, obj in ipairs(bucket) do
                        if not autoRemove then break end

                        local wv = obj:FindFirstChild("Weight") ;  local w = wv and wv.Value or 0
                        if w > maxFruitWeight or obj:GetAttribute("Favorited") then continue end

                        local tgt = obj:IsA("Model")
                                and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                                 or (obj:IsA("BasePart") and obj)
                        if tgt and equipShovel() then
                            RemoveItemRemote:FireServer(tgt)
                            didSomething = true
                            task.wait(0.05)
                        end
                    end
                end

                -------------------------------------------------- pause → unequip
                if not didSomething then unequip() end
                task.wait(didSomething and 0.3 or 1)
            end

            -- loop exited (toggle-off / script unload) – tidy up
            unequip()
        end)
    end
})

local function isSelectedFruit(name)
	for _, fruit in ipairs(selectedFruits) do
		if fruit == name then return true end
	end
	return false
end

-- Auto shovel loop
task.spawn(function()
	while not Library.Unloaded do
		if autoRemove then
			task.wait(0.4)
			if not game.Players.LocalPlayer.Character or not game.Players.LocalPlayer.Character:FindFirstChild("Shovel [Destroy Plants]") then continue end

			local farm = myFarm
			local plantFolder = farm and farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
			if not plantFolder then continue end

			for _, model in ipairs(plantFolder:GetChildren()) do
				if model:IsA("Model") and isSelectedFruit(model.Name) then
                -- print(isSelectedFruit(model.Name))
					game:GetService("ReplicatedStorage").GameEvents:WaitForChild("Remove_Item"):FireServer("Part", model)
				end
			end
		else
			game:GetService("RunService").RenderStepped:Wait()
		end
	end
end)


local petRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("Data"):WaitForChild("PetRegistry"):WaitForChild("PetList"))

local petlist = {}
for petName, _ in pairs(petRegistry) do
    table.insert(petlist, petName)
end
table.sort(petlist)

local selectedpets = {}

local function getSelectedNames()
    local names = {}
    if typeof(selectedpets) == "table" then
        if #selectedpets > 0 then
            
            for _, name in ipairs(selectedpets) do
                table.insert(names, name)
            end
        else
            
            for name, val in pairs(selectedpets) do
                if val then table.insert(names, name) end
            end
        end
    end
    return names
end

-- local function getBaseName(toolName)
--     return (toolName:gsub("%s*%b[]", "")):gsub("^%s*(.-)%s*$", "%1")
-- end


dino:AddDropdown("dna", {
    Text = "Pet List",
    Default = {},
    Multi = true,
    Searchable = true,
    Values = petlist,
    Callback = function(selected)
        -- print("Callback fired")
        selectedpets = selected
        
        if #selectedpets > 0 then
            -- print(table.concat(selectedpets, ", "))
        else
            local names = {}
            for name, val in pairs(selectedpets) do
                if val then table.insert(names, name) end
            end
        end
    end
})

--------------------------------------------------------------------
--  ⚡ Fast Auto-DNA  (skips if machine busy)
--------------------------------------------------------------------
local autoDNA   = false
local DS        = require(game:GetService("ReplicatedStorage").Modules.DataService)
local DNA_RE    = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("DinoMachineService_RE")

-- helper ▸ strip “[ … ]” parts from a tool name → base species
local function base(name)  return (name:gsub("%s*%b[]","")) end

-- helper ▸ O(1) membership test
local function toSet(t)
    local s = {};  for _,v in ipairs(t) do s[v]=true end;  return s
end

-- helper ▸ true while the Dino-Machine is working
local function machineBusy()
    local d = DS:GetData()
    return d and d.DinoMachine and d.DinoMachine.IsRunning
end

dino:AddToggle("autodnapets",{
    Text    = "Auto DNA",
    Default = false,
    Callback = function(state)
        autoDNA = state
        if not state then
            Library:Notify("[AutoDNA] Disabled")
            return
        end

        Library:Notify("[AutoDNA] Enabled")

        -- snapshot the user’s current selection once;   
        -- if your UI lets them change the list at runtime,  
        -- just rebuild wanted-set inside *that* callback instead.
        local wanted = toSet(getSelectedNames())
		local player = game:GetService("Players").LocalPlayer
		local character = player.Character
		local backpack = player.Backpack
        task.spawn(function()
            while autoDNA and not Library.Unloaded do
                -----------------------------------------------------
                -- only act while machine is idle
                -----------------------------------------------------
				local label = workspace.DinoEvent.BenchRewardPart.BenchPart.BillboardPart.BillboardGui.DnaMachineLabel
				if label and label.Text == "READY" then 
					game:GetService("ReplicatedStorage")
                    .GameEvents
                    .DinoMachineService_RE
                    :FireServer("ClaimReward")
				end
                if not machineBusy() then
                    for _,tool in ipairs(backpack:GetChildren()) do
                        if  tool:IsA("Tool")
                        and tool:GetAttribute("ItemType")=="Pet"
                        and wanted[ base(tool.Name) ]
                        and not tool:GetAttribute("d")          -- not already DNA’d
                        then
                            ----------------------------------------------------------------
                            -- 1) equip to character
                            ----------------------------------------------------------------
                            tool.Parent = character
                            task.wait()            -- tiny yield so the server registers equip

                            ----------------------------------------------------------------
                            -- 2) start machine
                            ----------------------------------------------------------------
                            DNA_RE:FireServer("MachineInteract")

                            break                  -- machine is now busy; wait for it to finish
                        end
                    end
                end

                task.wait(0.25)  -- iterate ~4× per s; tweak as you like
            end
        end)
    end
})
local auto_claim_enabled = false

-- ▶️ Toggle only sets the flag
dino:AddToggle("auto_claim", {
    Text    = "Auto Claim",
    Default = false,
    Callback = function(state)
        auto_claim_enabled = state
    end
})

-- ▶️ Background task that always runs
task.spawn(function()
    while not Library.Unloaded do
        if auto_claim_enabled then
            -- grab the READY label
            local label = workspace.DinoEvent.BenchRewardPart.BenchPart.BillboardPart.BillboardGui.DnaMachineLabel
			-- print(label.Text)

            if label and label.Text == "READY" then
                -- one-liner remote
                game:GetService("ReplicatedStorage")
                    .GameEvents
                    .DinoMachineService_RE
                    :FireServer("ClaimReward")
            end
        end

        task.wait(1)  -- check every second
    end
end)

local selectedpetss = {}
local function getSelectedNamess()
    local names = {}
    if typeof(selectedpetss) == "table" then
        if #selectedpetss > 0 then
            
            for _, name in ipairs(selectedpetss) do
                table.insert(names, name)
            end
        else
            
            for name, val in pairs(selectedpetss) do
                if val then table.insert(names, name) end
            end
        end
    end
    return names
end

pet:AddDropdown("sellpetsd", {
    Text = "Pet List",
    Default = {},
    Multi = true,
    Searchable = true,
    Values = petlist,
    Callback = function(selected)
        -- print("Callback fired")
        selectedpetss = selected
        
        if #selectedpetss > 0 then
            -- print(table.concat(selectedpetss, ", "))
        else
            local names = {}
            for name, val in pairs(selectedpetss) do
                if val then table.insert(names, name) end
            end
        end
    end
})
-- local minPetWeight = 0
pet:AddInput("MinWeight", {
    Text = "Min Weight (kg)",
    Placeholder = "Default 0",
    Callback = function(value)
        minPetWeight = tonumber(value)
        Library:Notify("Min weight set to: " .. (minPetWeight or "none"))
    end
})
-- local minPetWeight = 999
pet:AddInput("MaxWeight", {
    Text = "Max Weight (kg)",
    Placeholder = "Default: 999",
    Callback = function(value)
        maxPetWeight = tonumber(value)
        Library:Notify("Max weight set to: " .. (maxPetWeight or "none"))
    end
})

pet:AddInput("MinAge", {
    Text = "Min Age",
    Placeholder = "e.g. 2",
    Callback = function(value)
        minPetAge = tonumber(value)
        Library:Notify("Min age set to: " .. (minPetAge or "none"))
    end
})

local function extractStatsFromName(name)
    local weight = tonumber(name:match("%[(%d+%.?%d*)%s*KG%]")) or 0
    local age = tonumber(name:match("%[Age%s*(%d+)%]")) or 0
    return weight, age
end

pet:AddToggle("togglesellpet", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(state)
        autosellpets = state

        if autosellpets then
            task.spawn(function()
                local sellRemote = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("SellPet_RE")

                while autosellpets and not Library.Unloaded do
                    for _, selectedName in ipairs(getSelectedNamess()) do
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:GetAttribute("ItemType") == "Pet" then
                                local baseName = util.getBaseName(tool.Name)
                                local weight, age = extractStatsFromName(tool.Name)
								local fave = tool:GetAttribute("d")
                                if baseName == selectedName then
                                    local passesWeight = (not minPetWeight or weight >= minPetWeight)
                                        and (not maxPetWeight or weight <= maxPetWeight)
                                    local passesAge = (not minPetAge or age < minPetAge)

                                    if passesWeight and passesAge and not fave then
                                        local current = character:FindFirstChildOfClass("Tool")
                                        if current and current ~= tool then
                                            current.Parent = backpack
                                            task.wait(0.2)
                                        end

                                        tool.Parent = character

                                        local timeout = 3
                                        while tool.Parent ~= character and timeout > 0 do
                                            task.wait(0.1)
                                            timeout -= 0.1
                                        end

                                        if tool.Parent == character then
                                            sellRemote:FireServer(tool)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})


local giftEvent = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("GiftPet")
local acceptGiftRemote = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("AcceptPetGift")
local giftNotification = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Gift_Notification")

pet:AddToggle("autoacceptpet", {
    Text = "Auto Accept Pet",
    Default = false,
    Callback = function(state)
        autoacceptpet = state
        
        giftEvent.OnClientEvent:Connect(function(petUUID, petName, fromPlayerName)
            acceptGiftRemote:FireServer(true, petUUID)
        end)
    end
})

local autogiftpets = false

local function getClosestPlayer()
    local closest = nil
    local shortest = math.huge
    local myChar = player.Character or player.CharacterAdded:Wait()
	local Players = game:GetService("Players")
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local dist = (myChar:GetPivot().Position - other.Character:GetPivot().Position).Magnitude
            if dist < MIN_DISTANCE and dist < shortest then
                closest = other
                shortest = dist
            end
        end
    end

    return closest
end

pet:AddToggle("autogiftpets", {
    Text = "Auto Gift Selected Pets",
    Tooltip = "Will gift pet to nearest player",
    Default = false,
    Callback = function(state)
        autogiftpets = state

        if autogiftpets then
            task.spawn(function()
                Library:Notify("[AutoGift] Enabled")

                while autogiftpets and not Library.Unloaded do
                    local targetPlayer = getClosestPlayer()

                    if targetPlayer and backpack then
                        for _, selectedName in ipairs(getSelectedNames()) do
                            for _, tool in ipairs(backpack:GetChildren()) do
                                if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "Pet" then
                                    local baseName = util.getBaseName(tool.Name)

                                    if baseName == selectedName and not tool:GetAttribute("d") then
                                        local currentTool = character:FindFirstChildOfClass("Tool")
                                        if currentTool and currentTool ~= tool then
                                            currentTool.Parent = backpack
                                            task.wait(0.1)
                                        end
                                        tool.Parent = character
                                        local timeout = 3
                                        while tool.Parent ~= character and timeout > 0 do
                                            task.wait(0.1)
                                            timeout -= 0.1
                                        end
                                        if tool.Parent == character then
                                            giftingService:GivePet(targetPlayer)
                                            task.wait(0.1)
                                        end

                                        break
                                    end
                                    
                                    local timeout = 3
                                    while tool.Parent ~= character and timeout > 0 do
                                        task.wait(0.1)
                                        timeout -= 0.1
                                    end

                                end
                            end
                        end
                    end

                    task.wait(1)
                end

                Library:Notify("[AutoGift] Disabled")
            end)
        else
            Library:Notify("[AutoGift] Turned Off")
        end
    end
})

local plantsList
local function getPlants()
    if not myFarm then return {} end
    local plantsFolder = myFarm:FindFirstChild("Important"):FindFirstChild("Plants_Physical")
    local uniqueNames = {}
    plantsList = {}

    if plantsFolder then
        for _, plant in ipairs(plantsFolder:GetChildren()) do
            if plant:isA("Model") then
                local name = plant.Name
                if not uniqueNames[name] then
                    uniqueNames[name] = true
                    table.insert(plantsList, name)
                end
            end
        end
    end
    return plantsList
end

getgenv().selectedPlantss = {}
local plantsList = getPlants()
trowel:AddDropdown("current_plant_dropdown", {
    Text = "Owned Plants",
    Default = {},
    Multi = true,
    Searchable = true,
    Values = plantsList,
    Callback = function(selected)
        getgenv().selectedPlantss = {}

        if typeof(selected) == "table" then
            for k, v in pairs(selected) do
                if v then
                    table.insert(getgenv().selectedPlantss, k)
                end
            end
        else
            table.insert(getgenv().selectedPlantss, selected)
        end
	end
})

trowel:AddToggle("remote_trowel", {
    Text = "Move",
    Default = false,
    Callback = function(state)
        util.moveSelectedPlantType()
    end
})

local replicated_storage = game:GetService("ReplicatedStorage")
local players            = game:GetService("Players")

local registry           = require(replicated_storage.Data.CraftingData.CraftingRecipeRegistry)
local crafting_remote    = replicated_storage.GameEvents.CraftingGlobalObjectService

local player   = players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

local recipes_by_name = registry.ItemRecipes               -- { [itemName] = recipeData, ... }
-- UI state
local selected_recipe, selected_machine_type, auto_craft_enabled = nil, nil, false

-- build dropdown values
local all_recipe_names = {}
for name in pairs(recipes_by_name) do
    table.insert(all_recipe_names, name)
end
table.sort(all_recipe_names)

-----------------------------------------------------------------
--  UI SETUP
-----------------------------------------------------------------
craft:AddDropdown("craft_dropdown", {
    Text       = "Select Recipe",
    Tooltip    = "Pick any recipe to craft",
    Values     = all_recipe_names,
    Searchable = true,
    Callback   = function(recipe_name)
        selected_recipe        = recipe_name
        selected_machine_type  = recipes_by_name[recipe_name].MachineTypes[1]
        print("🍳 Selected:", recipe_name, "→", selected_machine_type)
    end
})

craft:AddToggle("auto_craft_toggle", {
    Text    = "Auto Craft",
    Default = false,
    Callback = function(state)
        auto_craft_enabled = state
    end
})

local function equip_tool_reliable(tool)
    for _ = 1, 15 do
        local char = player.Character or player.CharacterAdded:Wait()
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if tool.Parent == char then
            return true
        end
        hum:EquipTool(tool)
		-- task.wait(1)
		-- hum:UnequipTools(tool)
        task.wait(0.1)
    end
    return false
end
local inv_enums = require(game:GetService("ReplicatedStorage").Data.EnumRegistry.InventoryServiceEnums)
local reverseEnum = require(game:GetService("ReplicatedStorage").Data.EnumRegistry.ReversedItemTypeEnums)

local function uuid_for_input(input_req)
	local want_type = input_req.ItemType
	local want_name = input_req.ItemData.ItemName
	-- print("Required Type: ",want_type)
	-- print("Required Name:", want_name)
	-- print("Want name: %s | Want type %s", want_name, want_type)
	for _, tool in ipairs(backpack:GetChildren()) do
		local base_name = util.getBaseName(tool.Name)
		-- print("Basename:",base_name)
		local raw_type = tool:GetAttribute(inv_enums.ITEM_TYPE) or tool:GetAttribute("b")
		local reverse_type = reverseEnum[raw_type]

		local attr_name = tool:GetAttribute("ItemName") or tool:GetAttribute(inv_enums.ItemName) or tool:GetAttribute("l")

		-- DEBUG
		-- print(string.format("🧪 Checking tool: %s | base: %s | attr_name: %s | type: %s", tool.Name, base_name, tostring(attr_name), tostring(reverse_type)))
		
		if tostring(attr_name) == tostring(want_name) and tostring(want_type) == tostring(reverse_type) then
			if equip_tool_reliable(tool) then
				task.wait(0.5)
				return tool:GetAttribute("UUID") or tool:GetAttribute("c")
			else
				warn("⚠️ Failed to equip tool:", tool.Name)
			end
		end
	end

	warn("❌ Couldn't find tool for:", want_name, want_type)
	return nil
end

-- isOnCooldown(workspace.CraftingTables.EventCraftingWorkBench)

task.spawn(function()
    while not Library.Unloaded do
        if auto_craft_enabled and selected_recipe and selected_machine_type then

            -- pause if either bench is still cooling down
            local tbl = workspace.CraftingTables
			-- isOnCooldown(tbl.EventCraftingWorkBench)
            if isOnCooldown(tbl.EventCraftingWorkBench)
            or  isOnCooldown(tbl.SeedEventCraftingWorkBench) then
                task.wait(2)
                continue
            end
			-- print("hehe")

            -- global pause: any machine busy?
            local anyBusy = false
            for _, m in ipairs(workspace:GetDescendants()) do
                if m.GetAttribute
                   and m:GetAttribute("CraftingObjectType") == selected_machine_type
                   and m:GetAttribute("IsRunning")
                then
                    anyBusy = true
                    break
                end
            end

            if not anyBusy then
				crafting_remote:FireServer("Claim", machine, selected_machine_type, 1)
                -- scan all idle machines and trigger craft
                for _, machine in ipairs(workspace:GetDescendants()) do
                    if machine.GetAttribute
                       and machine:GetAttribute("CraftingObjectType") == selected_machine_type
                       and not machine:GetAttribute("IsRunning")
                    then

						crafting_remote:FireServer("Claim", machine, selected_machine_type, 1)
                        -- print("🏆 Claimed:", selected_recipe)
                        -- set recipe
                        crafting_remote:FireServer("SetRecipe", machine, selected_machine_type, selected_recipe)
                        task.wait(0.2)

                        -- feed ingredients
                        local missing = false
                        for slot, input_req in ipairs(recipes_by_name[selected_recipe].Inputs or {}) do
                            local uuid = uuid_for_input(input_req)
                            if not uuid then
                                Library:Notify(("❌ Missing %s"):format(input_req.ItemData.ItemName), 3)
                                task.wait(5)
                                missing = true
                                break
                            end
                            crafting_remote:FireServer(
                                "InputItem",
                                machine, selected_machine_type, slot,
                                { ItemType = input_req.ItemType, ItemData = { UUID = tostring(uuid) } }
                            )
                            task.wait(0.1)
							-- print("inputted")
							player.Character.Humanoid:UnequipTools()
                        end

                        -- craft & claim
                        if not missing then
                            crafting_remote:FireServer("Craft", machine, selected_machine_type)
                            -- print("🎬 Crafting started:", selected_recipe)

                            while machine:GetAttribute("IsRunning") do
                                task.wait(1)
                            end
                        end
                    end
                end
            end
        end

        task.wait(2)
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local SeedPackData = require(ReplicatedStorage.Data.SeedPackData)

local localPlayer = Players.LocalPlayer
local selectedPacks = {}
local autoOpen = false
local busy = false

-- List available packs
-- print("🧪 Valid seed pack names:")
-- for k in pairs(SeedPackData.Packs) do
-- 	print(" -", k)
-- end

-- Build pack list
local function getPackNames()
	local names = {}
	for k in pairs(SeedPackData.Packs) do
		table.insert(names, k)
	end
	table.sort(names)
	return names
end

-- Listen for result
Remotes.SeedPack.Result.listen(function(data)
	busy = false
	print("✅ Opened:", data.seedPackType)
	Remotes.SeedPack.SpinFinished.send()
end)

-- Dropdown
seedShop:AddDropdown("seedpack_dropdown", {
	Text = "Select Seed Packs",
	Values = getPackNames(),
	Multi = true,
	Default = {},
	Callback = function(selection)
		selectedPacks = util.keysOf(selection) -- converts dictionary to array
		if #selectedPacks > 0 then
			print("📦 Selected Packs:", table.concat(selectedPacks, ", "))
		else
			selectedPacks = {}
			print("⚠️ No seed packs selected.")
		end
	end
})

seedShop:AddToggle("auto_seed_toggle", {
	Text = "Auto Open Seed Packs",
	Default = false,
	Callback = function(state)
		autoOpen = state

		if not state then
			print("🛑 Auto Open Disabled")
			busy = false -- force-stop any stuck loop
			return
		end

		print("🚀 Auto Open Enabled")

		task.spawn(function()
			while autoOpen do
				if #selectedPacks == 0 then
					print("⚠️ No packs selected.")
					break
				end

				for _, packName in ipairs(selectedPacks) do
					if not autoOpen then break end
					if busy then continue end

					busy = true
					print("🎯 Sending pack:", packName)

					pcall(function()
						Remotes.SeedPack.Open.send(packName)
					end)

					-- Wait until server confirms spin is done or we toggle off
					while busy and autoOpen do
						task.wait(0.1)
					end
				end

				task.wait(0.5)
			end
		end)
	end
})


ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:SetIgnoreIndexes({"MenuKeybind"})

ThemeManager:SetFolder("Y-Hub")
SaveManager:SetFolder("Y-Hub/Grow-a-Garden")

ThemeManager:ApplyToTab(setting["UI Settings"])
SaveManager:BuildConfigSection(setting["UI Settings"])

if SaveManager:GetAutoloadConfig() == "none" then
    SaveManager:SaveAutoloadConfig("Grow-a-Garden")
end

SaveManager:LoadAutoloadConfig()
SaveManager:AutoSave(1)
