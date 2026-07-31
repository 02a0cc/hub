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

local RaidGroupbox = TowerTab:CreateGroupbox({
    Name = "AutoRaid",
    Column = 2,
}, "RaidGroupbox")

local TraitGroupbox = MainTab:CreateGroupbox({
    Name = "Auto Trait",
    Column = 2,
}, "TraitGroupbox")

local RollStarsGroupbox = MainTab:CreateGroupbox({
    Name = "Auto RollStars",
    Column = 1,
}, "RollStarsGroupbox")

local StatsRerollGroupbox = MainTab:CreateGroupbox({
    Name = "Auto Stats Reroll",
    Column = 1,
}, "StatsRerollGroupbox")

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

-- Fighter Dropdown (multi-select)
local FighterLabel = TraitGroupbox:CreateLabel({
    Name = "Select Fighters"
}, "FighterLabel")

-- selectedTraitFighters guarda a seleção do dropdown.
-- traitQueue guarda apenas os fighters que ainda precisam receber uma trait alvo.
local selectedTraitFighters = {}
local traitQueue = {}

local function ResetTraitQueue()
    traitQueue = {}
    for _, fighter in ipairs(selectedTraitFighters) do
        table.insert(traitQueue, fighter)
    end
end

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
    MultipleOptions = true,
    Callback = function(Options)
        selectedTraitFighters = {}
        if Options then
            local fighters = GetFighters()
            for _, opt in ipairs(Options) do
                local text = type(opt) == "table" and opt.Text or tostring(opt)
                for _, fighter in ipairs(fighters) do
                    if fighter.Display == text then
                        table.insert(selectedTraitFighters, fighter)
                        break
                    end
                end
            end
        end

        -- Se a seleção mudar, reinicia a fila com os fighters atualmente marcados.
        ResetTraitQueue()

        local displays = {}
        for _, fighter in ipairs(selectedTraitFighters) do
            table.insert(displays, fighter.Display)
        end
        print('[cb] FighterDropdown changed:', #selectedTraitFighters, 'fighters selected:', table.concat(displays, ", "))
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
        if Value then
            -- Cada nova ativação reprocessa todos os fighters marcados.
            ResetTraitQueue()
        end
        print('[cb] Auto Trait changed to:', Value)
    end,
}, "AutoTraitToggle")

