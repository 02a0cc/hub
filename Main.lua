-- Starlight UI Script - Noquitis Hub
local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

local Window = Starlight:CreateWindow({
    Name = "Noquitis Hub",
    Subtitle = "v1.0",
    LoadingSettings = {
        Title = "Noquitis Hub",
        Subtitle = "Welcome to Noquitis Hub",
    },
    FileSettings = {
        ConfigFolder = "NoquitisHub"
    },
})

-- ============================================
-- TAB SECTIONS
-- ============================================
local MainSection = Window:CreateTabSection("Main")
local TrialSection = Window:CreateTabSection("Trial/Raids")
local TowerSection = Window:CreateTabSection("Tower")

-- ============================================
-- TABS
-- ============================================
local MainTab = MainSection:CreateTab({
    Name = "Main",
    Columns = 2,
}, "MainTab")

local TrialTab = TrialSection:CreateTab({
    Name = "Trial/Raids",
    Columns = 2,
}, "TrialTab")

local TowerTab = TowerSection:CreateTab({
    Name = "Tower",
    Columns = 2,
}, "TowerTab")

-- ============================================
-- GROUPBOXES
-- ============================================
local EnemiesGroupbox = MainTab:CreateGroupbox({
    Name = "Enemies",
    Column = 1,
}, "EnemiesGroupbox")

local TrialGroupbox = TrialTab:CreateGroupbox({
    Name = "Trial",
    Column = 1,
}, "TrialGroupbox")

local TowerGroupbox = TowerTab:CreateGroupbox({
    Name = "AutoTower",
    Column = 1,
}, "TowerGroupbox")

local TraitGroupbox = MainTab:CreateGroupbox({
    Name = "Auto Trait",
    Column = 2,
}, "TraitGroupbox")

-- ============================================
-- MAIN TAB: Enemies (World)
-- ============================================
local function GetEnemyNames()
    local names = {}
    local seen = {}
    local Client = game.Workspace:FindFirstChild('Client')
    if Client then
        local Enemies = Client:FindFirstChild('Enemies')
        if Enemies then
            for _, enemy in ipairs(Enemies:GetChildren()) do
                if not seen[enemy.Name] then
                    seen[enemy.Name] = true
                    table.insert(names, enemy.Name)
                end
            end
        end
    end
    return names
end

local function FindEnemy(selectedName)
    local Client = game.Workspace:FindFirstChild('Client')
    if not Client then return nil end
    local Enemies = Client:FindFirstChild('Enemies')
    if not Enemies then return nil end
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if enemy.Name == selectedName then
            local hrp = enemy:FindFirstChild('HumanoidRootPart')
            if hrp then return enemy end
        end
    end
    return nil
end

local lastTeleportPosition = nil

local function TeleportToEnemy()
    if not AutofarmToggle then return end
    if not AutofarmToggle.Values.CurrentValue then return end
    local selectedEnemy = EnemyDropdown.Values.CurrentOptions and EnemyDropdown.Values.CurrentOptions[1] or nil
    if not selectedEnemy then return end
    local enemy = FindEnemy(selectedEnemy)
    if not enemy then return end
    local hrp = enemy:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    -- Só teleporta se a posição mudou (evita spam de packets)
    if lastTeleportPosition and lastTeleportPosition == hrp.Position then return end
    local player = game.Players.LocalPlayer
    if not player or not player.Character then return end
    local playerHrp = player.Character:FindFirstChild('HumanoidRootPart')
    if not playerHrp then return end
    playerHrp.CFrame = hrp.CFrame
    lastTeleportPosition = hrp.Position
    print('[Teleport] Teleported to:', selectedEnemy, '| Position:', tostring(hrp.Position))
end

-- Label para o Dropdown (nested)
local EnemyLabel = EnemiesGroupbox:CreateLabel({
    Name = "Select Enemy"
}, "EnemyLabel")

EnemyDropdown = EnemyLabel:AddDropdown({
    Options = GetEnemyNames(),
    CurrentOptions = {},
    Placeholder = "None Selected",
    Callback = function(Options)
        print('[cb] EnemyDropdown changed:', Options)
        TeleportToEnemy()
    end,
}, "EnemyDropdown")

