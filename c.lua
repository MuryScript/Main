repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

getgenv().MuryRunning = getgenv().MuryRunning or false

getgenv().MuryShared = getgenv().MuryShared or {}
getgenv().MuryShared.SellKnivesActive = getgenv().MuryShared.SellKnivesActive or false

if getgenv().MuryRunning or game.PlaceId ~= 125003919504672 then return end
getgenv().MuryRunning = true

local Shared = getgenv().MuryShared or {}
getgenv().MuryShared = Shared
Shared.SellKnivesActive = false

local State = {
    SpawnsCrate = false,
    SpawnsCrateRunning = false,
    BuyCrates = false,
    BuyCratesRunning = false,
    AutoSell = false,
    AutoSellRunning = false,
    SellKnives = false,
    SellKnivesRunning = false,
    SellCooldown = 2,
    PrefRarity = {},
    PrefMutation = {},
    SellRarity = {},
    SellMutation = {},
    SellMethod = "Rarity & Mutation",
    BuyCrateMethod = "Rarity & Mutation",
    PlaytimeClaim = false,
    PlaytimeRunning = false,
    SpinWheel = false,
    SpinRunning = false
}

local Rayfield
do
    local src = game:HttpGet("https://sirius.menu/rayfield")
    Rayfield = loadstring(src)()
end

local Window = Rayfield:CreateWindow({
    Name = "Murysium Legacy - My Knife Farm",
    ScriptID = "sid_vti2ntudfwkr",
    Icon = 139828479294253,
    LoadingTitle = "v1",
    LoadingSubtitle = "Initializing...",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = { Enabled = false},
    Discord = { Enabled = false },
    KeySystem = false,
})

local HomeTab = Window:CreateTab("Home", "home")
local FarmTab = Window:CreateTab("Farm", "bot")
local SellTab = Window:CreateTab("Sell", "shopping-cart")
local MiscTab = Window:CreateTab("Misc", "circle-ellipsis")

HomeTab:CreateButton({
    Name = "Copy Discord Invite",
    Callback = function()
        setclipboard("https://discord.gg/CZCjz2UTkM")
        Rayfield:Notify({ Title = "Copied!", Content = "Discord link copied.", Duration = 3 })
    end,
})

HomeTab:CreateParagraph({
    Title = "Supported Games",
    Content = "Be a Lucky Block\nZoo or Oof\nMy Knife Farm\nSlime RNG",
})

local PlayerPlot
repeat
    for _, Plot in pairs(workspace.Plots:GetChildren()) do
        if Plot:GetAttribute("Owner") == Player.UserId then
            PlayerPlot = Plot
            break
        end
    end
    task.wait()
until PlayerPlot

local function GetBaseModel()
    return PlayerPlot and PlayerPlot:FindFirstChild("Plot_Models")
        and PlayerPlot.Plot_Models:FindFirstChild("BaseModel")
end

local function GetSpawnPoint()
    local base = GetBaseModel()
    return base and base:FindFirstChild("PackConveyor")
        and base.PackConveyor:FindFirstChild("SpawnedCase")
end

local function GetSellPart()
    local base = GetBaseModel()
    return base and base:FindFirstChild("SellButton")
        and base.SellButton:FindFirstChild("SellP")
end

local function GetBoxStand()
    local base = GetBaseModel()
    return base and base:FindFirstChild("BoxStand")
end

local function GetKnivesPrompt()
    local stand = GetBoxStand()
    return stand and stand:FindFirstChild("ProximityPrompt")
end

local Events = ReplicatedStorage:WaitForChild("Events")
local GamePath = Events:WaitForChild("Game")
local RewardPath = Events:WaitForChild("Rewards")

local BuyCrate = GamePath:WaitForChild("CaseTriggered")
local SellRemote = GamePath:WaitForChild("SellThis")
local CodeRemote = RewardPath:WaitForChild("RedeemEvent")
local SpinRemote = RewardPath:WaitForChild("SpinRewards")
local PlaytimeRemote = RewardPath:WaitForChild("TimeRewards")

