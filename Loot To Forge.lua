--[[
    ========================================================================
    [Enhance] +1 Loot To Forge - Fluent Hub
    Engineered for paneer
    ========================================================================
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========================================================================
-- SILENT BULLETPROOF ANTI-AFK ENGINE (No Kick, No Rejoin, No UI Toggle)
-- ========================================================================
local function DisableCoreIdledConnections()
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
                if conn.Disable then
                    conn:Disable()
                elseif conn.Disconnect then
                    conn:Disconnect()
                end
            end
        end
    end)
end

local function PulseAntiAfkInput()
    pcall(function()
        -- 1. Hardware-level mouse micro-movement via VirtualInputManager
        local cam = workspace.CurrentCamera
        local vpSize = cam and cam.ViewportSize or Vector2.new(800, 600)
        VirtualInputManager:SendMouseMoveEvent(vpSize.X / 2 + 1, vpSize.Y / 2 + 1, game)
        task.wait(0.04)
        VirtualInputManager:SendMouseMoveEvent(vpSize.X / 2, vpSize.Y / 2, game)
    end)
    pcall(function()
        -- 2. Virtual right-click drag with camera CFrame
        VirtualUser:CaptureController()
        local camCFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new()
        VirtualUser:Button2Down(Vector2.new(0, 0), camCFrame)
        task.wait(0.05)
        VirtualUser:Button2Up(Vector2.new(0, 0), camCFrame)
    end)
end

-- Immediately disable Roblox's built-in 20-minute idle kick listener
DisableCoreIdledConnections()

-- Fallback listener if Idled ever fires
pcall(function()
    LocalPlayer.Idled:Connect(function()
        DisableCoreIdledConnections()
        PulseAntiAfkInput()
    end)
end)

-- Continuous background heartbeat every 90 seconds (resets inactivity timer before 20-min window)
task.spawn(function()
    while true do
        task.wait(90)
        if State.AntiAFK ~= false then
            DisableCoreIdledConnections()
            PulseAntiAfkInput()
        end
    end
end)

-- Safely resolve game utilities and data managers
local CommunicationUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("CommunicationUtils"))
local EncodingUtils = require(ReplicatedStorage.Utils.EncodingUtils)
local CalculateUtils = require(ReplicatedStorage.Utils.CalculateUtils)
local BalanceUtils = require(ReplicatedStorage.Utils.BalanceUtils)
local AbbNumber = require(ReplicatedStorage.Utils.AbbNumber)

local HPCTRL = require(ReplicatedStorage.CTRL.HPCTRL)
local EnemyCTRL = require(ReplicatedStorage.CTRL.EnemyCTRL)
local BackpackData = require(ReplicatedStorage.LocalData.BackpackData)
local StatsData = require(ReplicatedStorage.LocalData.StatsData)
local UpgradeData = require(ReplicatedStorage.LocalData.UpgradeData)
local DungeonData = require(ReplicatedStorage.LocalData.DungeonData)
local IndexData = require(ReplicatedStorage.LocalData.IndexData)
local OnlineData = require(ReplicatedStorage.LocalData.OnlineData)

local RebirthHelper = require(ReplicatedStorage.Config.Rebirth.Helper)
local TrainAreaHelper = require(ReplicatedStorage.Config.TrainArea.Helper)
local TranslateUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("TranslateUtils"))
-- local TrainCTRL omitted to avoid client capability conflicts
local PemData = require(ReplicatedStorage.LocalData.PemData)
local StageManager = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Manager"):WaitForChild("StageManager")
local StageUtils = require(StageManager:WaitForChild("StageUtils"))

-- Remotes
local Remote = ReplicatedStorage:WaitForChild("Remote")
local TrainRemote = Remote:WaitForChild("Train")
local StageRemote = Remote:WaitForChild("Stage")
local DevRemote = Remote:WaitForChild("Dev")
local AttackRemote = Remote:WaitForChild("Attack")
local BackpackRemote = Remote:WaitForChild("Backpack")
local ForgeRemote = Remote:WaitForChild("Forge")
local DungeonRemote = Remote:WaitForChild("Dungeon")
local SuperLootRemote = Remote:WaitForChild("SuperLoot")
local OnlineRemote = Remote:WaitForChild("Online")
local UpdateLogRemote = Remote:WaitForChild("UpdateLog")
local PlayerRemote = Remote:WaitForChild("Player")
local PotionRemote = Remote:WaitForChild("Potion")
local IndexRemote = Remote:WaitForChild("Index")

-- Global Farm State
local State = {
    AutoTrain = false,
    AutoRebirth = false,
    AutoStage27Raid = false,
    AutoCollectOres = false,
    AutoSmartFreePack = false,
    AutoForge = false,
    ForgeType = "Weapon", -- "Weapon", "Armor", "Hat"
    AutoEquipBest = false,
    AutoSellAll = false,
    AutoDungeonSweep = false,
    AutoKillSuperLoot = false,
    AutoSkills = false,
    AutoClaimAll = false,
    AutoClaimIndex = false,
    AntiAFK = true,
    Language = "TH",
}

-- Clean up any legacy custom GUIs
for _, name in ipairs({"SpinachUltimateHub", "SpinachMasterGui"}) do
    if PlayerGui:FindFirstChild(name) then
        PlayerGui[name]:Destroy()
    end
end

-- ========================================================================
-- ORE COLLECTOR CORE ENGINE
-- ========================================================================
local function CollectAllWorldOres()
    pcall(function()
        StageRemote.ClaimedAllOreRE:FireServer()
    end)

    local oreCache = workspace:FindFirstChild("OreCache")
    if oreCache then
        for _, item in ipairs(oreCache:GetChildren()) do
            local pp = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pp and pp.Enabled then
                pcall(function()
                    if fireproximityprompt then
                        fireproximityprompt(pp, 0)
                    end
                end)
            end
            pcall(function()
                StageRemote.GetOreRF:InvokeServer(item.Name)
                StageRemote.GetEnhantStoneRE:FireServer(item.Name)
            end)
        end
    end

    pcall(function()
        for _, drop in ipairs(workspace:GetDescendants()) do
            if drop:IsA("ProximityPrompt") and (drop.ActionText == "Collect" or drop.Name == "PPButton") and drop.Enabled then
                if fireproximityprompt then
                    fireproximityprompt(drop, 0)
                end
            end
        end
    end)
end

-- Real-time event listener: triggers the moment any ore touches OreCache
task.spawn(function()
    local oreCache = workspace:WaitForChild("OreCache", 10)
    if oreCache then
        oreCache.ChildAdded:Connect(function(child)
            if State.AutoCollectOres then
                task.wait(0.01)
                local pp = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pp and fireproximityprompt then
                    pcall(function() fireproximityprompt(pp, 0) end)
                end
                pcall(function()
                    StageRemote.GetOreRF:InvokeServer(child.Name)
                    StageRemote.GetEnhantStoneRE:FireServer(child.Name)
                end)
            end
        end)
    end
end)

-- ========================================================================
-- TRAIN HELPER ENGINE (WARP BEST UNLOCKED AREA)
-- ========================================================================
local function GetBestUnlockedTrainArea()
    local rebirthVal = LocalPlayer:FindFirstChild("Eco") and LocalPlayer.Eco:FindFirstChild("rebirth") and LocalPlayer.Eco.rebirth.Value or 0
    -- Check paid areas if owned
    for id = 11, 9, -1 do
        local ok, owns = pcall(function() return PemData.isHavePem("AutoTrainArea_" .. id) end)
        if ok and owns then
            return tostring(id)
        end
    end
    -- Check free areas from 8 down to 1
    for id = 8, 1, -1 do
        local need = TrainAreaHelper.GetNeedRebirth(id)
        if not TrainAreaHelper.GetIsPay(id) and need and rebirthVal >= need then
            return tostring(id)
        end
    end
    return "1"
end

local function WarpToBestTrainArea()
    local bestID = GetBestUnlockedTrainArea()
    local touched = workspace:FindFirstChild("TOUCHED")
    local pad = touched and touched:FindFirstChild("AutoTrainArea") and touched.AutoTrainArea:FindFirstChild(bestID)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and pad then
        char.HumanoidRootPart.CFrame = pad.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
        pcall(function()
            LocalPlayer:SetAttribute("AutoTrainAreaID", tonumber(bestID))
            TrainCTRL.StartAutoTrain()
        end)
    end
    return bestID
end