-- Auto Trait loop: mantém o primeiro fighter da fila até ele receber uma trait alvo.
-- Ao concluir, remove somente esse fighter e passa automaticamente para o próximo.
local traitCooldown = false
task.spawn(function()
    while task.wait(0.01) do
        if not AutoTraitToggle then break end
        if AutoTraitToggle.Values.CurrentValue and not traitCooldown then
            if #traitQueue > 0 and #selectedTraits > 0 then
                local currentFighter = traitQueue[1]
                local currentTrait = GetCurrentFighterTrait(currentFighter.UUID)

                if currentTrait and table.find(selectedTraits, currentTrait) then
                    table.remove(traitQueue, 1)
                    print('[Trait] Fighter completed:', currentFighter.Display, '| Trait:', currentTrait, '| Remaining:', #traitQueue)

                    if #traitQueue == 0 then
                        print('[Trait] All selected fighters have a target trait - Stopping!')
                        AutoTraitToggle.Values.CurrentValue = false
                    end
                else
                    local traitRemote = GetTraitRemote()
                    if traitRemote then
                        traitCooldown = true
                        print('[Trait] Applying trait on:', currentFighter.Display, '| Current:', currentTrait or 'None', '| Target:', table.concat(selectedTraits, ", "))
                        traitRemote:InvokeServer(currentFighter.UUID)
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
-- BRIDGE REMOTE (usado por RollStars e Trial/Tower)
-- ============================================
local function GetBridgeRemote()
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs:WaitForChild("Remotes", 10)
    if remotes then
        return remotes:WaitForChild("Bridge", 10)
    end
    return nil
end

-- ============================================
-- AUTO ROLLSTARS
-- ============================================
local rollStarsSelectedFighters = {}
local RollStarsLabel = RollStarsGroupbox:CreateLabel({
    Name = "Select Fighters"
}, "RollStarsLabel")

local RollStarsDropdown = RollStarsLabel:AddDropdown({
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
    MultipleOptions = true,
    Callback = function(Options)
        rollStarsSelectedFighters = {}
        if Options then
            for _, opt in ipairs(Options) do
                local text = type(opt) == "table" and opt.Text or tostring(opt)
                local fighters = GetFighters()
                for _, f in ipairs(fighters) do
                    if f.Display == text then
                        table.insert(rollStarsSelectedFighters, f)
                        break
                    end
                end
            end
        end
        local displays = {}
        for _, f in ipairs(rollStarsSelectedFighters) do
            table.insert(displays, f.Display)
        end
        print('[cb] RollStarsDropdown changed:', #rollStarsSelectedFighters, 'fighters:', table.concat(displays, ", "))
    end,
}, "RollStarsDropdown")

RollStarsGroupbox:CreateDivider()

local AutoRollStarsToggle = RollStarsGroupbox:CreateToggle({
    Name = "Auto RollStars",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Auto RollStars changed to:', Value)
    end,
}, "AutoRollStarsToggle")

-- Auto RollStars loop (roda para todos os fighters selecionados)
local rollStarsIndex = 1
task.spawn(function()
    while task.wait(0.01) do
        if not AutoRollStarsToggle then break end
        if AutoRollStarsToggle.Values.CurrentValue and #rollStarsSelectedFighters > 0 then
            local bridge = GetBridgeRemote()
            if bridge then
                local fighter = rollStarsSelectedFighters[rollStarsIndex]
                if fighter then
                    print('[RollStars] Rerolling:', fighter.Display)
                    bridge:FireServer("General", "RollStars", "Reroll", fighter.UUID)
                end
                rollStarsIndex = rollStarsIndex % #rollStarsSelectedFighters + 1
            else
                print('[RollStars] Bridge remote not found!')
            end
        end
    end
end)

-- ============================================
-- AUTO STATS REROLL
-- ============================================

local statsRerollSelectedFighters = {}
local statsRerollQueue = {}

local function ResetStatsRerollQueue()
    statsRerollQueue = {}
    for _, fighter in ipairs(statsRerollSelectedFighters) do
        table.insert(statsRerollQueue, fighter)
    end
end

local StatsRerollDropdown = StatsRerollGroupbox:CreateLabel({
    Name = "Select Fighters"
}, "StatsRerollLabel"):AddDropdown({
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
    MultipleOptions = true,
    Callback = function(Options)
        statsRerollSelectedFighters = {}
        if Options then
            for _, opt in ipairs(Options) do
                local text = type(opt) == "table" and opt.Text or tostring(opt)
                local fighters = GetFighters()
                for _, f in ipairs(fighters) do
                    if f.Display == text then
                        table.insert(statsRerollSelectedFighters, f)
                        break
                    end
                end
            end
        end
        -- Reinicia a fila com os fighters selecionados
        ResetStatsRerollQueue()
        local displays = {}
        for _, f in ipairs(statsRerollSelectedFighters) do
            table.insert(displays, f.Display)
        end
        print('[cb] StatsRerollDropdown changed:', #statsRerollSelectedFighters, 'fighters:', table.concat(displays, ", "))
    end,
}, "StatsRerollDropdown")

StatsRerollGroupbox:CreateDivider()

local StatTypeLabel = StatsRerollGroupbox:CreateLabel({
    Name = "Select Stats"
}, "StatTypeLabel")

local selectedStats = {}
local StatTypeDropdown = StatTypeLabel:AddDropdown({
    Options = {"Damage", "UltimateDamage", "SpeedAttack"},
    CurrentOptions = {},
    Placeholder = "Select stats...",
    MultipleOptions = true,
    Callback = function(Options)
        selectedStats = {}
        if Options then
            for _, opt in ipairs(Options) do
                local text = type(opt) == "table" and opt.Text or tostring(opt)
                table.insert(selectedStats, text)
            end
        end
        print('[cb] StatTypeDropdown changed:', table.concat(selectedStats, ", "))
    end,
}, "StatTypeDropdown")

StatsRerollGroupbox:CreateDivider()

local StatValueLabel = StatsRerollGroupbox:CreateLabel({
    Name = "Select Target Values"
}, "StatValueLabel")

local selectedTargetValues = {}
local StatValueDropdown = StatValueLabel:AddDropdown({
    Options = {"S+", "S", "A", "B", "C", "D", "E"},
    CurrentOptions = {},
    Placeholder = "Select values...",
    MultipleOptions = true,
    Callback = function(Options)
        selectedTargetValues = {}
        if Options then
            for _, opt in ipairs(Options) do
                local text = type(opt) == "table" and opt.Text or tostring(opt)
                table.insert(selectedTargetValues, text)
            end
        end
        print('[cb] StatValueDropdown changed:', table.concat(selectedTargetValues, ", "))
    end,
}, "StatValueDropdown")

StatsRerollGroupbox:CreateDivider()

local AutoStatsRerollToggle = StatsRerollGroupbox:CreateToggle({
    Name = "Auto Stats Reroll",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        if Value then
            ResetStatsRerollQueue()
        end
        print('[cb] Auto Stats Reroll changed to:', Value)
    end,
}, "AutoStatsRerollToggle")

-- Estado de lock por fighter: { [UUID] = { Damage = true, SpeedAttack = false, ... } }
local statsLocked = {}

-- Capturar resposta do Bridge: OnClientEvent recebe (category, sub, action, patches)
-- onde patches é um array de { Value = "...", Path = { "Fighters", UUID, "Stats", statName } }
local statsResponses = {}
local bridgeForStats = GetBridgeRemote()
if bridgeForStats then
    bridgeForStats.OnClientEvent:Connect(function(category, sub, action, patches)
        if category == "Data" and sub == "Manager" and action == "Patch" and type(patches) == "table" then
            statsResponses = patches
            print('[Stats Reroll] Received', #patches, 'patches')
            for i, p in ipairs(patches) do
                if type(p) == "table" and p.Path then
                    -- Path pode vir como tabela { "Fighters", UUID, "Stats", statName }
                    local pathStr = type(p.Path) == "table" and table.concat(p.Path, ".") or tostring(p.Path)
                    local patchUUID = nil
                    local patchStat = nil
                    
                    if type(p.Path) == "table" and #p.Path >= 4 then
                        patchUUID = p.Path[2]
                        patchStat = p.Path[4]
                    else
                        local matchUUID = pathStr:match("Fighters%.([^%.]+)%.Stats%.")
                        local matchStat = pathStr:match("Stats%.(.+)")
                        if matchUUID and matchStat then
                            patchUUID = matchUUID
                            patchStat = matchStat
                        end
                    end
                    
                    if patchUUID and patchStat then
                        local patchValue = tostring(p.Value)
                        print('[Stats Reroll]   [' .. i .. '] Fighter=' .. patchUUID .. ' Stat=' .. patchStat .. ' Value=' .. patchValue)
                        
                        -- Verificar se é uma stat selecionada e se bate com algum target
                        for _, stat in ipairs(selectedStats) do
                            if stat == patchStat then
                                for _, target in ipairs(selectedTargetValues) do
                                    if patchValue == target then
                                        print('[Stats Reroll] LOCKING', patchStat, '=', patchValue)
                                        if not statsLocked[patchUUID] then
                                            statsLocked[patchUUID] = {}
                                        end
                                        statsLocked[patchUUID][patchStat] = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto Stats Reroll loop (mesmo padrão do Auto Trait: fila separada da seleção)
local statsCooldown = false
task.spawn(function()
    while task.wait(0.4) do
        if not AutoStatsRerollToggle then break end
        if AutoStatsRerollToggle.Values.CurrentValue and not statsCooldown then
            if #statsRerollQueue > 0 and #selectedStats > 0 and #selectedTargetValues > 0 then
                local fighter = statsRerollQueue[1]
                if fighter then
                    -- Enviar Reroll com locks
                    local locks = {}
                    local statsToRoll = {}
                    for _, statName in ipairs(selectedStats) do
                        if statsLocked[fighter.UUID] and statsLocked[fighter.UUID][statName] then
                            locks[statName] = true
                        else
                            table.insert(statsToRoll, statName)
                        end
                    end
                    
                    local bridge = GetBridgeRemote()
                    if bridge and #statsToRoll > 0 then
                        statsCooldown = true
                        print('[Stats Reroll] Rolling:', fighter.Display, '| Stats:', table.concat(statsToRoll, ", "))
                        bridge:FireServer("General", "Stats", "Reroll", fighter.UUID, locks, true)
                        
                        task.delay(0.4, function()
                            statsCooldown = false
                        end)
                    elseif bridge and #statsToRoll == 0 then
                        -- Todas as stats já estão locked para este fighter
                        table.remove(statsRerollQueue, 1)
                        print('[Stats Reroll] Fighter completed:', fighter.Display, '| Remaining:', #statsRerollQueue)
                        if #statsRerollQueue == 0 then
                            print('[Stats Reroll] All fighters completed - Stopping!')
                            pcall(function()
                                AutoStatsRerollToggle.Values.CurrentValue = false
                            end)
                        end
                    end
                end
            end
        end
    end
end)


-- ============================================
-- TRIAL/RAIDS TAB
-- ============================================

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

local function GetCurrentRaidWave()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local waveFrame = playerGui:FindFirstChild("UI") and playerGui.UI:FindFirstChild("HUD") and playerGui.UI.HUD:FindFirstChild("Tower") and playerGui.UI.HUD.Tower:FindFirstChild("Frame") and playerGui.UI.HUD.Tower.Frame:FindFirstChild("Wave")
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

local function GetRaidEnemy()
    local Server = game.Workspace:FindFirstChild('Server')
    if not Server then return nil end
    local Raid = Server:FindFirstChild('Tower')
    if not Raid then return nil end
    local Enemies = Raid:FindFirstChild('Enemies')
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

local function IsRaidActive()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local hud = playerGui:FindFirstChild("UI") and playerGui.UI:FindFirstChild("HUD")
    if not hud then return false end
    local raid = hud:FindFirstChild("Tower")
    return raid and raid.Visible or false
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
                local bridge = GetBridgeRemote()
                if bridge then
                    if IsRaidActive() then
                        bridge:FireServer("Gamemodes", "Tower", "Leave")
                        print('[Trial] Leaving Raid before Trial at', os.date('%H:%M'))
                        task.delay(2, function()
                            local bridge2 = GetBridgeRemote()
                            if bridge2 then
                                bridge2:FireServer("Gamemodes", "Trial", "Join")
                                print('[Trial] Auto Join triggered at', os.date('%H:%M'))
                            end
                        end)
                    elseif IsTowerActive() then
                        bridge:FireServer("Gamemodes", "TowerRaid", "Leave")
                        print('[Trial] Leaving TowerRaid before Trial at', os.date('%H:%M'))
                        task.delay(2, function()
                            local bridge2 = GetBridgeRemote()
                            if bridge2 then
                                bridge2:FireServer("Gamemodes", "Trial", "Join")
                                print('[Trial] Auto Join triggered at', os.date('%H:%M'))
                            end
                        end)
                    else
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

-- Bloqueia modos de menor prioridade durante a janela de Trial.
local function IsTrialTime()
    local minute = tonumber(os.date('%M')) or 0
    local second = tonumber(os.date('%S')) or 0
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

-- Raid tem prioridade sobre TowerRaid quando o jogador pediu Create ou Join.
local function IsRaidPriorityEnabled()
    return (RaidAutoCreateToggle and RaidAutoCreateToggle.Values.CurrentValue)
        or (RaidAutoJoinToggle and RaidAutoJoinToggle.Values.CurrentValue)
end

local function IsTowerBlockedByPriority()
    return IsTrialActive() or IsTrialTime() or IsRaidActive() or IsRaidPriorityEnabled()
end

-- Raid pode interromper TowerRaid, mas nunca uma Trial ativa ou iminente.
local function RunRaidAction(action, source)
    if IsTrialActive() or IsTrialTime() then
        print('[Raid] Trial has priority - skipping', source)
        return
    end

    local bridge = GetBridgeRemote()
    if not bridge then return end

    if IsTowerActive() then
        bridge:FireServer("Gamemodes", "TowerRaid", "Leave")
        print('[Raid] Leaving TowerRaid for Raid priority')
        task.delay(2, function()
            if not IsTrialActive() and not IsTrialTime() and not IsTowerActive() and not IsRaidActive() then
                local bridge2 = GetBridgeRemote()
                if bridge2 then
                    bridge2:FireServer("Gamemodes", "Tower", action)
                    print('[Raid]', source, 'triggered after leaving TowerRaid!')
                end
            end
        end)
    elseif not IsRaidActive() then
        bridge:FireServer("Gamemodes", "Tower", action)
        print('[Raid]', source, 'triggered!')
    end
end

-- ============================================
-- AUTO TOWER
-- ============================================
TowerAutoCreateToggle = TowerGroupbox:CreateToggle({
    Name = "AutoCreate",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Tower AutoCreate changed to:', Value)
        if Value and not IsTowerActive() and not IsTowerBlockedByPriority() then
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Create")
                print('[Tower] AutoCreate triggered!')
            end
        elseif Value then
            print('[Tower] Higher-priority mode is active - skipping AutoCreate')
        end
    end,
}, "TowerAutoCreateToggle")

TowerAutoJoinToggle = TowerGroupbox:CreateToggle({
    Name = "AutoJoin",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Tower AutoJoin changed to:', Value)
        if Value and not IsTowerActive() and not IsTowerBlockedByPriority() then
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Join")
                print('[Tower] AutoJoin triggered!')
            end
        elseif Value then
            print('[Tower] Higher-priority mode is active - skipping AutoJoin')
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

-- ============================================
-- AUTO RAID
-- ============================================
RaidAutoCreateToggle = RaidGroupbox:CreateToggle({
    Name = "AutoCreate",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Raid AutoCreate changed to:', Value)
        if Value then
            RunRaidAction("Create", "AutoCreate")
        end
    end,
}, "RaidAutoCreateToggle")

RaidAutoJoinToggle = RaidGroupbox:CreateToggle({
    Name = "AutoJoin",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Raid AutoJoin changed to:', Value)
        if Value then
            RunRaidAction("Join", "AutoJoin")
        end
    end,
}, "RaidAutoJoinToggle")

RaidAutoFarmToggle = RaidGroupbox:CreateToggle({
    Name = "AutoFarm",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Raid AutoFarm changed to:', Value)
    end,
}, "RaidAutoFarmToggle")

RaidAutoExitToggle = RaidGroupbox:CreateToggle({
    Name = "Auto Exit at Wave",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        print('[cb] Raid Auto Exit at Wave changed to:', Value)
    end,
}, "RaidAutoExitToggle")

RaidGroupbox:CreateDivider()

RaidWaveInput = RaidGroupbox:CreateInput({
    Name = "Wave",
    CurrentValue = "",
    PlaceholderText = "Enter wave number...",
    Numeric = true,
    Callback = function(Text)
        print('[cb] Raid Wave Input:', Text)
    end,
}, "RaidWaveInput")

-- Auto Create loop: cria automaticamente a cada 30 segundos (only if not in Trial AND not in Tower AND not Trial time)
task.spawn(function()
    while task.wait(30) do
        if not TowerAutoCreateToggle then break end
        if TowerAutoCreateToggle.Values.CurrentValue and not IsTowerActive() and not IsTowerBlockedByPriority() then
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
        if TowerAutoJoinToggle.Values.CurrentValue and not IsTowerActive() and not towerJoinCooldown and not IsTowerBlockedByPriority() then
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
        if TowerAutoFarmToggle.Values.CurrentValue and IsTowerActive() and not IsTrialActive() and not IsRaidActive() then
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
        -- TowerRaid cede espaço para Trial e Raid.
        if not exiting and IsTowerActive() and (IsTrialActive() or IsTrialTime() or IsRaidActive() or IsRaidPriorityEnabled()) then
            exiting = true
            local priorityName = (IsTrialActive() or IsTrialTime()) and "Trial" or "Raid"
            print('[Tower] ' .. priorityName .. ' has priority - Leaving TowerRaid!')
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "TowerRaid", "Leave")
                print('[Tower] Left TowerRaid for ' .. priorityName .. '!')
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
                                if not IsTowerBlockedByPriority() then
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
                                    print('[Tower] Higher-priority mode - skipping Create/Join after exit')
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
-- AUTO RAID LOOPS
-- ============================================
task.spawn(function()
    while task.wait(30) do
        if not RaidAutoCreateToggle then break end
        if RaidAutoCreateToggle.Values.CurrentValue and not IsTrialActive() and not IsTrialTime() then
            RunRaidAction("Create", "AutoCreate")
        end
    end
end)

local raidJoinCooldown = false
task.spawn(function()
    while task.wait(1) do
        if not RaidAutoJoinToggle then break end
        if RaidAutoJoinToggle.Values.CurrentValue and not raidJoinCooldown and not IsTrialActive() and not IsTrialTime() then
            RunRaidAction("Join", "AutoJoin")
            raidJoinCooldown = true
            task.delay(5, function()
                raidJoinCooldown = false
            end)
        end
    end
end)

task.spawn(function()
    local canTeleport = true
    while task.wait(1) do
        if not RaidAutoFarmToggle then break end
        if RaidAutoFarmToggle.Values.CurrentValue and IsRaidActive() and not IsTrialActive() and not IsTrialTime() then
            local enemy = GetRaidEnemy()
            if enemy and canTeleport then
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    local playerHrp = player.Character:FindFirstChild('HumanoidRootPart')
                    if playerHrp then
                        playerHrp.CFrame = enemy.CFrame
                        canTeleport = false
                        print('[Raid Farm] Teleported to:', enemy.Name, '| Position:', tostring(enemy.Position))
                        task.delay(2, function()
                            canTeleport = true
                        end)
                    end
                end
            elseif not enemy then
                print('[Raid Farm] No enemies left - waiting for next wave...')
            end
        end
    end
end)

task.spawn(function()
    local exiting = false
    while task.wait(1) do
        if not RaidAutoExitToggle then break end
        if not exiting and IsRaidActive() and (IsTrialActive() or IsTrialTime()) then
            exiting = true
            print('[Raid] Trial has priority - Leaving Raid!')
            local bridge = GetBridgeRemote()
            if bridge then
                bridge:FireServer("Gamemodes", "Tower", "Leave")
                print('[Raid] Left Raid for Trial!')
            end
            task.delay(3, function()
                exiting = false
            end)
        end
        if RaidAutoExitToggle.Values.CurrentValue and not exiting then
            local waveInput = RaidWaveInput and RaidWaveInput.Values.CurrentValue or nil
            if waveInput and waveInput ~= '' then
                local targetWave = tonumber(waveInput)
                if targetWave then
                    local currentWave = GetCurrentRaidWave()
                    if currentWave and currentWave >= targetWave then
                        exiting = true
                        print('[Raid] Wave', currentWave, 'reached target (', targetWave, ') - Leaving raid!')
                        local bridge = GetBridgeRemote()
                        if bridge then
                            bridge:FireServer("Gamemodes", "Tower", "Leave")
                            print('[Raid] Left raid!')
                            task.delay(2, function()
                                if not IsTrialActive() and not IsTrialTime() then
                                    if RaidAutoCreateToggle and RaidAutoCreateToggle.Values.CurrentValue then
                                        local bridge2 = GetBridgeRemote()
                                        if bridge2 then
                                            bridge2:FireServer("Gamemodes", "Tower", "Create")
                                            print('[Raid] AutoCreate triggered after exit!')
                                            if RaidAutoJoinToggle and RaidAutoJoinToggle.Values.CurrentValue then
                                                local bridge3 = GetBridgeRemote()
                                                if bridge3 then
                                                    bridge3:FireServer("Gamemodes", "Tower", "Join")
                                                    print('[Raid] AutoJoin triggered after create!')
                                                end
                                            end
                                        end
                                    end
                                else
                                    print('[Raid] Trial has priority - skipping Create/Join after exit')
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
-- ANTI AFK (roda automaticamente ao injetar)
-- Simula input local de clique em vez de mover o personagem.
-- ============================================
task.spawn(function()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local virtualInput = nil
    local virtualUser = nil
    local lastClick = 0

    pcall(function()
        virtualInput = game:GetService("VirtualInputManager")
    end)
    pcall(function()
        virtualUser = game:GetService("VirtualUser")
    end)

    local function SimulateLocalClick(source)
        -- Evita dois cliques quase ao mesmo tempo se o Idled disparar junto do timer.
        if os.clock() - lastClick < 2 then
            return
        end
        lastClick = os.clock()

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        -- Clique direito no canto da tela para evitar ativar botões da interface do jogo.
        local x = math.max(2, viewport.X - 2)
        local y = math.max(2, viewport.Y - 2)
        local sent = false

        if virtualInput then
            local inputSuccess = pcall(function()
                -- MouseButton2: clique direito local, pressionar e soltar.
                virtualInput:SendMouseButtonEvent(x, y, 1, true, game, 0)
                task.wait(0.05)
                virtualInput:SendMouseButtonEvent(x, y, 1, false, game, 0)
            end)
            sent = inputSuccess
        end

        -- Fallback para executores que não expõem VirtualInputManager.
        if not sent and virtualUser then
            sent = pcall(function()
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.new(x, y))
            end)
        end

        if sent then
            print('[Anti-AFK] Local click simulated (' .. source .. ').')
        else
            print('[Anti-AFK] Unable to simulate local input in this executor.')
        end
    end

    -- Dispara uma atividade periódica e também reage ao aviso de inatividade do Roblox.
    player.Idled:Connect(function()
        SimulateLocalClick('Idled')
    end)

    print('[Anti-AFK] Running with local click simulation!')
    while task.wait(60) do
        SimulateLocalClick('Timer')
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