EnemiesGroupbox:CreateDivider()

AutofarmToggle = EnemiesGroupbox:CreateToggle({
    Name = "Autofarm",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Autofarm changed to:', Value)
        if Value then TeleportToEnemy() end
    end,
}, "AutofarmToggle")

-- Monitor loop for autofarm
task.spawn(function()
    local lastEnemyPosition = nil
    while task.wait(1) do
        if not AutofarmToggle then break end
        if AutofarmToggle.Values.CurrentValue then
            local selectedEnemy = EnemyDropdown.Values.CurrentOptions and EnemyDropdown.Values.CurrentOptions[1] or nil
            if selectedEnemy then
                local enemy = FindEnemy(selectedEnemy)
                if enemy then
                    local hrp = enemy:FindFirstChild('HumanoidRootPart')
                    if hrp then
                        -- Só teletransporta se a posição mudou (novo enemy na mesma posição)
                        if lastEnemyPosition == nil or hrp.Position ~= lastEnemyPosition then
                            print('[Monitor] New enemy found:', selectedEnemy, '| Position:', tostring(hrp.Position))
                            TeleportToEnemy()
                        end
                        lastEnemyPosition = hrp.Position
                    end
                else
                    -- Enemy morreu, reseta para detectar o próximo
                    print('[Monitor] Enemy died, waiting for respawn:', selectedEnemy)
                    lastEnemyPosition = nil
                end
            end
        end
    end
end)

-- ============================================
-- AUTO TRAIT
-- ============================================
local function GetFighters()
    local fighters = {}
    local Server = game.Workspace:FindFirstChild('Server')
    if not Server then return fighters end
    local Fighters = Server:FindFirstChild('Fighters')
    if not Fighters then return fighters end
    local myId = tostring(game.Players.LocalPlayer.UserId)
    local myFolder = Fighters:FindFirstChild(myId)
    if not myFolder then
        -- Fallback: usar primeiro folder se não achar pelo UserId
        myFolder = Fighters:GetChildren()[1]
    end
    if myFolder then
        for _, fighter in ipairs(myFolder:GetChildren()) do
            local customName = fighter:GetAttribute('Custom_Name') or fighter.Name
            local level = fighter:GetAttribute('Level') or '?'
            table.insert(fighters, {
                UUID = fighter.Name,
                Display = customName .. ' - Lvl ' .. tostring(level),
                Instance = fighter
            })
        end
    end
    return fighters
end

local function GetAvailableTraits()
    local traits = {}
    local RS = game:GetService("ReplicatedStorage")
    local Shared = RS:FindFirstChild("Shared")
    if Shared then
        local TraitsModule = Shared:FindFirstChild("Traits")
        if TraitsModule then
            local success, result = pcall(require, TraitsModule)
            if success then
                for k, v in pairs(result) do
                    table.insert(traits, k)
                end
            end
        end
    end
    table.sort(traits)
    return traits
end

local function GetCurrentFighterTrait(fighterUUID)
    local Server = game.Workspace:FindFirstChild('Server')
    if not Server then return nil end
    local Fighters = Server:FindFirstChild('Fighters')
    if not Fighters then return nil end
    for _, folder in ipairs(Fighters:GetChildren()) do
        local fighter = folder:FindFirstChild(fighterUUID)
        if fighter then
            return fighter:GetAttribute('Trait')
        end
    end
    return nil
end

local function GetTraitRemote()
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs:WaitForChild("Remotes", 10)
    if remotes then
        return remotes:WaitForChild("Trait", 10)
    end
    return nil
end

-- Fighter Dropdown
local FighterLabel = TraitGroupbox:CreateLabel({
    Name = "Select Fighter"
}, "FighterLabel")