-- ========================================================================
-- STAGE 27 WARP, BATTLE, LOOT & RETURN ENGINE
-- ========================================================================
local function RunStage27Cycle()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart

    -- 1. Warp character directly to Stage 27 arena
    root.CFrame = CFrame.new(1, 7, -2955)
    task.wait(0.3)

    -- 2. Initiate Stage 27 fight
    pcall(function()
        LocalPlayer:SetAttribute("StageID", "Stage_27")
        if not LocalPlayer:GetAttribute("IntoFight") then
            StageUtils.StartFight("Stage_27")
        else
            StageUtils.StartStage("Stage_27")
        end
    end)

    -- 3. Continuously hit all enemies until every mob is confirmed dead
    local combatStart = tick()
    local sawEnemies = false
    local maxWaitSeconds = 10

    while (tick() - combatStart) < maxWaitSeconds do
        local enemyFolder = workspace:FindFirstChild("EnemyFolder")
        local aliveCount = 0

        if enemyFolder then
            local children = enemyFolder:GetChildren()
            if #children > 0 then
                sawEnemies = true
            end
            for _, enemy in ipairs(children) do
                if not enemy:GetAttribute("Dead") then
                    aliveCount = aliveCount + 1
                    pcall(function()
                        Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                            Damage = 1e30,
                            SkillID = "K_ATK_1",
                            IsCrit = true
                        })
                    end)
                end
            end
        end

        -- If enemies spawned and are now completely eliminated, break out
        if sawEnemies and aliveCount == 0 and (tick() - combatStart) > 0.8 then
            break
        end

        task.wait(0.12)
    end

    -- 4. Invoke drops and collect all ores
    pcall(function()
        StageRemote.StageFinishedRF:InvokeServer("Stage_27")
    end)
    task.wait(0.3)
    CollectAllWorldOres()
    task.wait(0.5)

    -- 5. Return by clicking the game's actual "Back" (Return) button
    pcall(function()
        local Hud = LocalPlayer.PlayerGui:FindFirstChild("Hud")
        local returnBtn = Hud and Hud:FindFirstChild("Top") and Hud.Top:FindFirstChild("Return")
        if returnBtn and returnBtn.Visible and firesignal then
            firesignal(returnBtn.MouseButton1Down)
        else
            CommunicationUtils.TryGetBindableEvent("Stage", "ExitFightBE"):Fire(true)
        end
    end)

    task.wait(0.6)

    -- Extra fallback if still in fight
    pcall(function()
        if LocalPlayer:GetAttribute("IntoFight") then
            StageUtils.ExitFight(true)
        end
    end)
end

-- ========================================================================
-- EQUIP BEST EQUIPMENT ENGINE (Weapon, Armor, Hat)
-- ========================================================================
local function GetItemPower(item, data)
    if not item then return 0 end
    local itemType = item.Type
    local val = 0
    if itemType == "Weapon" then
        local ok, res = pcall(function()
            return BalanceUtils.GetWeaponTrainValue(LocalPlayer, item, data)
        end)
        if ok and res and res > 0 then
            val = res
        else
            local base = (item.MainAffix and item.MainAffix.Number) or 1
            local lvl = item.Level or 0
            val = base * (1 + lvl * 0.2)
        end
    elseif itemType == "Armor" or itemType == "Hat" then
        local ok, res = pcall(function()
            return BalanceUtils.GetArmorValue(LocalPlayer, item, data)
        end)
        if ok and res and res > 0 then
            val = res
        else
            local lvl = item.Level or 0
            val = 1 + lvl * 0.1
        end
    end
    return val
end

local function EquipBestEquipment()
    local data = BackpackData.GetData()
    if not data or not data.have then return false, 0 end

    local best = {
        Weapon = { uuid = nil, val = -1 },
        Armor = { uuid = nil, val = -1 },
        Hat = { uuid = nil, val = -1 },
    }

    for uuid, item in pairs(data.have) do
        local itemType = item.Type
        if best[itemType] then
            local val = GetItemPower(item, data)
            if val > best[itemType].val then
                best[itemType].uuid = uuid
                best[itemType].val = val
            end
        end
    end

    local equippedCurrent = data.equiped or {}
    local changedCount = 0

    for eqType, info in pairs(best) do
        if info.uuid and info.uuid ~= equippedCurrent[eqType] then
            pcall(function()
                BackpackData.EquipedItem(info.uuid, eqType)
            end)
            changedCount = changedCount + 1
            task.wait(0.08)
        end
    end

    return changedCount > 0, changedCount
end

-- Clean up previous sessions safely
if getgenv and getgenv().Fluent then
    pcall(function() getgenv().Fluent:Destroy() end)
    getgenv().Fluent = nil
end
if _G.SpinachFluentLib then
    pcall(function() _G.SpinachFluentLib:Destroy() end)
    _G.SpinachFluentLib = nil
end
if _G.SpinachFluentWindow then
    pcall(function() _G.SpinachFluentWindow:Destroy() end)
    _G.SpinachFluentWindow = nil
end

-- ========================================================================
-- FLUENT UI LIBRARY INITIALIZATION
-- ========================================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

_G.SpinachFluentLib = Fluent

local Window = Fluent:CreateWindow({
    Title = "[Enhance] +1 Loot To Forge",
    SubTitle = "BY.STREET HUB",
    TabWidth = 150,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})
_G.SpinachFluentWindow = Window

