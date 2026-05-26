-- LOCAL SCRIPT (StarterPlayerScripts)
-- With Password System & Smooth Transition
-- [ULTRA ANTI-BAN EDITION] - Mobile Optimized
-- CLEAN UI - All Elements Inside Background

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- ENHANCED ANTI-BAN / STEALTH CONFIGURATION
--------------------------------------------------
local ANTIBAN = {
    RANDOM_DELAYS = true,
    RANDOM_MOVEMENT = true,
    FAKE_ERRORS = false,
    USE_LOW_PROFILE = true,
    DETECTION_BYPASS = true,
    FAKE_TELEMETRY = true,
    SPOOF_REMOTE_EVENTS = true,
}

math.randomseed(os.time() * LocalPlayer.UserId * math.random(1000, 9999))

local function randomDelay(min, max)
    if ANTIBAN.RANDOM_DELAYS then
        local delay = (min or 0.03) + math.random() * ((max or 0.15) - (min or 0.03))
        task.wait(delay)
    else
        task.wait(0.03)
    end
end

if ANTIBAN.FAKE_TELEMETRY then
    task.spawn(function()
        while task.wait(math.random(45, 120)) do
            pcall(function() end)
        end
    end)
end

--------------------------------------------------
-- PASSWORD CONFIGURATION
--------------------------------------------------
local CONFIG = {
    PASSWORD = "KenapaNyak",
    MAX_ATTEMPTS = 3,
    LOCKOUT_TIME = 60,
}

local isAuthenticated = false
local authAttempts = 0
local lockoutUntil = 0

--------------------------------------------------
-- PASSWORD GUI
--------------------------------------------------
local authGui = nil
local mainGui = nil

local function showError(message)
    local errorFrame = Instance.new("Frame")
    errorFrame.Size = UDim2.new(0, 280, 0, 40)
    errorFrame.Position = UDim2.new(0.5, -140, 0.8, 0)
    errorFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    errorFrame.BackgroundTransparency = 0.2
    errorFrame.Parent = authGui
    
    local errorCorner = Instance.new("UICorner")
    errorCorner.CornerRadius = UDim.new(0, 8)
    errorCorner.Parent = errorFrame
    
    local errorText = Instance.new("TextLabel")
    errorText.Size = UDim2.new(1, 0, 1, 0)
    errorText.BackgroundTransparency = 1
    errorText.Text = message
    errorText.TextColor3 = Color3.new(1, 1, 1)
    errorText.TextSize = 14
    errorText.Font = Enum.Font.GothamBold
    errorText.Parent = errorFrame
    
    task.spawn(function()
        task.wait(2.5)
        if errorFrame then
            errorFrame:Destroy()
        end
    end)
end

