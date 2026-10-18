--[[
    ========================================================================
    Street Hub - [Enhance] +1 Loot To Forge
    Supported: PC, Delta Mobile, Fluxus, Hydrogen, Codex, Arceus X, Solara
    Engineered for paneer
    ========================================================================
--]]

-- Ensure game and LocalPlayer are loaded (Crucial for Delta Mobile, Fluxus, Codex, Arceus X auto-execute)
if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Universal Safe GUI Parent Resolver (Prioritizes gethui for Mobile/PC, fallback to CoreGui/PlayerGui for Solara)
local function GetSafeGuiParent()
    local target = nil
    if gethui then
        pcall(function() target = gethui() end)
    end
    if not target then
        pcall(function()
            local cg = game:GetService("CoreGui")
            local test = Instance.new("Folder", cg)
            test:Destroy()
            target = cg
        end)
    end
    return target or LocalPlayer:WaitForChild("PlayerGui")
end

-- Resilient HttpGet fetcher (Handles Delta Mobile 302 redirects & network retries across all executors)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
local function FetchScript(url, maxRetries)
    maxRetries = maxRetries or 3
    for attempt = 1, maxRetries do
        if httpRequest then
            local reqOk, res = pcall(function()
                return httpRequest({ Url = url, Method = "GET" })
            end)
            if reqOk and res and res.Body and #res.Body > 50 then
                return res.Body
            end
        end
        local ok, result = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and result and #result > 50 then
            return result
        end
        task.wait(0.3)
    end
    return nil
end

-- Universal ProximityPrompt interaction for Delta Mobile & PC
local function SafeFireProximityPrompt(pp)
    if not pp or not pp.Parent or not pp.Enabled then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(pp, 0)
        elseif pp.InputHoldBegin then
            local old = pp.HoldDuration
            pp.HoldDuration = 0
            pp:InputHoldBegin()
            task.wait(0.01)
            pp:InputHoldEnd()
            pp.HoldDuration = old
        end
    end)
end

-- Global Farm State
local isMobileDevice = UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)
local State = {
    -- Brutal Master Bypass Flags
    UnlockAllGamePasses = true, -- Free All GamePasses & VIP Privileges
    OmniKillAura = true, -- Map-Wide 1-Hit Kill (1e30 Damage)
    GodMode = true, -- Immortal / Invincible (Zero Damage Taken)
    InsaneStatBoost = true, -- Extreme Multiplier (+5000% Luck / Damage / Coins / Ores)
    SpeedHack = false,
    WalkSpeedValue = 48,
    JumpPowerHack = false,
    JumpPowerValue = 80,
    Noclip = false,
    InfiniteJump = false,
    DisableBlur = true, -- Remove screen blur, TrainDOF, and Depth of Field

    -- Core Automation
    AutoTrain = false,
    Force100xTrain = true, -- Free GamePass VIP x100 Train Bypass
    AstralGenesisSet = true, -- Free Astral Genesis (Tri-Wyrm Set) Bypass
    AutoAstralSkill = false, -- Auto spam Astral Burst Domain (1100% damage)
    AutoRebirth = false,
    AutoStage27Raid = false,
    AutoCollectOres = false,
    AutoSmartFreePack = false,
    AutoForge = false,
    ForgeType = "Weapon", -- "Weapon", "Armor", "Hat"
    AutoEquipBest = false,
    AutoSellAll = false,
    AutoDungeonSweep = false,
    AutoFarmSeason2Coins = false, -- High-speed Dungeon Floor 50 Season 2 Coin farm
    AutoPetLuck = false, -- Auto roll Season 2 Pet Luck (400 SS2 Coins per roll)
    AutoKillSuperLoot = false,
    AutoWorldBoss = false,
    WorldBossCountdown = "Calculating...",
    AutoSkills = false,
    AutoClaimAll = false,
    AutoClaimIndex = false,
    AntiAFK = true,
    Language = "TH",
    WindowScale = isMobileDevice and 0.85 or 1.0,
    WindowWidth = isMobileDevice and 480 or 560,
    WindowHeight = isMobileDevice and 340 or 420,
}

local RequestAutoSave

-- ========================================================================
-- SILENT BULLETPROOF ANTI-AFK ENGINE (No Kick, No Rejoin, No UI Toggle)
-- ========================================================================
local function DisableCoreIdledConnections()
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
                pcall(function()
                    if disableconnection then
                        disableconnection(conn)
                    elseif conn.Disable then
                        conn:Disable()
                    elseif conn.Disconnect then
                        conn:Disconnect()
                    elseif conn.Enabled ~= nil then
                        conn.Enabled = false
                    end
                end)
            end
        end
    end)
end

local function PulseAntiAfkInput()
    -- 1. Hardware mouse micro-movement via VirtualInputManager (Desktop / supported mobile)
    pcall(function()
        if VirtualInputManager and VirtualInputManager.SendMouseMoveEvent then
            local cam = workspace.CurrentCamera
            local vpSize = cam and cam.ViewportSize or Vector2.new(800, 600)
            VirtualInputManager:SendMouseMoveEvent(vpSize.X / 2 + 1, vpSize.Y / 2 + 1, game)
            task.wait(0.04)
            VirtualInputManager:SendMouseMoveEvent(vpSize.X / 2, vpSize.Y / 2, game)
        end
    end)
    -- 2. Virtual right-click / camera pulse
    pcall(function()
        if VirtualUser then
            pcall(function() VirtualUser:CaptureController() end)
            local camCFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new()
            VirtualUser:Button2Down(Vector2.new(0, 0), camCFrame)
            task.wait(0.05)
            VirtualUser:Button2Up(Vector2.new(0, 0), camCFrame)
        end
    end)
    -- 3. Touch tap pulse for Mobile / Delta Android
    pcall(function()
        if UserInputService.TouchEnabled and VirtualUser then
            VirtualUser:ClickButton1(Vector2.new(10, 10))
        end
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
        if State and State.AntiAFK ~= false then
            DisableCoreIdledConnections()
            PulseAntiAfkInput()
        end
    end
end)

-- ========================================================================
-- ANTI-BLUR & CRYSTAL CLEAR SCREEN ENGINE (Zero Blur, No TrainDOF)
-- ========================================================================
local function RemoveAllBlurs()
    local Lighting = game:GetService("Lighting")
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
            if v:IsA("DepthOfFieldEffect") then
                pcall(function()
                    v.FarIntensity = 0
                    v.NearIntensity = 0
                end)
            end
        end
    end
end

local function HookAntiBlur(effect)
    if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") then
        if State and State.DisableBlur then
            effect.Enabled = false
            if effect:IsA("DepthOfFieldEffect") then
                pcall(function()
                    effect.FarIntensity = 0
                    effect.NearIntensity = 0
                end)
            end
        end
        effect:GetPropertyChangedSignal("Enabled"):Connect(function()
            if State and State.DisableBlur and effect.Enabled then
                effect.Enabled = false
            end
        end)
    end
end

for _, v in ipairs(game:GetService("Lighting"):GetDescendants()) do
    HookAntiBlur(v)
end

game:GetService("Lighting").DescendantAdded:Connect(function(v)
    HookAntiBlur(v)
end)

-- Dedicated background pulse to ensure no game script ever turns blur back on
task.spawn(function()
    while true do
        if State and State.DisableBlur then
            RemoveAllBlurs()
        end
        task.wait(0.5)
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
local function GetRemoteFolder(name)
    return Remote:FindFirstChild(name .. "_Server") 
        or Remote:FindFirstChild(name) 
        or Remote:WaitForChild(name .. "_Server", 3) 
        or Remote:WaitForChild(name, 3)
end

local TrainRemote = GetRemoteFolder("Train")
local StageRemote = GetRemoteFolder("Stage")
local DevRemote = GetRemoteFolder("Dev")
local AttackRemote = GetRemoteFolder("Attack")
local BackpackRemote = GetRemoteFolder("Backpack")
local ForgeRemote = GetRemoteFolder("Forge")
local DungeonRemote = GetRemoteFolder("Dungeon")
local SuperLootRemote = GetRemoteFolder("SuperLoot")
local OnlineRemote = GetRemoteFolder("Online")
local UpdateLogRemote = GetRemoteFolder("UpdateLog")
local PlayerRemote = GetRemoteFolder("Player")
local PotionRemote = GetRemoteFolder("Potion")
local IndexRemote = GetRemoteFolder("Index")
local CodeRemote = GetRemoteFolder("Code")
local RebirthRemote = GetRemoteFolder("Rebirth")
local WorldBossRemote = GetRemoteFolder("WorldBoss")


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
                SafeFireProximityPrompt(pp)
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
                SafeFireProximityPrompt(drop)
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
                if pp then
                    SafeFireProximityPrompt(pp)
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
-- UNIVERSAL MASTER BYPASS ENGINE (ALL GAMEPASSES, STATS, GOD MODE, KILL AURA)
-- ========================================================================
local BYPASS_GAMEPASS_LIST = {
    "VIP",
    "SuperLuck",
    "UltraLuck",
    "CommonLuck",
    "MoreOre",
    "SkipForge",
    "AutoCollectOre",
    "x2Damage",
    "SeasonVIP",
    "SeasonBossRewardx2",
    "AutoTrainArea_9",
    "AutoTrainArea_10",
    "AutoTrainArea_11",
    "TrainMulti_1",
    "TrainMulti_2",
    "Old_RebirthDunTic",
    "Old_OreLockDataFix",
    "PlayerInGroup"
}

-- 1. Hook PemData & inject gamepasses into active player data
pcall(function()
    local oldIsHave = PemData.isHavePem
    PemData.isHavePem = function(name)
        if State and State.UnlockAllGamePasses then
            for _, pass in ipairs(BYPASS_GAMEPASS_LIST) do
                if name == pass or (name and string.find(name, "AutoTrainArea_") and tonumber(string.match(name, "%d+")) and tonumber(string.match(name, "%d+")) >= 9) then
                    return true
                end
            end
        end
        if State and State.Force100xTrain and name == "AutoTrainArea_9" then
            return true
        end
        return oldIsHave(name)
    end
end)

local function ApplyGamePassAndVIPBypass()
    if not (State and State.UnlockAllGamePasses) then return end
    pcall(function()
        -- 1. Inject into PemData.GetData()
        local d = PemData.GetData and PemData.GetData()
        if type(d) == "table" then
            for _, pass in ipairs(BYPASS_GAMEPASS_LIST) do
                d[pass] = true
            end
        end

        -- 2. Inject into ProfileData Pem store
        local pdInst = ReplicatedStorage:FindFirstChild("ProfileData")
        if pdInst then
            local ProfileData = require(pdInst)
            local pemStore = ProfileData.GetStoreData and ProfileData.GetStoreData("Pem")
            if type(pemStore) == "table" then
                for _, pass in ipairs(BYPASS_GAMEPASS_LIST) do
                    pemStore[pass] = true
                end
            end
        end

        -- 3. Inject into ProfileData Season store & hook SeasonData
        if pdInst and ReplicatedStorage:FindFirstChild("LocalData") and ReplicatedStorage.LocalData:FindFirstChild("SeasonData") then
            local ProfileData = require(pdInst)
            local SeasonData = require(ReplicatedStorage.LocalData.SeasonData)
            local seasonStore = ProfileData.GetStoreData and ProfileData.GetStoreData("Season")
            if seasonStore and seasonStore.Season1 then
                seasonStore.Season1.IsVIP = true
                seasonStore.Season1.Cardx2 = true
            end
            SeasonData.IsVIP = function() return true end
            SeasonData.IsCardx2 = function() return true end
            SeasonData.IsRewardLock = function() return false end
        end

        -- 4. Set player attributes for VIP & AutoCollect
        LocalPlayer:SetAttribute("IsVIP", true)
        LocalPlayer:SetAttribute("VIP", true)
        LocalPlayer:SetAttribute("AutoCollect", "Common")

        -- 5. Trigger game's built-in AutoCollectOre logic
        task.spawn(function()
            pcall(function()
                local StageManager = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Manager") and LocalPlayer.PlayerScripts.Manager:FindFirstChild("StageManager")
                if StageManager and StageManager:FindFirstChild("OreUtils") then
                    local OreUtils = require(StageManager.OreUtils)
                    if OreUtils and OreUtils.OpenAutoCollect then
                        OreUtils.OpenAutoCollect("Common")
                    end
                end
            end)
            pcall(function()
                if StageRemote and StageRemote:FindFirstChild("OpenAutoCollectRE") then
                    StageRemote.OpenAutoCollectRE:FireServer("Common")
                end
            end)
        end)

        -- 6. Trigger all registered PemData UI callbacks in separate ephemeral threads to prevent yields
        local getuv = debug and debug.getupvalue or getupvalue
        if getuv then
            local callbacks = getuv(PemData.AddCallback, 1)
            if type(callbacks) == "table" then
                for _, cb in ipairs(callbacks) do
                    task.spawn(function()
                        pcall(cb)
                    end)
                end
            end
        end

        -- 7. Update Shop GUI if loaded
        pcall(function()
            if ReplicatedStorage:FindFirstChild("GuiUtils") and ReplicatedStorage.GuiUtils:FindFirstChild("Shop") then
                local ShopModule = require(ReplicatedStorage.GuiUtils.Shop)
                if ShopModule and ShopModule.updateGamePass then
                    ShopModule.updateGamePass()
                end
            end
        end)

        -- 8. Hide in-game buy buttons directly from PlayerGui
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local rightContent = pg:FindFirstChild("Hud") and pg.Hud:FindFirstChild("Right") and pg.Hud.Right:FindFirstChild("Content")
            if rightContent then rightContent.Visible = false end

            local skipForging = pg:FindFirstChild("ScreenMain") and pg.ScreenMain:FindFirstChild("Forge") and pg.ScreenMain.Forge:FindFirstChild("Bottom") and pg.ScreenMain.Forge.Bottom:FindFirstChild("SkipForging")
            if skipForging and skipForging:FindFirstChild("Button") then
                skipForging.Button.Visible = false
            end
        end
    end)
end

-- 2. Hook MarketplaceService to block prompts and spoof ownership
pcall(function()
    local MarketplaceService = game:GetService("MarketplaceService")
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if self == MarketplaceService and State and State.UnlockAllGamePasses then
                if method == "UserOwnsGamePassAsync" then
                    return true
                elseif method == "PromptGamePassPurchase" or method == "PromptProductPurchase" then
                    return
                end
            end
            return oldNamecall(self, ...)
        end)
    end
    if hookfunction then
        pcall(function()
            hookfunction(MarketplaceService.UserOwnsGamePassAsync, function() return true end)
        end)
        pcall(function()
            hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
        end)
    end
end)

-- Continuous GamePass & VIP Guardian
task.spawn(function()
    while true do
        if State and State.UnlockAllGamePasses then
            ApplyGamePassAndVIPBypass()
            task.wait(2.0)
        else
            task.wait(3.0)
        end
    end
end)

-- Background Auto-Vacuum for AutoCollectOre GamePass emulation
task.spawn(function()
    while true do
        if State and State.UnlockAllGamePasses then
            pcall(CollectAllWorldOres)
            task.wait(0.6)
        else
            task.wait(2.0)
        end
    end
end)

-- 3. Extreme Luck & Stat Multiplier Hook (BalanceUtils)
pcall(function()
    local oldGetPem = BalanceUtils.GetPemBoost
    BalanceUtils.GetPemBoost = function(plr, typ, data)
        if State and State.InsaneStatBoost then
            if typ == "Luck" then return 50 end
            if typ == "Damage" then return 50 end
            if typ == "Coin" then return 50 end
            if typ == "OreNumber" then return 50 end
            if typ == "Train" then return 50 end
        end
        return oldGetPem(plr, typ, data)
    end
end)

-- 4. God Mode / Immortal Invincibility Hook (HPCTRL)
pcall(function()
    local oldDamageOnce = HPCTRL.DamageOnce
    HPCTRL.DamageOnce = function(target, dmg, ...)
        local char = LocalPlayer.Character
        if State and State.GodMode and target and (target == char or (char and target:IsDescendantOf(char))) then
            return 0
        end
        return oldDamageOnce(target, dmg, ...)
    end
end)

-- Continuous God Mode Health Keeper
task.spawn(function()
    while true do
        if State and State.GodMode then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health < hum.MaxHealth then
                        hum.Health = hum.MaxHealth
                    end
                    local hpVal = char:FindFirstChild("HPValue")
                    if hpVal then
                        local max = hpVal:GetAttribute("MaxHP") or 100
                        if hpVal.Value < max then
                            hpVal.Value = max
                        end
                    end
                    if LocalPlayer:GetAttribute("Dead") then
                        LocalPlayer:SetAttribute("Dead", false)
                    end
                end
            end)
            task.wait(0.2)
        else
            task.wait(1)
        end
    end
end)