-- ========================================================================
-- FLOATING DRAGGABLE UI TOGGLE BUTTON (Open / Close)
-- ========================================================================
local function CreateFloatingToggleButton()
    local CoreGui = game:GetService("CoreGui")
    local prev = CoreGui:FindFirstChild("SpinachHubToggleButton") or (PlayerGui and PlayerGui:FindFirstChild("SpinachHubToggleButton"))
    if prev then pcall(function() prev:Destroy() end) end

    local targetParent = CoreGui
    local success = pcall(function() local t = Instance.new("Folder", CoreGui) t:Destroy() end)
    if not success then targetParent = PlayerGui end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpinachHubToggleButton"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999
    screenGui.Parent = targetParent

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(0, 120, 0, 34)
    btn.Position = UDim2.new(0, 16, 0.58, 0)
    btn.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 215, 125)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -24, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "BY.STREET HUB"
    title.TextColor3 = Color3.fromRGB(245, 245, 250)
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = btn

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(1, -16, 0.5, -5)
    dot.BackgroundColor3 = Color3.fromRGB(0, 230, 120)
    dot.BorderSizePixel = 0
    dot.Parent = btn

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    -- Smooth draggable mechanics
    local dragging, dragInput, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Click toggle
    local downTick = 0
    btn.MouseButton1Down:Connect(function() downTick = tick() end)
    btn.MouseButton1Up:Connect(function()
        if tick() - downTick < 0.25 then
            local win = _G.SpinachFluentWindow
            if win and win.Root then
                local newVis = not win.Root.Visible
                win.Root.Visible = newVis
                dot.BackgroundColor3 = newVis and Color3.fromRGB(0, 230, 120) or Color3.fromRGB(120, 125, 135)
                stroke.Color = newVis and Color3.fromRGB(0, 215, 125) or Color3.fromRGB(80, 85, 95)
            end
        end
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    end)
end
CreateFloatingToggleButton()

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "zap" }),
    Forge = Window:AddTab({ Title = "Forge", Icon = "hammer" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Rewards = Window:AddTab({ Title = "Claim", Icon = "gift" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local UIElements = {}

-- ========================================================================
-- MULTI-LANGUAGE SYSTEM (English & ภาษาไทย)
-- ========================================================================
local I18N = {
    EN = {
        TabFarm = "Farm",
        TabForge = "Forge",
        TabCombat = "Combat",
        TabRewards = "Claim",
        TabSettings = "Settings",

        StatTitle = "📊 Live Player Statistics",
        AutoTrainTitle = "⚡ Hyper Fast Auto Train",
        AutoTrainDesc = "Auto-warps directly to your highest unlocked train pad & trains at max multiplier",
        AutoRebirthTitle = "🔄 Auto Rebirth (Max Speed)",
        AutoRebirthDesc = "Instantly performs Rebirth the moment level requirement is met",
        AutoStage27Title = "🚀 Auto Stage 27 Raid & Return Loop",
        AutoStage27Desc = "Warps to Stage 27, kills all mobs, collects drops, clicks Back, and waits 5s cooldown",
        BtnStage27Title = "⚡ Warp Stage 27 -> Kill -> Loot -> Return",
        BtnStage27Desc = "Run one full Stage 27 sweep cycle now",
        AutoCollectOresTitle = "🧲 Auto Collect Ores (Instant Magnet & Prompt)",
        AutoCollectOresDesc = "Automatically triggers proximity prompts and vacuums every ore across the map",
        AutoSmartPackTitle = "📦 Auto Free Pack (Craft 10 Ores When Full)",
        AutoSmartPackDesc = "Automatically crafts equipment using 10 ores whenever the 24-slot pack fills up",
        BtnCollectOresTitle = "🧲 Instant Collect All Ground Ores",
        BtnCollectOresDesc = "Collects all dropped ores currently on the map",
        BtnWarpTrainTitle = "📍 Teleport To Best Unlocked Train Area",
        BtnWarpTrainDesc = "Instantly warps to your highest multiplier training dummy pad",
        BtnMaxUpgradesTitle = "⭐ Max Upgrade Passives (Train / Luck / OrePack)",
        BtnMaxUpgradesDesc = "Upgrades Train, Luck, and OrePack capacity to max level",

        AutoForgeTitle = "🔥 Auto Forge (Batches of 10 Ores)",
        AutoForgeDesc = "Continuously crafts items using 10 ores per batch",
        ForgeTypeTitle = "Craft Target Type",
        AutoEquipBestTitle = "🛡️ Auto Equip Best Gear (Weapon / Armor / Hat)",
        AutoEquipBestDesc = "Automatically scans inventory and equips the highest stat equipment",
        BtnInstantEquipTitle = "⚡ Instant Equip Best Gear",
        BtnInstantEquipDesc = "Equips the strongest weapon, armor, and hat currently in your inventory",
        AutoSellAllTitle = "💰 Auto Sell Non-Equipped Items",
        AutoSellAllDesc = "Periodically sells extra crafted items for coins",
        BtnMultiForgeTitle = "🔨 Instant Multi-Forge 5x",
        BtnMultiForgeDesc = "Crafts 5 batches of equipment immediately",
        BtnSellAllTitle = "🗑️ Instant Sell All Non-Equipped Items",
        BtnSellAllDesc = "Sells all unequipped gear in backpack for coins",

        AutoDungeonTitle = "🏰 Auto Sweep Dungeon (Rounds 1 - 30)",
        AutoDungeonDesc = "Enters dungeon and completes all floors automatically",
        AutoSuperLootTitle = "🎯 Auto Kill Mobs & SuperLoot",
        AutoSuperLootDesc = "Insta-kills any monsters and SuperLoot entities that spawn in the map",
        AutoSkillsTitle = "💥 Auto Spam Weapon Skills",
        AutoSkillsDesc = "Fires weapon skills constantly",
        BtnEnterDungeonTitle = "🚪 Enter Dungeon Floor 1",
        BtnExitDungeonTitle = "🏃 Exit Current Dungeon",

        AutoClaimAllTitle = "🎁 Auto Claim Daily / Online / Index / Log Rewards",
        AutoClaimAllDesc = "Continuously claims online gift rewards and index level-ups",
        AutoClaimIndexTitle = "📖 Auto Claim Index (Exp & Level)",
        AutoClaimIndexDesc = "Continuously scans unlocked Weapon, Armor, Hat, and Ore index entries for Exp & Level rewards",
        BtnClaimIndexTitle = "📖 Instant Claim All Index Rewards",
        BtnClaimIndexDesc = "Claims all pending unlocked weapons, armors, hats, and ores in Index",
        BtnOnlineTitle = "🎁 Claim All Online Gifts (1 - 12)",
        BtnTicketTitle = "🎫 Claim Daily Dungeon Ticket",
        BtnGroupTitle = "👑 Claim Group Gift & Update Reward",
        BtnCodesTitle = "🏷️ Redeem All Active Promo Codes",

        LanguageTitle = "🌐 Language / เลือกภาษา",
        ProfileTitle = "👤 Active Account Profile",
        ProfileContent = "Account: %s (%s)\nFolder: %s",
        AutoSaveTitle = "💾 Per-Account Auto Save System",
        AutoSaveContent = "Auto Save is ACTIVE and isolated per account.\nSettings and autoload are saved specifically for %s.",
        AutoSaveToggleTitle = "💾 Enable Auto Save",
        AutoSaveToggleDesc = "Automatically writes configuration to file whenever any toggle is clicked",
        AntiAFKTitle = "🛡️ Anti-AFK (Zero Disconnect & Rejoin)",
        AntiAFKDesc = "Disables Roblox 20-minute idle kicks and pulses anti-afk input",
        BtnForceSaveTitle = "💾 Force Save All Settings Now",
        BtnForceSaveDesc = "Immediately writes current setup to disk",

        NotifyLoaded = "Config loaded for %s! Press Right-Control to toggle.",
        NotifyLangChanged = "Language switched to English!",
    },
    TH = {
        TabFarm = "ฟาร์ม",
        TabForge = "หลอมอุปกรณ์",
        TabCombat = "ต่อสู้/ดันเจี้ยน",
        TabRewards = "รับรางวัล",
        TabSettings = "ตั้งค่า",

        StatTitle = "📊 ข้อมูลสถิติผู้เล่นเรียลไทม์",
        AutoTrainTitle = "⚡ ฟาร์มเทรนพลังอัตโนมัติ (เร็วสูงสุด)",
        AutoTrainDesc = "วาปไปยังจุดเทรนที่ดีที่สุดที่ปลดล็อกแล้ว และเริ่มเทรนที่ตัวคูณสูงสุดทันที",
        AutoRebirthTitle = "🔄 จุติอัตโนมัติ (Auto Rebirth ทันที)",
        AutoRebirthDesc = "กดจุติทันทีเมื่อเลเวลถึงเกณฑ์กำหนดเพื่อเพิ่มตัวคูณพลัง",
        AutoStage27Title = "🚀 ลูปตีมอน Stage 27 วาปไป-กลับ",
        AutoStage27Desc = "วาปไปด่าน 27 ฆ่ามอนทั้งหมด ดูดแร่ กดปุ่ม Back แล้วรอคูลดาวน์ 5 วินาทีเพื่อเริ่มลูปใหม่",
        BtnStage27Title = "⚡ วาปด่าน 27 ตีมอน เก็บแร่ วาปกลับ (1 รอบ)",
        BtnStage27Desc = "สั่งลูปด่าน 27 ทำงานทันที 1 รอบ",
        AutoCollectOresTitle = "🧲 ดูดแร่อัตโนมัติ (แม่เหล็กทั่วแมพ)",
        AutoCollectOresDesc = "เก็บแร่และกด Proximity Prompt ดึงแร่ทั่วทั้งแมพเข้าตัวอัตโนมัติ",
        AutoSmartPackTitle = "📦 หลอมแร่อัตโนมัติเมื่อกระเป๋าเต็ม (10 ก้อน)",
        AutoSmartPackDesc = "เมื่อกระเป๋าแร่เต็ม 24 ช่อง จะนำแร่ 10 ก้อนไปหลอมเป็นอุปกรณ์เพื่อเคลียร์พื้นที่",
        BtnCollectOresTitle = "🧲 ดูดแร่บนพื้นทั้งหมดทันที",
        BtnCollectOresDesc = "เก็บแร่ทุกชิ้นที่ตกอยู่บนพื้นทั่วแมพในครั้งเดียว",
        BtnWarpTrainTitle = "📍 วาปไปยังจุดเทรนที่ดีที่สุด",
        BtnWarpTrainDesc = "วาปตัวละครไปยังแท่นเทรนพลังที่มีตัวคูณสูงสุดที่ปลดล็อกแล้ว",
        BtnMaxUpgradesTitle = "⭐ อัปเกรดสกิลติดตัวเต็ม (Train / Luck / OrePack)",
        BtnMaxUpgradesDesc = "อัปเกรดพลังเทรน ค่าดวง และความจุกระเป๋าแร่ขึ้นเลเวลสูงสุด",

        AutoForgeTitle = "🔥 หลอมอุปกรณ์อัตโนมัติ (ทีละ 10 ก้อน)",
        AutoForgeDesc = "คราฟต์อุปกรณ์ต่อเนื่องโดยใช้แร่ชุดละ 10 ก้อน",
        ForgeTypeTitle = "ประเภทอุปกรณ์ที่ต้องการหลอม",
        AutoEquipBestTitle = "🛡️ สวมใส่อุปกรณ์ที่ดีที่สุดอัตโนมัติ (ดาบ/เกราะ/หัว)",
        AutoEquipBestDesc = "สแกนกระเป๋าและสวมใส่อาวุธ เกราะ หมวก ที่มีพลังสูงสุดเสมอ",
        BtnInstantEquipTitle = "⚡ สวมใส่อุปกรณ์ที่ดีที่สุดทันที",
        BtnInstantEquipDesc = "สแกนและเปลี่ยนใส่อาวุธ ชุดเกราะ และหมวกที่เก่งที่สุดในตัวทันที",
        AutoSellAllTitle = "💰 ขายอุปกรณ์ที่ไม่ได้ใส่ทั้งหมดอัตโนมัติ",
        AutoSellAllDesc = "ขายอุปกรณ์ที่ไม่ได้สวมใส่ในกระเป๋าเป็นเหรียญทองเป็นระยะ",
        BtnMultiForgeTitle = "🔨 หลอมอุปกรณ์รวดเดียว 5 ครั้ง",
        BtnMultiForgeDesc = "คราฟต์อุปกรณ์ทันที 5 ชุดต่อเนื่อง",
        BtnSellAllTitle = "🗑️ ขายอุปกรณ์ที่ไม่ได้ใส่ทั้งหมดทันที",
        BtnSellAllDesc = "ขายอุปกรณ์ทั้งหมดที่ไม่ได้สวมใส่เพื่อรับเหรียญทองทันที",

        AutoDungeonTitle = "🏰 ลุยดันเจี้ยนอัตโนมัติ (ชั้น 1 - 30)",
        AutoDungeonDesc = "ลงดันเจี้ยนและกวาดล้างมอนสเตอร์ผ่านทุกชั้นอัตโนมัติ",
        AutoSuperLootTitle = "🎯 ฆ่ามอนสเตอร์ & กล่อง SuperLoot ทันที",
        AutoSuperLootDesc = "โจมตีปลิดชีพมอนสเตอร์และกล่อง SuperLoot ทั่วทั้งแมพทันทีที่เกิด",
        AutoSkillsTitle = "💥 กดสกิลอาวุธอัตโนมัติต่อเนื่อง",
        AutoSkillsDesc = "ใช้สกิลของอาวุธที่ติดตั้งอยู่ตลอดเวลา",
        BtnEnterDungeonTitle = "🚪 เข้าสู่ดันเจี้ยนชั้นที่ 1",
        BtnExitDungeonTitle = "🏃 ออกจากดันเจี้ยนปัจจุบัน",

        AutoClaimAllTitle = "🎁 รับรางวัลทั้งหมดอัตโนมัติ (Online/ประจำวัน/Index)",
        AutoClaimAllDesc = "กดรับของขวัญออนไลน์ ตั๋วดันเจี้ยน และรางวัลล็อกอินต่อเนื่อง",
        AutoClaimIndexTitle = "📖 รับรางวัล Index อัตโนมัติ (Exp & Level)",
        AutoClaimIndexDesc = "สแกน Index ดาบ เกราะ หมวก แร่ ที่ปลดล็อกแล้วและกดรับ Exp พร้อมรางวัลเลเวล",
        BtnClaimIndexTitle = "📖 รับรางวัล Index ทั้งหมดทันที",
        BtnClaimIndexDesc = "กดรับ Exp และรางวัล Index ทั้งหมดที่ยังค้างอยู่ในคลิกเดียว",
        BtnOnlineTitle = "🎁 รับของขวัญออนไลน์ทั้งหมด (1 - 12)",
        BtnTicketTitle = "🎫 รับตั๋วดันเจี้ยนประจำวัน",
        BtnGroupTitle = "👑 รับรางวัลกลุ่ม & รางวัลอัปเดตเกม",
        BtnCodesTitle = "🏷️ ใส่โค้ดรับของรางวัลทั้งหมด",

        LanguageTitle = "🌐 เลือกภาษา / Language",
        ProfileTitle = "👤 ข้อมูลโปรไฟล์บัญชีนี้",
        ProfileContent = "บัญชี: %s (%s)\nโฟลเดอร์: %s",
        AutoSaveTitle = "💾 ระบบบันทึกอัตโนมัติแยกบัญชี",
        AutoSaveContent = "ระบบ Auto Save ทำงานปกติและแยกโปรไฟล์ตามไอดี\nการตั้งค่าจะถูกบันทึกให้ %s โดยเฉพาะ",
        AutoSaveToggleTitle = "💾 เปิดใช้งาน Auto Save",
        AutoSaveToggleDesc = "บันทึกการตั้งค่าลงไฟล์ของบัญชีนี้อัตโนมัติทุกครั้งที่มีการเปลี่ยนตัวเลือก",
        AntiAFKTitle = "🛡️ ระบบกันหลุด Anti-AFK (ไม่โดนเตะ ไม่ต้อง Rejoin)",
        AntiAFKDesc = "ปิดระบบเตะ 20 นาทีของ Roblox และส่งสัญญาณรีเซ็ตเวลาอัตโนมัติ",
        BtnForceSaveTitle = "💾 บันทึกการตั้งค่าลงดิสก์ทันที",
        BtnForceSaveDesc = "เขียนข้อมูลการตั้งค่าปัจจุบันลงไฟล์ดิสก์ทันที",

        NotifyLoaded = "โหลดการตั้งค่าของ %s สำเร็จ! กด Right-Control เพื่อเปิด/ปิด",
        NotifyLangChanged = "เปลี่ยนภาษาเป็น ภาษาไทย เรียบร้อยแล้ว!",
    }
}

local function UpdateLanguage(lang)
    lang = (lang == "TH" or lang == "ไทย (Thai)") and "TH" or "EN"
    State.Language = lang
    local t = I18N[lang] or I18N.TH

    -- Update Tab Titles in sidebar
    local tabNameMap = {
        Farm = t.TabFarm,
        Forge = t.TabForge,
        Combat = t.TabCombat,
        Rewards = t.TabRewards,
        Settings = t.TabSettings,
    }
    for tabKey, tabObj in pairs(Tabs) do
        if tabObj and tabObj.Frame and tabNameMap[tabKey] then
            for _, desc in ipairs(tabObj.Frame:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    desc.Text = tabNameMap[tabKey]
                end
            end
        end
    end

    -- Update Elements
    local E = UIElements
    if E.StatParagraph then E.StatParagraph:SetTitle(t.StatTitle) end
    if E.ToggleAutoTrain then E.ToggleAutoTrain:SetTitle(t.AutoTrainTitle) E.ToggleAutoTrain:SetDesc(t.AutoTrainDesc) end
    if E.ToggleAutoRebirth then E.ToggleAutoRebirth:SetTitle(t.AutoRebirthTitle) E.ToggleAutoRebirth:SetDesc(t.AutoRebirthDesc) end
    if E.ToggleStage27Raid then E.ToggleStage27Raid:SetTitle(t.AutoStage27Title) E.ToggleStage27Raid:SetDesc(t.AutoStage27Desc) end
    if E.BtnStage27Once then E.BtnStage27Once:SetTitle(t.BtnStage27Title) E.BtnStage27Once:SetDesc(t.BtnStage27Desc) end
    if E.ToggleAutoCollectOres then E.ToggleAutoCollectOres:SetTitle(t.AutoCollectOresTitle) E.ToggleAutoCollectOres:SetDesc(t.AutoCollectOresDesc) end
    if E.ToggleSmartPack then E.ToggleSmartPack:SetTitle(t.AutoSmartPackTitle) E.ToggleSmartPack:SetDesc(t.AutoSmartPackDesc) end
    if E.BtnCollectAllOres then E.BtnCollectAllOres:SetTitle(t.BtnCollectOresTitle) E.BtnCollectAllOres:SetDesc(t.BtnCollectOresDesc) end
    if E.BtnTeleportBestTrain then E.BtnTeleportBestTrain:SetTitle(t.BtnWarpTrainTitle) E.BtnTeleportBestTrain:SetDesc(t.BtnWarpTrainDesc) end
    if E.BtnMaxUpgradePassives then E.BtnMaxUpgradePassives:SetTitle(t.BtnMaxUpgradesTitle) E.BtnMaxUpgradePassives:SetDesc(t.BtnMaxUpgradesDesc) end

    if E.ToggleAutoForge then E.ToggleAutoForge:SetTitle(t.AutoForgeTitle) E.ToggleAutoForge:SetDesc(t.AutoForgeDesc) end
    if E.DropdownForgeType then E.DropdownForgeType:SetTitle(t.ForgeTypeTitle) end
    if E.ToggleAutoEquipBest then E.ToggleAutoEquipBest:SetTitle(t.AutoEquipBestTitle) E.ToggleAutoEquipBest:SetDesc(t.AutoEquipBestDesc) end
    if E.BtnInstantEquipBest then E.BtnInstantEquipBest:SetTitle(t.BtnInstantEquipTitle) E.BtnInstantEquipBest:SetDesc(t.BtnInstantEquipDesc) end
    if E.ToggleAutoSellAll then E.ToggleAutoSellAll:SetTitle(t.AutoSellAllTitle) E.ToggleAutoSellAll:SetDesc(t.AutoSellAllDesc) end
    if E.BtnInstantMultiForge then E.BtnInstantMultiForge:SetTitle(t.BtnMultiForgeTitle) E.BtnInstantMultiForge:SetDesc(t.BtnMultiForgeDesc) end
    if E.BtnInstantSellAll then E.BtnInstantSellAll:SetTitle(t.BtnSellAllTitle) E.BtnInstantSellAll:SetDesc(t.BtnSellAllDesc) end

    if E.ToggleDungeonSweep then E.ToggleDungeonSweep:SetTitle(t.AutoDungeonTitle) E.ToggleDungeonSweep:SetDesc(t.AutoDungeonDesc) end
    if E.ToggleKillSuperLoot then E.ToggleKillSuperLoot:SetTitle(t.AutoSuperLootTitle) E.ToggleKillSuperLoot:SetDesc(t.AutoSuperLootDesc) end
    if E.ToggleSkills then E.ToggleSkills:SetTitle(t.AutoSkillsTitle) E.ToggleSkills:SetDesc(t.AutoSkillsDesc) end
    if E.BtnEnterDungeon then E.BtnEnterDungeon:SetTitle(t.BtnEnterDungeonTitle) end
    if E.BtnExitDungeon then E.BtnExitDungeon:SetTitle(t.BtnExitDungeonTitle) end

    if E.ToggleAutoClaimAll then E.ToggleAutoClaimAll:SetTitle(t.AutoClaimAllTitle) E.ToggleAutoClaimAll:SetDesc(t.AutoClaimAllDesc) end
    if E.ToggleAutoClaimIndex then E.ToggleAutoClaimIndex:SetTitle(t.AutoClaimIndexTitle) E.ToggleAutoClaimIndex:SetDesc(t.AutoClaimIndexDesc) end
    if E.BtnInstantClaimIndex then E.BtnInstantClaimIndex:SetTitle(t.BtnInstantClaimIndexTitle) E.BtnInstantClaimIndex:SetDesc(t.BtnInstantClaimIndexDesc) end
    if E.BtnClaimOnline then E.BtnClaimOnline:SetTitle(t.BtnOnlineTitle) end
    if E.BtnClaimTicket then E.BtnClaimTicket:SetTitle(t.BtnTicketTitle) end
    if E.BtnClaimGroup then E.BtnClaimGroup:SetTitle(t.BtnGroupTitle) end
    if E.BtnRedeemCodes then E.BtnRedeemCodes:SetTitle(t.BtnCodesTitle) end

    local accountFolderRef = "SpinachHub/Enhance1LootToForge/accounts/" .. (string.gsub(LocalPlayer.Name, "[^%w_]", "") .. "_" .. tostring(LocalPlayer.UserId))
    if E.ProfileParagraph then
        E.ProfileParagraph:SetTitle(t.ProfileTitle)
        E.ProfileParagraph:SetDesc(string.format(t.ProfileContent, LocalPlayer.Name, tostring(LocalPlayer.UserId), accountFolderRef))
    end
    if E.AutoSaveParagraph then
        E.AutoSaveParagraph:SetTitle(t.AutoSaveTitle)
        E.AutoSaveParagraph:SetDesc(string.format(t.AutoSaveContent, LocalPlayer.Name))
    end
    if E.ToggleAutoSaveSetting then E.ToggleAutoSaveSetting:SetTitle(t.AutoSaveToggleTitle) E.ToggleAutoSaveSetting:SetDesc(t.AutoSaveToggleDesc) end
    if E.ToggleAntiAFK then E.ToggleAntiAFK:SetTitle(t.AntiAFKTitle) E.ToggleAntiAFK:SetDesc(t.AntiAFKDesc) end
    if E.BtnForceSave then E.BtnForceSave:SetTitle(t.BtnForceSaveTitle) E.BtnForceSave:SetDesc(t.BtnForceSaveDesc) end

    if E.DropdownLanguage then E.DropdownLanguage:SetTitle(t.LanguageTitle) end
end

-- ========================================================================
-- PER-ACCOUNT AUTO SAVE SYSTEM
-- ========================================================================
local HttpService = game:GetService("HttpService")

local function SafeMakeFolder(path)
    if not isfolder or not makefolder then return end
    local parts = string.split(path, "/")
    local current = ""
    for _, part in ipairs(parts) do
        if part ~= "" then
            current = (current == "") and part or (current .. "/" .. part)
            if not isfolder(current) then
                pcall(makefolder, current)
            end
        end
    end
end

-- Isolate configuration directory per account (Username + UserId)
local safeAccountName = string.gsub(LocalPlayer.Name, "[^%w_]", "")
local accountKey = safeAccountName .. "_" .. tostring(LocalPlayer.UserId)
local accountFolder = "SpinachHub/Enhance1LootToForge/accounts/" .. accountKey
local accountSettingsFolder = accountFolder .. "/settings"
local CONFIG_FILE = accountSettingsFolder .. "/auto_state.json"
local AUTOLOAD_FILE = accountSettingsFolder .. "/autoload.txt"
local LEGACY_CONFIG = "SpinachHub/Enhance1LootToForge/settings/auto_state.json"

local autoSaveLoaded = false
local autoSaveDebounce = false
local autoSaveEnabled = true

local function SaveCurrentState()
    if not autoSaveEnabled then return end
    pcall(function()
        SafeMakeFolder(accountSettingsFolder)

        local data = {
            AutoTrain = State.AutoTrain,
            AutoRebirth = State.AutoRebirth,
            AutoStage27Raid = State.AutoStage27Raid,
            AutoCollectOres = State.AutoCollectOres,
            AutoSmartFreePack = State.AutoSmartFreePack,
            AutoForge = State.AutoForge,
            ForgeType = State.ForgeType,
            AutoEquipBest = State.AutoEquipBest,
            AutoSellAll = State.AutoSellAll,
            AutoDungeonSweep = State.AutoDungeonSweep,
            AutoKillSuperLoot = State.AutoKillSuperLoot,
            AutoSkills = State.AutoSkills,
            AutoClaimAll = State.AutoClaimAll,
            AutoClaimIndex = State.AutoClaimIndex,
            AntiAFK = State.AntiAFK,
            Language = State.Language,
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function LoadSavedState()
    pcall(function()
        local targetFile = CONFIG_FILE
        -- If this account doesn't have an isolated config yet, fallback to legacy config if available
        if isfile and not isfile(targetFile) and isfile(LEGACY_CONFIG) then
            targetFile = LEGACY_CONFIG
        end

        if isfile and isfile(targetFile) then
            local raw = readfile(targetFile)
            local data = HttpService:JSONDecode(raw)
            if data and type(data) == "table" then
                if data.Language then
                    State.Language = data.Language
                end
                for k, v in pairs(data) do
                    if Options[k] and Options[k].SetValue then
                        Options[k]:SetValue(v)
                    end
                end
                if Options.LanguageSetting then
                    Options.LanguageSetting:SetValue(State.Language == "EN" and "English" or "ไทย (Thai)")
                end
            end
        end
    end)
end

local function RequestAutoSave()
    if not autoSaveLoaded or not autoSaveEnabled then return end
    if autoSaveDebounce then return end
    autoSaveDebounce = true
    task.delay(0.2, function()
        autoSaveDebounce = false
        SaveCurrentState()
        pcall(function()
            SaveManager:Save("default")
            if writefile and isfolder and isfolder(accountSettingsFolder) then
                writefile(AUTOLOAD_FILE, "default")
            end
        end)
    end)
end

-- ========================================================================
-- TAB: FARM
-- ========================================================================
local StatParagraph = Tabs.Farm:AddParagraph({
    Title = "📊 Live Player Statistics",
    Content = "Connecting to player data..."
})
UIElements.StatParagraph = StatParagraph

local ToggleAutoTrain = Tabs.Farm:AddToggle("AutoTrain", {
    Title = "⚡ Hyper Fast Auto Train",
    Description = "Auto-warps directly to your highest unlocked train pad & trains at max multiplier",
    Default = false
})
ToggleAutoTrain:OnChanged(function()
    State.AutoTrain = Options.AutoTrain.Value
    if State.AutoTrain then
        task.spawn(WarpToBestTrainArea)
    end
    RequestAutoSave()
end)
UIElements.ToggleAutoTrain = ToggleAutoTrain

local ToggleAutoRebirth = Tabs.Farm:AddToggle("AutoRebirth", {
    Title = "🔄 Auto Rebirth (Max Speed)",
    Description = "Instantly performs Rebirth the moment level requirement is met",
    Default = false
})
ToggleAutoRebirth:OnChanged(function()
    State.AutoRebirth = Options.AutoRebirth.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoRebirth = ToggleAutoRebirth

local ToggleStage27Raid = Tabs.Farm:AddToggle("AutoStage27Raid", {
    Title = "🚀 Auto Stage 27 Raid & Return Loop",
    Description = "Warps to Stage 27, kills all mobs, collects drops, clicks Back, and waits 5s cooldown before next run",
    Default = false
})
ToggleStage27Raid:OnChanged(function()
    State.AutoStage27Raid = Options.AutoStage27Raid.Value
    RequestAutoSave()
end)
UIElements.ToggleStage27Raid = ToggleStage27Raid

local BtnStage27Once = Tabs.Farm:AddButton({
    Title = "⚡ Warp Stage 27 -> Kill -> Loot -> Return",
    Description = "Run one full Stage 27 sweep cycle now",
    Callback = function()
        task.spawn(RunStage27Cycle)
    end
})
UIElements.BtnStage27Once = BtnStage27Once

local ToggleAutoCollectOres = Tabs.Farm:AddToggle("AutoCollectOres", {
    Title = "🧲 Auto Collect Ores (Instant Magnet & Prompt)",
    Description = "Automatically triggers proximity prompts and vacuums every ore across the map",
    Default = false
})
ToggleAutoCollectOres:OnChanged(function()
    State.AutoCollectOres = Options.AutoCollectOres.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoCollectOres = ToggleAutoCollectOres

local ToggleSmartPack = Tabs.Farm:AddToggle("AutoSmartFreePack", {
    Title = "📦 Auto Free Pack (Craft 10 Ores When Full)",
    Description = "Automatically crafts equipment using 10 ores whenever the 24-slot pack fills up",
    Default = false
})
ToggleSmartPack:OnChanged(function()
    State.AutoSmartFreePack = Options.AutoSmartFreePack.Value
    RequestAutoSave()
end)
UIElements.ToggleSmartPack = ToggleSmartPack

local BtnCollectAllOres = Tabs.Farm:AddButton({
    Title = "🧲 Instant Collect All Ground Ores",
    Description = "Collects all dropped ores currently on the map",
    Callback = function()
        CollectAllWorldOres()
    end
})
UIElements.BtnCollectAllOres = BtnCollectAllOres

local BtnTeleportBestTrain = Tabs.Farm:AddButton({
    Title = "📍 Teleport To Best Unlocked Train Area",
    Description = "Instantly warps to your highest multiplier training dummy pad",
    Callback = function()
        local bestID = WarpToBestTrainArea()
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Train Area",
            Content = string.format(t.NotifyWarpTrain, tostring(bestID)),
            Duration = 2
        })
    end
})
UIElements.BtnTeleportBestTrain = BtnTeleportBestTrain

local BtnMaxUpgradePassives = Tabs.Farm:AddButton({
    Title = "⭐ Max Upgrade Passives (Train / Luck / OrePack)",
    Description = "Upgrades Train, Luck, and OrePack capacity to max level",
    Callback = function()
        for _, key in ipairs({"Train", "Luck", "OrePack"}) do
            for i = 1, 15 do
                UpgradeData.UpgradeOnce(key)
            end
        end
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Upgrades",
            Content = t.NotifyUpgraded,
            Duration = 2
        })
    end
})
UIElements.BtnMaxUpgradePassives = BtnMaxUpgradePassives

-- ========================================================================
-- TAB: FORGE & INVENTORY
-- ========================================================================
local ToggleAutoForge = Tabs.Forge:AddToggle("AutoForge", {
    Title = "🔥 Auto Forge (Batches of 10 Ores)",
    Description = "Continuously crafts items using 10 ores per batch",
    Default = false
})
ToggleAutoForge:OnChanged(function()
    State.AutoForge = Options.AutoForge.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoForge = ToggleAutoForge

local DropdownForgeType = Tabs.Forge:AddDropdown("ForgeType", {
    Title = "Craft Target Type",
    Values = {"Weapon", "Armor", "Hat"},
    Multi = false,
    Default = "Weapon"
})
DropdownForgeType:OnChanged(function(Value)
    State.ForgeType = Value
    RequestAutoSave()
end)
UIElements.DropdownForgeType = DropdownForgeType

local ToggleAutoEquipBest = Tabs.Forge:AddToggle("AutoEquipBest", {
    Title = "🛡️ Auto Equip Best Gear (Weapon / Armor / Hat)",
    Description = "Automatically scans inventory and equips the highest stat equipment",
    Default = false
})
ToggleAutoEquipBest:OnChanged(function()
    State.AutoEquipBest = Options.AutoEquipBest.Value
    if State.AutoEquipBest then
        task.spawn(EquipBestEquipment)
    end
    RequestAutoSave()
end)
UIElements.ToggleAutoEquipBest = ToggleAutoEquipBest

local BtnInstantEquipBest = Tabs.Forge:AddButton({
    Title = "⚡ Instant Equip Best Gear",
    Description = "Equips the strongest weapon, armor, and hat currently in your inventory",
    Callback = function()
        local changed, count = EquipBestEquipment()
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Equip Best",
            Content = changed and string.format(t.NotifyEquipped, count) or t.NotifyAlreadyBest,
            Duration = 2
        })
    end
})
UIElements.BtnInstantEquipBest = BtnInstantEquipBest

local ToggleAutoSellAll = Tabs.Forge:AddToggle("AutoSellAll", {
    Title = "💰 Auto Sell Non-Equipped Items",
    Description = "Periodically sells extra crafted items for coins",
    Default = false
})
ToggleAutoSellAll:OnChanged(function()
    State.AutoSellAll = Options.AutoSellAll.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoSellAll = ToggleAutoSellAll

local BtnInstantMultiForge = Tabs.Forge:AddButton({
    Title = "🔨 Instant Multi-Forge 5x",
    Description = "Crafts 5 batches of equipment immediately",
    Callback = function()
        task.spawn(function()
            for i = 1, 5 do
                local data = BackpackData.GetData()
                if not data or not data.have then break end
                local oreList = {}
                local total = 0
                for uuid, item in pairs(data.have) do
                    if item.Type == "Ore" and item.Number and item.Number > 0 then
                        local take = math.min(item.Number, 10 - total)
                        oreList[uuid] = take
                        total = total + take
                        if total >= 10 then break end
                    end
                end
                if total >= 4 then
                    ForgeRemote.ForgeRF:InvokeServer({
                        ConfigType = State.ForgeType,
                        UUIDList = oreList
                    })
                end
                task.wait(0.15)
            end
            local lang = State.Language or "TH"
            local t = I18N[lang] or I18N.TH
            Fluent:Notify({
                Title = "Forge",
                Content = t.NotifyForged5x,
                Duration = 2
            })
        end)
    end
})
UIElements.BtnInstantMultiForge = BtnInstantMultiForge

local BtnInstantSellAll = Tabs.Forge:AddButton({
    Title = "🗑️ Instant Sell All Non-Equipped Items",
    Description = "Sells all unequipped gear in backpack for coins",
    Callback = function()
        BackpackData.SellAll()
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Sell",
            Content = t.NotifySold,
            Duration = 2
        })
    end
})
UIElements.BtnInstantSellAll = BtnInstantSellAll

-- ========================================================================
-- TAB: COMBAT & DUNGEON
-- ========================================================================
local ToggleDungeonSweep = Tabs.Combat:AddToggle("AutoDungeonSweep", {
    Title = "🏰 Auto Sweep Dungeon (Rounds 1 - 30)",
    Description = "Enters dungeon and completes all floors automatically",
    Default = false
})
ToggleDungeonSweep:OnChanged(function()
    State.AutoDungeonSweep = Options.AutoDungeonSweep.Value
    RequestAutoSave()
end)
UIElements.ToggleDungeonSweep = ToggleDungeonSweep

local ToggleKillSuperLoot = Tabs.Combat:AddToggle("AutoKillSuperLoot", {
    Title = "🎯 Auto Kill Mobs & SuperLoot",
    Description = "Insta-kills any monsters and SuperLoot entities that spawn in the map",
    Default = false
})
ToggleKillSuperLoot:OnChanged(function()
    State.AutoKillSuperLoot = Options.AutoKillSuperLoot.Value
    RequestAutoSave()
end)
UIElements.ToggleKillSuperLoot = ToggleKillSuperLoot

local ToggleSkills = Tabs.Combat:AddToggle("AutoSkills", {
    Title = "💥 Auto Spam Weapon Skills",
    Description = "Fires weapon skills constantly",
    Default = false
})
ToggleSkills:OnChanged(function()
    State.AutoSkills = Options.AutoSkills.Value
    RequestAutoSave()
end)
UIElements.ToggleSkills = ToggleSkills

local BtnEnterDungeon = Tabs.Combat:AddButton({
    Title = "🚪 Enter Dungeon Floor 1",
    Callback = function()
        DungeonData.TryIntoDungeon(1)
    end
})
UIElements.BtnEnterDungeon = BtnEnterDungeon

local BtnExitDungeon = Tabs.Combat:AddButton({
    Title = "🏃 Exit Current Dungeon",
    Callback = function()
        DungeonData.ExitDungeon()
    end
})
UIElements.BtnExitDungeon = BtnExitDungeon

-- ========================================================================
-- TAB: REWARDS & CLAIM
-- ========================================================================
local ToggleAutoClaimAll = Tabs.Rewards:AddToggle("AutoClaimAll", {
    Title = "🎁 Auto Claim All Rewards",
    Description = "Continuously claims online gifts, daily tickets, group gifts, and index rewards",
    Default = false
})
ToggleAutoClaimAll:OnChanged(function()
    State.AutoClaimAll = Options.AutoClaimAll.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoClaimAll = ToggleAutoClaimAll

local ToggleAutoClaimIndex = Tabs.Rewards:AddToggle("AutoClaimIndex", {
    Title = "📖 Auto Claim Index (Exp & Level)",
    Description = "Automatically claims newly discovered weapons, armors, hats, ores, and title level rewards in Index",
    Default = false
})
ToggleAutoClaimIndex:OnChanged(function()
    State.AutoClaimIndex = Options.AutoClaimIndex.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoClaimIndex = ToggleAutoClaimIndex

local BtnInstantClaimIndex = Tabs.Rewards:AddButton({
    Title = "📖 Instant Claim All Index Rewards",
    Description = "Claims all discovered Index EXP and Level rewards now",
    Callback = function()
        local count = 0
        pcall(function()
            local data = IndexData.GetData()
            if data and data.unlocked then
                for fullID, _ in pairs(data.unlocked) do
                    if not (data.claimed and data.claimed[fullID]) then
                        local split = string.split(fullID, "-")
                        if #split == 2 then
                            if IndexData.TryClaimedExp(split[1], split[2]) then
                                count = count + 1
                            end
                        end
                    end
                end
            end
            IndexData.TryClaimedLevel()
        end)
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Index Rewards",
            Content = string.format(t.NotifyIndexClaimed, count),
            Duration = 3
        })
    end
})
UIElements.BtnInstantClaimIndex = BtnInstantClaimIndex

local BtnClaimOnline = Tabs.Rewards:AddButton({
    Title = "🎁 Claim All Online Gifts (1 - 12)",
    Callback = function()
        for i = 1, 12 do
            OnlineData.TryClaim(i)
        end
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Online Gifts",
            Content = t.NotifyOnlineClaimed,
            Duration = 2
        })
    end
})
UIElements.BtnClaimOnline = BtnClaimOnline

local BtnClaimTicket = Tabs.Rewards:AddButton({
    Title = "🎫 Claim Daily Dungeon Ticket",
    Callback = function()
        DungeonData.TryClaimDailyDunTic()
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Dungeon",
            Content = t.NotifyTicketClaimed,
            Duration = 2
        })
    end
})
UIElements.BtnClaimTicket = BtnClaimTicket