local selectedFighter = nil
local FighterDropdown = FighterLabel:AddDropdown({
    Options = (function()
        local fighters = GetFighters()
        local names = {}
        for _, f in ipairs(fighters) do
            table.insert(names, f.Display)
        end
        return names
    end)(),
    CurrentOptions = {},
    Placeholder = "None Selected",
    Callback = function(Options)
        selectedFighter = nil
        if Options and Options[1] then
            local text = type(Options[1]) == "table" and Options[1].Text or tostring(Options[1])
            local fighters = GetFighters()
            for _, f in ipairs(fighters) do
                if f.Display == text then
                    selectedFighter = f
                    break
                end
            end
        end
        print('[cb] FighterDropdown changed:', selectedFighter and selectedFighter.Display or "None")
    end,
}, "FighterDropdown")

TraitGroupbox:CreateDivider()

-- Trait Dropdown
local TraitLabel = TraitGroupbox:CreateLabel({
    Name = "Select Trait"
}, "TraitLabel")

local selectedTraits = {}
local TraitDropdown = TraitLabel:AddDropdown({
    Options = GetAvailableTraits(),
    CurrentOptions = {},
    Placeholder = "None Selected",
    MultipleOptions = true,
    Callback = function(Options)
        selectedTraits = {}
        if Options then
            for _, opt in ipairs(Options) do
                local text = type(opt) == "table" and opt.Text or tostring(opt)
                table.insert(selectedTraits, text)
            end
        end
        print('[cb] TraitDropdown changed:', #selectedTraits, 'traits selected:', table.concat(selectedTraits, ", "))
    end,
}, "TraitDropdown")

TraitGroupbox:CreateDivider()

AutoTraitToggle = TraitGroupbox:CreateToggle({
    Name = "Auto Trait",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Auto Trait changed to:', Value)
    end,
}, "AutoTraitToggle")

-- Auto Trait loop
local traitCooldown = false
task.spawn(function()
    while task.wait(0.01) do
        if not AutoTraitToggle then break end
        if AutoTraitToggle.Values.CurrentValue and not traitCooldown then
            if selectedFighter and #selectedTraits > 0 then
                -- Verificar trait atual do fighter
                local currentTrait = GetCurrentFighterTrait(selectedFighter.UUID)
                if currentTrait and table.find(selectedTraits, currentTrait) then
                    -- Já tem uma das traits alvo, parar
                    print('[Trait] Fighter already has trait:', currentTrait, '- Stopping!')
                    AutoTraitToggle.Values.CurrentValue = false
                else
                    -- Não tem, aplicar trait
                    local traitRemote = GetTraitRemote()
                    if traitRemote then
                        traitCooldown = true
                        print('[Trait] Applying trait on:', selectedFighter.Display, '| Current:', currentTrait or 'None', '| Target:', table.concat(selectedTraits, ", "))
                        traitRemote:InvokeServer(selectedFighter.UUID)
                        task.delay(0.05, function()
                            traitCooldown = false
                        end)
                    else
                        print('[Trait] Trait remote not found!')
                    end
                end
            end
        end
    end
end)

-- ============================================
-- TRIAL/RAIDS TAB
-- ============================================
local function GetBridgeRemote()
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs:WaitForChild("Remotes", 10)
    if remotes then
        return remotes:WaitForChild("Bridge", 10)
    end
    return nil
end

local function GetCurrentWave()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local waveFrame = playerGui:FindFirstChild("UI") and playerGui.UI:FindFirstChild("HUD") and playerGui.UI.HUD:FindFirstChild("Trial") and playerGui.UI.HUD.Trial:FindFirstChild("Frame") and playerGui.UI.HUD.Trial.Frame:FindFirstChild("Wave")
    if waveFrame then
        local value = waveFrame:FindFirstChild("Value")
        if value then
            local waveNum = tonumber(value.Text)
            return waveNum
        end
    end
    return nil
end

local function GetCurrentTowerWave()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local waveFrame = playerGui:FindFirstChild("UI") and playerGui.UI:FindFirstChild("HUD") and playerGui.UI.HUD:FindFirstChild("TowerRaid") and playerGui.UI.HUD.TowerRaid:FindFirstChild("Frame") and playerGui.UI.HUD.TowerRaid.Frame:FindFirstChild("Wave")
    if waveFrame then
        local value = waveFrame:FindFirstChild("Value")
        if value then
            local waveNum = tonumber(value.Text)
            return waveNum
        end
    end
    return nil
end

local function GetTowerEnemy()
    local Server = game.Workspace:FindFirstChild('Server')
    if not Server then return nil end
    local TowerRaid = Server:FindFirstChild('TowerRaid')
    if not TowerRaid then return nil end
    local Enemies = TowerRaid:FindFirstChild('Enemies')
    if not Enemies then return nil end
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if enemy:IsA('BasePart') and enemy.CFrame then
            return enemy
        end
    end
    return nil
end

local function IsTrialActive()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local hud = playerGui:FindFirstChild("UI") and playerGui.UI:FindFirstChild("HUD")
    if not hud then return false end
    local trial = hud:FindFirstChild("Trial")
    return trial and trial.Visible or false
end

local function IsTowerActive()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local hud = playerGui:FindFirstChild("UI") and playerGui.UI:FindFirstChild("HUD")
    if not hud then return false end
    local towerRaid = hud:FindFirstChild("TowerRaid")
    return towerRaid and towerRaid.Visible or false
end

local function GetTrialEnemy()
    local Server = game.Workspace:FindFirstChild('Server')
    if not Server then return nil end
    local Trial = Server:FindFirstChild('Trial')
    if not Trial then return nil end
    local Enemies = Trial:FindFirstChild('Enemies')
    if not Enemies then return nil end
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if enemy:IsA('BasePart') and enemy.CFrame then
            return enemy
        end
    end
    return nil
end

-- Auto Join loop (leave Tower first if inside)
local trialJoinSent = false
task.spawn(function()
    while task.wait(1) do
        if not TrialAutoJoinToggle then break end
        if TrialAutoJoinToggle.Values.CurrentValue then
            local now = os.date('*t')
            local minute = now.min
            if (minute == 0 or minute == 30) and not trialJoinSent then
                if IsTowerActive() then
                    local bridge = GetBridgeRemote()
                    if bridge then
                        bridge:FireServer("Gamemodes", "TowerRaid", "Leave")
                        print('[Trial] Leaving Tower before Trial at', os.date('%H:%M'))
                        task.delay(2, function()
                            local bridge2 = GetBridgeRemote()
                            if bridge2 then
                                bridge2:FireServer("Gamemodes", "Trial", "Join")
                                print('[Trial] Auto Join triggered at', os.date('%H:%M'))
                            end
                        end)
                    end
                else
                    local bridge = GetBridgeRemote()
                    if bridge then
                        bridge:FireServer("Gamemodes", "Trial", "Join")
                        print('[Trial] Auto Join triggered at', os.date('%H:%M'))
                    end
                end
                trialJoinSent = true
            elseif minute ~= 0 and minute ~= 30 then
                trialJoinSent = false
            end
        else
            trialJoinSent = false
        end
    end
end)

-- Auto Farm loop (only inside active Trial)
task.spawn(function()
    local canTeleport = true
    while task.wait(1) do
        if not TrialAutoFarmToggle then break end
        if TrialAutoFarmToggle.Values.CurrentValue and IsTrialActive() then
            local enemy = GetTrialEnemy()
            if enemy and canTeleport then
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    local playerHrp = player.Character:FindFirstChild('HumanoidRootPart')
                    if playerHrp then
                        playerHrp.CFrame = enemy.CFrame
                        canTeleport = false
                        print('[Trial Farm] Teleported to:', enemy.Name, '| Position:', tostring(enemy.Position))
                        task.delay(2, function()
                            canTeleport = true
                        end)
                    end
                end
            elseif not enemy then
                print('[Trial Farm] No enemies left - waiting for next wave...')
            end

            -- Check wave target for auto leave (handled by separate loop)
        end
    end
end)

-- Auto Exit at Wave loop (only inside active Trial)
task.spawn(function()
    local exiting = false
    while task.wait(1) do
        if not TrialAutoExitToggle then break end
        if TrialAutoExitToggle.Values.CurrentValue and not exiting and IsTrialActive() then
            local waveInput = TrialWaveInput and TrialWaveInput.Values.CurrentValue or nil
            if waveInput and waveInput ~= '' then
                local targetWave = tonumber(waveInput)
                if targetWave then
                    local currentWave = GetCurrentWave()
                    if currentWave and currentWave >= targetWave then
                        exiting = true
                        print('[Trial] Wave', currentWave, 'reached target (', targetWave, ') - Leaving trial!')
                        local bridge = GetBridgeRemote()
                        if bridge then
                            bridge:FireServer("Gamemodes", "Trial", "Leave")
                            print('[Trial] Left trial!')
                        end
                        task.delay(1, function()
                            exiting = false
                        end)
                    end
                end
            end
        end
    end
end)

TrialAutoJoinToggle = TrialGroupbox:CreateToggle({
    Name = "Auto Join",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Trial Auto Join changed to:', Value)
    end,
}, "TrialAutoJoinToggle")

TrialAutoFarmToggle = TrialGroupbox:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Trial Auto Farm changed to:', Value)
    end,
}, "TrialAutoFarmToggle")