-- 5. Omni-Kill Aura (Instant Map Obliteration 1e30)
task.spawn(function()
    while true do
        if State and State.OmniKillAura then
            pcall(function()
                local folders = {
                    workspace:FindFirstChild("EnemyFolder"),
                    workspace:FindFirstChild("EnemyFolder_Server")
                }
                for _, folder in ipairs(folders) do
                    if folder then
                        for _, enemy in ipairs(folder:GetChildren()) do
                            if enemy and not enemy:GetAttribute("Dead") then
                                -- Instant hit event with 1e30 damage
                                pcall(function()
                                    if Remote:FindFirstChild("Attack") and Remote.Attack:FindFirstChild("EnemyHitBE") then
                                        Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                                            Damage = 1e30,
                                            SkillID = "K_ATK_1",
                                            IsCrit = true
                                        })
                                    end
                                end)
                                -- Trigger server kill event
                                pcall(function()
                                    if AttackRemote and AttackRemote:FindFirstChild("KillEnemyRE") then
                                        AttackRemote.KillEnemyRE:FireServer(enemy.Name)
                                    end
                                end)
                                -- SuperLoot kill event
                                pcall(function()
                                    if SuperLootRemote and SuperLootRemote:FindFirstChild("KillSuperLootRE") then
                                        SuperLootRemote.KillSuperLootRE:FireServer(enemy.Name)
                                    end
                                end)
                            end
                        end
                    end
                end
            end)
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- 6. Player Movement Bypass (WalkSpeed, JumpPower, Noclip, Infinite Jump)
task.spawn(function()
    RunService.Stepped:Connect(function()
        if State and State.Noclip then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if State and State.SpeedHack and State.WalkSpeedValue then
                if hum.WalkSpeed ~= State.WalkSpeedValue then
                    hum.WalkSpeed = State.WalkSpeedValue
                end
            end
            if State and State.JumpPowerHack and State.JumpPowerValue then
                if hum.JumpPower ~= State.JumpPowerValue then
                    hum.JumpPower = State.JumpPowerValue
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if State and State.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function GetBestUnlockedTrainArea()
    if State and State.Force100xTrain then
        return "9"
    end
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
    local char = LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return bestID end

    if bestID == "9" then
        -- Teleport directly to the VIP Royal Throne Chair (Safe, NO Robux prompts)
        char.HumanoidRootPart.CFrame = CFrame.new(-111.58, 12, 0.58)
        task.wait(0.2)
        pcall(function()
            LocalPlayer:SetAttribute("AutoTrainAreaID", 9)
            TrainRemote.IntoAutoTrainRE:FireServer(9)
            TrainCTRL.StartAutoTrain()
        end)
        return "9"
    end

    local touched = workspace:FindFirstChild("TOUCHED")
    local pad = touched and touched:FindFirstChild("AutoTrainArea") and touched.AutoTrainArea:FindFirstChild(bestID)
    if pad then
        char.HumanoidRootPart.CFrame = pad.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
        pcall(function()
            local idNum = tonumber(bestID)
            LocalPlayer:SetAttribute("AutoTrainAreaID", idNum)
            TrainRemote.IntoAutoTrainRE:FireServer(idNum)
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
-- ASTRAL GENESIS SET (TRI-WYRM VIP BYPASS ENGINE) & EQUIPMENT MANAGERS
-- ========================================================================
local EquipmentModelUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("EquipmentModelUtils"))
local SkillCTRL
pcall(function()
    SkillCTRL = require(ReplicatedStorage:WaitForChild("SkillSystemNew"):WaitForChild("SkillCTRL"))
end)

local ASTRAL_WEAPON_ID = "G_1002"
local ASTRAL_ARMOR_ID = "HArmor_1002"
local ASTRAL_HAT_ID = "HHat_1002"

local VIRTUAL_ASTRAL_UUID_WEAPON = "VIRTUAL_ASTRAL_G_1002"
local VIRTUAL_ASTRAL_UUID_ARMOR = "VIRTUAL_ASTRAL_HArmor_1002"
local VIRTUAL_ASTRAL_UUID_HAT = "VIRTUAL_ASTRAL_HHat_1002"

local function GetAstralGenesisPieces()
    local data = BackpackData.GetData()
    if not data or not data.have then return nil, nil, nil end
    local wUUID, aUUID, hUUID
    for uuid, item in pairs(data.have) do
        if item.ID == ASTRAL_WEAPON_ID and not wUUID then
            wUUID = uuid
        elseif item.ID == ASTRAL_ARMOR_ID and not aUUID then
            aUUID = uuid
        elseif item.ID == ASTRAL_HAT_ID and not hUUID then
            hUUID = uuid
        end
    end
    return wUUID, aUUID, hUUID
end

local function EnsureAstralGenesisData()
    local data = BackpackData.GetData()
    if not data or not data.have then return nil, nil, nil end
    if not data.equiped then data.equiped = {} end

    local wUUID, aUUID, hUUID = GetAstralGenesisPieces()

    if not wUUID then
        wUUID = VIRTUAL_ASTRAL_UUID_WEAPON
        data.have[wUUID] = {
            ID = ASTRAL_WEAPON_ID,
            Type = "Weapon",
            Level = 25,
            EnchanceNum = 2,
            SkillNum = 1,
            MainAffix = { Type = "Train", Number = 100.0 },
            SkillList = { { ID = "G_Skill_10" }, { ID = "G_Skill_1001" } },
            EnchanceList = { { ID = "Fire_3" }, { ID = "Poison_3" } },
            Affix = {},
            AffixNum = 0,
            Lock = true
        }
    end

    if not aUUID then
        aUUID = VIRTUAL_ASTRAL_UUID_ARMOR
        data.have[aUUID] = {
            ID = ASTRAL_ARMOR_ID,
            Type = "Armor",
            Level = 25,
            EnchanceNum = 2,
            MainAffix = { Type = "Defence", Number = 100.0 },
            EnchanceList = { { ID = "Fire_3" }, { ID = "Poison_3" } },
            Affix = {},
            AffixNum = 0,
            Lock = true
        }
    end

    if not hUUID then
        hUUID = VIRTUAL_ASTRAL_UUID_HAT
        data.have[hUUID] = {
            ID = ASTRAL_HAT_ID,
            Type = "Hat",
            Level = 25,
            EnchanceNum = 2,
            MainAffix = { Type = "Train", Number = 100.0 },
            EnchanceList = { { ID = "Fire_3" }, { ID = "Poison_3" } },
            Affix = {},
            AffixNum = 0,
            Lock = true
        }
    end

    return wUUID, aUUID, hUUID
end

local function ApplyAstralGenesisVisuals()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    pcall(function()
        local weaponObj = char:FindFirstChild("WEAPON")
        if not weaponObj or weaponObj:GetAttribute("ID") ~= ASTRAL_WEAPON_ID then
            EquipmentModelUtils.CreateWeaponModel(char, ASTRAL_WEAPON_ID, {
                Level = 25,
                EnchanceList = { { ID = "Fire_3" }, { ID = "Poison_3" } }
            })
        end
        local armorObj = char:FindFirstChild("Armor")
        if not armorObj or armorObj:GetAttribute("ID") ~= ASTRAL_ARMOR_ID then
            EquipmentModelUtils.CreateArmorModel(char, ASTRAL_ARMOR_ID, "Armor", {
                Level = 25,
                EnchanceList = { { ID = "Fire_3" }, { ID = "Poison_3" } }
            })
        end
        local hatObj = char:FindFirstChild("Hat")
        if not hatObj or hatObj:GetAttribute("ID") ~= ASTRAL_HAT_ID then
            EquipmentModelUtils.CreateArmorModel(char, ASTRAL_HAT_ID, "Hat", {
                Level = 25,
                EnchanceList = { { ID = "Fire_3" }, { ID = "Poison_3" } }
            })
        end
    end)
end

local function EquipAstralGenesisSet(forceNotify)
    local wUUID, aUUID, hUUID = EnsureAstralGenesisData()
    local data = BackpackData.GetData()

    pcall(function()
        if wUUID and wUUID ~= VIRTUAL_ASTRAL_UUID_WEAPON then
            BackpackData.EquipedItem(wUUID, "Weapon")
        elseif data and data.equiped then
            data.equiped.Weapon = VIRTUAL_ASTRAL_UUID_WEAPON
        end
    end)

    pcall(function()
        if aUUID and aUUID ~= VIRTUAL_ASTRAL_UUID_ARMOR then
            BackpackData.EquipedItem(aUUID, "Armor")
        elseif data and data.equiped then
            data.equiped.Armor = VIRTUAL_ASTRAL_UUID_ARMOR
        end
    end)

    pcall(function()
        if hUUID and hUUID ~= VIRTUAL_ASTRAL_UUID_HAT then
            BackpackData.EquipedItem(hUUID, "Hat")
        elseif data and data.equiped then
            data.equiped.Hat = VIRTUAL_ASTRAL_UUID_HAT
        end
    end)

    ApplyAstralGenesisVisuals()

    if forceNotify then
        local lang = State.Language or "TH"
        Fluent:Notify({
            Title = "ASTRAL GENESIS",
            Content = (lang == "TH")
                and "เสกและติดตั้งเซ็ต Astral Genesis (ดาบ Supernova, เกราะ Devourer, มงกุฎ Sovereign) เรียบร้อย!"
                or "Astral Genesis Set (Supernova Edge, Devourer Plate, Sovereign Crown) successfully equipped!",
            Duration = 3
        })
    end
end

local function CastAstralBurstDomain()
    pcall(function()
        if SkillCTRL and SkillCTRL.UseSkill then
            SkillCTRL.UseSkill(LocalPlayer, "G_Skill_1001", { SkillIndex = "Extra" })
        end
    end)
end

-- Hook BackpackData to ensure client logic treats Astral Genesis as equipped when enabled
pcall(function()
    local oldGetEquipedWeaponID = BackpackData.GetEquipedWeaponID
    BackpackData.GetEquipedWeaponID = function(...)
        if State and State.AstralGenesisSet then
            return ASTRAL_WEAPON_ID
        end
        return oldGetEquipedWeaponID(...)
    end

    local oldGetEquipedArmorID = BackpackData.GetEquipedArmorID
    BackpackData.GetEquipedArmorID = function(...)
        if State and State.AstralGenesisSet then
            return ASTRAL_ARMOR_ID
        end
        return oldGetEquipedArmorID(...)
    end

    local oldGetEquipedHatID = BackpackData.GetEquipedHatID
    BackpackData.GetEquipedHatID = function(...)
        if State and State.AstralGenesisSet then
            return ASTRAL_HAT_ID
        end
        return oldGetEquipedHatID(...)
    end

    local oldGetItemDataByIndex = BackpackData.GetItemDataByIndex
    BackpackData.GetItemDataByIndex = function(slot, ...)
        if State and State.AstralGenesisSet then
            local data = BackpackData.GetData()
            if data and data.have then
                if slot == "Weapon" then
                    local wUUID = GetAstralGenesisPieces()
                    if wUUID and data.have[wUUID] then return data.have[wUUID] end
                    if data.have[VIRTUAL_ASTRAL_UUID_WEAPON] then return data.have[VIRTUAL_ASTRAL_UUID_WEAPON] end
                elseif slot == "Armor" then
                    local _, aUUID = GetAstralGenesisPieces()
                    if aUUID and data.have[aUUID] then return data.have[aUUID] end
                    if data.have[VIRTUAL_ASTRAL_UUID_ARMOR] then return data.have[VIRTUAL_ASTRAL_UUID_ARMOR] end
                elseif slot == "Hat" then
                    local _, _, hUUID = GetAstralGenesisPieces()
                    if hUUID and data.have[hUUID] then return data.have[hUUID] end
                    if data.have[VIRTUAL_ASTRAL_UUID_HAT] then return data.have[VIRTUAL_ASTRAL_UUID_HAT] end
                end
            end
        end
        return oldGetItemDataByIndex(slot, ...)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if State and State.AstralGenesisSet then
        task.wait(1.0)
        EquipAstralGenesisSet(false)
    end
end)

-- Continuous Astral Genesis Set Guardian (Guarantees models stay intact without vanishing)
task.spawn(function()
    while true do
        if State and State.AstralGenesisSet then
            pcall(function()
                EnsureAstralGenesisData()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local w = char:FindFirstChild("WEAPON")
                    local a = char:FindFirstChild("Armor")
                    local h = char:FindFirstChild("Hat")
                    if (not w or w:GetAttribute("ID") ~= ASTRAL_WEAPON_ID)
                        or (not a or a:GetAttribute("ID") ~= ASTRAL_ARMOR_ID)
                        or (not h or h:GetAttribute("ID") ~= ASTRAL_HAT_ID) then
                        ApplyAstralGenesisVisuals()
                    end
                end
            end)
            task.wait(1.0)
        else
            task.wait(1.5)
        end
    end
end)

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

    local wUUID, aUUID, hUUID
    if State and State.AstralGenesisSet then
        wUUID, aUUID, hUUID = GetAstralGenesisPieces()
    end

    local best = {
        Weapon = { uuid = nil, val = -1 },
        Armor = { uuid = nil, val = -1 },
        Hat = { uuid = nil, val = -1 },
    }

    for uuid, item in pairs(data.have) do
        local itemType = item.Type
        if best[itemType] then
            local val = GetItemPower(item, data)
            if State and State.AstralGenesisSet then
                if item.ID == ASTRAL_WEAPON_ID and itemType == "Weapon" then
                    val = math.huge
                elseif item.ID == ASTRAL_ARMOR_ID and itemType == "Armor" then
                    val = math.huge
                elseif item.ID == ASTRAL_HAT_ID and itemType == "Hat" then
                    val = math.huge
                end
            end
            if val > best[itemType].val then
                best[itemType].uuid = uuid
                best[itemType].val = val
            end
        end
    end

    if State and State.AstralGenesisSet then
        if wUUID then best.Weapon.uuid = wUUID end
        if aUUID then best.Armor.uuid = aUUID end
        if hUUID then best.Hat.uuid = hUUID end
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

    if State and State.AstralGenesisSet then
        ApplyAstralGenesisVisuals()
    end

    return changedCount > 0, changedCount
end

-- Clean up previous sessions safely
if getgenv and getgenv().Fluent then
    pcall(function() getgenv().Fluent:Destroy() end)
    getgenv().Fluent = nil
end
for _, libName in ipairs({"StreetHubFluentLib", "SpinachFluentLib"}) do
    if _G[libName] then
        pcall(function() _G[libName]:Destroy() end)
        _G[libName] = nil
    end
end
for _, winName in ipairs({"StreetHubFluentWindow", "SpinachFluentWindow"}) do
    if _G[winName] then
        pcall(function() _G[winName]:Destroy() end)
        _G[winName] = nil
    end
end

-- ========================================================================
-- FLUENT UI LIBRARY INITIALIZATION (Universal Safe Loader)
-- ========================================================================
local FluentRaw = FetchScript("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/releases/latest/download/main.lua")
    or FetchScript("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua")
    or FetchScript("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")

if not FluentRaw then
    warn("[Street Hub] Failed to load Fluent UI library.")
    return
end

local FluentPatched = FluentRaw
    :gsub("game:GetService%'CoreGui%'", "game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')")
    :gsub('game:GetService%("CoreGui"%)', "game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')")
    :gsub("protectgui", "dummy_protectgui")
    :gsub("protect_gui", "dummy_protect_gui")

local Fluent = nil
local okFluent, resFluent = pcall(function()
    return loadstring(FluentPatched)()
end)
if okFluent and resFluent then
    Fluent = resFluent
else
    Fluent = loadstring(FluentRaw)()
end

local SaveManager = nil
pcall(function()
    local smRaw = FetchScript("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
    if smRaw then SaveManager = loadstring(smRaw)() end
end)
local InterfaceManager = nil
pcall(function()
    local imRaw = FetchScript("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")
    if imRaw then InterfaceManager = loadstring(imRaw)() end
end)

_G.StreetHubFluentLib = Fluent
_G.SpinachFluentLib = Fluent

local isMobile = UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)
local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 600)
local winWidth = State.WindowWidth or (isMobile and math.clamp(math.floor(vp.X * 0.90), 320, 500) or 560)
local winHeight = State.WindowHeight or (isMobile and math.clamp(math.floor(vp.Y * 0.85), 260, 360) or 420)
if _G.StreetHubFluentWindow and _G.StreetHubFluentWindow.Root then
    pcall(function()
        local sg = _G.StreetHubFluentWindow.Root:FindFirstAncestorWhichIsA("ScreenGui")
        if sg then sg:Destroy() end
    end)
end

-- Cleanup any test windows
pcall(function()
    local cg = game:GetService("CoreGui")
    for _, g in ipairs({cg, cg:FindFirstChild("RobloxGui"), LocalPlayer:FindFirstChild("PlayerGui")}) do
        if g then
            for _, c in ipairs(g:GetChildren()) do
                if c:IsA("ScreenGui") and c.Name == "ScreenGui" then
                    local t = c:FindFirstChild("Title", true)
                    if t and (t.Text == "Test" or t.Text == "Tab") then
                        c:Destroy()
                    end
                end
            end
        end
    end
end)

local tabWidth = isMobile and 120 or 145

local Window = Fluent:CreateWindow({
    Title = "[Enhance] +1 Loot To Forge",
    SubTitle = "STREET HUB",
    TabWidth = tabWidth,
    Size = UDim2.fromOffset(winWidth, winHeight),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})
_G.StreetHubFluentWindow = Window
_G.SpinachFluentWindow = Window

-- Protect and parent Fluent.GUI safely in safe container to eliminate CoreGui capability restrictions
if Fluent and Fluent.GUI then
    Fluent.GUI.ResetOnSpawn = false
    pcall(function()
        Fluent.GUI.Parent = GetSafeGuiParent()
    end)
end

-- Setup Window UIScale controller
local WindowUIScale = Window.Root:FindFirstChild("StreetHubUIScale")
if not WindowUIScale then
    WindowUIScale = Instance.new("UIScale")
    WindowUIScale.Name = "StreetHubUIScale"
    WindowUIScale.Scale = State.WindowScale or (isMobile and 0.85 or 1.0)
    WindowUIScale.Parent = Window.Root
else
    WindowUIScale.Scale = State.WindowScale or (isMobile and 0.85 or 1.0)
end

-- ========================================================================
-- INTERACTIVE CORNER RESIZE HANDLE (Drag freely on Mobile & PC)
-- ========================================================================
local function SetupWindowResizeHandle()
    local root = Window.Root
    if not root then return end

    local prev = root:FindFirstChild("StreetHubResizeGrip")
    if prev then pcall(function() prev:Destroy() end) end

    local grip = Instance.new("TextButton")
    grip.Name = "StreetHubResizeGrip"
    grip.Size = UDim2.fromOffset(26, 26)
    grip.Position = UDim2.new(1, -26, 1, -26)
    grip.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
    grip.BackgroundTransparency = 0.3
    grip.BorderSizePixel = 0
    grip.Text = "⤡"
    grip.TextColor3 = Color3.fromRGB(0, 215, 125)
    grip.TextSize = 16
    grip.Font = Enum.Font.GothamBold
    grip.AutoButtonColor = false
    grip.ZIndex = 9999
    grip.Parent = root

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = grip

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 215, 125)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.Parent = grip

    local resizing = false
    local dragStart = Vector2.new()
    local startSize = Vector2.new()

    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startSize = Vector2.new(root.AbsoluteSize.X, root.AbsoluteSize.Y)

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    if conn then conn:Disconnect() end
                    State.WindowWidth = root.AbsoluteSize.X
                    State.WindowHeight = root.AbsoluteSize.Y
                    if RequestAutoSave then
                        RequestAutoSave()
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            local cam = workspace.CurrentCamera
            local vpSize = cam and cam.ViewportSize or Vector2.new(1200, 800)
            local currentScale = (WindowUIScale and WindowUIScale.Scale) or 1.0

            local adjustedDeltaX = delta.X / currentScale
            local adjustedDeltaY = delta.Y / currentScale

            local minW, minH = 360, 240
            local maxW, maxH = math.floor((vpSize.X * 0.98) / currentScale), math.floor((vpSize.Y * 0.95) / currentScale)

            local newW = math.clamp(math.floor(startSize.X + adjustedDeltaX), minW, maxW)
            local newH = math.clamp(math.floor(startSize.Y + adjustedDeltaY), minH, maxH)
            root.Size = UDim2.fromOffset(newW, newH)
        end
    end)

    grip.MouseEnter:Connect(function()
        grip.BackgroundColor3 = Color3.fromRGB(36, 40, 50)
        grip.BackgroundTransparency = 0.1
    end)
    grip.MouseLeave:Connect(function()
        grip.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
        grip.BackgroundTransparency = 0.3
    end)