local BtnClaimGroup = Tabs.Rewards:AddButton({
    Title = "👑 Claim Group Gift & Update Reward",
    Callback = function()
        pcall(function()
            PlayerRemote.TryJoinGroupRE:FireServer()
            UpdateLogRemote.TryClaimUPDRewardRE:FireServer()
        end)
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Rewards",
            Content = t.NotifyGroupClaimed,
            Duration = 2
        })
    end
})
UIElements.BtnClaimGroup = BtnClaimGroup

local BtnRedeemCodes = Tabs.Rewards:AddButton({
    Title = "🏷️ Redeem All Active Promo Codes",
    Callback = function()
        local codes = {"UPDATE", "RELEASE", "FORGE", "GOODBRO", "LIKE1000", "ENHANCE"}
        task.spawn(function()
            for _, c in ipairs(codes) do
                pcall(function()
                    Remote.Code.TryUseCodeRF:InvokeServer(c)
                end)
                task.wait(0.2)
            end
            local lang = State.Language or "TH"
            local t = I18N[lang] or I18N.TH
            Fluent:Notify({
                Title = "Codes",
                Content = t.NotifyCodesRedeemed,
                Duration = 2
            })
        end)
    end
})
UIElements.BtnRedeemCodes = BtnRedeemCodes

-- ========================================================================
-- TAB: SETTINGS & CONFIGS
-- ========================================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName", "AutoSaveToggle" })

