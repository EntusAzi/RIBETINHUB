-- LOCAL SCRIPT (StarterPlayerScripts)
-- With Password System & Smooth Transition

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- PASSWORD CONFIGURATION
--------------------------------------------------
local CONFIG = {
    PASSWORD = "KenapaNyak",  -- GANTI PASSWORD ANDA DI SINI
    MAX_ATTEMPTS = 3,
    LOCKOUT_TIME = 60,
}

local isAuthenticated = false
local authAttempts = 0
local lockoutUntil = 0

--------------------------------------------------
-- PASSWORD GUI (DENGAN TRANSISI LANGSUNG)
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
    -- MAIN SCRIPT STATE
    local STATE = {
        ESP_NAME = false,
        ESP_PLAYERS = false,
        HITBOX = false,
        INSTANT_PROMPT = false,
        AUTO_ATM = false,
        SIZE = 30  -- Default size 30 (tengah-tengah 5-110)
    }

    local Objects = {}
    local BigHeadData = {}
    local BigHeadPaused = {}
    local EnforcementConnection = nil
    local PlayerConnections = {}
    local ActiveTweens = {}

    local PromptConnections = {}
    local InstantPromptEnabled = false

    local ATMTask = nil
    local ATMRunning = false
    local ClickedButtons = {}
    local lastATMProcess = 0
    local ATMProcessDelay = 0.3

    --------------------------------------------------
    -- AUTO ATM HACK SYSTEM
    --------------------------------------------------
    local function GetCodes()
        local success, result = pcall(function()
            local atmGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
            if not atmGui then return nil end
            
            local center = atmGui:FindFirstChild("Center")
            if not center then return nil end
            
            local middle = center:FindFirstChild("Middle")
            if not middle then return nil end
            
            local hacking = middle:FindFirstChild("HackingMinigames")
            if not hacking then return nil end
            
            local atmHack = hacking:FindFirstChild("ATM Hack")
            if not atmHack then return nil end
            
            local sequence = atmHack:FindFirstChild("Sequence1")
            if not sequence then return nil end
            
            local Codes = {}
            for Code in string.gmatch(sequence.Text, "([^%s]+)") do
                table.insert(Codes, Code)
            end
            return Codes
        end)
        
        if success and result then
            return result
        end
        return nil
    end

    local function ClickButton(Button)
        local success, result = pcall(function()
            if not Button or not Button.Parent then return false end
            
            local Pos = Button.AbsolutePosition
            local Size = Button.AbsoluteSize
            
            if Pos.X > 0 and Pos.Y > 0 and Size.X > 0 and Size.Y > 0 then
                local X = Pos.X + Size.X / 2
                local Y = Pos.Y + Size.Y / 2
                VirtualInputManager:SendMouseButtonEvent(X, Y, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(X, Y, 0, false, game, 0)
                return true
            end
            return false
        end)
        return success and result or false
    end

    local function resetATMClicked()
        if ClickedButtons then
            local count = 0
            for _ in pairs(ClickedButtons) do
                count = count + 1
            end
            if count > 50 then
                ClickedButtons = {}
            end
        end
    end

    local function processATMHack()
        if not STATE.AUTO_ATM then return end
        
        local now = tick()
        if now - lastATMProcess < ATMProcessDelay then
            return
        end
        lastATMProcess = now
        
        resetATMClicked()
        
        pcall(function()
            local atmGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
            if not atmGui then return end
            
            local center = atmGui:FindFirstChild("Center")
            if not center then return end
            
            local middle = center:FindFirstChild("Middle")
            if not middle then return end
            
            local hacking = middle:FindFirstChild("HackingMinigames")
            if not hacking then return end
            
            local atmHack = hacking:FindFirstChild("ATM Hack")
            if not atmHack then return end
            
            local sequence = atmHack:FindFirstChild("Sequence1")
            if not sequence or sequence.Text == "" then return end
            
            local Codes = GetCodes()
            if not Codes or #Codes == 0 then return end
            
            local BlockedColor = Color3.fromRGB(74, 75, 93)
            local list = atmHack:FindFirstChild("List")
            if not list then return end
            
            local clickedAny = false
            
            for _, Button in ipairs(list:GetDescendants()) do
                if Button:IsA("ImageButton") then
                    if ClickedButtons[Button] then continue end
                    if Button.ImageColor3 == BlockedColor then continue end
                    
                    for _, Label in ipairs(Button:GetDescendants()) do
                        if Label:IsA("TextLabel") and Label.Text ~= "" then
                            for _, Code in ipairs(Codes) do
                                if Label.Text == Code then
                                    if ClickButton(Button) then
                                        ClickedButtons[Button] = true
                                        clickedAny = true
                                    end
                                    break
                                end
                            end
                            break
                        end
                    end
                end
            end
            
            if not clickedAny and #Codes > 0 then
                local allClickedOrBlocked = true
                for _, Button in ipairs(list:GetDescendants()) do
                    if Button:IsA("ImageButton") then
                        if not ClickedButtons[Button] and Button.ImageColor3 ~= BlockedColor then
                            allClickedOrBlocked = false
                            break
                        end
                    end
                end
                
                if allClickedOrBlocked then
                    task.wait(0.5)
                    ClickedButtons = {}
                end
            end
        end)
    end

    local function startAutoATM()
        if ATMRunning then return end
        ATMRunning = true
        ClickedButtons = {}
        lastATMProcess = 0
        
        ATMTask = task.spawn(function()
            while ATMRunning and STATE.AUTO_ATM do
                processATMHack()
                task.wait(0.3)
            end
        end)
    end

    local function stopAutoATM()
        ATMRunning = false
        if ATMTask then
            task.cancel(ATMTask)
            ATMTask = nil
        end
        ClickedButtons = {}
    end

    local function toggleAutoATM(state)
        if state then
            startAutoATM()
        else
            stopAutoATM()
        end
    end

    --------------------------------------------------
    -- INSTANT PROXIMITY PROMPT SYSTEM
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
        if state then
            enableInstantPrompt()
        else
            disableInstantPrompt()
        end
    end

    --------------------------------------------------
    -- SMOOTH FUNCTIONS (Big Head) - UPDATED RANGE 5-110
    --------------------------------------------------
    local function getHeadScaleFromSize(sizeValue)
        -- Range 5-110 dengan skala yang lebih ekstrim
        -- size 5 = kepala kecil, size 110 = kepala sangat besar
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
        
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(head, tweenInfo, {Size = targetSize})
        tween:Play()
        ActiveTweens[player] = tween
        
        tween.Completed:Connect(function()
            if ActiveTweens[player] == tween then
                ActiveTweens[player] = nil
            end
        end)
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
                decals = getAllHeadDecals(head)
            }
        end
        
        local currentSize = math.clamp(STATE.SIZE, 5, 110)
        local targetSize = getHeadScaleFromSize(currentSize)
        smoothResizeHead(head, targetSize, player)
        
        head.Transparency = 0.85
        head.CanCollide = false
        head.Massless = true
        
        for _, decal in ipairs(getAllHeadDecals(head)) do
            decal.Parent = nil
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
                decal.Parent = head
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
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local char = p.Character
                
                if STATE.ESP_PLAYERS then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(255, 200, 0)
                    h.FillTransparency = 0.4
                    h.OutlineTransparency = 0.5
                    h.Parent = char
                    table.insert(Objects, h)
                end
                
                if STATE.ESP_NAME then
                    local head = char:FindFirstChild("Head")
                    if head then
                        local bill = Instance.new("BillboardGui")
                        bill.Size = UDim2.new(0, 100, 0, 30)
                        bill.AlwaysOnTop = true
                        bill.StudsOffset = Vector3.new(0, 1.5, 0)
                        bill.Parent = head
                        
                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = Color3.new(1, 1, 1)
                        txt.TextStrokeTransparency = 0.3
                        txt.TextScaled = true
                        txt.Text = p.Name
                        txt.Parent = bill
                        
                        table.insert(Objects, bill)
                    end
                end
            end
        end
    end

    -- Auto refresh ESP
    local function setupESPRefresh()
        for _, p in pairs(Players:GetPlayers()) do
            p.CharacterAdded:Connect(function()
                task.wait(0.5)
                applyESP()
            end)
        end
        
        Players.PlayerAdded:Connect(function(p)
            setupPlayerEvents(p)
            p.CharacterAdded:Connect(function()
                task.wait(0.5)
                applyESP()
            end)
        end)
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
    -- CLEANUP FUNCTION
    --------------------------------------------------
    local function cleanup()
        stopEnforcement()
        stopAutoATM()
        disableInstantPrompt()
        revertAllBigHeads()
        clearESP()
        
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
    -- CREATE MAIN UI
    --------------------------------------------------
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "FastHubGUI"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = LocalPlayer.PlayerGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 320, 0, 370)
    main.Position = UDim2.new(0.5, -160, 0.5, -185)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.Parent = mainGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundTransparency = 1
    header.Parent = main

    local title = Instance.new("TextLabel")
    title.Text = "RIBETINHUB"
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(0, 170, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Header buttons frame
    local headerButtons = Instance.new("Frame")
    headerButtons.Size = UDim2.new(0, 70, 1, 0)
    headerButtons.Position = UDim2.new(1, -80, 0, 0)
    headerButtons.BackgroundTransparency = 1
    headerButtons.Parent = header

    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(0, 0, 0.5, -15)
    minimizeBtn.Text = "−"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = headerButtons

    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(1, 0)
    minimizeCorner.Parent = minimizeBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -30, 0.5, -15)
    closeBtn.Text = "✕"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Parent = headerButtons

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        cleanup()
        mainGui:Destroy()
    end)

    -- DRAG
    local dragging = false
    local dragStart = nil
    local startPos = nil

    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- TOGGLE BUTTON
    local contentFrames = {}

    local function createToggle(name, y, key)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -16, 0, 36)
        frame.Position = UDim2.new(0, 8, 0, y)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame.BackgroundTransparency = 0.5
        frame.Parent = main
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 8)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 44, 0, 24)
        btn.Position = UDim2.new(1, -54, 0.5, -12)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        btn.Text = ""
        btn.Parent = frame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 20, 0, 20)
        dot.Position = UDim2.new(0, 2, 0.5, -10)
        dot.BackgroundColor3 = Color3.new(1, 1, 1)
        dot.Parent = btn
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        if STATE[key] then
            btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            dot.Position = UDim2.new(1, -22, 0.5, -10)
        end
        
        btn.MouseButton1Click:Connect(function()
            STATE[key] = not STATE[key]
            
            if key == "HITBOX" and STATE[key] and STATE.SIZE < 5 then
                STATE.SIZE = 5
                if valueLabel then
                    valueLabel.Text = tostring(STATE.SIZE)
                end
                initSlider()
            end
            
            local targetColor = STATE[key] and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)
            local targetPos = STATE[key] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = targetPos}):Play()
            
            applyAll()
        end)
        
        table.insert(contentFrames, frame)
        return frame
    end

    -- Toggle buttons
    createToggle("ESP Name", 46, "ESP_NAME")
    createToggle("ESP Players", 86, "ESP_PLAYERS")
    createToggle("Big Head Hitbox", 126, "HITBOX")

    -- SLIDER (Range 5-110)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -16, 0, 55)
    sliderFrame.Position = UDim2.new(0, 8, 0, 176)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sliderFrame.BackgroundTransparency = 0.5
    sliderFrame.Parent = main

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 8)
    sliderCorner.Parent = sliderFrame

    table.insert(contentFrames, sliderFrame)

    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 24)
    sliderLabel.Position = UDim2.new(0, 10, 0, 4)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Hitbox Size (5-110)"
    sliderLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    sliderLabel.TextSize = 11
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 24)
    valueLabel.Position = UDim2.new(1, -60, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(STATE.SIZE)
    valueLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = sliderFrame

    local minLabel = Instance.new("TextLabel")
    minLabel.Size = UDim2.new(0, 20, 0, 16)
    minLabel.Position = UDim2.new(0.23, 0, 0.68, 0)
    minLabel.BackgroundTransparency = 1
    minLabel.Text = "5"
    minLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    minLabel.TextSize = 10
    minLabel.Parent = sliderFrame

    local maxLabel = Instance.new("TextLabel")
    maxLabel.Size = UDim2.new(0, 25, 0, 16)
    maxLabel.Position = UDim2.new(0.73, 0, 0.68, 0)
    maxLabel.BackgroundTransparency = 1
    maxLabel.Text = "110"
    maxLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    maxLabel.TextSize = 10
    maxLabel.Parent = sliderFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.5, 0, 0, 4)
    bar.Position = UDim2.new(0.25, 0, 0.62, -2)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.Parent = sliderFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
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
        
        -- Range 5-110
        local newSize = math.floor(5 + (110 - 5) * a)
        if newSize ~= STATE.SIZE then
            STATE.SIZE = newSize
            valueLabel.Text = tostring(STATE.SIZE)
            
            if STATE.HITBOX then
                updateAllHeadSizes()
            end
        end
    end

    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(i.Position.X)
        end
    end)

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(i.Position.X)
        end
    end)

    local function initSlider()
        local a = (STATE.SIZE - 5) / (110 - 5)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
    end
    initSlider()

    -- TOGGLE BAWAH
    createToggle("Instant Prompt", 242, "INSTANT_PROMPT")
    createToggle("Auto ATM Hack", 282, "AUTO_ATM")

    -- MINIMIZE / MAXIMIZE FUNCTION
    local isMinimized = false
    local originalSize = main.Size

    local function minimizeGUI()
        if isMinimized then return end
        isMinimized = true
        
        originalSize = main.Size
        
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 150, 0, 38)
        }):Play()
        
        for _, frame in ipairs(contentFrames) do
            frame.Visible = false
        end
        
        minimizeBtn.Text = "□"
    end

    local function maximizeGUI()
        if not isMinimized then return end
        isMinimized = false
        
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = originalSize
        }):Play()
        
        for _, frame in ipairs(contentFrames) do
            frame.Visible = true
        end
        
        minimizeBtn.Text = "−"
    end

    minimizeBtn.MouseButton1Click:Connect(function()
        if isMinimized then
            maximizeGUI()
        else
            minimizeGUI()
        end
    end)

    -- Hover effects
    minimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()
    end)
    minimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
    end)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
    end)

    -- Setup initial events
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            setupPlayerEvents(p)
        end
    end

    setupESPRefresh()
    applyAll()

    print("[FASTHUB] Main UI Loaded Successfully! (Hitbox Range: 5-110)")