local function createMainGUI()
    local STATE = {
        ESP_WANTED = false,
        ESP_PLAYERS = false,
        HITBOX = false,
        INSTANT_PROMPT = false,
        AUTO_ATM = false,
        SIZE = 30
    }

    local Objects = {}
    local BigHeadData = {}
    local BigHeadPaused = {}
    local EnforcementConnection = nil
    local PlayerConnections = {}
    local ActiveTweens = {}
    local ESPUpdateConnection = nil

    local PromptConnections = {}
    local InstantPromptEnabled = false
    
    local wantedPlayers = {}
    
    --------------------------------------------------
    -- WANTED SYSTEM DETECTION
    --------------------------------------------------
    local function updateWantedPlayers()
        wantedPlayers = {}
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local isWanted = false
                
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    local wanted = leaderstats:FindFirstChild("Wanted") or leaderstats:FindFirstChild("WantedLevel") or leaderstats:FindFirstChild("Stars")
                    if wanted and wanted.Value > 0 then
                        isWanted = true
                    end
                end
                
                if not isWanted then
                    local attributes = player:GetAttributes()
                    if attributes.Wanted or attributes.WantedLevel or attributes.Bounty then
                        isWanted = true
                    end
                end
                
                if not isWanted and player.Character then
                    local tag = player.Character:FindFirstChild("WantedTag") or player.Character:FindFirstChild("Wanted")
                    if tag then
                        isWanted = true
                    end
                end
                
                if isWanted then
                    wantedPlayers[player] = true
                end
            end
        end
        
        return wantedPlayers
    end

    --------------------------------------------------
    -- AUTO ATM
    --------------------------------------------------
    local ATMRunning = false
    local ATMTask = nil
    local ClickedButtons = {}
    local atmCheckConnection = nil
    local isATMOpen = false
    local lastATMProcess = 0
    
    local ATM_CONFIG = {
        CLICK_DELAY = 0.08,
        RANDOM_OFFSET = 3,
    }
    
    local cachedAtmGui = nil
    local cachedSequence = nil
    local cachedList = nil
    local cacheTime = 0
    
    local function getATMGui()
        local now = tick()
        if not cachedAtmGui or now - cacheTime > 0.5 then
            local success, result = pcall(function()
                local screenGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
                if not screenGui then return nil end
                local center = screenGui:FindFirstChild("Center")
                if not center then return nil end
                local middle = center:FindFirstChild("Middle")
                if not middle then return nil end
                local hacking = middle:FindFirstChild("HackingMinigames")
                if not hacking then return nil end
                return hacking:FindFirstChild("ATM Hack")
            end)
            
            if success and result then
                cachedAtmGui = result
                if cachedAtmGui then
                    cachedSequence = cachedAtmGui:FindFirstChild("Sequence1")
                    cachedList = cachedAtmGui:FindFirstChild("List")
                end
                cacheTime = now
            else
                cachedAtmGui = nil
                cachedSequence = nil
                cachedList = nil
            end
        end
        return cachedAtmGui, cachedSequence, cachedList
    end
    
    local function isATMCurrentlyOpen()
        local gui, _, _ = getATMGui()
        return gui and gui.Visible or false
    end
    
    local function GetCodes()
        local _, sequence, _ = getATMGui()
        if not sequence or sequence.Text == "" then return {} end
        local Codes = {}
        for Code in string.gmatch(sequence.Text, "([^%s]+)") do
            table.insert(Codes, Code)
        end
        return Codes
    end
    
    local function ClickButtonMobile(Button)
        local success, result = pcall(function()
            if not Button or not Button.Parent then return false end
            local Pos = Button.AbsolutePosition
            local Size = Button.AbsoluteSize
            if Pos.X <= 0 or Pos.Y <= 0 or Size.X <= 0 or Size.Y <= 0 then
                return false
            end
            local randomX = (math.random() - 0.5) * ATM_CONFIG.RANDOM_OFFSET
            local randomY = (math.random() - 0.5) * ATM_CONFIG.RANDOM_OFFSET
            local X = Pos.X + Size.X/2 + randomX
            local Y = Pos.Y + Size.Y/2 + randomY
            VirtualInputManager:SendMouseButtonEvent(X, Y, 0, true, game, 0)
            task.wait(0.02 + math.random() * 0.03)
            VirtualInputManager:SendMouseButtonEvent(X, Y, 0, false, game, 0)
            return true
        end)
        return success and result or false
    end
    
    local function scanATMHack()
        local _, _, list = getATMGui()
        if not list then return {} end
        local Codes = GetCodes()
        if #Codes == 0 then return {} end
        local BlockedColor = Color3.fromRGB(74, 75, 93)
        local buttonsToClick = {}
        local function findButtons(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ImageButton") then
                    if not ClickedButtons[child] and child.ImageColor3 ~= BlockedColor then
                        for _, label in ipairs(child:GetDescendants()) do
                            if label:IsA("TextLabel") and label.Text ~= "" then
                                for _, Code in ipairs(Codes) do
                                    if label.Text == Code then
                                        table.insert(buttonsToClick, child)
                                        break
                                    end
                                end
                                break
                            end
                        end
                    end
                end
                findButtons(child)
            end
        end
        findButtons(list)
        return buttonsToClick
    end
    
    local function processATMHack()
        if not STATE.AUTO_ATM then return end
        if not isATMOpen then return end
        local now = tick()
        if now - lastATMProcess < 0.05 then return end
        lastATMProcess = now
        local buttonsToClick = scanATMHack()
        if #buttonsToClick > 0 then
            for _, button in ipairs(buttonsToClick) do
                if ClickButtonMobile(button) then
                    ClickedButtons[button] = true
                    randomDelay(0.05, 0.1)
                end
            end
        else
            local anyUnclicked = false
            local _, _, list = getATMGui()
            if list then
                local BlockedColor = Color3.fromRGB(74, 75, 93)
                local function checkUnclicked(parent)
                    for _, child in ipairs(parent:GetChildren()) do
                        if child:IsA("ImageButton") then
                            if not ClickedButtons[child] and child.ImageColor3 ~= BlockedColor then
                                anyUnclicked = true
                                return
                            end
                        end
                        checkUnclicked(child)
                    end
                end
                checkUnclicked(list)
            end
            if not anyUnclicked then
                task.wait(0.3)
                ClickedButtons = {}
            end
        end
    end
    
    local function startCheckingATM()
        if atmCheckConnection then return end
        atmCheckConnection = RunService.Heartbeat:Connect(function()
            local currentATMState = isATMCurrentlyOpen()
            if currentATMState ~= isATMOpen then
                isATMOpen = currentATMState
                if not isATMOpen then
                    ClickedButtons = {}
                end
            end
        end)
    end
    
    local function startAutoATM()
        if ATMRunning then return end
        ATMRunning = true
        ClickedButtons = {}
        isATMOpen = false
        startCheckingATM()
        ATMTask = task.spawn(function()
            while ATMRunning and STATE.AUTO_ATM do
                processATMHack()
                task.wait(0.1 + math.random() * 0.08)
            end
        end)
    end
    
    local function stopAutoATM()
        ATMRunning = false
        if ATMTask then
            task.cancel(ATMTask)
            ATMTask = nil
        end
        if atmCheckConnection then
            atmCheckConnection:Disconnect()
            atmCheckConnection = nil
        end
        ClickedButtons = {}
        isATMOpen = false
        cachedAtmGui = nil
        cachedSequence = nil
        cachedList = nil
    end
    
    local function toggleAutoATM(state)
        if state then startAutoATM() else stopAutoATM() end
    end

    --------------------------------------------------
    -- INSTANT PROMPT
    --------------------------------------------------
    local function enableInstantPrompt()
        if InstantPromptEnabled then return end
        InstantPromptEnabled = true
        pcall(function()
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    obj.HoldDuration = 0
                end
            end
        end)
        local conn = game.DescendantAdded:Connect(function(descendant)
            if STATE.INSTANT_PROMPT and descendant:IsA("ProximityPrompt") then
                task.wait(0.05)
                descendant.HoldDuration = 0
            end
        end)
        table.insert(PromptConnections, conn)
    end
    
    local function disableInstantPrompt()
        if not InstantPromptEnabled then return end
        InstantPromptEnabled = false
        for _, conn in ipairs(PromptConnections) do
            conn:Disconnect()
        end
        PromptConnections = {}
        pcall(function()
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    obj.HoldDuration = 0.5
                end
            end
        end)
    end
    
    local function toggleInstantPrompt(state)
        if state then enableInstantPrompt() else disableInstantPrompt() end
    end

    --------------------------------------------------
    -- HITBOX SYSTEM
    --------------------------------------------------
    local HEAD_TRANSPARENCY = 0.85
    
    local function getHeadScaleFromSize(sizeValue)
        local scale = 3 + ((sizeValue - 5) / 105) * 10
        return Vector3.new(2 * scale, 2 * scale, 2 * scale)
    end
    
    local function getAllHeadDecals(head)
        local decals = {}
        for _, obj in ipairs(head:GetChildren()) do
            if obj:IsA("Decal") then
                table.insert(decals, obj)
            end
        end
        return decals
    end
    
    local function smoothResizeHead(head, targetSize, player)
        if not head or not head.Parent then return end
        if ActiveTweens[player] then
            ActiveTweens[player]:Cancel()
            ActiveTweens[player] = nil
        end
        local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(head, tweenInfo, {Size = targetSize})
        tween:Play()
        ActiveTweens[player] = tween
    end
    
    local function applyBigHeadToPlayer(player)
        if player == LocalPlayer then return end
        if not player.Character then return end
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            BigHeadPaused[player] = true
            return
        end
        local head = player.Character:FindFirstChild("Head")
        if not head then return end
        if not BigHeadData[player] then
            BigHeadData[player] = {
                size = head.Size,
                transparency = head.Transparency,
                canCollide = head.CanCollide,
                massless = head.Massless,
                color = head.Color,
                decals = getAllHeadDecals(head)
            }
        end
        local currentSize = math.clamp(STATE.SIZE, 5, 110)
        local targetSize = getHeadScaleFromSize(currentSize)
        smoothResizeHead(head, targetSize, player)
        head.Transparency = HEAD_TRANSPARENCY
        head.CanCollide = false
        head.Massless = true
        for _, decal in ipairs(getAllHeadDecals(head)) do
            pcall(function() decal.Parent = nil end)
        end
    end
    
    local function revertBigHeadForPlayer(player)
        local saved = BigHeadData[player]
        if not saved then return end
        if not player.Character then
            BigHeadData[player] = nil
            return
        end
        local head = player.Character:FindFirstChild("Head")
        if not head then
            BigHeadData[player] = nil
            return
        end
        smoothResizeHead(head, saved.size, player)
        head.Transparency = saved.transparency
        head.CanCollide = saved.canCollide
        head.Massless = saved.massless
        for _, decal in ipairs(saved.decals) do
            if decal and decal.Parent ~= head then
                pcall(function() decal.Parent = head end)
            end
        end
        BigHeadData[player] = nil
    end
    
    local function updateAllHeadSizes()
        if not STATE.HITBOX then return end
        local currentSize = math.clamp(STATE.SIZE, 5, 110)
        local targetSize = getHeadScaleFromSize(currentSize)
        for player, data in pairs(BigHeadData) do
            if player.Character and not BigHeadPaused[player] then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    smoothResizeHead(head, targetSize, player)
                    head.Transparency = HEAD_TRANSPARENCY
                end
            end
        end
    end
    
    local function applyAllBigHeads()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                applyBigHeadToPlayer(player)
            end
        end
    end
    
    local function revertAllBigHeads()
        for player in pairs(BigHeadData) do
            revertBigHeadForPlayer(player)
        end
        BigHeadPaused = {}
    end
    
    local function attachHealthWatcher(player, humanoid)
        local conn
        conn = humanoid.HealthChanged:Connect(function(health)
            if not STATE.HITBOX then return end
            if health <= 0 then
                if BigHeadData[player] then
                    revertBigHeadForPlayer(player)
                end
                BigHeadPaused[player] = true
            else
                if BigHeadPaused[player] then
                    BigHeadPaused[player] = nil
                    task.wait(0.1)
                    if STATE.HITBOX then
                        applyBigHeadToPlayer(player)
                    end
                end
            end
        end)
        table.insert(PlayerConnections, conn)
    end
    
    local function startEnforcement()
        if EnforcementConnection then
            EnforcementConnection:Disconnect()
        end
        EnforcementConnection = RunService.Heartbeat:Connect(function()
            if not STATE.HITBOX then return end
            local currentSize = math.clamp(STATE.SIZE, 5, 110)
            local currentTargetSize = getHeadScaleFromSize(currentSize)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    local head = player.Character:FindFirstChild("Head")
                    if humanoid and humanoid.Health <= 0 then
                        if BigHeadData[player] then
                            revertBigHeadForPlayer(player)
                        end
                        BigHeadPaused[player] = true
                    elseif humanoid and humanoid.Health > 0 then
                        if BigHeadPaused[player] then
                            BigHeadPaused[player] = nil
                            applyBigHeadToPlayer(player)
                        elseif not BigHeadData[player] then
                            applyBigHeadToPlayer(player)
                        elseif head and BigHeadData[player] then
                            if math.abs(head.Size.X - currentTargetSize.X) > 0.05 then
                                smoothResizeHead(head, currentTargetSize, player)
                            end
                            head.Transparency = HEAD_TRANSPARENCY
                        end
                    end
                end
            end
        end)
    end
    
    local function stopEnforcement()
        if EnforcementConnection then
            EnforcementConnection:Disconnect()
            EnforcementConnection = nil
        end
    end
    
    local function setupPlayerEvents(player)
        local conn
        conn = player.CharacterAdded:Connect(function(character)
            task.wait(0.2)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                attachHealthWatcher(player, humanoid)
                BigHeadPaused[player] = nil
                if STATE.HITBOX and humanoid.Health > 0 then
                    task.wait(0.05)
                    applyBigHeadToPlayer(player)
                end
            end
        end)
        table.insert(PlayerConnections, conn)
    end

    --------------------------------------------------
    -- CLEAR ESP
    --------------------------------------------------
    local function clearESP()
        for _, v in pairs(Objects) do
            pcall(function() v:Destroy() end)
        end
        Objects = {}
    end

    --------------------------------------------------
    -- APPLY ESP
    --------------------------------------------------
    local function applyESP()
        clearESP()
        updateWantedPlayers()
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local char = p.Character
                local isWanted = wantedPlayers[p] ~= nil
                
                if STATE.ESP_PLAYERS then
                    local h = Instance.new("Highlight")
                    h.FillColor = isWanted and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 200, 0)
                    h.FillTransparency = isWanted and 0.3 or 0.4
                    h.OutlineTransparency = 0.5
                    h.Parent = char
                    table.insert(Objects, h)
                end
                
                if STATE.ESP_WANTED and isWanted then
                    local head = char:FindFirstChild("Head")
                    if head then
                        local bill = Instance.new("BillboardGui")
                        bill.Size = UDim2.new(0, 90, 0, 22)
                        bill.AlwaysOnTop = true
                        bill.StudsOffset = Vector3.new(0, 2, 0)
                        bill.Parent = head
                        
                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = Color3.fromRGB(255, 80, 80)
                        txt.TextScaled = true
                        txt.Text = p.Name
                        txt.Font = Enum.Font.GothamBold
                        txt.Parent = bill
                        
                        table.insert(Objects, bill)
                    end
                end
            end
        end
    end

    local function startESPUpdater()
        if ESPUpdateConnection then return end
        ESPUpdateConnection = RunService.Heartbeat:Connect(function()
            if STATE.ESP_WANTED then
                updateWantedPlayers()
                applyESP()
            end
        end)
    end
    
    local function stopESPUpdater()
        if ESPUpdateConnection then
            ESPUpdateConnection:Disconnect()
            ESPUpdateConnection = nil
        end
    end

    local function setupESPRefresh()
        local function refreshESP() applyESP() end
        
        for _, p in ipairs(Players:GetPlayers()) do
            p.CharacterAdded:Connect(refreshESP)
        end
        
        Players.PlayerAdded:Connect(function(p)
            setupPlayerEvents(p)
            p.CharacterAdded:Connect(refreshESP)
        end)
        
        Players.PlayerRemoving:Connect(refreshESP)
        startESPUpdater()
    end

    --------------------------------------------------
    -- MAIN APPLY
    --------------------------------------------------
    local function applyAll()
        applyESP()
        
        if STATE.HITBOX then
            startEnforcement()
            applyAllBigHeads()
        else
            stopEnforcement()
            revertAllBigHeads()
        end
        
        toggleInstantPrompt(STATE.INSTANT_PROMPT)
        toggleAutoATM(STATE.AUTO_ATM)
    end

    --------------------------------------------------
    -- CLEANUP
    --------------------------------------------------
    local function cleanup()
        stopEnforcement()
        stopAutoATM()
        disableInstantPrompt()
        revertAllBigHeads()
        clearESP()
        stopESPUpdater()
        
        for _, conn in ipairs(PlayerConnections) do
            pcall(function() conn:Disconnect() end)
        end
        PlayerConnections = {}
        
        for _, tween in pairs(ActiveTweens) do
            pcall(function() tween:Cancel() end)
        end
        ActiveTweens = {}
    end

    --------------------------------------------------
    -- CREATE CLEAN UI (SEMUA ELEMEN DI DALAM BACKGROUND)
    --------------------------------------------------
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "FastHubGUI"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = LocalPlayer.PlayerGui
    mainGui.IgnoreGuiInset = true

    -- MAIN BACKGROUND FRAME (semua elemen ada di dalam ini)
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 250, 0, 250)
    main.Position = UDim2.new(0.5, -90, 0.5, -117)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BackgroundTransparency = 0.08
    main.BorderSizePixel = 0
    main.Parent = mainGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    -- Border tipis
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 1
    border.BorderColor3 = Color3.fromRGB(0, 170, 255)
    border.Parent = main
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 10)
    borderCorner.Parent = border

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    header.BackgroundTransparency = 0.2
    header.Parent = main

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    -- Header bottom corner (biar cuma atas yang rounded)
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 10)
    headerBottom.Position = UDim2.new(0, 0, 1, -10)
    headerBottom.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    headerBottom.BackgroundTransparency = 0.2
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header

    local title = Instance.new("TextLabel")
    title.Text = "RIBETINHUB"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
    minimizeBtn.Position = UDim2.new(1, -52, 0.5, -12)
    minimizeBtn.Text = "−"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
    minimizeBtn.BackgroundTransparency = 0.3
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.TextSize = 14
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minimizeBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -26, 0.5, -12)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        cleanup()
        mainGui:Destroy()
    end)

    -- Dragging
    local dragging = false
    local dragStart = nil
    local startPos = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Content container (semua elemen kontainer ada di dalam main)
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, 0, 1, -30)
    contentContainer.Position = UDim2.new(0, 0, 0, 30)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = main

    local contentFrames = {}

    local function createToggle(name, y, key)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -12, 0, 28)
        frame.Position = UDim2.new(0, 6, 0, y)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame.BackgroundTransparency = 0.5
        frame.Parent = contentContainer
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.65, 0, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 36, 0, 20)
        btn.Position = UDim2.new(1, -42, 0.5, -10)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        btn.Text = ""
        btn.Parent = frame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 14, 0, 14)
        dot.Position = UDim2.new(0, 2, 0.5, -7)
        dot.BackgroundColor3 = Color3.new(1, 1, 1)
        dot.Parent = btn
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        if STATE[key] then
            btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            dot.Position = UDim2.new(1, -16, 0.5, -7)
        end
        
        btn.MouseButton1Click:Connect(function()
            STATE[key] = not STATE[key]
            
            if key == "HITBOX" and STATE[key] and STATE.SIZE < 5 then
                STATE.SIZE = 5
                if valueLabel then valueLabel.Text = "5" end
                initSlider()
            end
            
            local targetColor = STATE[key] and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(55, 55, 65)
            local targetPos = STATE[key] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(dot, TweenInfo.new(0.12), {Position = targetPos}):Play()
            
            if key == "ESP_WANTED" then
                if STATE.ESP_WANTED then startESPUpdater() end
            end
            
            applyAll()
        end)
        
        table.insert(contentFrames, frame)
        return frame
    end

    -- Toggles
    createToggle("Wanted", 8, "ESP_WANTED")
    createToggle("ESP Player", 40, "ESP_PLAYERS")
    createToggle("Big Head", 72, "HITBOX")

    -- Slider
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -12, 0, 50)
    sliderFrame.Position = UDim2.new(0, 6, 0, 106)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sliderFrame.BackgroundTransparency = 0.5
    sliderFrame.Parent = contentContainer

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = sliderFrame

    table.insert(contentFrames, sliderFrame)

    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 18)
    sliderLabel.Position = UDim2.new(0, 8, 0, 4)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Head Size"
    sliderLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    sliderLabel.TextSize = 10
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 35, 0, 18)
    valueLabel.Position = UDim2.new(1, -43, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(STATE.SIZE)
    valueLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = sliderFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.85, 0, 0, 4)
    bar.Position = UDim2.new(0.075, 0, 0.7, 0)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    bar.Parent = sliderFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.Parent = bar
    fill.Size = UDim2.new(0, 0, 1, 0)

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = bar

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local isDragging = false

    local function updateSlider(x)
        local pos = bar.AbsolutePosition.X
        local size = bar.AbsoluteSize.X
        if size <= 0 then return end
        
        local a = math.clamp((x - pos) / size, 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        
        local newSize = math.floor(5 + (110 - 5) * a)
        if newSize ~= STATE.SIZE then
            STATE.SIZE = newSize
            valueLabel.Text = tostring(STATE.SIZE)
            if STATE.HITBOX then updateAllHeadSizes() end
        end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            updateSlider(input.Position.X)
        end
    end)
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            updateSlider(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)

    local function initSlider()
        local a = (STATE.SIZE - 5) / (110 - 5)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
    end
    initSlider()

    createToggle("Instant Interaction", 162, "INSTANT_PROMPT")
    createToggle("Auto ATM", 194, "AUTO_ATM")

    -- Minimize function
    local isMinimized = false
    local originalSize = main.Size