InterfaceManager:SetFolder("SpinachHub")
SaveManager:SetFolder(accountFolder)

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local DropdownLanguage = Tabs.Settings:AddDropdown("LanguageSetting", {
    Title = "🌐 Language / เลือกภาษา",
    Values = {"ไทย (Thai)", "English"},
    Multi = false,
    Default = (State.Language == "EN" and "English" or "ไทย (Thai)")
})
DropdownLanguage:OnChanged(function(Value)
    local selected = (Value == "English") and "EN" or "TH"
    if State.Language ~= selected then
        State.Language = selected
        UpdateLanguage(selected)
        RequestAutoSave()
        local t = I18N[selected]
        Fluent:Notify({
            Title = "BY.STREET HUB",
            Content = t.NotifyLangChanged,
            Duration = 2
        })
    end
end)
UIElements.DropdownLanguage = DropdownLanguage

local ProfileParagraph = Tabs.Settings:AddParagraph({
    Title = "👤 Active Account Profile",
    Content = "Account: " .. LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")\n" ..
              "Folder: " .. accountFolder
})
UIElements.ProfileParagraph = ProfileParagraph

local AutoSaveParagraph = Tabs.Settings:AddParagraph({
    Title = "💾 Per-Account Auto Save System",
    Content = "Auto Save is ACTIVE and isolated per account.\nSettings and autoload are saved specifically for " .. LocalPlayer.Name .. "."
})
UIElements.AutoSaveParagraph = AutoSaveParagraph