end
SetupWindowResizeHandle()

-- ========================================================================
-- FLOATING DRAGGABLE UI TOGGLE BUTTON (Open / Close)
-- ========================================================================
local function CreateFloatingToggleButton()
    local targetParent = GetSafeGuiParent()

    local function cleanupOld(container)
        if not container then return end
        for _, name in ipairs({"StreetHubToggleButton", "SpinachHubToggleButton"}) do
            local prev = container:FindFirstChild(name)
            if prev then pcall(function() prev:Destroy() end) end
        end
    end

    if gethui then pcall(cleanupOld, gethui()) end
    pcall(function() cleanupOld(game:GetService("CoreGui")) end)
    pcall(function() cleanupOld(PlayerGui) end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StreetHubToggleButton"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999
    screenGui.Parent = targetParent

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = isMobile and UDim2.new(0, 126, 0, 36) or UDim2.new(0, 120, 0, 34)
    btn.Position = isMobile and UDim2.new(0, 16, 0.22, 0) or UDim2.new(0, 16, 0.40, 0)
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
    title.Text = "STREET HUB"
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

    -- Smooth draggable mechanics for Touch & Mouse
    local dragging = false
    local dragStart = Vector3.new()
    local startPos = UDim2.new()
    local movedFar = false

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            movedFar = false
            dragStart = input.Position
            startPos = btn.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 10 then
                movedFar = true
            end
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function ToggleWindow()
        local win = _G.StreetHubFluentWindow or _G.SpinachFluentWindow
        if win and win.Root then
            local newVis = not win.Root.Visible
            win.Root.Visible = newVis
            dot.BackgroundColor3 = newVis and Color3.fromRGB(0, 230, 120) or Color3.fromRGB(120, 125, 135)
            stroke.Color = newVis and Color3.fromRGB(0, 215, 125) or Color3.fromRGB(80, 85, 95)
        end
    end

    btn.Activated:Connect(function()
        if not movedFar then
            ToggleWindow()
        end
    end)

    -- Hover effect (desktop only)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    end)
end

-- Permanently suppress Roblox CoreGui PurchasePromptApp, FoundationOverlay, and Upsell modals
local function SetupPurchasePromptBlocker()
    pcall(function()
        local cg = game:GetService("CoreGui")
        local blockedNames = {
            PurchasePromptApp = true,
            FoundationOverlay = true,
            AvatarEditorPromptsApp = true,
            CommercePurchaseApp = true,
            BulkPurchaseApp = true
        }

        local function suppress(obj)
            if not obj then return end
            if blockedNames[obj.Name] then
                pcall(function()
                    if obj:IsA("ScreenGui") then obj.Enabled = false end
                    for _, d in ipairs(obj:GetChildren()) do pcall(function() d:Destroy() end) end
                end)
                if obj:IsA("ScreenGui") then
                    obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                        if obj.Enabled then obj.Enabled = false end
                    end)
                end
            end
        end

        for _, child in ipairs(cg:GetChildren()) do
            suppress(child)
        end
        cg.ChildAdded:Connect(suppress)
    end)
end
SetupPurchasePromptBlocker()

CreateFloatingToggleButton()