local Rarities = {"Common","Rare","Epic","Elite","Legendary","Mythic","Secret","Limited","Exclusive","Timeless","Godly","Soul","Fruit","Ninja","Historical","Shadow","Frost","Demon","Arsenal"}
local Mutations = {"Rusty","Normal","Golden","Space","Blood","Dark","Candy","Rainbow","Emerald","Blue Gem"}

local function VerifyRarity()
    local SpawnPoint = GetSpawnPoint()
    if not SpawnPoint or #State.PrefRarity == 0 then return false end
    for _, v in ipairs(State.PrefRarity) do
        if SpawnPoint:FindFirstChild(v) then
            return true
        end
    end
    return false
end

local function VerifyMutation()
    local SpawnPoint = GetSpawnPoint()
    if not SpawnPoint or #State.PrefMutation == 0 then return false end
    local children = SpawnPoint:GetChildren()
    local first = children[1]
    if not first then return false end
    local base = first:FindFirstChild("BasePart")
    if not base then return false end
    local billboard = base:FindFirstChild("BillboardGui")
    if not billboard then return false end
    local label = billboard:FindFirstChild("EventRarity")
    if not label then return false end
    for _, v in ipairs(State.PrefMutation) do
        if label.Text == v then
            return true
        end
    end
    return false
end

local function VerifySellTool()
    for _, Tool in ipairs(Player.Backpack:GetChildren()) do
        local hasRarity = false
        local hasMutation = false

        if #State.SellRarity > 0 then
            for _, v in ipairs(State.SellRarity) do
                if Tool:FindFirstChild(v) then
                    hasRarity = true
                    break
                end
            end
        end

        local item = Tool:FindFirstChildWhichIsA("Model")
        if item then
            local base = item:FindFirstChild("BasePart")
            if base then
                local billboard = base:FindFirstChild("BillboardGui")
                if billboard then
                    local label = billboard:FindFirstChild("EventRarity")
                    if label then
                        for _, v in ipairs(State.SellMutation) do
                            if label.Text == v then
                                hasMutation = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if State.SellMethod == "Rarity & Mutation" and hasRarity and hasMutation then
            return Tool
        elseif State.SellMethod == "Rarity" and hasRarity then
            return Tool
        elseif State.SellMethod == "Mutation" and hasMutation then
            return Tool
        end
    end
end

FarmTab:CreateLabel("Plot : " .. tostring(PlayerPlot))

FarmTab:CreateToggle({
    Name = "Auto Spawn Crate",
    Callback = function(Value)
        State.SpawnsCrate = Value
        if Value and not State.SpawnsCrateRunning then
            State.SpawnsCrateRunning = true
            task.spawn(function()
                while State.SpawnsCrate do
                    pcall(function()
                        local base = GetBaseModel()
                        if base then
                            fireclickdetector(base.ButtonModel.PacketClick.ClickDetector)
                        end
                    end)
                    task.wait(0.75)
                end
                State.SpawnsCrateRunning = false
            end)
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Buy Selected Crates",
    Callback = function(Value)
        State.BuyCrates = Value
        if Value and not State.BuyCratesRunning then
            State.BuyCratesRunning = true
            task.spawn(function()
                while State.BuyCrates do
                    pcall(function()
                        if State.BuyCrateMethod == "Rarity & Mutation" then
                            if VerifyMutation() and VerifyRarity() then
                                BuyCrate:FireServer()
                            end
                        elseif State.BuyCrateMethod == "Rarity" then
                            if VerifyRarity() then
                                BuyCrate:FireServer()
                            end
                        elseif State.BuyCrateMethod == "Mutation" then
                            if VerifyMutation() then
                                BuyCrate:FireServer()
                            end
                        end
                    end)
                    task.wait(0.5)
                end
                State.BuyCratesRunning = false
            end)
        end
    end,
})

FarmTab:CreateDropdown({
    Name = "Rarity Selection",
    Options = Rarities,
    MultipleOptions = true,
    Callback = function(Options)
        State.PrefRarity = Options or {}
    end,
})