local ToggleAutoSaveSetting = Tabs.Settings:AddToggle("AutoSaveToggle", {
    Title = "💾 Enable Auto Save",
    Description = "Automatically writes configuration to file whenever any toggle is clicked",
    Default = true
})
ToggleAutoSaveSetting:OnChanged(function()
    autoSaveEnabled = Options.AutoSaveToggle.Value
end)
UIElements.ToggleAutoSaveSetting = ToggleAutoSaveSetting

local ToggleAntiAFK = Tabs.Settings:AddToggle("AntiAFKToggle", {
    Title = "🛡️ Anti-AFK (Zero Disconnect & Rejoin)",
    Description = "Disables Roblox 20-minute idle kicks and pulses anti-afk input",
    Default = true
})
ToggleAntiAFK:OnChanged(function()
    State.AntiAFK = Options.AntiAFKToggle.Value
    RequestAutoSave()
end)
UIElements.ToggleAntiAFK = ToggleAntiAFK

local BtnForceSave = Tabs.Settings:AddButton({
    Title = "💾 Force Save All Settings Now",
    Description = "Immediately writes current setup to disk",
    Callback = function()
        SaveCurrentState()
        pcall(function() SaveManager:Save("default") end)
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Auto Save",
            Content = t.NotifySaved,
            Duration = 2
        })
    end
})
UIElements.BtnForceSave = BtnForceSave