end

--------------------------------------------------
-- CREATE PASSWORD GUI DENGAN TRANSISI HALUS
--------------------------------------------------
local function createPasswordGUI()
    authGui = Instance.new("ScreenGui")
    authGui.Name = "AuthGUI"
    authGui.ResetOnSpawn = false
    authGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    authGui.Parent = LocalPlayer.PlayerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.7
    background.Parent = authGui
    
    -- Main frame
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
    
    -- Border glow
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 2
    border.BorderColor3 = Color3.fromRGB(0, 170, 255)
    border.Parent = authMain
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 16)
    borderCorner.Parent = border
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "🔐 HARUS BAYAR DULU"
    title.TextColor3 = Color3.fromRGB(0, 170, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = authMain
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 70)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Tanya Anak CK Bayar Berapa"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = authMain
    
    -- Password input box
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
    
    -- Hide password toggle
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
    
    -- Submit button
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0, 280, 0, 45)
    submitBtn.Position = UDim2.new(0.5, -140, 0, 180)
    submitBtn.Text = "SUKA-SUKA LU"
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    submitBtn.TextColor3 = Color3.new(1, 1, 1)
    submitBtn.TextSize = 16
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.Parent = authMain
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 8)
    submitCorner.Parent = submitBtn
    
    -- Attempt counter
    local attemptText = Instance.new("TextLabel")
    attemptText.Size = UDim2.new(1, 0, 0, 20)
    attemptText.Position = UDim2.new(0, 0, 0, 240)
    attemptText.BackgroundTransparency = 1
    attemptText.Text = "Percobaan: " .. authAttempts .. "/" .. CONFIG.MAX_ATTEMPTS
    attemptText.TextColor3 = Color3.fromRGB(100, 100, 100)
    attemptText.TextSize = 11
    attemptText.Font = Enum.Font.Gotham
    attemptText.Parent = authMain
    
    -- Verify function with smooth transition
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
            -- Authentication success with smooth transition
            isAuthenticated = true
            
            -- Animate success
            submitBtn.Text = "✓ VERIFIED!"
            submitBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            
            -- Fade out animation
            TweenService:Create(authMain, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(border, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(background, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
            
            -- Wait for animation
            task.wait(0.35)
            
            -- Destroy auth GUI
            authGui:Destroy()
            
            -- Create main GUI
            createMainGUI()
            
            print("[FASTHUB] Authentication successful! Welcome!")
        else
            -- Failed attempt
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
    
    -- Animated border glow
    task.spawn(function()
        local glow = 0
        local direction = 1
        while authGui and authGui.Parent do
            glow = glow + direction * 0.05
            if glow >= 1 then direction = -1 end
            if glow <= 0 then direction = 1 end
            border.BorderColor3 = Color3.fromRGB(0, 170 * glow, 255 * glow)
            task.wait(0.05)
        end
    end)
end

--------------------------------------------------
-- START AUTHENTICATION
--------------------------------------------------
createPasswordGUI()