TrialAutoExitToggle = TrialGroupbox:CreateToggle({
    Name = "Auto Exit at Wave",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Trial Auto Exit at Wave changed to:', Value)
    end,
}, "TrialAutoExitToggle")

TrialGroupbox:CreateDivider()

TrialWaveInput = TrialGroupbox:CreateInput({
    Name = "Wave",
    CurrentValue = "",
    PlaceholderText = "Enter wave number...",
    Numeric = true,
    Callback = function(Text)
        print('[cb] Trial Wave Input:', Text)
    end,
}, "TrialWaveInput")

-- ============================================
-- AUTO TOWER
-- ============================================
TowerAutoCreateToggle = TowerGroupbox:CreateToggle({
    Name = "AutoCreate",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Tower AutoCreate changed to:', Value)
        if Value then
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Create")
                print('[Tower] AutoCreate triggered!')
            end
        end
    end,
}, "TowerAutoCreateToggle")

TowerAutoJoinToggle = TowerGroupbox:CreateToggle({
    Name = "AutoJoin",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Tower AutoJoin changed to:', Value)
        if Value then
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Join")
                print('[Tower] AutoJoin triggered!')
            end
        end
    end,
}, "TowerAutoJoinToggle")

TowerAutoFarmToggle = TowerGroupbox:CreateToggle({
    Name = "AutoFarm",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Tower AutoFarm changed to:', Value)
    end,
}, "TowerAutoFarmToggle")