local Tabs = {
    Bypass = Window:AddTab({ Title = "🔥 Bypass", Icon = "zap" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "sprout" }),
    Forge = Window:AddTab({ Title = "Forge", Icon = "hammer" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Rewards = Window:AddTab({ Title = "Claim", Icon = "gift" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local function CreateSection(tab, title)
    local container = tab.ScrollFrame or tab.Container
    local sec = {}
    local frame = Instance.new("Frame")
    frame.Name = "SectionHeader"
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = 7
    frame.Parent = container

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Size = UDim2.new(1, -8, 0, 16)
    titleLbl.Position = UDim2.new(0, 4, 0, 4)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = string.upper(title)
    titleLbl.TextColor3 = Color3.fromRGB(0, 215, 125)
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame

    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, -8, 0, 1)
    sep.Position = UDim2.new(0, 4, 1, -1)
    sep.BackgroundColor3 = Color3.fromRGB(36, 40, 48)
    sep.BorderSizePixel = 0
    sep.Parent = frame

    function sec:SetTitle(newTitle)
        titleLbl.Text = string.upper(newTitle)
    end

    return sec
end

for _, tab in pairs(Tabs) do
    tab.AddSection = function(self, title)
        return CreateSection(self, title)
    end
end

local Options = Fluent.Options
local UIElements = {}

-- ========================================================================
-- MULTI-LANGUAGE SYSTEM (English & ภาษาไทย)
-- ========================================================================
local I18N = {
    EN = {
        TabBypass = "🔥 Bypass",
        TabFarm = "Farm",
        TabForge = "Forge",
        TabCombat = "Combat",
        TabRewards = "Claim",
        TabSettings = "Settings",

        -- Section Headers
        SecBypassCore = "Core Bypasses",
        SecBypassMovement = "Movement & Visuals",
        SecBypassActions = "Instant Actions",

        SecFarmStats = "Live Dashboard",
        SecFarmTrain = "Training & Rebirth",
        SecFarmSeason = "Season 2 & Pets",
        SecFarmOres = "Ores & Inventory",
        SecFarmRaid = "Stage 27 Raid",

        SecForgeCraft = "Auto Crafting",
        SecForgeGear = "Gear Management",
        SecForgeAstral = "Astral Genesis VIP Set",

        SecCombatTower = "Frozen Tower (Floor 1-50)",
        SecCombatBoss = "World Boss",
        SecCombatSkills = "Skills & Combat",

        SecRewardsAuto = "Automated Claims",
        SecRewardsInstant = "Instant Claims",

        SecSettingsProfile = "Profile & Language",
        SecSettingsSave = "Auto Save & Protection",
        SecSettingsWindow = "Window Display",
        SecSettingsConfig = "Configurations",

        -- Bypass Tab
        BypassInfoTitle = "Master Bypass Engine",
        BypassInfoContent = "Unlocks all VIP GamePasses, Instant 1e30 Kill Aura, Immortal God Mode, and Extreme Stat Multipliers.",
        UnlockGamePassesTitle = "Unlock All GamePasses & VIP",
        UnlockGamePassesDesc = "Grants VIP, SuperLuck, UltraLuck, CommonLuck, MoreOre, SkipForge, AutoCollectOre, 2xDamage, SeasonVIP, and VIP Train Areas 9-11 without Robux",
        OmniKillAuraTitle = "Omni-Kill Aura (1e30 Damage)",
        OmniKillAuraDesc = "Instantly eliminates all enemies across the entire map using 1e30 damage and server execution events",
        GodModeTitle = "God Mode (Immortal)",
        GodModeDesc = "Completely zeroes out all incoming damage; keeps health at 100% permanently",
        InsaneStatsTitle = "Extreme Stat Multiplier (+5000%)",
        InsaneStatsDesc = "Hooks game balance formulas for massive Luck, Damage, Coins, and Ore drop rates",
        SpeedHackTitle = "WalkSpeed Boost",
        SpeedHackDesc = "Overrides player movement speed (16 - 150)",
        WalkSpeedSliderTitle = "Custom WalkSpeed",
        JumpHackTitle = "JumpPower Boost",
        JumpHackDesc = "Overrides player jump height (50 - 200)",
        JumpPowerSliderTitle = "Custom JumpPower",
        NoclipTitle = "Noclip (Walk Through Walls)",
        NoclipDesc = "Disables collision on character parts, allowing you to walk through walls and gates",
        InfiniteJumpTitle = "Infinite Jump",
        InfiniteJumpDesc = "Allows jumping repeatedly in mid-air without landing",
        DisableBlurTitle = "Disable Blur & Depth of Field",
        DisableBlurDesc = "Permanently removes TrainDOF, Blur, and Depth of Field for a crystal clear view",
        BtnNukeAllTitle = "Nuke All Map Enemies Now",
        BtnNukeAllDesc = "Sends 1e30 damage to every monster currently present in workspace",
        BtnVacuumOresTitle = "Vacuum All World Ores",
        BtnVacuumOresDesc = "Instantly collects all dropped ores across the entire game",

        -- Farm Tab
        StatTitle = "Live Player Statistics",
        AutoTrainTitle = "Auto Train (Highest Area)",
        AutoTrainDesc = "Auto-warps directly to your highest unlocked train pad & trains at max multiplier",
        Force100xTrainTitle = "Force 100x Train Pad (VIP)",
        Force100xTrainDesc = "Forces VIP 100x multiplier train pad without purchasing the GamePass",
        AutoRebirthTitle = "Auto Rebirth (Max Speed)",
        AutoRebirthDesc = "Instantly performs Rebirth the moment level requirement is met",
        BtnWarpTrainTitle = "Warp to Best Train Area",
        BtnWarpTrainDesc = "Instantly warps to your highest multiplier training dummy pad",
        BtnMaxUpgradesTitle = "Max Upgrade Passives",
        BtnMaxUpgradesDesc = "Upgrades Train, Luck, and OrePack capacity to max level",

        AutoFarmSS2Title = "Auto Farm SS2 Coins (Tower 50)",
        AutoFarmSS2Desc = "Spams Dungeon Floor 50 completions to rapidly farm massive Season 2 Coins, Ores & Enchant Stones",
        BtnFarmSS2Title = "Instant Farm 100x SS2 Coins",
        BtnFarmSS2Desc = "Runs a 100-round burst of Dungeon Floor 50 immediately",
        NotifySS2Farmed = "Farmed %d rounds (+%s SS2 Coins)!",
        AutoPetLuckTitle = "Auto Roll Pet Luck",
        AutoPetLuckDesc = "Automatically rolls Season 2 Pet Luck when having >= 400 SS2 Coins (bypasses roll animations)",
        BtnRollPetLuckTitle = "Instant Roll Pet Luck (10x)",
        BtnRollPetLuckDesc = "Draws 10 Season 2 Pets instantly using 4,000 SS2 Coins",
        NotifyPetLuckRoll = "Drew Pet Luck: %s [%s]!",
        NotifyPetLuckBurst = "Rolled %d Season 2 pet(s)!",
        NotifyNotEnoughCoins = "Not enough SS2 Coins! Need at least 400 coins per roll.",

        AutoCollectOresTitle = "Auto Collect Ores",
        AutoCollectOresDesc = "Automatically triggers proximity prompts and vacuums every ore across the map",
        AutoSmartPackTitle = "Auto Forge 10 Ores When Full",
        AutoSmartPackDesc = "Automatically crafts equipment using 10 ores whenever the 24-slot pack fills up",
        BtnCollectOresTitle = "Collect All Ground Ores",
        BtnCollectOresDesc = "Collects all dropped ores currently on the map",

        AutoStage27Title = "Auto Stage 27 Raid Loop",
        AutoStage27Desc = "Warps to Stage 27, kills all mobs, collects drops, clicks Back, and waits 5s cooldown",
        BtnStage27Title = "Run Stage 27 Sweep Once",
        BtnStage27Desc = "Run one full Stage 27 sweep cycle now",

        -- Forge Tab
        AutoForgeTitle = "Auto Forge (10 Ores)",
        AutoForgeDesc = "Continuously crafts items using 10 ores per batch",
        ForgeTypeTitle = "Craft Target Type",
        BtnMultiForgeTitle = "Instant Forge 5 Batches",
        BtnMultiForgeDesc = "Crafts 5 batches of equipment immediately",
        AutoEquipBestTitle = "Auto Equip Best Gear",
        AutoEquipBestDesc = "Automatically scans inventory and equips the highest stat equipment",
        BtnInstantEquipTitle = "Instant Equip Best Gear",
        BtnInstantEquipDesc = "Equips the strongest weapon, armor, and hat currently in your inventory",
        AutoSellAllTitle = "Auto Sell Non-Equipped Items",
        AutoSellAllDesc = "Periodically sells extra crafted items for coins",
        BtnSellAllTitle = "Instant Sell All Non-Equipped",
        BtnSellAllDesc = "Sells all unequipped gear in backpack for coins",
        ToggleAstralSetTitle = "Permanent Astral Genesis Set",
        ToggleAstralSetDesc = "Keeps Astral Genesis gear models and effects equipped on character",
        BtnEquipAstralTitle = "Spawn Astral Genesis Set Now",
        BtnEquipAstralDesc = "Attaches Astral Supernova Edge, Devourer Plate, and Sovereign Crown",

        -- Combat Tab
        AutoDungeonTitle = "Auto Clear Tower Floors 1-50",
        AutoDungeonDesc = "Enters Frozen Tower and instantly completes all 50 floors in one pass without climbing floor by floor",
        BtnInstantTowerTitle = "Instant Clear Tower 1-50 (1-Click)",
        BtnInstantTowerDesc = "Instantly clears all 50 floors in seconds, wipes mobs with 1e30, and vacuums all rewards",
        BtnEnterFloor50Title = "Enter Tower Floor 50 Directly",
        BtnEnterFloor50Desc = "Enters top floor 50 of Frozen Tower directly",
        BtnEnterDungeonTitle = "Enter Tower Floor 1",
        BtnExitDungeonTitle = "Exit Tower / Dungeon",

        WorldBossStatusTitle = "World Boss Status",
        AutoWorldBossTitle = "Auto World Boss (One-Shot & Claim)",
        AutoWorldBossDesc = "Automatically joins arena when World Boss spawns, one-shots with 1e30 damage, claims card reward, and returns",
        BtnJoinWorldBossTitle = "Join World Boss Arena",
        BtnJoinWorldBossDesc = "Teleports to World Boss arena and registers fight now",
        BtnExitWorldBossTitle = "Exit World Boss Arena",
        BtnExitWorldBossDesc = "Leaves World Boss arena and teleports back to spawn",

        AutoSkillsTitle = "Auto Spam Weapon Skills",
        AutoSkillsDesc = "Fires weapon skills constantly",
        ToggleAstralSkillTitle = "Auto Cast Astral Burst Domain",
        ToggleAstralSkillDesc = "Continuously activates Astral Burst Domain during combat",
        BtnCastAstralTitle = "Cast Astral Burst Domain Now",
        BtnCastAstralDesc = "Unleashes the cosmic dragon domain dealing continuous 1100% damage",
        AutoSuperLootTitle = "Auto Kill Mobs & SuperLoot",
        AutoSuperLootDesc = "Insta-kills any monsters and SuperLoot entities that spawn in the map",

        -- Rewards Tab
        AutoClaimAllTitle = "Auto Claim Daily & Online Gifts",
        AutoClaimAllDesc = "Continuously claims online gift rewards and index level-ups",
        AutoClaimIndexTitle = "Auto Claim Index Exp & Level",
        AutoClaimIndexDesc = "Continuously scans unlocked Weapon, Armor, Hat, and Ore index entries for Exp & Level rewards",
        BtnClaimIndexTitle = "Instant Claim All Index Rewards",
        BtnClaimIndexDesc = "Claims all pending unlocked weapons, armors, hats, and ores in Index",
        BtnInstantClaimIndexTitle = "Instant Claim All Index Rewards",
        BtnInstantClaimIndexDesc = "Claims all pending unlocked weapons, armors, hats, and ores in Index",
        BtnOnlineTitle = "Claim All Online Gifts (1 - 12)",
        BtnTicketTitle = "Claim Daily Dungeon Ticket",
        BtnGroupTitle = "Claim Group & Update Gifts",
        BtnCodesTitle = "Redeem All Active Promo Codes",

        -- Settings Tab
        LanguageTitle = "Language / เลือกภาษา",
        ProfileTitle = "Active Account Profile",
        ProfileContent = "Account: %s (%s)\nFolder: %s",
        AutoSaveTitle = "Per-Account Auto Save System",
        AutoSaveContent = "Auto Save is ACTIVE and isolated per account.\nSettings and autoload are saved specifically for %s.",
        AutoSaveToggleTitle = "Enable Auto Save",
        AutoSaveToggleDesc = "Automatically writes configuration to file whenever any toggle is clicked",
        BtnForceSaveTitle = "Force Save Settings Now",
        BtnForceSaveDesc = "Immediately writes current setup to disk",
        AntiAFKTitle = "Anti-AFK Protection",
        AntiAFKDesc = "Disables Roblox 20-minute idle kicks and pulses anti-afk input",
        WindowScaleTitle = "Window UI Scale (Zoom)",
        WindowScaleDesc = "Adjust overall UI scale percentage (60% - 125%)",
        WindowPresetTitle = "Window Size Preset",
        BtnResetWindowSizeTitle = "Reset Window Size & Scale",
        BtnResetWindowSizeDesc = "Restore window dimensions and zoom back to default",
        NotifyWindowReset = "Window size & scale restored to default!",

        NotifyLoaded = "Config loaded for %s! Tap STREET HUB or press Right-Control to toggle.",
        NotifyLangChanged = "Language switched to English!",
        NotifyWarpTrain = "Teleported to Train Area %s",
        NotifyUpgraded = "All upgrades maxed out!",
        NotifyEquipped = "Equipped %d stronger gear item(s)!",
        NotifyAlreadyBest = "Already wearing the best available gear!",
        NotifyForged5x = "Successfully forged 5 items!",
        NotifySold = "All non-equipped items sold for coins!",
        NotifyIndexClaimed = "Claimed %d Index rewards & levels!",
        NotifyOnlineClaimed = "All online play-time gifts claimed!",
        NotifyTicketClaimed = "Daily dungeon ticket claimed!",
        NotifyGroupClaimed = "Group & update rewards claimed!",
        NotifyCodesRedeemed = "All active codes redeemed!",
        NotifySaved = "Configuration saved to disk!",
    },
    TH = {
        TabBypass = "🔥 Bypass",
        TabFarm = "ฟาร์ม",
        TabForge = "หลอมอุปกรณ์",
        TabCombat = "ต่อสู้/ดันเจี้ยน",
        TabRewards = "รับรางวัล",
        TabSettings = "ตั้งค่า",

        -- Section Headers
        SecBypassCore = "ระบบหลัก",
        SecBypassMovement = "การเคลื่อนที่ & มุมมอง",
        SecBypassActions = "คำสั่งด่วน",

        SecFarmStats = "ข้อมูลผู้เล่น",
        SecFarmTrain = "ฝึกพลัง & รีเบิร์ธ",
        SecFarmSeason = "ซีซั่น 2 & สัตว์เลี้ยง",
        SecFarmOres = "แร่ & กระเป๋า",
        SecFarmRaid = "ดันเจี้ยน Stage 27",

        SecForgeCraft = "หลอมอุปกรณ์",
        SecForgeGear = "จัดการอุปกรณ์",
        SecForgeAstral = "เซ็ตเทพ Astral Genesis",

        SecCombatTower = "หอคอยเยือกแข็ง (ชั้น 1-50)",
        SecCombatBoss = "บอสโลก",
        SecCombatSkills = "สกิล & การโจมตี",

        SecRewardsAuto = "รับรางวัลอัตโนมัติ",
        SecRewardsInstant = "กดรับของรางวัลทันที",

        SecSettingsProfile = "ภาษา & ข้อมูลบัญชี",
        SecSettingsSave = "ระบบบันทึก & กันหลุด",
        SecSettingsWindow = "ปรับแต่งหน้าต่าง",
        SecSettingsConfig = "จัดการการตั้งค่า (Config)",

        -- Bypass Tab
        BypassInfoTitle = "ระบบ Master Bypass ขั้นสุดยอด",
        BypassInfoContent = "ปลดล็อก GamePass ทุกอย่างฟรี, วันช็อตมอนทั้งแมพดาเมจ 1e30, เลือดอมตะ 100%, และคูณดวง/ดาเมจ/เหรียญมหาศาล",
        UnlockGamePassesTitle = "ปลดล็อก GamePass & VIP ทั้งหมด",
        UnlockGamePassesDesc = "ปลดล็อก VIP, SuperLuck, UltraLuck, CommonLuck, MoreOre, SkipForge, AutoCollectOre, 2xDamage, SeasonVIP และแท่นฝึก VIP 9-11 ฟรีไม่ต้องเติม Robux",
        OmniKillAuraTitle = "ออร่าวันช็อตมอนทั้งแมพ (1e30)",
        OmniKillAuraDesc = "กำจัดมอนสเตอร์ บอส และ SuperLoot ทุกตัวในแมพทันทีด้วยดาเมจ 1e30",
        GodModeTitle = "โหมดอมตะ (ไม่ลดเลือด)",
        GodModeDesc = "ล็อกเลือดเต็ม 100% ตลอดเวลา ป้องกันการโดนมอนสเตอร์หรือบอสตีตาย",
        InsaneStatsTitle = "ตัวคูณสเตตัสระดับเทพ (+5000%)",
        InsaneStatsDesc = "Hook สูตรคำนวณของเกม เพิ่มค่า Luck, Damage, Coins และ Ore Drop อัตราสูงพิเศษ",
        SpeedHackTitle = "เร่งความเร็วเดิน",
        SpeedHackDesc = "บังคับความเร็วเดินของตัวละคร (16 - 150)",
        WalkSpeedSliderTitle = "ความเร็วเดิน (WalkSpeed)",
        JumpHackTitle = "เปิดใช้งานกระโดดสูง",
        JumpHackDesc = "บังคับความสูงในการกระโดด (50 - 200)",
        JumpPowerSliderTitle = "แรงกระโดด (JumpPower)",
        NoclipTitle = "เดินทะลุกำแพง (Noclip)",
        NoclipDesc = "ปิดระบบชนของตัวละคร ทำให้เดินทะลุกำแพง สิ่งกีดขวาง และประตูได้อิสระ",
        InfiniteJumpTitle = "กระโดดกลางอากาศไม่จำกัด",
        InfiniteJumpDesc = "กระโดดได้ต่อเนื่องบนอากาศโดยไม่ต้องแตะพื้น",
        DisableBlurTitle = "ปิดภาพเบลอหน้าจอ (Clear Screen)",
        DisableBlurDesc = "ปิดเอฟเฟกต์เบลอ TrainDOF และ Depth of Field ถาวร หน้าจอชัดใส 100%",
        BtnNukeAllTitle = "ล้างบางมอนสเตอร์ทั้งแมพทันที",
        BtnNukeAllDesc = "ส่งดาเมจ 1e30 ใส่มอนสเตอร์ทุกตัวที่อยู่ในแมพตอนนี้ในพริบตา",
        BtnVacuumOresTitle = "ดูดแร่ทั่วทั้งแมพเข้าตัวทันที",
        BtnVacuumOresDesc = "เก็บแร่และหินอัปเกรดทั้งหมดที่ตกอยู่ในแมพเข้าตัวทันที",

        -- Farm Tab
        StatTitle = "ข้อมูลสถิติผู้เล่นเรียลไทม์",
        AutoTrainTitle = "เทรนพลังอัตโนมัติ (แท่นสูงสุด)",
        AutoTrainDesc = "วาปไปยังจุดเทรนที่ดีที่สุดที่ปลดล็อกแล้ว และเริ่มเทรนที่ตัวคูณสูงสุดทันที",
        Force100xTrainTitle = "ล็อกแท่นเทรน VIP 100x",
        Force100xTrainDesc = "ปลดล็อกตัวคูณพลัง x100 เท่าของโซน VIP ตลอดเวลาโดยไม่ต้องซื้อเกมพาส",
        AutoRebirthTitle = "รีเบิร์ธอัตโนมัติต่อเนื่อง",
        AutoRebirthDesc = "กดจุติทันทีเมื่อเลเวลถึงเกณฑ์กำหนดเพื่อเพิ่มตัวคูณพลัง",
        BtnWarpTrainTitle = "วาปไปยังจุดเทรนที่ดีที่สุด",
        BtnWarpTrainDesc = "วาปตัวละครไปยังแท่นเทรนพลังที่มีตัวคูณสูงสุดที่ปลดล็อกแล้ว",
        BtnMaxUpgradesTitle = "อัปเกรดสกิลติดตัวเต็มทุกสาย",
        BtnMaxUpgradesDesc = "อัปเกรดพลังเทรน ค่าดวง และความจุกระเป๋าแร่ขึ้นเลเวลสูงสุด",

        AutoFarmSS2Title = "ปั้มเหรียญ SS2 อัตโนมัติ (หอคอย 50)",
        AutoFarmSS2Desc = "ยิงรอบดันเจี้ยนชั้น 50 ต่อเนื่อง ปั้มเหรียญซีซั่น 2 รัวๆ พร้อมหินออฟและแร่",
        BtnFarmSS2Title = "ปั้มเหรียญ SS2 ทันที (100 รอบ)",
        BtnFarmSS2Desc = "ยิงรอบดันเจี้ยนชั้น 50 รวดเดียว 100 รอบในพริบตา",
        NotifySS2Farmed = "ปั้มเหรียญ SS2 สำเร็จ %d รอบ (+%s เหรียญ)!",
        AutoPetLuckTitle = "สุ่ม Pet Luck อัตโนมัติ",
        AutoPetLuckDesc = "สุ่มสัตว์เลี้ยงซีซั่น 2 อัตโนมัติทันทีที่เหรียญ SS2 พอ (ครั้งละ 400 เหรียญ) บายพาสแอนิเมชัน ไม่ต้องเปิดหน้าต่างเกม",
        BtnRollPetLuckTitle = "สุ่ม Pet Luck ทันที (10 ตัว)",
        BtnRollPetLuckDesc = "กดสุ่มสัตว์เลี้ยง Season 2 รวดเดียว 10 ตัวทันที (ใช้ 4,000 เหรียญ SS2)",
        NotifyPetLuckRoll = "สุ่มได้สัตว์เลี้ยง %s [%s]!",
        NotifyPetLuckBurst = "สุ่มสัตว์เลี้ยง Season 2 สำเร็จ %d ตัว!",
        NotifyNotEnoughCoins = "เหรียญ SS2 ไม่พอ! ต้องการอย่างน้อย 400 เหรียญต่อการสุ่ม 1 ครั้ง",

        AutoCollectOresTitle = "เก็บแร่อัตโนมัติ (ทั่วทั้งแมพ)",
        AutoCollectOresDesc = "เก็บแร่และกด Proximity Prompt ดึงแร่ทั่วทั้งแมพเข้าตัวอัตโนมัติ",
        AutoSmartPackTitle = "หลอมแร่อัตโนมัติเมื่อกระเป๋าเต็ม",
        AutoSmartPackDesc = "เมื่อกระเป๋าแร่เต็ม 24 ช่อง จะนำแร่ 10 ก้อนไปหลอมเป็นอุปกรณ์เพื่อเคลียร์พื้นที่",
        BtnCollectOresTitle = "ดูดแร่บนพื้นทั้งหมดทันที",
        BtnCollectOresDesc = "เก็บแร่ทุกชิ้นที่ตกอยู่บนพื้นทั่วแมพในครั้งเดียว",

        AutoStage27Title = "ฟาร์มดันเจี้ยน Stage 27 ต่อเนื่อง",
        AutoStage27Desc = "วาปไปด่าน 27 ฆ่ามอนทั้งหมด ดูดแร่ กดปุ่ม Back แล้วรอคูลดาวน์ 5 วินาที",
        BtnStage27Title = "ลงฟาร์ม Stage 27 ทันที 1 รอบ",
        BtnStage27Desc = "สั่งลูปด่าน 27 ทำงานทันที 1 รอบ",

        -- Forge Tab
        AutoForgeTitle = "หลอมอุปกรณ์อัตโนมัติ (ชุดละ 10 ก้อน)",
        AutoForgeDesc = "คราฟต์อุปกรณ์ต่อเนื่องโดยใช้แร่ชุดละ 10 ก้อน",
        ForgeTypeTitle = "ประเภทอุปกรณ์ที่ต้องการหลอม",
        BtnMultiForgeTitle = "หลอมอุปกรณ์รวดเดียว 5 ชุด",
        BtnMultiForgeDesc = "คราฟต์อุปกรณ์ทันที 5 ชุดต่อเนื่อง",
        AutoEquipBestTitle = "สวมใส่อุปกรณ์ที่ดีที่สุดอัตโนมัติ",
        AutoEquipBestDesc = "สแกนกระเป๋าและสวมใส่อาวุธ เกราะ หมวก ที่มีพลังสูงสุดเสมอ",
        BtnInstantEquipTitle = "สวมใส่อุปกรณ์ที่ดีที่สุดทันที",
        BtnInstantEquipDesc = "สแกนและเปลี่ยนใส่อาวุธ ชุดเกราะ และหมวกที่เก่งที่สุดในตัวทันที",
        AutoSellAllTitle = "ขายอุปกรณ์ที่ไม่ได้ใส่อัตโนมัติ",
        AutoSellAllDesc = "ขายอุปกรณ์ที่ไม่ได้สวมใส่ในกระเป๋าเป็นเหรียญทองเป็นระยะ",
        BtnSellAllTitle = "ขายอุปกรณ์ที่ไม่ได้ใส่ทั้งหมดทันที",
        BtnSellAllDesc = "ขายอุปกรณ์ทั้งหมดที่ไม่ได้สวมใส่เพื่อรับเหรียญทองทันที",
        ToggleAstralSetTitle = "สวมใส่เซ็ต Astral Genesis ถาวร",
        ToggleAstralSetDesc = "ล็อกโมเดลและเอฟเฟกต์เซ็ต Astral Genesis ติดตัวละครตลอดเวลา",
        BtnEquipAstralTitle = "เสกเซ็ต Astral Genesis ทันที",
        BtnEquipAstralDesc = "ติดตั้งดาบยักษ์ Astral Supernova, เกราะ Devourer, และมงกุฎ Sovereign",

        -- Combat Tab
        AutoDungeonTitle = "เคลียร์หอคอย 1-50 อัตโนมัติ",
        AutoDungeonDesc = "เข้าสู่หอคอย Frozen Tower และกวาดล้างรวดเดียวตั้งแต่ชั้น 1 ถึง 50 ทันที",
        BtnInstantTowerTitle = "เคลียร์หอคอยชั้น 1-50 ทันที (1-Click)",
        BtnInstantTowerDesc = "สังหารมอนสเตอร์ด้วย 1e30 เคลียร์รวดเดียว 50 ชั้นในไม่กี่วินาที พร้อมดูดของรางวัลทั้งหมดเข้าตัว",
        BtnEnterFloor50Title = "เข้าสู่หอคอยชั้น 50 โดยตรง",
        BtnEnterFloor50Desc = "เข้าสู่ชั้นสูงสุด (ชั้น 50) ของหอคอยทันที",
        BtnEnterDungeonTitle = "เข้าสู่หอคอยชั้นที่ 1",
        BtnExitDungeonTitle = "ออกจากหอคอย / ดันเจี้ยน",

        WorldBossStatusTitle = "สถานะบอสโลก",
        AutoWorldBossTitle = "ตีบอสโลกอัตโนมัติ (วันช็อต & รับของ)",
        AutoWorldBossDesc = "วาปเข้าห้องบอสโลกอัตโนมัติเมื่อเกิด วันช็อตด้วยดาเมจ 1e30 สุ่มเลือกการ์ดรางวัล และวาปกลับมาฟาร์มต่อ",
        BtnJoinWorldBossTitle = "เข้าห้องบอสโลกทันที",
        BtnJoinWorldBossDesc = "วาปเข้าสู่สนามประลองบอสโลกและลงทะเบียนต่อสู้ทันที",
        BtnExitWorldBossTitle = "ออกจากห้องบอสโลก",
        BtnExitWorldBossDesc = "ออกจากสนามประลองบอสโลกและวาปกลับจุดเกิดทันที",

        AutoSkillsTitle = "กดสกิลอาวุธอัตโนมัติต่อเนื่อง",
        AutoSkillsDesc = "ใช้สกิลของอาวุธที่ติดตั้งอยู่ตลอดเวลา",
        ToggleAstralSkillTitle = "ปล่อยสกิล Astral Burst Domain อัตโนมัติ",
        ToggleAstralSkillDesc = "ปล่อยสกิล Astral Burst Domain ต่อเนื่องอัตโนมัติในการต่อสู้",
        BtnCastAstralTitle = "ปล่อยสกิล Astral Burst Domain ทันที",
        BtnCastAstralDesc = "ปล่อยสกิลมังกร 3 หัวสร้างโดเมนดวงดาวโจมตีต่อเนื่อง 1100% รอบตัว",
        AutoSuperLootTitle = "ฆ่ามอนสเตอร์ & SuperLoot ทันที",
        AutoSuperLootDesc = "โจมตีปลิดชีพมอนสเตอร์และกล่อง SuperLoot ทั่วทั้งแมพทันทีที่เกิด",

        -- Rewards Tab
        AutoClaimAllTitle = "รับของขวัญประจำวันและออนไลน์อัตโนมัติ",
        AutoClaimAllDesc = "กดรับของขวัญออนไลน์ ตั๋วดันเจี้ยน และรางวัลล็อกอินต่อเนื่อง",
        AutoClaimIndexTitle = "รับรางวัล Index (Exp & Level) อัตโนมัติ",
        AutoClaimIndexDesc = "สแกน Index ดาบ เกราะ หมวก แร่ ที่ปลดล็อกแล้วและกดรับ Exp พร้อมรางวัลเลเวล",
        BtnClaimIndexTitle = "รับรางวัล Index ทั้งหมดทันที",
        BtnClaimIndexDesc = "กดรับ Exp และรางวัล Index ทั้งหมดที่ยังค้างอยู่ในคลิกเดียว",
        BtnInstantClaimIndexTitle = "รับรางวัล Index ทั้งหมดทันที",
        BtnInstantClaimIndexDesc = "กดรับ Exp และรางวัล Index ทั้งหมดที่ยังค้างอยู่ในคลิกเดียว",
        BtnOnlineTitle = "รับของขวัญออนไลน์ทั้งหมด (1 - 12)",
        BtnTicketTitle = "รับตั๋วดันเจี้ยนประจำวัน",
        BtnGroupTitle = "รับของขวัญกลุ่ม & รางวัลอัปเดต",
        BtnCodesTitle = "ใส่โค้ดรับของรางวัลทั้งหมด",

        -- Settings Tab
        LanguageTitle = "เลือกภาษา / Language",
        ProfileTitle = "ข้อมูลบัญชีผู้ใช้",
        ProfileContent = "บัญชี: %s (%s)\nโฟลเดอร์: %s",
        AutoSaveTitle = "ระบบบันทึกอัตโนมัติแยกบัญชี",
        AutoSaveContent = "ระบบ Auto Save ทำงานปกติและแยกโปรไฟล์ตามไอดี\nการตั้งค่าจะถูกบันทึกให้ %s โดยเฉพาะ",
        AutoSaveToggleTitle = "เปิดใช้งาน Auto Save",
        AutoSaveToggleDesc = "บันทึกการตั้งค่าลงไฟล์ของบัญชีนี้อัตโนมัติทุกครั้งที่มีการเปลี่ยนตัวเลือก",
        BtnForceSaveTitle = "บันทึกการตั้งค่าทันที",
        BtnForceSaveDesc = "เขียนข้อมูลการตั้งค่าปัจจุบันลงไฟล์ดิสก์ทันที",
        AntiAFKTitle = "ระบบกันหลุด Anti-AFK",
        AntiAFKDesc = "ปิดระบบเตะ 20 นาทีของ Roblox และส่งสัญญาณรีเซ็ตเวลาอัตโนมัติ",
        WindowScaleTitle = "สเกลขนาดหน้าต่าง (Zoom UI)",
        WindowScaleDesc = "ปรับย่อ-ขยายขนาดหน้าต่างและเมนูทั้งหมด (60% - 125%)",
        WindowPresetTitle = "ขนาดหน้าต่างสำเร็จรูป",
        BtnResetWindowSizeTitle = "รีเซ็ตขนาดหน้าต่างและสเกล",
        BtnResetWindowSizeDesc = "คืนค่าขนาดหน้าต่างและระยะซูมกลับเป็นค่าเริ่มต้น",
        NotifyWindowReset = "รีเซ็ตขนาดหน้าต่างและสเกลเป็นค่าเริ่มต้นเรียบร้อย!",

        NotifyLoaded = "โหลดการตั้งค่าของ %s สำเร็จ! แตะปุ่ม STREET HUB หรือกด Right-Control เพื่อเปิด/ปิด",
        NotifyLangChanged = "เปลี่ยนภาษาเป็น ภาษาไทย เรียบร้อยแล้ว!",
        NotifyWarpTrain = "วาปไปยังจุดเทรนที่ %s เรียบร้อย",
        NotifyUpgraded = "อัปเกรดความสามารถเต็มทุกสายแล้ว!",
        NotifyEquipped = "เปลี่ยนใส่อุปกรณ์ที่ดีกว่า %d ชิ้นเรียบร้อย!",
        NotifyAlreadyBest = "คุณกำลังสวมใส่อุปกรณ์ที่ดีที่สุดอยู่แล้ว!",
        NotifyForged5x = "หลอมอุปกรณ์ 5 ชิ้นเสร็จสิ้น!",
        NotifySold = "ขายอุปกรณ์ที่ไม่ได้สวมใส่ทั้งหมดแล้ว!",
        NotifyIndexClaimed = "รับรางวัล Index สำเร็จ %d รายการ!",
        NotifyOnlineClaimed = "กดรับของขวัญออนไลน์ทั้งหมดเรียบร้อย!",
        NotifyTicketClaimed = "รับตั๋วดันเจี้ยนประจำวันเรียบร้อย!",
        NotifyGroupClaimed = "รับรางวัลกลุ่มและรางวัลอัปเดตเรียบร้อย!",
        NotifyCodesRedeemed = "ใส่โค้ดรับของรางวัลทั้งหมดเรียบร้อย!",
        NotifySaved = "บันทึกการตั้งค่าลงดิสก์เรียบร้อย!",
    }
}

local function UpdateLanguage(lang)
    lang = (lang == "TH" or lang == "ไทย (Thai)") and "TH" or "EN"
    State.Language = lang
    local t = I18N[lang] or I18N.TH

    -- Update Tab Titles in sidebar
    local tabNameMap = {
        Bypass = t.TabBypass,
        Farm = t.TabFarm,
        Forge = t.TabForge,
        Combat = t.TabCombat,
        Rewards = t.TabRewards,
        Settings = t.TabSettings,
    }
    for tabKey, tabObj in pairs(Tabs) do
        if tabObj and tabNameMap[tabKey] then
            tabObj.Title = tabNameMap[tabKey]
            if tabObj.Frame then
                for _, desc in ipairs(tabObj.Frame:GetDescendants()) do
                    if desc:IsA("TextLabel") then
                        desc.Text = tabNameMap[tabKey]
                    end
                end
            end
            if tabObj.Selected and Window and Window.TabDisplay then
                Window.TabDisplay.Text = tabNameMap[tabKey]
            end
        end
    end

    -- Update Elements
    local E = UIElements

    -- Sections
    if E.SecBypassCore then E.SecBypassCore:SetTitle(t.SecBypassCore) end
    if E.SecBypassMovement then E.SecBypassMovement:SetTitle(t.SecBypassMovement) end
    if E.SecBypassActions then E.SecBypassActions:SetTitle(t.SecBypassActions) end

    if E.SecFarmStats then E.SecFarmStats:SetTitle(t.SecFarmStats) end
    if E.SecFarmTrain then E.SecFarmTrain:SetTitle(t.SecFarmTrain) end
    if E.SecFarmSeason then E.SecFarmSeason:SetTitle(t.SecFarmSeason) end
    if E.SecFarmOres then E.SecFarmOres:SetTitle(t.SecFarmOres) end
    if E.SecFarmRaid then E.SecFarmRaid:SetTitle(t.SecFarmRaid) end

    if E.SecForgeCraft then E.SecForgeCraft:SetTitle(t.SecForgeCraft) end
    if E.SecForgeGear then E.SecForgeGear:SetTitle(t.SecForgeGear) end
    if E.SecForgeAstral then E.SecForgeAstral:SetTitle(t.SecForgeAstral) end

    if E.SecCombatTower then E.SecCombatTower:SetTitle(t.SecCombatTower) end
    if E.SecCombatBoss then E.SecCombatBoss:SetTitle(t.SecCombatBoss) end
    if E.SecCombatSkills then E.SecCombatSkills:SetTitle(t.SecCombatSkills) end

    if E.SecRewardsAuto then E.SecRewardsAuto:SetTitle(t.SecRewardsAuto) end
    if E.SecRewardsInstant then E.SecRewardsInstant:SetTitle(t.SecRewardsInstant) end

    if E.SecSettingsProfile then E.SecSettingsProfile:SetTitle(t.SecSettingsProfile) end
    if E.SecSettingsSave then E.SecSettingsSave:SetTitle(t.SecSettingsSave) end
    if E.SecSettingsWindow then E.SecSettingsWindow:SetTitle(t.SecSettingsWindow) end
    if E.SecSettingsConfig then E.SecSettingsConfig:SetTitle(t.SecSettingsConfig) end

    -- Bypass Tab
    if E.BypassParagraph then E.BypassParagraph:SetTitle(t.BypassInfoTitle) E.BypassParagraph:SetDesc(t.BypassInfoContent) end
    if E.ToggleUnlockAllGamePasses then E.ToggleUnlockAllGamePasses:SetTitle(t.UnlockGamePassesTitle) E.ToggleUnlockAllGamePasses:SetDesc(t.UnlockGamePassesDesc) end
    if E.ToggleOmniKillAura then E.ToggleOmniKillAura:SetTitle(t.OmniKillAuraTitle) E.ToggleOmniKillAura:SetDesc(t.OmniKillAuraDesc) end
    if E.ToggleGodMode then E.ToggleGodMode:SetTitle(t.GodModeTitle) E.ToggleGodMode:SetDesc(t.GodModeDesc) end
    if E.ToggleInsaneStatBoost then E.ToggleInsaneStatBoost:SetTitle(t.InsaneStatsTitle) E.ToggleInsaneStatBoost:SetDesc(t.InsaneStatsDesc) end
    if E.ToggleSpeedHack then E.ToggleSpeedHack:SetTitle(t.SpeedHackTitle) E.ToggleSpeedHack:SetDesc(t.SpeedHackDesc) end
    if E.SliderWalkSpeed then E.SliderWalkSpeed:SetTitle(t.WalkSpeedSliderTitle) end
    if E.ToggleJumpPowerHack then E.ToggleJumpPowerHack:SetTitle(t.JumpHackTitle) E.ToggleJumpPowerHack:SetDesc(t.JumpHackDesc) end
    if E.SliderJumpPower then E.SliderJumpPower:SetTitle(t.JumpPowerSliderTitle) end
    if E.ToggleNoclip then E.ToggleNoclip:SetTitle(t.NoclipTitle) E.ToggleNoclip:SetDesc(t.NoclipDesc) end
    if E.ToggleInfiniteJump then E.ToggleInfiniteJump:SetTitle(t.InfiniteJumpTitle) E.ToggleInfiniteJump:SetDesc(t.InfiniteJumpDesc) end
    if E.ToggleDisableBlur then E.ToggleDisableBlur:SetTitle(t.DisableBlurTitle) E.ToggleDisableBlur:SetDesc(t.DisableBlurDesc) end
    if E.BtnNukeAllMobs then E.BtnNukeAllMobs:SetTitle(t.BtnNukeAllTitle) E.BtnNukeAllMobs:SetDesc(t.BtnNukeAllDesc) end
    if E.BtnVacuumOres then E.BtnVacuumOres:SetTitle(t.BtnVacuumOresTitle) E.BtnVacuumOres:SetDesc(t.BtnVacuumOresDesc) end

    -- Farm Tab
    if E.StatParagraph then E.StatParagraph:SetTitle(t.StatTitle) end
    if E.ToggleAutoTrain then E.ToggleAutoTrain:SetTitle(t.AutoTrainTitle) E.ToggleAutoTrain:SetDesc(t.AutoTrainDesc) end
    if E.ToggleForce100xTrain then E.ToggleForce100xTrain:SetTitle(t.Force100xTrainTitle) E.ToggleForce100xTrain:SetDesc(t.Force100xTrainDesc) end
    if E.ToggleAutoRebirth then E.ToggleAutoRebirth:SetTitle(t.AutoRebirthTitle) E.ToggleAutoRebirth:SetDesc(t.AutoRebirthDesc) end
    if E.BtnTeleportBestTrain then E.BtnTeleportBestTrain:SetTitle(t.BtnWarpTrainTitle) E.BtnTeleportBestTrain:SetDesc(t.BtnWarpTrainDesc) end
    if E.BtnMaxUpgradePassives then E.BtnMaxUpgradePassives:SetTitle(t.BtnMaxUpgradesTitle) E.BtnMaxUpgradePassives:SetDesc(t.BtnMaxUpgradesDesc) end

    if E.ToggleAutoFarmSeason2Coins then E.ToggleAutoFarmSeason2Coins:SetTitle(t.AutoFarmSS2Title) E.ToggleAutoFarmSeason2Coins:SetDesc(t.AutoFarmSS2Desc) end
    if E.BtnInstantFarmSS2Coins then E.BtnInstantFarmSS2Coins:SetTitle(t.BtnFarmSS2Title) E.BtnInstantFarmSS2Coins:SetDesc(t.BtnFarmSS2Desc) end
    if E.ToggleAutoPetLuck then E.ToggleAutoPetLuck:SetTitle(t.AutoPetLuckTitle) E.ToggleAutoPetLuck:SetDesc(t.AutoPetLuckDesc) end
    if E.BtnRollPetLuck10x then E.BtnRollPetLuck10x:SetTitle(t.BtnRollPetLuckTitle) E.BtnRollPetLuck10x:SetDesc(t.BtnRollPetLuckDesc) end

    if E.ToggleAutoCollectOres then E.ToggleAutoCollectOres:SetTitle(t.AutoCollectOresTitle) E.ToggleAutoCollectOres:SetDesc(t.AutoCollectOresDesc) end
    if E.ToggleSmartPack then E.ToggleSmartPack:SetTitle(t.AutoSmartPackTitle) E.ToggleSmartPack:SetDesc(t.AutoSmartPackDesc) end
    if E.BtnCollectAllOres then E.BtnCollectAllOres:SetTitle(t.BtnCollectOresTitle) E.BtnCollectAllOres:SetDesc(t.BtnCollectOresDesc) end

    if E.ToggleStage27Raid then E.ToggleStage27Raid:SetTitle(t.AutoStage27Title) E.ToggleStage27Raid:SetDesc(t.AutoStage27Desc) end
    if E.BtnStage27Once then E.BtnStage27Once:SetTitle(t.BtnStage27Title) E.BtnStage27Once:SetDesc(t.BtnStage27Desc) end

    -- Forge Tab
    if E.ToggleAutoForge then E.ToggleAutoForge:SetTitle(t.AutoForgeTitle) E.ToggleAutoForge:SetDesc(t.AutoForgeDesc) end
    if E.DropdownForgeType then E.DropdownForgeType:SetTitle(t.ForgeTypeTitle) end
    if E.BtnInstantMultiForge then E.BtnInstantMultiForge:SetTitle(t.BtnMultiForgeTitle) E.BtnInstantMultiForge:SetDesc(t.BtnMultiForgeDesc) end
    if E.ToggleAutoEquipBest then E.ToggleAutoEquipBest:SetTitle(t.AutoEquipBestTitle) E.ToggleAutoEquipBest:SetDesc(t.AutoEquipBestDesc) end
    if E.BtnInstantEquipBest then E.BtnInstantEquipBest:SetTitle(t.BtnInstantEquipTitle) E.BtnInstantEquipBest:SetDesc(t.BtnInstantEquipDesc) end
    if E.ToggleAutoSellAll then E.ToggleAutoSellAll:SetTitle(t.AutoSellAllTitle) E.ToggleAutoSellAll:SetDesc(t.AutoSellAllDesc) end
    if E.BtnInstantSellAll then E.BtnInstantSellAll:SetTitle(t.BtnSellAllTitle) E.BtnInstantSellAll:SetDesc(t.BtnSellAllDesc) end
    if E.ToggleAstralSet then E.ToggleAstralSet:SetTitle(t.ToggleAstralSetTitle) E.ToggleAstralSet:SetDesc(t.ToggleAstralSetDesc) end
    if E.BtnEquipAstralSet then E.BtnEquipAstralSet:SetTitle(t.BtnEquipAstralTitle) E.BtnEquipAstralSet:SetDesc(t.BtnEquipAstralDesc) end

    -- Combat Tab
    if E.ToggleDungeonSweep then E.ToggleDungeonSweep:SetTitle(t.AutoDungeonTitle) E.ToggleDungeonSweep:SetDesc(t.AutoDungeonDesc) end
    if E.BtnInstantTower then E.BtnInstantTower:SetTitle(t.BtnInstantTowerTitle) E.BtnInstantTower:SetDesc(t.BtnInstantTowerDesc) end
    if E.BtnEnterFloor50 then E.BtnEnterFloor50:SetTitle(t.BtnEnterFloor50Title) E.BtnEnterFloor50:SetDesc(t.BtnEnterFloor50Desc) end
    if E.BtnEnterDungeon then E.BtnEnterDungeon:SetTitle(t.BtnEnterDungeonTitle) end
    if E.BtnExitDungeon then E.BtnExitDungeon:SetTitle(t.BtnExitDungeonTitle) end
    if E.WorldBossParagraph then E.WorldBossParagraph:SetTitle(t.WorldBossStatusTitle) end
    if E.ToggleAutoWorldBoss then E.ToggleAutoWorldBoss:SetTitle(t.AutoWorldBossTitle) E.ToggleAutoWorldBoss:SetDesc(t.AutoWorldBossDesc) end
    if E.BtnJoinWorldBoss then E.BtnJoinWorldBoss:SetTitle(t.BtnJoinWorldBossTitle) E.BtnJoinWorldBoss:SetDesc(t.BtnJoinWorldBossDesc) end
    if E.BtnExitWorldBoss then E.BtnExitWorldBoss:SetTitle(t.BtnExitWorldBossTitle) E.BtnExitWorldBoss:SetDesc(t.BtnExitWorldBossDesc) end
    if E.ToggleSkills then E.ToggleSkills:SetTitle(t.AutoSkillsTitle) E.ToggleSkills:SetDesc(t.AutoSkillsDesc) end
    if E.ToggleAstralSkill then E.ToggleAstralSkill:SetTitle(t.ToggleAstralSkillTitle) E.ToggleAstralSkill:SetDesc(t.ToggleAstralSkillDesc) end
    if E.BtnCastAstralSkill then E.BtnCastAstralSkill:SetTitle(t.BtnCastAstralTitle) E.BtnCastAstralSkill:SetDesc(t.BtnCastAstralDesc) end
    if E.ToggleKillSuperLoot then E.ToggleKillSuperLoot:SetTitle(t.AutoSuperLootTitle) E.ToggleKillSuperLoot:SetDesc(t.AutoSuperLootDesc) end

    -- Rewards Tab
    if E.ToggleAutoClaimAll then E.ToggleAutoClaimAll:SetTitle(t.AutoClaimAllTitle) E.ToggleAutoClaimAll:SetDesc(t.AutoClaimAllDesc) end
    if E.ToggleAutoClaimIndex then E.ToggleAutoClaimIndex:SetTitle(t.AutoClaimIndexTitle) E.ToggleAutoClaimIndex:SetDesc(t.AutoClaimIndexDesc) end
    if E.BtnInstantClaimIndex then E.BtnInstantClaimIndex:SetTitle(t.BtnInstantClaimIndexTitle) E.BtnInstantClaimIndex:SetDesc(t.BtnInstantClaimIndexDesc) end
    if E.BtnClaimOnline then E.BtnClaimOnline:SetTitle(t.BtnOnlineTitle) end
    if E.BtnClaimTicket then E.BtnClaimTicket:SetTitle(t.BtnTicketTitle) end
    if E.BtnClaimGroup then E.BtnClaimGroup:SetTitle(t.BtnGroupTitle) end
    if E.BtnRedeemCodes then E.BtnRedeemCodes:SetTitle(t.BtnCodesTitle) end

    -- Settings Tab
    local accountFolderRef = "StreetHub/Enhance1LootToForge/accounts/" .. (string.gsub(LocalPlayer.Name, "[^%w_]", "") .. "_" .. tostring(LocalPlayer.UserId))
    if E.ProfileParagraph then
        E.ProfileParagraph:SetTitle(t.ProfileTitle)
        E.ProfileParagraph:SetDesc(string.format(t.ProfileContent, LocalPlayer.Name, tostring(LocalPlayer.UserId), accountFolderRef))
    end
    if E.AutoSaveParagraph then
        E.AutoSaveParagraph:SetTitle(t.AutoSaveTitle)
        E.AutoSaveParagraph:SetDesc(string.format(t.AutoSaveContent, LocalPlayer.Name))
    end
    if E.ToggleAutoSaveSetting then E.ToggleAutoSaveSetting:SetTitle(t.AutoSaveToggleTitle) E.ToggleAutoSaveSetting:SetDesc(t.AutoSaveToggleDesc) end
    if E.BtnForceSave then E.BtnForceSave:SetTitle(t.BtnForceSaveTitle) E.BtnForceSave:SetDesc(t.BtnForceSaveDesc) end
    if E.ToggleAntiAFK then E.ToggleAntiAFK:SetTitle(t.AntiAFKTitle) E.ToggleAntiAFK:SetDesc(t.AntiAFKDesc) end
    if E.DropdownLanguage then E.DropdownLanguage:SetTitle(t.LanguageTitle) end
    if E.SliderWindowScale then E.SliderWindowScale:SetTitle(t.WindowScaleTitle) E.SliderWindowScale:SetDesc(t.WindowScaleDesc) end
    if E.DropdownWindowPreset then E.DropdownWindowPreset:SetTitle(t.WindowPresetTitle) end
    if E.BtnResetWindowSize then E.BtnResetWindowSize:SetTitle(t.BtnResetWindowSizeTitle) E.BtnResetWindowSize:SetDesc(t.BtnResetWindowSizeDesc) end
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
local accountFolder = "StreetHub/Enhance1LootToForge/accounts/" .. accountKey
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
            UnlockAllGamePasses = State.UnlockAllGamePasses,
            OmniKillAura = State.OmniKillAura,
            GodMode = State.GodMode,
            InsaneStatBoost = State.InsaneStatBoost,
            SpeedHack = State.SpeedHack,
            WalkSpeedValue = State.WalkSpeedValue,
            JumpPowerHack = State.JumpPowerHack,
            JumpPowerValue = State.JumpPowerValue,
            Noclip = State.Noclip,
            InfiniteJump = State.InfiniteJump,
            DisableBlur = State.DisableBlur,

            AutoTrain = State.AutoTrain,
            Force100xTrain = State.Force100xTrain,
            AstralGenesisSet = State.AstralGenesisSet,
            AutoAstralSkill = State.AutoAstralSkill,
            AutoRebirth = State.AutoRebirth,
            AutoStage27Raid = State.AutoStage27Raid,
            AutoCollectOres = State.AutoCollectOres,
            AutoSmartFreePack = State.AutoSmartFreePack,
            AutoForge = State.AutoForge,
            ForgeType = State.ForgeType,
            AutoEquipBest = State.AutoEquipBest,
            AutoSellAll = State.AutoSellAll,
            AutoDungeonSweep = State.AutoDungeonSweep,
            AutoFarmSeason2Coins = State.AutoFarmSeason2Coins,
            AutoPetLuck = State.AutoPetLuck,
            AutoKillSuperLoot = State.AutoKillSuperLoot,
            AutoWorldBoss = State.AutoWorldBoss,
            AutoSkills = State.AutoSkills,
            AutoClaimAll = State.AutoClaimAll,
            AutoClaimIndex = State.AutoClaimIndex,
            AntiAFK = State.AntiAFK,
            Language = State.Language,
            WindowScale = State.WindowScale,
            WindowWidth = State.WindowWidth,
            WindowHeight = State.WindowHeight,
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
                if data.WindowScale then
                    State.WindowScale = tonumber(data.WindowScale)
                end
                if data.WindowWidth then
                    State.WindowWidth = tonumber(data.WindowWidth)
                end
                if data.WindowHeight then
                    State.WindowHeight = tonumber(data.WindowHeight)
                end
                for k, v in pairs(data) do
                    if Options[k] and Options[k].SetValue then
                        Options[k]:SetValue(v)
                    end
                end
                if Options.LanguageSetting then
                    Options.LanguageSetting:SetValue(State.Language == "EN" and "English" or "ไทย (Thai)")
                end
                if Options.WindowScaleSlider and State.WindowScale then
                    Options.WindowScaleSlider:SetValue(math.floor(State.WindowScale * 100))
                end
            end
        end
    end)
end

RequestAutoSave = function()
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
-- HELPER FUNCTIONS FOR COMBAT, DUNGEON, AND PETS
-- ========================================================================
local function RunInstantTower1To50Cycle()
    pcall(function()
        DungeonData.TryClaimDailyDunTic()
    end)
    task.wait(0.1)

    local res = DungeonData.TryIntoDungeon(1)
    if not res then return false, 0, 0 end

    local floorsCleared = 0
    local startTime = tick()

    for floor = 1, 50 do
        pcall(function()
            DungeonData.StartRound(floor)
        end)
        task.wait(0.03)
        pcall(function()
            DungeonData.CompleteRound(floor)
        end)
        floorsCleared = floor

        local folders = {
            workspace:FindFirstChild("EnemyFolder"),
            workspace:FindFirstChild("EnemyFolder_Server")
        }
        for _, folder in ipairs(folders) do
            if folder then
                for _, enemy in ipairs(folder:GetChildren()) do
                    if enemy and not enemy:GetAttribute("Dead") then
                        pcall(function()
                            if Remote:FindFirstChild("Attack") and Remote.Attack:FindFirstChild("EnemyHitBE") then
                                Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                                    Damage = 1e30,
                                    SkillID = "K_ATK_1",
                                    IsCrit = true
                                })
                            end
                            if AttackRemote and AttackRemote:FindFirstChild("KillEnemyRE") then
                                AttackRemote.KillEnemyRE:FireServer(enemy.Name)
                            end
                        end)
                    end
                end
            end
        end
        task.wait(0.03)
    end

    CollectAllWorldOres()
    task.wait(0.2)

    pcall(function()
        DungeonData.ExitDungeon()
    end)

    pcall(function()
        local info = LocalPlayer.PlayerGui:FindFirstChild("Info")
        if info then
            if info:FindFirstChild("DungeonResult") then info.DungeonResult.Visible = false end
            if info:FindFirstChild("RoundCompleted") then info.RoundCompleted.Visible = false end
        end
        local dGui = LocalPlayer.PlayerGui:FindFirstChild("Dungeon")
        if dGui then dGui.Enabled = false end
        local hud = LocalPlayer.PlayerGui:FindFirstChild("Hud")
        if hud then
            for _, p in ipairs({"Left", "LeftInfos", "RightTop", "Right", "Race"}) do
                if hud:FindFirstChild(p) then hud[p].Visible = true end
            end
        end
        local char = LocalPlayer.Character
        if char then
            local tu = require(ReplicatedStorage.Utils.TranslateUtils)
            tu.ToSpawn(char)
        end
        if State.AutoTrain then
            task.delay(0.3, function()
                WarpToBestTrainArea()
            end)
        end
    end)

    return true, floorsCleared, tick() - startTime
end

local function RunSeason2CoinsFarmBurst(targetRounds)
    targetRounds = targetRounds or 60
    local DS = DungeonRemote or (Remote and Remote:FindFirstChild("Dungeon_Server")) or (ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Dungeon_Server"))
    if not DS then return 0, 0 end

    pcall(function()
        if DS:FindFirstChild("TryClaimDailyDunTicRE") then
            DS.TryClaimDailyDunTicRE:FireServer()
        end
    end)
    task.wait(0.1)

    local entered = false
    pcall(function()
        if DS:FindFirstChild("TryIntoDungeonRF") then
            entered = DS.TryIntoDungeonRF:InvokeServer(true, 50)
        end
    end)
    if not entered then return 0, 0 end

    local rounds = 0
    local gainedCoins = 0
    local done = false
    local workers = 4
    local completedWorkers = 0

    for _ = 1, workers do
        task.spawn(function()
            while not done and rounds < targetRounds do
                local ok, result = pcall(function()
                    if DS:FindFirstChild("StartRoundRE") then
                        DS.StartRoundRE:FireServer(50)
                    end
                    if DS:FindFirstChild("CompleteRoundRF") then
                        return DS.CompleteRoundRF:InvokeServer(50)
                    end
                    return nil
                end)
                if not ok or type(result) ~= "table" then
                    done = true
                    break
                end
                rounds = rounds + 1
                for _, item in ipairs(result) do
                    if item.ID == "SeasonCoin" then
                        gainedCoins = gainedCoins + (item.Number or 0)
                    end
                end
            end
            completedWorkers = completedWorkers + 1
        end)
    end

    local start = tick()
    while not done and rounds < targetRounds and (tick() - start) < 25 do
        task.wait(0.15)
        if completedWorkers >= workers then break end
    end
    done = true

    pcall(function()
        local info = LocalPlayer.PlayerGui:FindFirstChild("Info")
        if info then
            if info:FindFirstChild("DungeonResult") then info.DungeonResult.Visible = false end
            if info:FindFirstChild("RoundCompleted") then info.RoundCompleted.Visible = false end
        end
        local dGui = LocalPlayer.PlayerGui:FindFirstChild("Dungeon")
        if dGui then dGui.Enabled = false end
    end)

    return rounds, gainedCoins
end

local SEASON_PET_MAP = {
    Event1_1 = { Name = "Jack", Rarity = "Epic", Color = "🎃", Tier = 1 },
    Event1_2 = { Name = "Hex", Rarity = "Legendary", Color = "🐱", Tier = 2 },
    Event1_3 = { Name = "Vampire: Drake", Rarity = "Mythic", Color = "🦇", Tier = 3 },
    Event1_4 = { Name = "Shadow: Fenrir", Rarity = "Eternal / Secret", Color = "🐺✨", Tier = 4 },
}

local function AutoEquipBestPet()
    pcall(function()
        local pd = ReplicatedStorage:FindFirstChild("ProfileData")
        local pld = ReplicatedStorage:FindFirstChild("LocalData") and ReplicatedStorage.LocalData:FindFirstChild("PetData")
        if not pd or not pld then return end
        local ProfileData = require(pd)
        local PetData = require(pld)
        local petStore = ProfileData.GetStoreData and ProfileData.GetStoreData("Pet")
        if not petStore or not petStore.have then return end

        local bestUUID = nil
        local bestTier = -1

        for uuid, pet in pairs(petStore.have) do
            local info = SEASON_PET_MAP[pet.ID]
            local tier = info and info.Tier or 0
            if tier > bestTier then
                bestTier = tier
                bestUUID = uuid
            end
        end

        if bestUUID and petStore.equiped and petStore.equiped[1] ~= bestUUID then
            local current = petStore.equiped[1]
            local petRemote = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Pet_Server")
            if petRemote and petRemote:FindFirstChild("IsEquipPetRE") then
                if current then
                    petRemote.IsEquipPetRE:FireServer(current, false)
                    task.wait(0.1)
                end
                petRemote.IsEquipPetRE:FireServer(bestUUID, true)
            else
                PetData.EquipPet(bestUUID)
            end
        end
    end)
end

local function RollPetLuckOnce()
    local pd = ReplicatedStorage:FindFirstChild("ProfileData")
    if not pd then return nil end
    local ProfileData = require(pd)
    local sStore = ProfileData.GetStoreData and ProfileData.GetStoreData("Season")
    local coin = sStore and sStore.Season2 and sStore.Season2.SeasonCoin or 0
    if coin < 400 then return nil end

    local remote = ReplicatedStorage:FindFirstChild("Remote")
        and ReplicatedStorage.Remote:FindFirstChild("Season_Server")
        and ReplicatedStorage.Remote.Season_Server:FindFirstChild("LuckPetRF")
    if not remote then return nil end

    local petID = remote:InvokeServer()
    if petID then
        AutoEquipBestPet()
    end
    return petID
end

local function RunPetLuckBurst(count)
    count = count or 10
    local rolledCount = 0
    local stats = {}

    for i = 1, count do
        local petID = RollPetLuckOnce()
        if not petID then break end
        rolledCount = rolledCount + 1
        stats[petID] = (stats[petID] or 0) + 1
        task.wait(0.08)
    end

    local parts = {}
    for petID, num in pairs(stats) do
        local info = SEASON_PET_MAP[petID]
        local name = info and info.Name or petID
        local icon = info and info.Color or "🐾"
        table.insert(parts, string.format("%s %s x%d", icon, name, num))
    end

    return rolledCount, table.concat(parts, ", ")
end

local function JoinWorldBossFight()
    pcall(function()
        if WorldBossRemote and WorldBossRemote:FindFirstChild("IntoWorldBossFight") then
            WorldBossRemote.IntoWorldBossFight:FireServer()
        end
        LocalPlayer:SetAttribute("IntoFight", "WorldBoss")
        local char = LocalPlayer.Character
        if char then
            local wbModel = workspace:FindFirstChild("WorldModel") and workspace.WorldModel:FindFirstChild("WorldBoss")
            local center = wbModel and wbModel:FindFirstChild("Center")
            if center then
                char:PivotTo(center:GetPivot() * CFrame.new(0, 4, 0))
            else
                local ok, tu = pcall(function() return require(ReplicatedStorage.Utils.TranslateUtils) end)
                if ok and tu and tu.ToWorldBoss then
                    tu.ToWorldBoss(char)
                end
            end
        end
    end)
end

local function ExitWorldBossFight()
    pcall(function()
        if WorldBossRemote and WorldBossRemote:FindFirstChild("ExitWorldBossFight") then
            WorldBossRemote.ExitWorldBossFight:FireServer()
        end
        LocalPlayer:SetAttribute("IntoFight", nil)
        local char = LocalPlayer.Character
        if char then
            local ok, tu = pcall(function() return require(ReplicatedStorage.Utils.TranslateUtils) end)
            if ok and tu and tu.ToSpawn then
                tu.ToSpawn(char)
            end
        end
        if State.AutoTrain then
            task.delay(0.5, function()
                WarpToBestTrainArea()
            end)
        end
    end)
end

-- ========================================================================
-- TAB 1: BYPASS (CORE BYPASSES, MOVEMENT, AND ACTIONS)
-- ========================================================================
local BypassParagraph = Tabs.Bypass:AddParagraph({
    Title = "Master Bypass Engine",
    Content = "Unlocks all VIP GamePasses, Instant 1e30 Kill Aura, Immortal God Mode, and Extreme Stat Multipliers."
})
UIElements.BypassParagraph = BypassParagraph

UIElements.SecBypassCore = Tabs.Bypass:AddSection("Core Bypasses")

local ToggleUnlockAllGamePasses = Tabs.Bypass:AddToggle("UnlockAllGamePasses", {
    Title = "Unlock All GamePasses & VIP",
    Description = "Grants VIP, SuperLuck, UltraLuck, CommonLuck, MoreOre, SkipForge, AutoCollectOre, 2xDamage, SeasonVIP, and VIP Train Areas 9-11 without Robux",
    Default = true
})
ToggleUnlockAllGamePasses:OnChanged(function()
    State.UnlockAllGamePasses = Options.UnlockAllGamePasses.Value
    if State.UnlockAllGamePasses then
        task.spawn(ApplyGamePassAndVIPBypass)
    end
    RequestAutoSave()
end)
UIElements.ToggleUnlockAllGamePasses = ToggleUnlockAllGamePasses

local ToggleOmniKillAura = Tabs.Bypass:AddToggle("OmniKillAura", {
    Title = "Omni-Kill Aura (1e30 Damage)",
    Description = "Instantly eliminates all enemies across the entire map using 1e30 damage and server execution events",
    Default = true
})
ToggleOmniKillAura:OnChanged(function()
    State.OmniKillAura = Options.OmniKillAura.Value
    RequestAutoSave()
end)
UIElements.ToggleOmniKillAura = ToggleOmniKillAura

local ToggleGodMode = Tabs.Bypass:AddToggle("GodMode", {
    Title = "God Mode (Immortal)",
    Description = "Completely zeroes out all incoming damage; keeps health at 100% permanently",
    Default = true
})
ToggleGodMode:OnChanged(function()
    State.GodMode = Options.GodMode.Value
    RequestAutoSave()
end)
UIElements.ToggleGodMode = ToggleGodMode

local ToggleInsaneStatBoost = Tabs.Bypass:AddToggle("InsaneStatBoost", {
    Title = "Extreme Stat Multiplier (+5000%)",
    Description = "Hooks game balance formulas for massive Luck, Damage, Coins, and Ore drop rates",
    Default = true
})
ToggleInsaneStatBoost:OnChanged(function()
    State.InsaneStatBoost = Options.InsaneStatBoost.Value
    RequestAutoSave()
end)
UIElements.ToggleInsaneStatBoost = ToggleInsaneStatBoost

UIElements.SecBypassMovement = Tabs.Bypass:AddSection("Movement & Visuals")

local ToggleSpeedHack = Tabs.Bypass:AddToggle("SpeedHack", {
    Title = "WalkSpeed Boost",
    Description = "Overrides player movement speed (16 - 150)",
    Default = false
})
ToggleSpeedHack:OnChanged(function()
    State.SpeedHack = Options.SpeedHack.Value
    if not State.SpeedHack then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    RequestAutoSave()
end)
UIElements.ToggleSpeedHack = ToggleSpeedHack

local SliderWalkSpeed = Tabs.Bypass:AddSlider("WalkSpeedValue", {
    Title = "Custom WalkSpeed",
    Default = 48,
    Min = 16,
    Max = 150,
    Rounding = 0,
})
SliderWalkSpeed:OnChanged(function(val)
    State.WalkSpeedValue = val
    RequestAutoSave()
end)
UIElements.SliderWalkSpeed = SliderWalkSpeed

local ToggleJumpPowerHack = Tabs.Bypass:AddToggle("JumpPowerHack", {
    Title = "JumpPower Boost",
    Description = "Overrides player jump height (50 - 200)",
    Default = false
})
ToggleJumpPowerHack:OnChanged(function()
    State.JumpPowerHack = Options.JumpPowerHack.Value
    if not State.JumpPowerHack then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 50 end
    end
    RequestAutoSave()
end)
UIElements.ToggleJumpPowerHack = ToggleJumpPowerHack

local SliderJumpPower = Tabs.Bypass:AddSlider("JumpPowerValue", {
    Title = "Custom JumpPower",
    Default = 80,
    Min = 50,
    Max = 200,
    Rounding = 0,
})
SliderJumpPower:OnChanged(function(val)
    State.JumpPowerValue = val
    RequestAutoSave()
end)
UIElements.SliderJumpPower = SliderJumpPower

local ToggleNoclip = Tabs.Bypass:AddToggle("Noclip", {
    Title = "Noclip (Walk Through Walls)",
    Description = "Disables collision on character parts, allowing you to walk through walls and gates",
    Default = false
})
ToggleNoclip:OnChanged(function()
    State.Noclip = Options.Noclip.Value
    RequestAutoSave()
end)
UIElements.ToggleNoclip = ToggleNoclip

local ToggleInfiniteJump = Tabs.Bypass:AddToggle("InfiniteJump", {
    Title = "Infinite Jump",
    Description = "Allows jumping repeatedly in mid-air without landing",
    Default = false
})
ToggleInfiniteJump:OnChanged(function()
    State.InfiniteJump = Options.InfiniteJump.Value
    RequestAutoSave()
end)
UIElements.ToggleInfiniteJump = ToggleInfiniteJump

local ToggleDisableBlur = Tabs.Bypass:AddToggle("DisableBlur", {
    Title = "Disable Blur & Depth of Field",
    Description = "Permanently removes TrainDOF, Blur, and Depth of Field for a crystal clear view",
    Default = true
})
ToggleDisableBlur:OnChanged(function()
    State.DisableBlur = Options.DisableBlur.Value
    if State.DisableBlur then
        RemoveAllBlurs()
    end
    RequestAutoSave()
end)
UIElements.ToggleDisableBlur = ToggleDisableBlur

UIElements.SecBypassActions = Tabs.Bypass:AddSection("Instant Actions")

local BtnNukeAllMobs = Tabs.Bypass:AddButton({
    Title = "Nuke All Map Enemies Now",
    Description = "Sends 1e30 damage to every monster currently present in workspace",
    Callback = function()
        local count = 0
        local folders = {
            workspace:FindFirstChild("EnemyFolder"),
            workspace:FindFirstChild("EnemyFolder_Server")
        }
        for _, folder in ipairs(folders) do
            if folder then
                for _, enemy in ipairs(folder:GetChildren()) do
                    if enemy and not enemy:GetAttribute("Dead") then
                        count = count + 1
                        pcall(function()
                            if Remote:FindFirstChild("Attack") and Remote.Attack:FindFirstChild("EnemyHitBE") then
                                Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                                    Damage = 1e30,
                                    SkillID = "K_ATK_1",
                                    IsCrit = true
                                })
                            end
                        end)
                        pcall(function()
                            if AttackRemote and AttackRemote:FindFirstChild("KillEnemyRE") then
                                AttackRemote.KillEnemyRE:FireServer(enemy.Name)
                            end
                        end)
                    end
                end
            end
        end
        local lang = State.Language or "TH"
        Fluent:Notify({
            Title = "Nuke Aura",
            Content = (lang == "TH")
                and string.format("ล้างบางมอนสเตอร์เรียบร้อย %d ตัว!", count)
                or string.format("Obliterated %d enemy mob(s)!", count),
            Duration = 2
        })
    end
})
UIElements.BtnNukeAllMobs = BtnNukeAllMobs