FarmTab:CreateDropdown({
    Name = "Mutation Selection",
    Options = Mutations,
    MultipleOptions = true,
    Callback = function(Options)
        State.PrefMutation = Options or {}
    end,
})

FarmTab:CreateDropdown({
    Name = "Filter by",
    Options = {"Rarity & Mutation","Mutation","Rarity"},
    Callback = function(Options)
        State.BuyCrateMethod = Options and Options[1] or "Rarity & Mutation"
    end,
})

SellTab:CreateToggle({
    Name = "Auto Sell Knives",
    Callback = function(Value)
        State.SellKnives = Value
        if Value and not State.SellKnivesRunning then
            State.SellKnivesRunning = true
            task.spawn(function()
                while State.SellKnives do
                    pcall(function()
                        local Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
                        local BoxStand = GetBoxStand()
                        local SellPart = GetSellPart()
                        local Prompt = GetKnivesPrompt()

                        if not Humanoid or not BoxStand or not SellPart or not Prompt then return end

                        Shared.SellKnivesActive = true
                        Humanoid:MoveTo(BoxStand.Position)
                        task.wait(1)
                        fireproximityprompt(Prompt)
                        task.wait(1)
                        Humanoid:MoveTo(SellPart.Position)
                        Humanoid.MoveToFinished:Wait()
                        Shared.SellKnivesActive = false
                    end)
                    task.wait(State.SellCooldown)
                end
                Shared.SellKnivesActive = false
                State.SellKnivesRunning = false
            end)
        end
    end,
})

SellTab:CreateSlider({
    Name = "Sell Cooldown",
    Range = {1,5},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(Value)
        State.SellCooldown = Value
    end,
})

SellTab:CreateToggle({
    Name = "Auto Sell Selected",
    Callback = function(Value)
        State.AutoSell = Value
        if Value and not State.AutoSellRunning then
            State.AutoSellRunning = true
            task.spawn(function()
                while State.AutoSell do
                    pcall(function()
                        local Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
                        local tool = VerifySellTool()
                        if not Humanoid or not tool then return end
                        Humanoid:EquipTool(tool)
                        SellRemote:FireServer()
                    end)
                    task.wait(0.5)
                end
                State.AutoSellRunning = false
            end)
        end
    end,
})

SellTab:CreateDropdown({
    Name = "Rarity Selection",
    Options = Rarities,
    MultipleOptions = true,
    Callback = function(Options)
        State.SellRarity = Options or {}
    end,
})

SellTab:CreateDropdown({
    Name = "Mutation Selection",
    Options = Mutations,
    MultipleOptions = true,
    Callback = function(Options)
        State.SellMutation = Options or {}
    end,
})

SellTab:CreateDropdown({
    Name = "Filter by",
    Options = {"Rarity & Mutation","Mutation","Rarity"},
    Callback = function(Options)
        State.SellMethod = Options and Options[1] or "Rarity & Mutation"
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Playtime Rewards",
    Callback = function(Value)
        State.PlaytimeClaim = Value
        if Value and not State.PlaytimeRunning then
            State.PlaytimeRunning = true
            task.spawn(function()
                while State.PlaytimeClaim do
                    for i = 1,6 do
                        if not State.PlaytimeClaim then break end
                        pcall(function()
                            PlaytimeRemote:FireServer(i)
                        end)
                        task.wait(20)
                    end
                end
                State.PlaytimeRunning = false
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Wheel",
    Callback = function(Value)
        State.SpinWheel = Value
        if Value and not State.SpinRunning then
            State.SpinRunning = true
            task.spawn(function()
                while State.SpinWheel do
                    pcall(function()
                        SpinRemote:FireServer()
                    end)
                    task.wait(10)
                end
                State.SpinRunning = false
            end)
        end
    end,
})

local Codes = {"40klikes","20klikes","Switcharts","4cases"}

MiscTab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        for _, code in ipairs(Codes) do
            pcall(function()
                CodeRemote:FireServer(code)
            end)
            task.wait(0.5)
        end
        Rayfield:Notify({ Title = "Done", Content = "All codes redeemed.", Duration = 3 })
    end,
})