TowerAutoExitToggle = TowerGroupbox:CreateToggle({
    Name = "Auto Exit at Wave",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Tower Auto Exit at Wave changed to:', Value)
    end,
}, "TowerAutoExitToggle")

TowerGroupbox:CreateDivider()

TowerWaveInput = TowerGroupbox:CreateInput({
    Name = "Wave",
    CurrentValue = "",
    PlaceholderText = "Enter wave number...",
    Numeric = true,
    Callback = function(Text)
        print('[cb] Tower Wave Input:', Text)
    end,
}, "TowerWaveInput")

-- Global trial time blocker: true durante todos os 60 segundos dos minutos :00 e :30
local function IsTrialTime()
    local minute = tonumber(os.date('%M')) or 0
    local second = tonumber(os.date('%S')) or 0
    -- Bloqueia durante todos os 60s dos minutos :00 e :30 + 10s extras do próximo minuto
    if minute == 0 or minute == 30 then
        return true
    end
    if minute == 1 and second <= 10 then
        return true
    end
    if minute == 31 and second <= 10 then
        return true
    end
    return false
end

-- Auto Create loop: cria automaticamente a cada 30 segundos (only if not in Trial AND not in Tower AND not Trial time)
task.spawn(function()
    while task.wait(30) do
        if not TowerAutoCreateToggle then break end
        if TowerAutoCreateToggle.Values.CurrentValue and not IsTrialActive() and not IsTowerActive() and not IsTrialTime() then
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Create")
                print('[Tower] AutoCreate triggered at', os.date('%H:%M:%S'))
            end
        end
    end
end)