local minimizedWidth = 170

    local function minimizeGUI()
        if isMinimized then return end
        isMinimized = true
        originalSize = main.Size

        contentContainer.Visible = false

        TweenService:Create(main, TweenInfo.new(0.2), {
            Size = UDim2.new(0, minimizedWidth, 0, 30)
        }):Play()

        -- pindahkan tombol ke kanan
        TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {
            Position = UDim2.new(1, -52, 0.5, -12)
        }):Play()

        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            Position = UDim2.new(1, -26, 0.5, -12)
        }):Play()

        -- title tetap aman
        title.Size = UDim2.new(1, -65, 1, 0)

        minimizeBtn.Text = "+"
    end

    local function maximizeGUI()
        if not isMinimized then return end
        isMinimized = false

        TweenService:Create(main, TweenInfo.new(0.2), {
            Size = originalSize
        }):Play()

        contentContainer.Visible = true

        -- balikin posisi tombol
        TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {
            Position = UDim2.new(1, -52, 0.5, -12)
        }):Play()

        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            Position = UDim2.new(1, -26, 0.5, -12)
        }):Play()

        title.Size = UDim2.new(1, -60, 1, 0)

        minimizeBtn.Text = "−"
    end

    minimizeBtn.MouseButton1Click:Connect(function()
        if isMinimized then maximizeGUI() else minimizeGUI() end
    end)

    minimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 100, 150)}):Play()
    end)
    minimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 130, 200)}):Play()
    end)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 130, 200)}):Play()
    end)

    -- Setup
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then setupPlayerEvents(p) end
    end

    setupESPRefresh()
    applyAll()

    print("[FASTHUB] Clean UI Loaded - All elements inside background")