Window:SelectTab(1)

-- ========================================================================
-- BACKGROUND RECURRING WORKERS
-- ========================================================================

-- Live HUD Dashboard updater
task.spawn(function()
    while true do
        pcall(function()
            local eco = LocalPlayer:FindFirstChild("Eco")
            local power = eco and eco:FindFirstChild("power") and eco.power.Value or 0
            local lvl = eco and eco:FindFirstChild("level") and eco.level.Value or 0
            local reb = eco and eco:FindFirstChild("rebirth") and eco.rebirth.Value or 0
            local coin = eco and eco:FindFirstChild("coin") and eco.coin.Value or 0

            local data = BackpackData.GetData()
            local oreTotal = 0
            if data and data.have then
                for _, item in pairs(data.have) do
                    if item.Type == "Ore" then
                        oreTotal = oreTotal + (item.Number or 1)
                    end
                end
            end

            local formattedPower = AbbNumber.AbbreviateNumber(power)
            local formattedCoins = AbbNumber.AbbreviateNumber(coin)
            StatParagraph:SetDesc(string.format("Power: %s\nLevel: %d\nRebirth: %d\nCoins: %s\nOres in Bag: %d/24",
                formattedPower, lvl, reb, formattedCoins, oreTotal))
        end)
        task.wait(0.5)
    end
end)