local BtnVacuumOres = Tabs.Bypass:AddButton({
    Title = "Vacuum All World Ores",
    Description = "Instantly collects all dropped ores across the entire game",
    Callback = function()
        CollectAllWorldOres()
        local lang = State.Language or "TH"
        Fluent:Notify({
            Title = "Ore Magnet",
            Content = (lang == "TH") and "ดูดแร่ทั่วทั้งแมพเรียบร้อย!" or "All map ores vacuumed!",
            Duration = 2
        })
    end
})
UIElements.BtnVacuumOres = BtnVacuumOres

-- ========================================================================
-- TAB 2: FARM (TRAINING, SEASON 2, ORES, AND RAIDS)
-- ========================================================================
UIElements.SecFarmStats = Tabs.Farm:AddSection("Live Dashboard")

local StatParagraph = Tabs.Farm:AddParagraph({
    Title = "Live Player Statistics",
    Content = "Connecting to player data..."
})
UIElements.StatParagraph = StatParagraph

UIElements.SecFarmTrain = Tabs.Farm:AddSection("Training & Rebirth")

local ToggleAutoTrain = Tabs.Farm:AddToggle("AutoTrain", {
    Title = "Auto Train (Highest Area)",
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

local ToggleForce100xTrain = Tabs.Farm:AddToggle("Force100xTrain", {
    Title = "Force 100x Train Pad (VIP)",
    Description = "Forces VIP 100x multiplier train pad without purchasing the GamePass",
    Default = true
})
ToggleForce100xTrain:OnChanged(function()
    State.Force100xTrain = Options.Force100xTrain.Value
    if State.AutoTrain then
        task.spawn(WarpToBestTrainArea)
    end
    RequestAutoSave()
end)
UIElements.ToggleForce100xTrain = ToggleForce100xTrain

local ToggleAutoRebirth = Tabs.Farm:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth (Max Speed)",
    Description = "Instantly performs Rebirth the moment level requirement is met",
    Default = false
})
ToggleAutoRebirth:OnChanged(function()
    State.AutoRebirth = Options.AutoRebirth.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoRebirth = ToggleAutoRebirth

local BtnTeleportBestTrain = Tabs.Farm:AddButton({
    Title = "Warp to Best Train Area",
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
    Title = "Max Upgrade Passives",
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

UIElements.SecFarmSeason = Tabs.Farm:AddSection("Season 2 & Pets")

local ToggleAutoFarmSeason2Coins = Tabs.Farm:AddToggle("AutoFarmSeason2Coins", {
    Title = "Auto Farm SS2 Coins (Tower 50)",
    Description = "Spams Dungeon Floor 50 completions to rapidly farm massive Season 2 Coins, Ores & Enchant Stones",
    Default = false
})
ToggleAutoFarmSeason2Coins:OnChanged(function()
    State.AutoFarmSeason2Coins = Options.AutoFarmSeason2Coins.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoFarmSeason2Coins = ToggleAutoFarmSeason2Coins

local BtnInstantFarmSS2Coins = Tabs.Farm:AddButton({
    Title = "Instant Farm 100x SS2 Coins",
    Description = "Runs a 100-round burst of Dungeon Floor 50 immediately",
    Callback = function()
        task.spawn(function()
            local lang = State.Language or "TH"
            local t = I18N[lang] or I18N.TH
            Fluent:Notify({
                Title = "Season 2 Farm",
                Content = (lang == "TH" and "กำลังเริ่มปั้มเหรียญ SS2 100 รอบ..." or "Starting 100-round SS2 coin farm burst..."),
                Duration = 2
            })
            local rounds, coins = RunSeason2CoinsFarmBurst(100)
            Fluent:Notify({
                Title = "Season 2 Farm",
                Content = string.format(t.NotifySS2Farmed or "Farmed %d rounds (+%s SS2 Coins)!", rounds, AbbNumber.AbbreviateNumber(coins)),
                Duration = 3
            })
        end)
    end
})
UIElements.BtnInstantFarmSS2Coins = BtnInstantFarmSS2Coins

local ToggleAutoPetLuck = Tabs.Farm:AddToggle("AutoPetLuck", {
    Title = "Auto Roll Pet Luck",
    Description = "Automatically rolls Season 2 Pet Luck when having >= 400 SS2 Coins (bypasses roll animations)",
    Default = false
})
ToggleAutoPetLuck:OnChanged(function()
    State.AutoPetLuck = Options.AutoPetLuck.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoPetLuck = ToggleAutoPetLuck

local BtnRollPetLuck10x = Tabs.Farm:AddButton({
    Title = "Instant Roll Pet Luck (10x)",
    Description = "Draws 10 Season 2 Pets instantly using 4,000 SS2 Coins",
    Callback = function()
        task.spawn(function()
            local lang = State.Language or "TH"
            local t = I18N[lang] or I18N.TH
            Fluent:Notify({
                Title = "Pet Luck",
                Content = (lang == "TH" and "กำลังเริ่มสุ่ม Pet Luck 10 ครั้ง..." or "Rolling Pet Luck 10 times..."),
                Duration = 2
            })
            local rolledCount, rolledSummary = RunPetLuckBurst(10)
            if rolledCount > 0 then
                Fluent:Notify({
                    Title = "Pet Luck",
                    Content = string.format(t.NotifyPetLuckBurst or "Rolled %d pets!", rolledCount) .. (rolledSummary ~= "" and ("\n" .. rolledSummary) or ""),
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Pet Luck",
                    Content = t.NotifyNotEnoughCoins or "Not enough SS2 Coins!",
                    Duration = 3
                })
            end
        end)
    end
})
UIElements.BtnRollPetLuck10x = BtnRollPetLuck10x

UIElements.SecFarmOres = Tabs.Farm:AddSection("Ores & Inventory")

local ToggleAutoCollectOres = Tabs.Farm:AddToggle("AutoCollectOres", {
    Title = "Auto Collect Ores",
    Description = "Automatically triggers proximity prompts and vacuums every ore across the map",
    Default = false
})
ToggleAutoCollectOres:OnChanged(function()
    State.AutoCollectOres = Options.AutoCollectOres.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoCollectOres = ToggleAutoCollectOres

local ToggleSmartPack = Tabs.Farm:AddToggle("AutoSmartFreePack", {
    Title = "Auto Forge 10 Ores When Full",
    Description = "Automatically crafts equipment using 10 ores whenever the 24-slot pack fills up",
    Default = false
})
ToggleSmartPack:OnChanged(function()
    State.AutoSmartFreePack = Options.AutoSmartFreePack.Value
    RequestAutoSave()
end)
UIElements.ToggleSmartPack = ToggleSmartPack

local BtnCollectAllOres = Tabs.Farm:AddButton({
    Title = "Collect All Ground Ores",
    Description = "Collects all dropped ores currently on the map",
    Callback = function()
        CollectAllWorldOres()
    end
})
UIElements.BtnCollectAllOres = BtnCollectAllOres

UIElements.SecFarmRaid = Tabs.Farm:AddSection("Stage 27 Raid")

local ToggleStage27Raid = Tabs.Farm:AddToggle("AutoStage27Raid", {
    Title = "Auto Stage 27 Raid Loop",
    Description = "Warps to Stage 27, kills all mobs, collects drops, clicks Back, and waits 5s cooldown",
    Default = false
})
ToggleStage27Raid:OnChanged(function()
    State.AutoStage27Raid = Options.AutoStage27Raid.Value
    RequestAutoSave()
end)
UIElements.ToggleStage27Raid = ToggleStage27Raid

local BtnStage27Once = Tabs.Farm:AddButton({
    Title = "Run Stage 27 Sweep Once",
    Description = "Run one full Stage 27 sweep cycle now",
    Callback = function()
        task.spawn(RunStage27Cycle)
    end
})
UIElements.BtnStage27Once = BtnStage27Once

-- ========================================================================
-- TAB 3: FORGE (CRAFTING, GEAR MANAGEMENT, AND ASTRAL SET)
-- ========================================================================
UIElements.SecForgeCraft = Tabs.Forge:AddSection("Auto Crafting")

local ToggleAutoForge = Tabs.Forge:AddToggle("AutoForge", {
    Title = "Auto Forge (10 Ores)",
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

local BtnInstantMultiForge = Tabs.Forge:AddButton({
    Title = "Instant Forge 5 Batches",
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

UIElements.SecForgeGear = Tabs.Forge:AddSection("Gear Management")

local ToggleAutoEquipBest = Tabs.Forge:AddToggle("AutoEquipBest", {
    Title = "Auto Equip Best Gear",
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
    Title = "Instant Equip Best Gear",
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
    Title = "Auto Sell Non-Equipped Items",
    Description = "Periodically sells extra crafted items for coins",
    Default = false
})
ToggleAutoSellAll:OnChanged(function()
    State.AutoSellAll = Options.AutoSellAll.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoSellAll = ToggleAutoSellAll

local BtnInstantSellAll = Tabs.Forge:AddButton({
    Title = "Instant Sell All Non-Equipped",
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

UIElements.SecForgeAstral = Tabs.Forge:AddSection("Astral Genesis VIP Set")

local ToggleAstralSet = Tabs.Forge:AddToggle("AstralGenesisSet", {
    Title = "Permanent Astral Genesis Set",
    Description = "Keeps Astral Genesis gear models and effects equipped on character",
    Default = true
})
ToggleAstralSet:OnChanged(function()
    State.AstralGenesisSet = Options.AstralGenesisSet.Value
    if State.AstralGenesisSet then
        task.spawn(function()
            EquipAstralGenesisSet(false)
        end)
    end
    RequestAutoSave()
end)
UIElements.ToggleAstralSet = ToggleAstralSet

local BtnEquipAstralSet = Tabs.Forge:AddButton({
    Title = "Spawn Astral Genesis Set Now",
    Description = "Attaches Astral Supernova Edge, Devourer Plate, and Sovereign Crown",
    Callback = function()
        State.AstralGenesisSet = true
        if Options and Options.AstralGenesisSet then
            pcall(function() Options.AstralGenesisSet:SetValue(true) end)
        end
        EquipAstralGenesisSet(true)
        RequestAutoSave()
    end
})
UIElements.BtnEquipAstralSet = BtnEquipAstralSet

-- ========================================================================
-- TAB 4: COMBAT (TOWER 1-50, WORLD BOSS, AND SKILLS)
-- ========================================================================
UIElements.SecCombatTower = Tabs.Combat:AddSection("Frozen Tower (Floor 1-50)")

local ToggleDungeonSweep = Tabs.Combat:AddToggle("AutoDungeonSweep", {
    Title = "Auto Clear Tower Floors 1-50",
    Description = "Enters Frozen Tower and instantly completes all 50 floors in one pass without climbing floor by floor",
    Default = false
})
ToggleDungeonSweep:OnChanged(function()
    State.AutoDungeonSweep = Options.AutoDungeonSweep.Value
    RequestAutoSave()
end)
UIElements.ToggleDungeonSweep = ToggleDungeonSweep

local BtnInstantTower = Tabs.Combat:AddButton({
    Title = "Instant Clear Tower 1-50 (1-Click)",
    Description = "Instantly clears all 50 floors in seconds, wipes mobs with 1e30, and vacuums all rewards",
    Callback = function()
        task.spawn(function()
            local ok, floors, dur = RunInstantTower1To50Cycle()
            local lang = State.Language or "TH"
            Fluent:Notify({
                Title = "Frozen Tower",
                Content = ok and string.format((lang == "TH" and "กวาดล้างหอคอยชั้น 1-%d สำเร็จใน %.1f วินาที!" or "Cleared Tower floors 1-%d in %.1f seconds!"), floors, dur)
                             or (lang == "TH" and "ไม่สามารถเข้าหอคอยได้!" or "Could not enter Tower!"),
                Duration = 3
            })
        end)
    end
})
UIElements.BtnInstantTower = BtnInstantTower

local BtnEnterFloor50 = Tabs.Combat:AddButton({
    Title = "Enter Tower Floor 50 Directly",
    Description = "Enters top floor 50 of Frozen Tower directly",
    Callback = function()
        DungeonData.TryIntoDungeon(50)
    end
})
UIElements.BtnEnterFloor50 = BtnEnterFloor50

local BtnEnterDungeon = Tabs.Combat:AddButton({
    Title = "Enter Tower Floor 1",
    Callback = function()
        DungeonData.TryIntoDungeon(1)
    end
})
UIElements.BtnEnterDungeon = BtnEnterDungeon

local BtnExitDungeon = Tabs.Combat:AddButton({
    Title = "Exit Tower / Dungeon",
    Callback = function()
        DungeonData.ExitDungeon()
    end
})
UIElements.BtnExitDungeon = BtnExitDungeon

UIElements.SecCombatBoss = Tabs.Combat:AddSection("World Boss")

local WorldBossParagraph = Tabs.Combat:AddParagraph({
    Title = "World Boss Status",
    Content = "Connecting to World Boss timer..."
})
UIElements.WorldBossParagraph = WorldBossParagraph

local ToggleAutoWorldBoss = Tabs.Combat:AddToggle("AutoWorldBoss", {
    Title = "Auto World Boss (One-Shot & Claim)",
    Description = "Automatically joins arena when World Boss spawns, one-shots with 1e30 damage, claims card reward, and returns",
    Default = false
})
ToggleAutoWorldBoss:OnChanged(function()
    State.AutoWorldBoss = Options.AutoWorldBoss.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoWorldBoss = ToggleAutoWorldBoss

local BtnJoinWorldBoss = Tabs.Combat:AddButton({
    Title = "Join World Boss Arena",
    Description = "Teleports to World Boss arena and registers fight now",
    Callback = function()
        JoinWorldBossFight()
    end
})
UIElements.BtnJoinWorldBoss = BtnJoinWorldBoss

local BtnExitWorldBoss = Tabs.Combat:AddButton({
    Title = "Exit World Boss Arena",
    Description = "Leaves World Boss arena and teleports back to spawn",
    Callback = function()
        ExitWorldBossFight()
    end
})
UIElements.BtnExitWorldBoss = BtnExitWorldBoss

UIElements.SecCombatSkills = Tabs.Combat:AddSection("Skills & Combat")

local ToggleSkills = Tabs.Combat:AddToggle("AutoSkills", {
    Title = "Auto Spam Weapon Skills",
    Description = "Fires weapon skills constantly",
    Default = false
})
ToggleSkills:OnChanged(function()
    State.AutoSkills = Options.AutoSkills.Value
    RequestAutoSave()
end)
UIElements.ToggleSkills = ToggleSkills

local ToggleAstralSkill = Tabs.Combat:AddToggle("AutoAstralSkill", {
    Title = "Auto Cast Astral Burst Domain",
    Description = "Continuously activates Astral Burst Domain during combat",
    Default = false
})
ToggleAstralSkill:OnChanged(function()
    State.AutoAstralSkill = Options.AutoAstralSkill.Value
    RequestAutoSave()
end)
UIElements.ToggleAstralSkill = ToggleAstralSkill

local BtnCastAstralSkill = Tabs.Combat:AddButton({
    Title = "Cast Astral Burst Domain Now",
    Description = "Unleashes the cosmic dragon domain dealing continuous 1100% damage",
    Callback = function()
        CastAstralBurstDomain()
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "Astral Burst",
            Content = t.NotifyAstralSkill or "Astral Burst Domain activated!",
            Duration = 2
        })
    end
})
UIElements.BtnCastAstralSkill = BtnCastAstralSkill

local ToggleKillSuperLoot = Tabs.Combat:AddToggle("AutoKillSuperLoot", {
    Title = "Auto Kill Mobs & SuperLoot",
    Description = "Insta-kills any monsters and SuperLoot entities that spawn in the map",
    Default = false
})
ToggleKillSuperLoot:OnChanged(function()
    State.AutoKillSuperLoot = Options.AutoKillSuperLoot.Value
    RequestAutoSave()
end)
UIElements.ToggleKillSuperLoot = ToggleKillSuperLoot

-- ========================================================================
-- TAB 5: REWARDS (AUTOMATED AND INSTANT CLAIMS)
-- ========================================================================
UIElements.SecRewardsAuto = Tabs.Rewards:AddSection("Automated Claims")

local ToggleAutoClaimAll = Tabs.Rewards:AddToggle("AutoClaimAll", {
    Title = "Auto Claim Daily & Online Gifts",
    Description = "Continuously claims online gift rewards and index level-ups",
    Default = false
})
ToggleAutoClaimAll:OnChanged(function()
    State.AutoClaimAll = Options.AutoClaimAll.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoClaimAll = ToggleAutoClaimAll

local ToggleAutoClaimIndex = Tabs.Rewards:AddToggle("AutoClaimIndex", {
    Title = "Auto Claim Index Exp & Level",
    Description = "Continuously scans unlocked Weapon, Armor, Hat, and Ore index entries for Exp & Level rewards",
    Default = false
})
ToggleAutoClaimIndex:OnChanged(function()
    State.AutoClaimIndex = Options.AutoClaimIndex.Value
    RequestAutoSave()
end)
UIElements.ToggleAutoClaimIndex = ToggleAutoClaimIndex

UIElements.SecRewardsInstant = Tabs.Rewards:AddSection("Instant Claims")

local BtnInstantClaimIndex = Tabs.Rewards:AddButton({
    Title = "Instant Claim All Index Rewards",
    Description = "Claims all pending unlocked weapons, armors, hats, and ores in Index",
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
    Title = "Claim All Online Gifts (1 - 12)",
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
    Title = "Claim Daily Dungeon Ticket",
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
    Title = "Claim Group & Update Gifts",
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
    Title = "Redeem All Active Promo Codes",
    Callback = function()
        local codes = {"UPDATE", "RELEASE", "FORGE", "GOODBRO", "LIKE1000", "ENHANCE"}
        task.spawn(function()
            for _, c in ipairs(codes) do
                pcall(function()
                    if CodeRemote and CodeRemote:FindFirstChild("TryUseCodeRF") then
                        CodeRemote.TryUseCodeRF:InvokeServer(c)
                    elseif Remote:FindFirstChild("Code") and Remote.Code:FindFirstChild("TryUseCodeRF") then
                        Remote.Code.TryUseCodeRF:InvokeServer(c)
                    end
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
-- TAB 6: SETTINGS (PROFILE, AUTO SAVE, AND WINDOW CUSTOMIZATION)
-- ========================================================================
UIElements.SecSettingsProfile = Tabs.Settings:AddSection("Profile & Language")

local DropdownLanguage = Tabs.Settings:AddDropdown("LanguageSetting", {
    Title = "Language / เลือกภาษา",
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
            Title = "STREET HUB",
            Content = t.NotifyLangChanged,
            Duration = 2
        })
    end
end)
UIElements.DropdownLanguage = DropdownLanguage

local ProfileParagraph = Tabs.Settings:AddParagraph({
    Title = "Active Account Profile",
    Content = "Account: " .. LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")\n" ..
              "Folder: " .. accountFolder
})
UIElements.ProfileParagraph = ProfileParagraph

UIElements.SecSettingsSave = Tabs.Settings:AddSection("Auto Save & Protection")

local AutoSaveParagraph = Tabs.Settings:AddParagraph({
    Title = "Per-Account Auto Save System",
    Content = "Auto Save is ACTIVE and isolated per account.\nSettings and autoload are saved specifically for " .. LocalPlayer.Name .. "."
})
UIElements.AutoSaveParagraph = AutoSaveParagraph

local ToggleAutoSaveSetting = Tabs.Settings:AddToggle("AutoSaveToggle", {
    Title = "Enable Auto Save",
    Description = "Automatically writes configuration to file whenever any toggle is clicked",
    Default = true
})
ToggleAutoSaveSetting:OnChanged(function()
    autoSaveEnabled = Options.AutoSaveToggle.Value
end)
UIElements.ToggleAutoSaveSetting = ToggleAutoSaveSetting

local BtnForceSave = Tabs.Settings:AddButton({
    Title = "Force Save Settings Now",
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

local ToggleAntiAFK = Tabs.Settings:AddToggle("AntiAFKToggle", {
    Title = "Anti-AFK Protection",
    Description = "Disables Roblox 20-minute idle kicks and pulses anti-afk input",
    Default = true
})
ToggleAntiAFK:OnChanged(function()
    State.AntiAFK = Options.AntiAFKToggle.Value
    RequestAutoSave()
end)
UIElements.ToggleAntiAFK = ToggleAntiAFK

UIElements.SecSettingsWindow = Tabs.Settings:AddSection("Window Display")

local SliderWindowScale = Tabs.Settings:AddSlider("WindowScaleSlider", {
    Title = "Window UI Scale (Zoom)",
    Description = "Adjust overall UI scale percentage (60% - 125%)",
    Default = math.floor((State.WindowScale or (isMobileDevice and 0.85 or 1.0)) * 100),
    Min = 60,
    Max = 125,
    Rounding = 0,
    Callback = function(Value)
        local scaleVal = Value / 100
        State.WindowScale = scaleVal
        if WindowUIScale then
            WindowUIScale.Scale = scaleVal
        end
        RequestAutoSave()
    end
})
UIElements.SliderWindowScale = SliderWindowScale

local DropdownWindowPreset = Tabs.Settings:AddDropdown("WindowPresetSetting", {
    Title = "Window Size Preset",
    Values = {"กะทัดรัด (Compact: 460 x 320)", "มาตรฐาน (Standard: 540 x 380)", "ใหญ่ (Large: 620 x 440)"},
    Multi = false,
    Default = (State.WindowWidth and State.WindowWidth <= 480) and "กะทัดรัด (Compact: 460 x 320)" or "มาตรฐาน (Standard: 540 x 380)"
})
DropdownWindowPreset:OnChanged(function(Value)
    if string.find(Value, "460") then
        Window.Root.Size = UDim2.fromOffset(460, 320)
    elseif string.find(Value, "540") then
        Window.Root.Size = UDim2.fromOffset(540, 380)
    elseif string.find(Value, "620") then
        Window.Root.Size = UDim2.fromOffset(620, 440)
    end
    State.WindowWidth = Window.Root.AbsoluteSize.X
    State.WindowHeight = Window.Root.AbsoluteSize.Y
    RequestAutoSave()
end)
UIElements.DropdownWindowPreset = DropdownWindowPreset

local BtnResetWindowSize = Tabs.Settings:AddButton({
    Title = "Reset Window Size & Scale",
    Description = "Restore window dimensions and zoom back to default",
    Callback = function()
        local defScale = isMobileDevice and 0.85 or 1.0
        local defW = isMobileDevice and 480 or 560
        local defH = isMobileDevice and 340 or 420
        State.WindowScale = defScale
        State.WindowWidth = defW
        State.WindowHeight = defH
        if WindowUIScale then
            WindowUIScale.Scale = defScale
        end
        Window.Root.Size = UDim2.fromOffset(defW, defH)
        if Options.WindowScaleSlider then
            Options.WindowScaleSlider:SetValue(math.floor(defScale * 100))
        end
        RequestAutoSave()
        local lang = State.Language or "TH"
        local t = I18N[lang] or I18N.TH
        Fluent:Notify({
            Title = "STREET HUB",
            Content = t.NotifyWindowReset,
            Duration = 2.5
        })
    end
})
UIElements.BtnResetWindowSize = BtnResetWindowSize

UIElements.SecSettingsConfig = Tabs.Settings:AddSection("Configurations")

if SaveManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName", "AutoSaveToggle" })
        SaveManager:SetFolder(accountFolder)
        SaveManager:BuildConfigSection(Tabs.Settings)
    end)
end

if InterfaceManager then
    pcall(function()
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:SetFolder("StreetHub")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    end)
end

-- Apply selected language across all UI elements immediately
UpdateLanguage(State.Language or "TH")

Window:SelectTab(2)

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
            local ss2Coins = 0
            pcall(function()
                local sData = ProfileData.GetStoreData("Season")
                if sData and sData.Season2 and sData.Season2.SeasonCoin then
                    ss2Coins = sData.Season2.SeasonCoin
                end
            end)
            local formattedSS2 = AbbNumber.AbbreviateNumber(ss2Coins)
            StatParagraph:SetDesc(string.format("Power: %s\nLevel: %d\nRebirth: %d\nCoins: %s\nSeason 2 Coins: %s\nOres in Bag: %d/24",
                formattedPower, lvl, reb, formattedCoins, formattedSS2, oreTotal))
        end)
        task.wait(0.5)
    end
end)

-- Dedicated Background Force 100x Train Lock Worker
task.spawn(function()
    while true do
        if State and State.Force100xTrain then
            pcall(function()
                local cg = game:GetService("CoreGui")
                local ppa = cg:FindFirstChild("PurchasePromptApp")
                if ppa and ppa.Enabled then
                    ppa.Enabled = false
                end

                if not LocalPlayer:GetAttribute("IntoFight") and not State.AutoStage27Raid and not LocalPlayer:GetAttribute("Dungeoning") then
                    if LocalPlayer:GetAttribute("AutoTrainAreaID") ~= 9 then
                        TrainRemote.IntoAutoTrainRE:FireServer(9)
                    end
                end
            end)
            task.wait(0.35)
        else
            task.wait(1.0)
        end
    end
end)

-- 1. Hyper Auto Train Worker (Up to 20 tokens per cycle at 100x)
local trainQueue = {}
local lastTrainWarpCheck = 0
task.spawn(function()
    while true do
        if State.AutoTrain then
            pcall(function()
                local bestID = GetBestUnlockedTrainArea()
                local targetNum = tonumber(bestID)

                -- Keep player aligned on best train pad if not in fight/raid/dungeon
                if not LocalPlayer:GetAttribute("IntoFight") and not State.AutoStage27Raid and not LocalPlayer:GetAttribute("Dungeoning") then
                    if tick() - lastTrainWarpCheck > 2.5 then
                        lastTrainWarpCheck = tick()
                        if LocalPlayer:GetAttribute("AutoTrainAreaID") ~= targetNum then
                            WarpToBestTrainArea()
                        end
                    end
                end

                -- Lock server AutoTrainAreaID to target pad (especially VIP Area 9 x100)
                if targetNum and LocalPlayer:GetAttribute("AutoTrainAreaID") ~= targetNum then
                    TrainRemote.IntoAutoTrainRE:FireServer(targetNum)
                end

                if #trainQueue < 80 then
                    TrainRemote.StartTrainRE:FireServer()
                    local buf = TrainRemote.InvokTrainDataListRF:InvokeServer()
                    if buf then
                        local list = EncodingUtils.DecodeTable(buf)
                        for _, item in ipairs(list) do
                            table.insert(trainQueue, item.UUID)
                        end
                    end
                end

                for i = 1, math.min(#trainQueue, 20) do
                    local token = table.remove(trainQueue, 1)
                    if token then
                        TrainRemote.TrainOnceRE:FireServer(token)
                    end
                end
            end)
        end
        task.wait(0.05)
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
                        if RebirthRemote and RebirthRemote:FindFirstChild("TryRebirthRE") then
                            RebirthRemote.TryRebirthRE:FireServer()
                        elseif Remote:FindFirstChild("Rebirth") and Remote.Rebirth:FindFirstChild("TryRebirthRE") then
                            Remote.Rebirth.TryRebirthRE:FireServer()
                        end
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

-- 7. Auto Tower / Dungeon Sweeper Worker (Instant 1-50 Nuke Clear)
local towerRunning = false
task.spawn(function()
    while true do
        if State.AutoDungeonSweep and not towerRunning then
            if not LocalPlayer:GetAttribute("Dungeoning") and not LocalPlayer:GetAttribute("IntoFight") and not State.AutoStage27Raid then
                towerRunning = true
                pcall(function()
                    RunInstantTower1To50Cycle()
                end)
                towerRunning = false
                task.wait(2.5) -- Cooldown between runs
            else
                task.wait(1.0)
            end
        else
            task.wait(1.0)
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

-- 9. Auto Skill Spam Worker & Astral Burst Domain
task.spawn(function()
    while true do
        if State.AutoSkills or State.AutoAstralSkill then
            pcall(function()
                if State.AutoAstralSkill then
                    CastAstralBurstDomain()
                end
                if State.AutoSkills then
                    AttackRemote.UseAnySkillRE:FireServer()
                end
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

-- 13. World Boss Real-time Status & Countdown Updater
task.spawn(function()
    while true do
        pcall(function()
            if UIElements.WorldBossParagraph then
                local currentBoss = workspace:GetAttribute("CurrentWorldBoss")
                local nextTick = workspace:GetAttribute("NextWorldBossTick")
                local serverTime = workspace:GetAttribute("ServerTime") or os.time()
                local lang = State.Language or "TH"

                if currentBoss then
                    local txt = (lang == "TH")
                        and string.format("🔴 บอสโลกกำลังเกิด: %s\n⚔️ กำลังต่อสู้ / ระบบสังหาร 1e30 กำลังทำงาน!", tostring(currentBoss))
                        or string.format("🔴 Active World Boss: %s\n⚔️ In combat / 1e30 instant elimination active!", tostring(currentBoss))
                    UIElements.WorldBossParagraph:SetDesc(txt)
                elseif nextTick then
                    local remaining = math.max(0, math.floor(nextTick - serverTime))
                    local mins = math.floor(remaining / 60)
                    local secs = remaining % 60
                    local autoStatus = State.AutoWorldBoss
                        and ((lang == "TH") and "เปิดใช้งาน (พร้อมเข้าสู้อัตโนมัติ)" or "ENABLED (Ready to auto-engage)")
                        or ((lang == "TH") and "ปิดใช้งาน" or "DISABLED")
                    local txt = (lang == "TH")
                        and string.format("⏳ บอสเกิดในอีก: %02d:%02d (%d วินาที)\nสถานะระบบออโต้: %s", mins, secs, remaining, autoStatus)
                        or string.format("⏳ Next Boss in: %02d:%02d (%d seconds)\nAuto World Boss: %s", mins, secs, remaining, autoStatus)
                    UIElements.WorldBossParagraph:SetDesc(txt)
                else
                    UIElements.WorldBossParagraph:SetDesc((lang == "TH") and "กำลังดึงเวลาบอสโลก..." or "Fetching World Boss timer...")
                end
            end
        end)
        task.wait(1.0)
    end
end)

-- 14. Auto World Boss Combat, 1e30 Annihilation & Reward Claim Loop
local worldBossClaiming = false
task.spawn(function()
    while true do
        if State.AutoWorldBoss then
            pcall(function()
                local currentBoss = workspace:GetAttribute("CurrentWorldBoss")
                if currentBoss and not worldBossClaiming then
                    if LocalPlayer:GetAttribute("IntoFight") ~= "WorldBoss" then
                        JoinWorldBossFight()
                        task.wait(0.5)
                    end

                    pcall(function()
                        if Remote:FindFirstChild("Attack") and Remote.Attack:FindFirstChild("EnemyHitBE") then
                            Remote.Attack.EnemyHitBE:Fire(currentBoss, 1e30, {
                                Damage = 1e30,
                                SkillID = "K_ATK_1",
                                IsCrit = true
                            })
                        end
                    end)
                    pcall(function()
                        if AttackRemote and AttackRemote:FindFirstChild("KillEnemyRE") then
                            AttackRemote.KillEnemyRE:FireServer(currentBoss)
                        end
                    end)

                    for _, folderName in ipairs({"EnemyFolder_Server", "EnemyFolder"}) do
                        local f = workspace:FindFirstChild(folderName)
                        if f then
                            for _, enemy in ipairs(f:GetChildren()) do
                                if enemy and not enemy:GetAttribute("Dead") then
                                    if enemy.Name == currentBoss or string.find(string.lower(enemy.Name), "boss") then
                                        pcall(function()
                                            if Remote:FindFirstChild("Attack") and Remote.Attack:FindFirstChild("EnemyHitBE") then
                                                Remote.Attack.EnemyHitBE:Fire(enemy.Name, 1e30, {
                                                    Damage = 1e30,
                                                    SkillID = "K_ATK_1",
                                                    IsCrit = true
                                                })
                                            end
                                            if AttackRemote and AttackRemote:FindFirstChild("KillEnemyRE") then
                                                AttackRemote.KillEnemyRE:FireServer(enemy.Name)
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end

                local bossFightGui = PlayerGui:FindFirstChild("BossFight")
                local bossReward = bossFightGui and bossFightGui:FindFirstChild("BossReward")
                if bossReward and bossReward.Visible and not worldBossClaiming then
                    worldBossClaiming = true
                    task.spawn(function()
                        task.wait(1.0)
                        local cardSlot = tostring(math.random(1, 8))
                        pcall(function()
                            if WorldBossRemote and WorldBossRemote:FindFirstChild("TryClaimBossRewardRE") then
                                WorldBossRemote.TryClaimBossRewardRE:FireServer(cardSlot)
                            end
                        end)
                        task.wait(2.5)
                        CollectAllWorldOres()
                        task.wait(1.0)
                        ExitWorldBossFight()
                        worldBossClaiming = false
                    end)
                end
            end)
            task.wait(0.2)
        else
            task.wait(1.0)
        end
    end
end)

-- Dedicated listener for World Boss BossDeadRE event
if WorldBossRemote and WorldBossRemote:FindFirstChild("BossDeadRE") then
    WorldBossRemote.BossDeadRE.OnClientEvent:Connect(function(...)
        if State.AutoWorldBoss and not worldBossClaiming then
            worldBossClaiming = true
            task.spawn(function()
                task.wait(3.2)
                local cardSlot = tostring(math.random(1, 8))
                pcall(function()
                    if WorldBossRemote and WorldBossRemote:FindFirstChild("TryClaimBossRewardRE") then
                        WorldBossRemote.TryClaimBossRewardRE:FireServer(cardSlot)
                    end
                end)
                task.wait(2.5)
                CollectAllWorldOres()
                task.wait(1.0)
                ExitWorldBossFight()
                worldBossClaiming = false
            end)
        end
    end)
end

-- 15. Auto Farm Season 2 Coins Worker (High-Speed Dungeon Floor 50 Multi-Worker)
task.spawn(function()
    while true do
        if State.AutoFarmSeason2Coins then
            pcall(function()
                RunSeason2CoinsFarmBurst(60)
            end)
            task.wait(0.2)
        else
            task.wait(1.5)
        end
    end
end)

-- 16. Auto Roll Pet Luck Worker (Season 2)
task.spawn(function()
    while true do
        if State.AutoPetLuck then
            pcall(function()
                local petID = RollPetLuckOnce()
                if petID and (petID == "Event1_3" or petID == "Event1_4") then
                    local lang = State.Language or "TH"
                    local t = I18N[lang] or I18N.TH
                    local info = SEASON_PET_MAP[petID]
                    local name = info and info.Name or petID
                    local rarity = info and info.Rarity or "Secret"
                    local icon = info and info.Color or "✨"
                    Fluent:Notify({
                        Title = "Pet Luck 🎉",
                        Content = string.format(t.NotifyPetLuckRoll or "Rolled %s [%s]!", icon .. " " .. name, rarity),
                        Duration = 3
                    })
                end
            end)
            task.wait(0.2)
        else
            task.wait(1.5)
        end
    end
end)

-- Load saved settings before starting regular flow
LoadSavedState()
pcall(function() SaveManager:LoadAutoloadConfig() end)

-- Apply user preferred window size and scale
if State.WindowWidth and State.WindowHeight and Window and Window.Root then
    pcall(function()
        Window.Root.Size = UDim2.fromOffset(State.WindowWidth, State.WindowHeight)
    end)
end
if State.WindowScale and WindowUIScale then
    pcall(function()
        WindowUIScale.Scale = State.WindowScale
    end)
end

-- Apply user preferred language
UpdateLanguage(State.Language or "TH")

if State.AstralGenesisSet then
    task.delay(0.5, function()
        EquipAstralGenesisSet(false)
    end)
end

task.delay(0.3, function()
    autoSaveLoaded = true
end)

local currentT = I18N[State.Language] or I18N.TH
Fluent:Notify({
    Title = "STREET HUB",
    Content = string.format(currentT.NotifyLoaded, LocalPlayer.Name),
    Duration = 4
})