-- Auto Join loop: entra automaticamente a cada 1 segundo (only if not in Trial AND not in Tower AND not Trial time)
local towerJoinCooldown = false
task.spawn(function()
    while task.wait(1) do
        if not TowerAutoJoinToggle then break end
        -- Bloqueia completamente durante minutos :00 e :30
        if TowerAutoJoinToggle.Values.CurrentValue and not IsTrialActive() and not IsTowerActive() and not towerJoinCooldown and not IsTrialTime() then
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Join")
                print('[Tower] AutoJoin triggered at', os.date('%H:%M:%S'))
                towerJoinCooldown = true
                task.delay(5, function()
                    towerJoinCooldown = false
                end)
            end
        end
    end
end)

-- Auto Farm loop (only inside active Tower, not in Trial)
task.spawn(function()
    local canTeleport = true
    while task.wait(1) do
        if not TowerAutoFarmToggle then break end
        if TowerAutoFarmToggle.Values.CurrentValue and IsTowerActive() and not IsTrialActive() then
            local enemy = GetTowerEnemy()
            if enemy and canTeleport then
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    local playerHrp = player.Character:FindFirstChild('HumanoidRootPart')
                    if playerHrp then
                        playerHrp.CFrame = enemy.CFrame
                        canTeleport = false
                        print('[Tower Farm] Teleported to:', enemy.Name, '| Position:', tostring(enemy.Position))
                        task.delay(2, function()
                            canTeleport = true
                        end)
                    end
                end
            elseif not enemy then
                print('[Tower Farm] No enemies left - waiting for next wave...')
            end
        end
    end
end)

-- Auto Exit at Wave + Create/Join after exit (also exits when Trial time arrives)
task.spawn(function()
    local exiting = false
    while task.wait(1) do
        if not TowerAutoExitToggle then break end
        -- Sair da Tower se for horário de Trial (durante TODOS os 60 segundos dos minutos :00 e :30)
        if not exiting and IsTowerActive() and IsTrialTime() and not IsTrialActive() then
            exiting = true
            print('[Tower] Trial time - Leaving tower!')
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Leave")
                print('[Tower] Left tower for Trial!')
            end
            task.delay(3, function()
                exiting = false
            end)
        end
        if TowerAutoExitToggle.Values.CurrentValue and not exiting then
            local waveInput = TowerWaveInput and TowerWaveInput.Values.CurrentValue or nil
            if waveInput and waveInput ~= '' then
                local targetWave = tonumber(waveInput)
                if targetWave then
                    local currentWave = GetCurrentTowerWave()
                    if currentWave and currentWave >= targetWave then
                        exiting = true
                        print('[Tower] Wave', currentWave, 'reached target (', targetWave, ') - Leaving tower!')
                        local bridge = GetBridgeRemote()
                        if bridge then
                            bridge:FireServer("Gamemodes", "TowerRaid", "Leave")
                            print('[Tower] Left tower!')
                            -- Create 2s after exit (only if not Trial time)
                            task.delay(2, function()
                                if not IsTrialTime() then
                                    if TowerAutoCreateToggle and TowerAutoCreateToggle.Values.CurrentValue then
                                        local bridge2 = GetBridgeRemote()
                                        if bridge2 then
                                            bridge2:FireServer("Gamemodes", "TowerRaid", "Create")
                                            print('[Tower] AutoCreate triggered after exit!')
                                            -- Join immediately after create
                                            if TowerAutoJoinToggle and TowerAutoJoinToggle.Values.CurrentValue then
                                                local bridge3 = GetBridgeRemote()
                                                if bridge3 then
                                                    bridge3:FireServer("Gamemodes", "TowerRaid", "Join")
                                                    print('[Tower] AutoJoin triggered after create!')
                                                end
                                            end
                                        end
                                    end
                                else
                                    print('[Tower] Trial time - skipping Create/Join after exit')
                                end
                                exiting = false
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================
-- DESTROY HANDLER
-- ============================================
Starlight:OnDestroy(function()
    print('[Noquitis Hub] Unloaded!')
end)

-- ============================================
-- CONFIG SECTION
-- ============================================
local ConfigTab = Window:CreateTabSection("UI Settings")
local ConfigTabInstance = ConfigTab:CreateTab({
    Name = "UI Settings",
    Columns = 2,
}, "ConfigTab")

ConfigTabInstance:BuildConfigGroupbox(1)
Starlight:LoadAutoloadConfig()