-- 1. Hyper Auto Train Worker
local trainQueue = {}
local lastTrainWarpCheck = 0
task.spawn(function()
    while true do
        if State.AutoTrain then
            pcall(function()
                -- Keep player aligned on best train pad if not in fight/raid/dungeon
                if not LocalPlayer:GetAttribute("IntoFight") and not State.AutoStage27Raid and not LocalPlayer:GetAttribute("Dungeoning") then
                    if tick() - lastTrainWarpCheck > 2.5 then
                        lastTrainWarpCheck = tick()
                        local bestID = GetBestUnlockedTrainArea()
                        if LocalPlayer:GetAttribute("AutoTrainAreaID") ~= tonumber(bestID) then
                            WarpToBestTrainArea()
                        end
                    end
                end

                if #trainQueue < 30 then
                    TrainRemote.StartTrainRE:FireServer()
                    local buf = TrainRemote.InvokTrainDataListRF:InvokeServer()
                    if buf then
                        local list = EncodingUtils.DecodeTable(buf)
                        for _, item in ipairs(list) do
                            table.insert(trainQueue, item.UUID)
                        end
                    end
                end

                for i = 1, math.min(#trainQueue, 8) do
                    local token = table.remove(trainQueue, 1)
                    if token then
                        TrainRemote.TrainOnceRE:FireServer(token)
                    end
                end
            end)
        end
        task.wait(0.06)
    end
end)

-- 2. Auto Rebirth Worker
task.spawn(function()
    while true do
        if State.AutoRebirth then
            pcall(function()
                local eco = LocalPlayer:FindFirstChild("Eco")
                if eco and eco:FindFirstChild("rebirth") and eco:FindFirstChild("level") then
                    local curRebirth = eco.rebirth.Value
                    local curLevel = eco.level.Value
                    local need = RebirthHelper.GetNeedLevel(curRebirth + 1)
                    if curLevel >= need and not RebirthHelper.CheckIsMax(curRebirth) then
                        Remote.Rebirth.TryRebirthRE:FireServer()
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- 3. Auto Stage 27 Raid & Return Loop Worker
task.spawn(function()
    while true do
        if State.AutoStage27Raid and not LocalPlayer:GetAttribute("Dungeoning") then
            pcall(RunStage27Cycle)
            -- 5-second cooldown after returning before launching the next loop
            local cdStart = tick()
            while (tick() - cdStart) < 5 and State.AutoStage27Raid do
                task.wait(0.2)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- 4. Auto Collect & Vacuum All Ores Worker
task.spawn(function()
    while true do
        if State.AutoCollectOres then
            pcall(CollectAllWorldOres)

            -- Smart pack overflow protection: auto craft 10 ores if pack is almost full
            if State.AutoSmartFreePack then
                pcall(function()
                    local LeftInfoGUI = require(ReplicatedStorage.GuiUtils.LeftInfoGUI)
                    local maxPack = UpgradeData.GetMaxNum("OrePack") or 24
                    if LeftInfoGUI.GetOrePack() >= maxPack - 2 then
                        local data = BackpackData.GetData()
                        if data and data.have then
                            local oreList = {}
                            local total = 0
                            for uuid, item in pairs(data.have) do
                                if item.Type == "Ore" and item.Number and item.Number > 0 then
                                    local take = math.min(item.Number, 10 - total)
                                    oreList[uuid] = take
                                    total = total + take
                                    if total >= 10 then break end
                                end
                            end
                            if total >= 4 then
                                ForgeRemote.ForgeRF:InvokeServer({
                                    ConfigType = State.ForgeType,
                                    UUIDList = oreList
                                })
                            end
                        end
                    end
                end)
            end
        end
        task.wait(0.12)
    end
end)

-- 5. Auto Forge Worker (Batches of 10 ores)
task.spawn(function()
    while true do
        if State.AutoForge then
            pcall(function()
                local data = BackpackData.GetData()
                if data and data.have then
                    local oreList = {}
                    local total = 0
                    for uuid, item in pairs(data.have) do
                        if item.Type == "Ore" and item.Number and item.Number > 0 then
                            local take = math.min(item.Number, 10 - total)
                            oreList[uuid] = take
                            total = total + take
                            if total >= 10 then break end
                        end
                    end
                    if total >= 4 then
                        ForgeRemote.ForgeRF:InvokeServer({
                            ConfigType = State.ForgeType,
                            UUIDList = oreList
                        })
                    end
                end
            end)
        end
        task.wait(0.35)
    end
end)

-- 6. Auto Sell All Non-Equipped Worker
task.spawn(function()
    while true do
        if State.AutoSellAll then
            pcall(function()
                if State.AutoEquipBest then
                    EquipBestEquipment()
                    task.wait(0.2)
                end
                BackpackData.SellAll()
            end)
        end
        task.wait(1.5)
    end
end)

-- 7. Auto Dungeon Sweeper Worker (Seamless Floor Sweep 1 to 30)
task.spawn(function()
    while true do
        if State.AutoDungeonSweep then
            pcall(function()
                -- If not currently in dungeon and not in another fight/raid, enter floor 1
                if not LocalPlayer:GetAttribute("Dungeoning") and not LocalPlayer:GetAttribute("IntoFight") and not State.AutoStage27Raid then
                    pcall(function() DungeonData.TryClaimDailyDunTic() end)
                    task.wait(0.2)
                    DungeonData.TryIntoDungeon(1)
                    task.wait(1.5)
                end

                -- While in dungeon, rapidly eliminate all spawned enemies and collect dropped ores
                if LocalPlayer:GetAttribute("Dungeoning") then
                    local enemyFolder = workspace:FindFirstChild("EnemyFolder")
                    if enemyFolder then
                        for _, enemy in ipairs(enemyFolder:GetChildren()) do
                            if not enemy:GetAttribute("Dead") then
                                Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                                    Damage = 1e30,
                                    SkillID = "K_ATK_1",
                                    IsCrit = true
                                })
                            end
                        end
                    end
                    -- Vacuum any reward ores created on the floor
                    CollectAllWorldOres()
                end
            end)
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- 8. Auto Kill Mobs & SuperLoot Worker
task.spawn(function()
    while true do
        if State.AutoKillSuperLoot then
            pcall(function()
                local enemyFolder = workspace:FindFirstChild("EnemyFolder")
                if enemyFolder then
                    for _, enemy in ipairs(enemyFolder:GetChildren()) do
                        if not enemy:GetAttribute("Dead") then
                            SuperLootRemote.KillSuperLootRE:FireServer(enemy.Name)
                            Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                                Damage = 1e30,
                                SkillID = "K_ATK_1",
                                IsCrit = true
                            })
                        end
                    end
                end
            end)
        end
        task.wait(0.15)
    end
end)

-- 9. Auto Skill Spam Worker
task.spawn(function()
    while true do
        if State.AutoSkills then
            pcall(function()
                AttackRemote.UseAnySkillRE:FireServer()
            end)
        end
        task.wait(0.2)
    end
end)

-- 10. Auto Claim Worker (Daily, Online, Group, Index)
task.spawn(function()
    while true do
        if State.AutoClaimAll then
            pcall(function()
                for i = 1, 12 do
                    OnlineData.TryClaim(i)
                end
                DungeonData.TryClaimDailyDunTic()
                IndexData.TryClaimedLevel()
                PlayerRemote.TryJoinGroupRE:FireServer()
                UpdateLogRemote.TryClaimUPDRewardRE:FireServer()
            end)
        end
        task.wait(5.0)
    end
end)

-- 11. Auto Claim Index Worker (Weapons, Armors, Hats, Ores & Level)
task.spawn(function()
    while true do
        if State.AutoClaimIndex or State.AutoClaimAll then
            pcall(function()
                local data = IndexData.GetData()
                if data and data.unlocked then
                    for fullID, _ in pairs(data.unlocked) do
                        if not (data.claimed and data.claimed[fullID]) then
                            local split = string.split(fullID, "-")
                            if #split == 2 then
                                IndexData.TryClaimedExp(split[1], split[2])
                                task.wait(0.05)
                            end
                        end
                    end
                end
                IndexData.TryClaimedLevel()
            end)
            task.wait(2.0)
        else
            task.wait(0.5)
        end
    end
end)

-- 12. Auto Equip Best Worker (Weapon, Armor, Hat)
task.spawn(function()
    while true do
        if State.AutoEquipBest then
            pcall(function()
                EquipBestEquipment()
            end)
            task.wait(1.5)
        else
            task.wait(0.5)
        end
    end
end)

-- Load saved settings before starting regular flow
LoadSavedState()
pcall(function() SaveManager:LoadAutoloadConfig() end)

-- Apply user preferred language
UpdateLanguage(State.Language or "TH")

task.delay(0.3, function()
    autoSaveLoaded = true
end)

local currentT = I18N[State.Language] or I18N.TH
Fluent:Notify({
    Title = "BY.STREET HUB",
    Content = string.format(currentT.NotifyLoaded, LocalPlayer.Name),
    Duration = 4
})