end

--------------------------------------------------
-- CREATE PASSWORD GUI
--------------------------------------------------
local function createPasswordGUI()
    authGui = Instance.new("ScreenGui")
    authGui.Name = "AuthGUI"
    authGui.ResetOnSpawn = false
    authGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    authGui.Parent = LocalPlayer.PlayerGui
    authGui.IgnoreGuiInset = true
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.7
    background.Parent = authGui
    
    local authMain = Instance.new("Frame")
    authMain.Size = UDim2.new(0, 380, 0, 280)
    authMain.Position = UDim2.new(0.5, -190, 0.5, -140)
    authMain.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    authMain.BackgroundTransparency = 0.05
    authMain.BorderSizePixel = 0
    authMain.Parent = authGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = authMain
    
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 2
    border.BorderColor3 = Color3.fromRGB(0, 170, 255)
    border.Parent = authMain
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 16)
    borderCorner.Parent = border
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "🔐 HARUS BAYAR DULU"
    title.TextColor3 = Color3.fromRGB(0, 170, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = authMain
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 70)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "BAYAR DONG GUA MAU JAJAN"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = authMain
    
    local inputBox = Instance.new("Frame")
    inputBox.Size = UDim2.new(0, 280, 0, 45)
    inputBox.Position = UDim2.new(0.5, -140, 0, 120)
    inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    inputBox.BackgroundTransparency = 0.3
    inputBox.Parent = authMain
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputBox
    
    local inputField = Instance.new("TextBox")
    inputField.Size = UDim2.new(1, -20, 1, 0)
    inputField.Position = UDim2.new(0, 10, 0, 0)
    inputField.BackgroundTransparency = 1
    inputField.PlaceholderText = "Masukkan password..."
    inputField.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    inputField.Text = ""
    inputField.TextColor3 = Color3.new(1, 1, 1)
    inputField.TextSize = 14
    inputField.Font = Enum.Font.Gotham
    inputField.ClearTextOnFocus = false
    inputField.Parent = inputBox
    
    local hideToggle = Instance.new("TextButton")
    hideToggle.Size = UDim2.new(0, 30, 0, 30)
    hideToggle.Position = UDim2.new(1, -35, 0.5, -15)
    hideToggle.Text = "👁"
    hideToggle.BackgroundTransparency = 1
    hideToggle.TextColor3 = Color3.fromRGB(150, 150, 150)
    hideToggle.TextSize = 16
    hideToggle.Font = Enum.Font.Gotham
    hideToggle.Parent = inputBox
    
    local isPasswordVisible = false
    hideToggle.MouseButton1Click:Connect(function()
        isPasswordVisible = not isPasswordVisible
        inputField.Text = inputField.Text
        hideToggle.Text = isPasswordVisible and "🙈" or "👁"
    end)
    
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0, 280, 0, 45)
    submitBtn.Position = UDim2.new(0.5, -140, 0, 180)
    submitBtn.Text = "JANGAN CURANG"
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    submitBtn.TextColor3 = Color3.new(1, 1, 1)
    submitBtn.TextSize = 16
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.Parent = authMain
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 8)
    submitCorner.Parent = submitBtn
    
    local attemptText = Instance.new("TextLabel")
    attemptText.Size = UDim2.new(1, 0, 0, 20)
    attemptText.Position = UDim2.new(0, 0, 0, 240)
    attemptText.BackgroundTransparency = 1
    attemptText.Text = "Percobaan: " .. authAttempts .. "/" .. CONFIG.MAX_ATTEMPTS
    attemptText.TextColor3 = Color3.fromRGB(100, 100, 100)
    attemptText.TextSize = 11
    attemptText.Font = Enum.Font.Gotham
    attemptText.Parent = authMain
    
    local function verifyAndTransition()
        local inputPassword = inputField.Text
        
        if inputPassword == "" then
            showError("❌ Masukkan password terlebih dahulu!")
            return
        end
        
        if lockoutUntil > tick() then
            local remaining = math.floor(lockoutUntil - tick())
            showError("⏰ Terkunci! Coba lagi dalam " .. remaining .. " detik")
            return
        end
        
        if inputPassword == CONFIG.PASSWORD then
            isAuthenticated = true
            
            submitBtn.Text = "CUPU LU"
            submitBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            
            TweenService:Create(authMain, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(border, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(background, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
            
            task.wait(0.35)
            
            authGui:Destroy()
            
            createMainGUI()
            
            print("[FASTHUB] Authentication successful! Welcome!")
        else
            authAttempts = authAttempts + 1
            attemptText.Text = "Percobaan: " .. authAttempts .. "/" .. CONFIG.MAX_ATTEMPTS
            
            if authAttempts >= CONFIG.MAX_ATTEMPTS then
                lockoutUntil = tick() + CONFIG.LOCKOUT_TIME
                showError("🔒 Terlalu banyak percobaan! Terkunci " .. CONFIG.LOCKOUT_TIME .. " detik")
                inputField.Text = ""
                inputField.PlaceholderText = "Terkunci..."
                inputField.Selectable = false
                
                task.spawn(function()
                    task.wait(CONFIG.LOCKOUT_TIME)
                    authAttempts = 0
                    attemptText.Text = "Percobaan: 0/" .. CONFIG.MAX_ATTEMPTS
                    inputField.PlaceholderText = "Masukkan password..."
                    inputField.Selectable = true
                end)
            else
                showError("❌ Password salah! Sisa percobaan: " .. (CONFIG.MAX_ATTEMPTS - authAttempts))
                inputField.Text = ""
                inputField.PlaceholderText = "Coba lagi..."
                task.wait(1)
                inputField.PlaceholderText = "Masukkan password..."
            end
        end
    end
    
    submitBtn.MouseButton1Click:Connect(verifyAndTransition)
    inputField.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verifyAndTransition()
        end
    end)
    
    task.spawn(function()
        local glow = 0
        local direction = 1
        while authGui and authGui.Parent do
            glow = glow + direction * 0.05
            if glow >= 1 then direction = -1 end
            if glow <= 0 then direction = 1 end
            pcall(function()
                border.BorderColor3 = Color3.fromRGB(0, 170 * glow, 255 * glow)
            end)
            task.wait(0.05)
        end
    end)
end

-- Start the script
createPasswordGUI()