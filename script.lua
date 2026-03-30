task.wait(3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local UIS = UserInputService

local player = Players.LocalPlayer
local Mouse = player:GetMouse()
repeat task.wait() until player.Character
local character = player.Character
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

-- CONFIG
local Config = {
    AimbotToggle = false,
    AimbotPart = "Head",
    RightMouseDown = false,
    FOV = 150,
    Sensitivity = 0.3,
    LockOnTarget = nil,
    ShowFOV = true,
    WallCheck = true,
    SilentAimToggle = false,
    SilentAimPart = "Head",
    SilentAimFOV = 200,
    SilentAimIntensity = 100,
    SilentAimKey = "F",
    ShowESP = false,
    EnemyColor = Color3.fromRGB(0, 170, 255),
    BlinkingESP = false,
    HPESP = true,
    ESPTransparency = 0.3,
    ShowNameTags = true,
    WalkSpeed = false,
    WalkSpeedValue = 25.2,
    JumpPower = false,
    JumpPowerValue = 20,
    Noclip = false,
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 100,
    Smoke = false,
    AutoRespawn = false,
}

local HumanModCons = {}
local connections = {}
local noclippedParts = {}
local storedNametags = {}
local InfiniteJumpConnection = nil
local DrawingCircle = nil

local spinSpeed = 10
local spinDirection = 1
local spinAxis = "Y"
local spinning, spinConnection = false, nil

local sticking, stickConnection = false, nil
local stickTarget = ""

local invisible = false
local originalTransparency = {}

local savedPositions = {}

local aimlockKeyName = "Q"
local flyKeyName = "G"
local silentAimKeyName = "F"

local allKeysList = {
    "Q","E","R","T","F","G","H","J","K","L","Z","X","C","V","B","N","M",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero",
    "LeftAlt","RightAlt","LeftShift","RightShift","Tab","CapsLock"
}

-- UPDATE PERSO
local function refresh()
    character = player.Character
    if not character then return end
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end

-- AUTO RESPAWN
local function setupAutoRespawn()
    humanoid.Died:Connect(function()
        if not Config.AutoRespawn then return end
        task.wait(0.1)
        player:LoadCharacter()
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    refresh()
    -- Les features persistent à travers la mort
    if Config.Fly then
        task.wait(0.5)
        -- Relance fly après respawn
        Config.Fly = false
        local function startFlyInternal()
            if Config.Fly then return end
            Config.Fly = true
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
            if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
            local gyro = Instance.new("BodyGyro")
            gyro.Name = "FlyGyro"
            gyro.MaxTorque = Vector3.new(1,1,1) * math.huge
            gyro.P = 100000
            gyro.CFrame = hrp.CFrame
            gyro.Parent = hrp
            local vel = Instance.new("BodyVelocity")
            vel.Name = "FlyVelocity"
            vel.MaxForce = Vector3.new(1,1,1) * math.huge
            vel.P = 10000
            vel.Velocity = Vector3.zero
            vel.Parent = hrp
            local conn
            conn = RunService.RenderStepped:Connect(function()
                if not Config.Fly or not hrp or not hrp.Parent then
                    if conn then conn:Disconnect() end
                    pcall(function() gyro:Destroy() end)
                    pcall(function() vel:Destroy() end)
                    return
                end
                local move = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
                vel.Velocity = move.Magnitude > 0 and move.Unit * Config.FlySpeed or Vector3.zero
                gyro.CFrame = Camera.CFrame
            end)
        end
        startFlyInternal()
    end
    setupAutoRespawn()
end)

setupAutoRespawn()

-- TEAM CHECK
local function isEnemy(p)
    if not p or p == player then return false end
    if player.Team and p.Team then return player.Team ~= p.Team end
    return true
end

-- SPIN
local function getSpinCF()
    local a = math.rad(spinSpeed) * spinDirection
    if spinAxis == "X" then return CFrame.Angles(a, 0, 0)
    elseif spinAxis == "Z" then return CFrame.Angles(0, 0, a)
    else return CFrame.Angles(0, a, 0) end
end

local function startSpin()
    if spinning then return end
    spinning = true
    spinConnection = RunService.RenderStepped:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.CFrame *= getSpinCF()
        end
    end)
end

local function stopSpin()
    spinning = false
    if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
end

-- FLY
local function startFly()
    if Config.Fly then return end
    Config.Fly = true
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
    if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "FlyGyro"
    gyro.MaxTorque = Vector3.new(1,1,1) * math.huge
    gyro.P = 100000
    gyro.CFrame = hrp.CFrame
    gyro.Parent = hrp

    local vel = Instance.new("BodyVelocity")
    vel.Name = "FlyVelocity"
    vel.MaxForce = Vector3.new(1,1,1) * math.huge
    vel.P = 10000
    vel.Velocity = Vector3.zero
    vel.Parent = hrp

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Config.Fly or not hrp or not hrp.Parent then
            if conn then conn:Disconnect() end
            pcall(function() gyro:Destroy() end)
            pcall(function() vel:Destroy() end)
            return
        end
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        vel.Velocity = move.Magnitude > 0 and move.Unit * Config.FlySpeed or Vector3.zero
        gyro.CFrame = Camera.CFrame
    end)
end

local function stopFly()
    Config.Fly = false
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
    end
end

-- NOCLIP
task.spawn(function()
    while true do
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if Config.Noclip then
                        if part.CanCollide then part.CanCollide = false; noclippedParts[part] = true end
                    else
                        if noclippedParts[part] then part.CanCollide = true; noclippedParts[part] = nil end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- WALKSPEED
local function startLoopSpeed()
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.WalkSpeed = Config.WalkSpeedValue end
    apply()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    HumanModCons.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
end

local function stopLoopSpeed()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 25.2 end
end

-- JUMPPOWER
local function startLoopPower()
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.UseJumpPower = true; h.JumpPower = Config.JumpPowerValue end
    apply()
    if HumanModCons.jp then HumanModCons.jp:Disconnect() end
    HumanModCons.jp = h:GetPropertyChangedSignal("JumpPower"):Connect(apply)
end

local function stopLoopPower()
    if HumanModCons.jp then HumanModCons.jp:Disconnect() end
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.JumpPower = 20 end
end

-- INFINITE JUMP
local function startInfiniteJump()
    if InfiniteJumpConnection then return end
    InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopInfiniteJump()
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect(); InfiniteJumpConnection = nil end
end

-- INVISIBLE
local function setInvis(state)
    invisible = state
    if not character then return end
    for _, p in pairs(character:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if state then
                originalTransparency[p] = p.Transparency
                p.Transparency = 1; p.LocalTransparencyModifier = 1
            else
                p.Transparency = originalTransparency[p] or 0; p.LocalTransparencyModifier = 0
            end
        end
        if p:IsA("Decal") then p.Transparency = state and 1 or 0 end
    end
    for _, obj in pairs(character:GetChildren()) do
        if obj:IsA("Accessory") then
            local h = obj:FindFirstChild("Handle")
            if h then
                if state then
                    originalTransparency[h] = h.Transparency
                    h.Transparency = 1; h.LocalTransparencyModifier = 1
                else
                    h.Transparency = originalTransparency[h] or 0; h.LocalTransparencyModifier = 0
                end
            end
        end
    end
    humanoid.DisplayDistanceType = state
        and Enum.HumanoidDisplayDistanceType.None
        or Enum.HumanoidDisplayDistanceType.Automatic
end

-- SMOKE
task.spawn(function()
    while true do
        if Config.Smoke then
            for _, v in pairs(workspace:GetChildren()) do
                if v.Name == "Smoke Grenade" then v:Destroy() end
            end
        end
        task.wait(0.1)
    end
end)

-- AIMBOT
if Drawing then
    DrawingCircle = Drawing.new("Circle")
    DrawingCircle.Thickness = 1
    DrawingCircle.Filled = false
    DrawingCircle.Transparency = 1
    DrawingCircle.Color = Color3.fromRGB(0, 170, 255)
    DrawingCircle.Visible = false
    DrawingCircle.Radius = Config.FOV
    table.insert(connections, RunService.RenderStepped:Connect(function()
        DrawingCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        DrawingCircle.Radius = Config.FOV
        DrawingCircle.Visible = Config.ShowFOV and Config.AimbotToggle
    end))
end

local function isValidTarget(p)
    if p == player then return false end
    if not p.Character then return false end
    if not p.Character:FindFirstChild("Humanoid") then return false end
    if p.Character.Humanoid.Health <= 0 then return false end
    if not isEnemy(p) then return false end
    return true
end

local function getTargetPart(char, partName)
    return char:FindFirstChild(partName or Config.AimbotPart)
end

local function isVisible(targetPlayer)
    local char = targetPlayer.Character
    if not char then return false end
    local targetPart = getTargetPart(char)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance then
        if not char:IsAncestorOf(result.Instance) then return false end
    end
    return true
end

local function getClosestPlayerInFOV()
    local closestPlayer, shortestDistance = nil, Config.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local targetPart = getTargetPart(p.Character)
            if targetPart then
                if not Config.WallCheck or isVisible(p) then
                    local screenPoint = Camera:WorldToScreenPoint(targetPart.Position)
                    local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = p
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function isLockedTargetValid()
    local target = Config.LockOnTarget
    if not target then return false end
    if not target.Parent then return false end
    if not isValidTarget(target) then return false end
    if not getTargetPart(target.Character) then return false end
    return true
end

-- SILENT AIM
local function getSilentAimTarget()
    local closest, minDist = nil, Config.SilentAimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character then
            local part = p.Character:FindFirstChild(Config.SilentAimPart)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist < minDist then minDist = dist; closest = p end
                end
            end
        end
    end
    return closest
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.RightMouseDown = true
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Config.SilentAimToggle then
            -- Intensité = chance que le silent aim réussisse
            local chance = math.random(1, 100)
            if chance <= Config.SilentAimIntensity then
                local target = getSilentAimTarget()
                if target and target.Character then
                    local part = target.Character:FindFirstChild(Config.SilentAimPart)
                    if part then
                        local originalCF = Camera.CFrame
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                        task.delay(0.07, function()
                            if Camera then Camera.CFrame = originalCF end
                        end)
                    end
                end
            end
        end
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.RightMouseDown = false
        Config.LockOnTarget = nil
    end
end))

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not Config.AimbotToggle or not Config.RightMouseDown then return end
    if Config.LockOnTarget and isLockedTargetValid() then
        local targetPart = getTargetPart(Config.LockOnTarget.Character)
        local targetPosition = Camera:WorldToScreenPoint(targetPart.Position)
        if targetPosition.Z > 0 then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local aimPos = Vector2.new(targetPosition.X, targetPosition.Y)
            local moveDelta = (aimPos - mousePos) * Config.Sensitivity
            mousemoverel(moveDelta.X, moveDelta.Y)
        end
    else
        local newTarget = getClosestPlayerInFOV()
        if newTarget then Config.LockOnTarget = newTarget end
    end
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(p)
    if Config.LockOnTarget == p then Config.LockOnTarget = nil end
end))

-- ESP
local function ClearHighlights()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("ESPHighlight")
            if hl then hl:Destroy() end
            local nt = p.Character:FindFirstChild("ESPNameTag")
            if nt then nt:Destroy() end
        end
    end
end

local function RefreshHighlights()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local existingHL = char:FindFirstChild("ESPHighlight")
            local existingBB = char:FindFirstChild("ESPNameTag")
            local shouldBlink = Config.BlinkingESP and (tick() % 4 < 2)
            if Config.ShowESP and (not Config.BlinkingESP or shouldBlink) then
                if not existingHL then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESPHighlight"
                    hl.FillTransparency = Config.ESPTransparency
                    hl.OutlineTransparency = 1
                    hl.FillColor = Config.EnemyColor
                    hl.Parent = char
                else
                    existingHL.FillColor = Config.EnemyColor
                    existingHL.FillTransparency = Config.ESPTransparency
                end
                if Config.ShowNameTags and not existingBB then
                    local head = char:FindFirstChild("Head")
                    if head then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "ESPNameTag"
                        bb.Adornee = head
                        bb.Size = UDim2.new(0,100,0,20)
                        bb.StudsOffset = Vector3.new(0,2.5,0)
                        bb.AlwaysOnTop = true
                        local label = Instance.new("TextLabel", bb)
                        label.Size = UDim2.new(1,0,1,0)
                        label.BackgroundTransparency = 1
                        label.TextColor3 = Config.EnemyColor
                        label.TextScaled = true
                        label.Font = Enum.Font.SourceSansBold
                        if Config.HPESP then
                            task.spawn(function()
                                while label and label.Parent and Config.ShowESP do
                                    local hp = math.floor(p.Character.Humanoid.Health)
                                    label.Text = p.Name.." | "..hp.." HP"
                                    task.wait(0.1)
                                end
                            end)
                        else
                            label.Text = p.Name
                        end
                        bb.Parent = char
                    end
                end
            else
                if existingHL then existingHL:Destroy() end
                if existingBB then existingBB:Destroy() end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        local hl = p.Character:FindFirstChildWhichIsA("Highlight")
        if hl then hl:Destroy() end
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1); RefreshHighlights()
    end)
end)

task.spawn(function()
    while true do
        if Config.ShowESP then RefreshHighlights(); task.wait(0.1)
        else ClearHighlights(); task.wait(0.1) end
    end
end)

-- KEYBINDS GLOBAUX
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode.Name
    if keyName == aimlockKeyName then
        Config.AimbotToggle = not Config.AimbotToggle
    end
    if keyName == flyKeyName then
        if Config.Fly then stopFly() else startFly() end
    end
end)

-- ========================
-- GUI CUSTOM (style Kiciahook)
-- ========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LSX_V1"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Couleurs
local C_BG = Color3.fromRGB(28, 28, 30)
local C_BG2 = Color3.fromRGB(38, 38, 42)
local C_BG3 = Color3.fromRGB(48, 48, 54)
local C_ACCENT = Color3.fromRGB(0, 162, 255)
local C_ACCENT2 = Color3.fromRGB(0, 120, 200)
local C_TEXT = Color3.fromRGB(220, 220, 220)
local C_TEXT2 = Color3.fromRGB(150, 150, 155)
local C_BORDER = Color3.fromRGB(60, 60, 68)
local C_GREEN = Color3.fromRGB(40, 200, 100)
local C_RED = Color3.fromRGB(220, 60, 60)

-- Fenêtre principale
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 680, 0, 460)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -230)
MainFrame.BackgroundColor3 = C_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 4)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C_BORDER
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Titlebar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = C_BG2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 4)
TitleCorner.Parent = TitleBar

-- Fix coin bas du titlebar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 8)
TitleFix.Position = UDim2.new(0, 0, 1, -8)
TitleFix.BackgroundColor3 = C_BG2
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "LSX V1  |  Rivals"
TitleLabel.TextColor3 = C_TEXT
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 22)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = C_RED
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 3)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 22)
MinBtn.Position = UDim2.new(1, -64, 0, 5)
MinBtn.BackgroundColor3 = C_BG3
MinBtn.Text = "−"
MinBtn.TextColor3 = C_TEXT
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 3)

-- TABS
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 32)
TabBar.Position = UDim2.new(0, 0, 0, 32)
TabBar.BackgroundColor3 = C_BG2
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

-- Content area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -64)
ContentArea.Position = UDim2.new(0, 0, 0, 64)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Drag
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Minimize
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentArea.Visible = not minimized
    TabBar.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 680, 0, 32) or UDim2.new(0, 680, 0, 460)
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    if DrawingCircle then DrawingCircle:Remove() end
end)

-- ========================
-- HELPERS UI
-- ========================
local function makeTabBtn(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.BackgroundColor3 = C_BG2
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = C_TEXT2
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.LayoutOrder = order
    btn.Parent = TabBar

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(1, 0, 0, 2)
    indicator.Position = UDim2.new(0, 0, 1, -2)
    indicator.BackgroundColor3 = C_ACCENT
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn

    return btn, indicator
end

local function makePanel()
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency = 1
    panel.Visible = false
    panel.Parent = ContentArea
    return panel
end

local function makeSection(parent, name, posY)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, -20, 0, 18)
    label.Position = UDim2.new(0, 10, 0, posY)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C_TEXT
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.45, -20, 0, 1)
    line.Position = UDim2.new(0, 10, 0, posY + 20)
    line.BackgroundColor3 = C_ACCENT
    line.BorderSizePixel = 0
    line.Parent = parent

    return posY + 26
end

local function makeRightSection(parent, name, posY)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -10, 0, 18)
    label.Position = UDim2.new(0.5, 5, 0, posY)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C_TEXT
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.5, -10, 0, 1)
    line.Position = UDim2.new(0.5, 5, 0, posY + 20)
    line.BackgroundColor3 = C_ACCENT
    line.BorderSizePixel = 0
    line.Parent = parent

    return posY + 26
end

local function makeCheckbox(parent, text, defaultVal, posY, isRight, callback)
    local xOff = isRight and UDim2.new(0.5, 5, 0, posY) or UDim2.new(0, 10, 0, posY)
    local w = isRight and UDim2.new(0.5, -15, 0, 22) or UDim2.new(0.45, -20, 0, 22)

    local row = Instance.new("Frame")
    row.Size = w
    row.Position = xOff
    row.BackgroundTransparency = 1
    row.Parent = parent

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 14, 0, 14)
    box.Position = UDim2.new(0, 0, 0.5, -7)
    box.BackgroundColor3 = defaultVal and C_ACCENT or C_BG3
    box.BorderSizePixel = 0
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 2)
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = C_BORDER
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(1,0,1,0)
    check.BackgroundTransparency = 1
    check.Text = defaultVal and "✓" or ""
    check.TextColor3 = Color3.new(1,1,1)
    check.TextSize = 10
    check.Font = Enum.Font.GothamBold
    check.Parent = box

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 20, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C_TEXT
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local val = defaultVal
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        val = not val
        box.BackgroundColor3 = val and C_ACCENT or C_BG3
        check.Text = val and "✓" or ""
        if callback then callback(val) end
    end)

    return posY + 24, function(v)
        val = v
        box.BackgroundColor3 = val and C_ACCENT or C_BG3
        check.Text = val and "✓" or ""
    end
end

local function makeSlider(parent, text, min, max, default, posY, isRight, callback)
    local xOff = isRight and UDim2.new(0.5, 5, 0, posY) or UDim2.new(0, 10, 0, posY)
    local w = isRight and UDim2.new(0.5, -15, 0, 38) or UDim2.new(0.45, -20, 0, 38)

    local container = Instance.new("Frame")
    container.Size = w
    container.Position = xOff
    container.BackgroundTransparency = 1
    container.Parent = parent

    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1,0,0,16)
    topRow.BackgroundTransparency = 1
    topRow.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TEXT
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = topRow

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.4,0,1,0)
    valLabel.Position = UDim2.new(0.6,0,0,0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default).."/"..tostring(max)
    valLabel.TextColor3 = C_TEXT2
    valLabel.TextSize = 10
    valLabel.Font = Enum.Font.Gotham
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = topRow

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,0,0,6)
    track.Position = UDim2.new(0,0,0,20)
    track.BackgroundColor3 = C_BG3
    track.BorderSizePixel = 0
    track.Parent = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C_ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local val = default
    local sliding = false

    local function updateSlider(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max-min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valLabel.Text = tostring(val).."/"..tostring(max)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)

    return posY + 42
end

local function makeKeyBind(parent, text, defaultKey, posY, isRight, callback)
    local xOff = isRight and UDim2.new(0.5, 5, 0, posY) or UDim2.new(0, 10, 0, posY)
    local w = isRight and UDim2.new(0.5, -15, 0, 22) or UDim2.new(0.45, -20, 0, 22)

    local row = Instance.new("Frame")
    row.Size = w
    row.Position = xOff
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TEXT
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0.38, 0, 1, 0)
    keyBtn.Position = UDim2.new(0.62, 0, 0, 0)
    keyBtn.BackgroundColor3 = C_BG3
    keyBtn.Text = defaultKey
    keyBtn.TextColor3 = C_ACCENT
    keyBtn.TextSize = 10
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.BorderSizePixel = 0
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 3)
    local ks = Instance.new("UIStroke")
    ks.Color = C_ACCENT2
    ks.Thickness = 1
    ks.Parent = keyBtn

    local waiting = false
    keyBtn.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = C_TEXT2
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local name = input.KeyCode.Name
                keyBtn.Text = name
                keyBtn.TextColor3 = C_ACCENT
                if callback then callback(name) end
                waiting = false
                conn:Disconnect()
            end
        end)
    end)

    return posY + 26
end

local function makeDropdown(parent, text, options, defaultOpt, posY, isRight, callback)
    local xOff = isRight and UDim2.new(0.5, 5, 0, posY) or UDim2.new(0, 10, 0, posY)
    local w = isRight and UDim2.new(0.5, -15, 0, 22) or UDim2.new(0.45, -20, 0, 22)

    local row = Instance.new("Frame")
    row.Size = w
    row.Position = xOff
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TEXT
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.53, 0, 1, 0)
    dropBtn.Position = UDim2.new(0.47, 0, 0, 0)
    dropBtn.BackgroundColor3 = C_BG3
    dropBtn.Text = defaultOpt.." ▾"
    dropBtn.TextColor3 = C_TEXT
    dropBtn.TextSize = 10
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.BorderSizePixel = 0
    dropBtn.Parent = row
    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 3)
    local ds = Instance.new("UIStroke")
    ds.Color = C_BORDER
    ds.Thickness = 1
    ds.Parent = dropBtn

    local menuOpen = false
    local menuFrame = nil

    dropBtn.MouseButton1Click:Connect(function()
        if menuOpen and menuFrame then
            menuFrame:Destroy(); menuFrame = nil; menuOpen = false; return
        end
        menuOpen = true
        menuFrame = Instance.new("Frame")
        menuFrame.Size = UDim2.new(0, 140, 0, #options * 22)
        menuFrame.Position = UDim2.new(0, dropBtn.AbsolutePosition.X - parent.AbsolutePosition.X, 0, posY + 24)
        menuFrame.BackgroundColor3 = C_BG2
        menuFrame.BorderSizePixel = 0
        menuFrame.ZIndex = 10
        menuFrame.Parent = parent
        Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 3)
        local ms = Instance.new("UIStroke")
        ms.Color = C_BORDER; ms.Thickness = 1; ms.Parent = menuFrame

        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 22)
            optBtn.Position = UDim2.new(0, 0, 0, (i-1)*22)
            optBtn.BackgroundTransparency = 1
            optBtn.Text = opt
            optBtn.TextColor3 = C_TEXT
            optBtn.TextSize = 10
            optBtn.Font = Enum.Font.Gotham
            optBtn.ZIndex = 11
            optBtn.Parent = menuFrame
            optBtn.MouseButton1Click:Connect(function()
                dropBtn.Text = opt.." ▾"
                if callback then callback(opt) end
                menuFrame:Destroy(); menuFrame = nil; menuOpen = false
            end)
            optBtn.MouseEnter:Connect(function() optBtn.BackgroundTransparency = 0; optBtn.BackgroundColor3 = C_BG3 end)
            optBtn.MouseLeave:Connect(function() optBtn.BackgroundTransparency = 1 end)
        end
    end)

    return posY + 26
end

-- ========================
-- TABS SETUP
-- ========================
local tabs = {}
local tabPanels = {}
local tabIndicators = {}
local currentTab = nil

local tabNames = {"Combat", "Visuals", "Misc", "Settings"}

for i, name in ipairs(tabNames) do
    local btn, ind = makeTabBtn(name, i)
    local panel = makePanel()
    tabs[name] = btn
    tabPanels[name] = panel
    tabIndicators[name] = ind

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabPanels) do p.Visible = false end
        for _, ind2 in pairs(tabIndicators) do ind2.Visible = false end
        for _, b in pairs(tabs) do b.TextColor3 = C_TEXT2 end
        panel.Visible = true
        ind.Visible = true
        btn.TextColor3 = C_TEXT
        currentTab = name
    end)
end

-- Active premier tab
tabPanels["Combat"].Visible = true
tabIndicators["Combat"].Visible = true
tabs["Combat"].TextColor3 = C_TEXT
currentTab = "Combat"

-- ========================
-- COMBAT TAB
-- ========================
local CP = tabPanels["Combat"]
local cy = 8

-- Colonne gauche
cy = makeSection(CP, "Aimbot", cy)
cy, _ = makeCheckbox(CP, "Activer Aimbot", false, cy, false, function(v)
    Config.AimbotToggle = v
end)
cy, _ = makeCheckbox(CP, "Wall Check", true, cy, false, function(v)
    Config.WallCheck = v
end)
cy, _ = makeCheckbox(CP, "Afficher FOV", true, cy, false, function(v)
    Config.ShowFOV = v
    if DrawingCircle then DrawingCircle.Visible = v and Config.AimbotToggle end
end)
cy = makeSlider(CP, "FOV", 10, 600, 150, cy, false, function(v) Config.FOV = v end)
cy = makeSlider(CP, "Sensibilité", 1, 100, 30, cy, false, function(v) Config.Sensitivity = v/100 end)
cy = makeDropdown(CP, "Partie visée", {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"}, "Head", cy, false, function(v)
    Config.AimbotPart = v
end)
cy = makeKeyBind(CP, "Touche Aimbot", "Q", cy, false, function(k)
    aimlockKeyName = k
end)

-- Colonne droite
local ry = 8
ry = makeRightSection(CP, "Silent Aim", ry)
ry, _ = makeCheckbox(CP, "Activer Silent Aim", false, ry, true, function(v)
    Config.SilentAimToggle = v
end)
ry = makeSlider(CP, "FOV Silent Aim", 10, 600, 200, ry, true, function(v) Config.SilentAimFOV = v end)
ry = makeSlider(CP, "Intensité (%)", 0, 100, 100, ry, true, function(v) Config.SilentAimIntensity = v end)
ry = makeDropdown(CP, "Partie visée", {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"}, "Head", ry, true, function(v)
    Config.SilentAimPart = v
end)
ry = makeKeyBind(CP, "Touche Silent Aim", "F", ry, true, function(k)
    silentAimKeyName = k
end)

-- ========================
-- VISUALS TAB
-- ========================
local VP = tabPanels["Visuals"]
local vy = 8

vy = makeSection(VP, "ESP", vy)
vy, _ = makeCheckbox(VP, "Activer ESP", false, vy, false, function(v)
    Config.ShowESP = v; RefreshHighlights()
end)
vy, _ = makeCheckbox(VP, "ESP Clignotant", false, vy, false, function(v)
    Config.BlinkingESP = v
end)
vy, _ = makeCheckbox(VP, "Noms", true, vy, false, function(v)
    Config.ShowNameTags = v; RefreshHighlights()
end)
vy, _ = makeCheckbox(VP, "HP dans le nom", true, vy, false, function(v)
    Config.HPESP = v; RefreshHighlights()
end)
vy = makeSlider(VP, "Transparence", 0, 100, 30, vy, false, function(v)
    Config.ESPTransparency = v/100; RefreshHighlights()
end)

local rvy = 8
rvy = makeRightSection(VP, "Fly", rvy)
rvy, _ = makeCheckbox(VP, "Activer Fly", false, rvy, true, function(v)
    if v then startFly() else stopFly() end
end)
rvy = makeSlider(VP, "Vitesse Fly", 10, 2000, 100, rvy, true, function(v) Config.FlySpeed = v end)
rvy = makeKeyBind(VP, "Touche Fly", "G", rvy, true, function(k) flyKeyName = k end)

rvy = makeRightSection(VP, "Spin", rvy)
rvy, _ = makeCheckbox(VP, "Activer Spin", false, rvy, true, function(v)
    if v then startSpin() else stopSpin() end
end)
rvy = makeSlider(VP, "Vitesse Spin", 1, 100, 10, rvy, true, function(v) spinSpeed = v end)
rvy = makeDropdown(VP, "Direction", {"Clockwise","Counterclockwise"}, "Clockwise", rvy, true, function(v)
    spinDirection = v == "Clockwise" and 1 or -1
end)
rvy = makeDropdown(VP, "Axe", {"Y","X","Z"}, "Y", rvy, true, function(v) spinAxis = v end)

-- ========================
-- MISC TAB
-- ========================
local MP = tabPanels["Misc"]
local my = 8

my = makeSection(MP, "Mouvement", my)
my, _ = makeCheckbox(MP, "Noclip", false, my, false, function(v) Config.Noclip = v end)
my, _ = makeCheckbox(MP, "Infinite Jump", false, my, false, function(v)
    Config.InfiniteJump = v
    if v then startInfiniteJump() else stopInfiniteJump() end
end)
my, _ = makeCheckbox(MP, "Invisible", false, my, false, function(v) setInvis(v) end)
my, _ = makeCheckbox(MP, "Auto Respawn", false, my, false, function(v) Config.AutoRespawn = v end)

my = makeSection(MP, "Character", my)
my, _ = makeCheckbox(MP, "WalkSpeed", false, my, false, function(v)
    Config.WalkSpeed = v
    if v then startLoopSpeed() else stopLoopSpeed() end
end)
my = makeSlider(MP, "Set WalkSpeed", 16, 500, 25, my, false, function(v) Config.WalkSpeedValue = v end)
my, _ = makeCheckbox(MP, "JumpPower", false, my, false, function(v)
    Config.JumpPower = v
    if v then startLoopPower() else stopLoopPower() end
end)
my = makeSlider(MP, "Set JumpPower", 20, 500, 20, my, false, function(v) Config.JumpPowerValue = v end)

local rmy = 8
rmy = makeRightSection(MP, "World", rmy)
rmy, _ = makeCheckbox(MP, "Supprimer Fumigènes", false, rmy, true, function(v) Config.Smoke = v end)

-- ========================
-- SETTINGS TAB
-- ========================
local SP = tabPanels["Settings"]
local sy = 8

sy = makeSection(SP, "Interface", sy)
sy, _ = makeCheckbox(SP, "Toujours visible", true, sy, false, function(v)
    ScreenGui.Enabled = v
end)

sy = makeSection(SP, "Fermer", sy)

local closeAllBtn = Instance.new("TextButton")
closeAllBtn.Size = UDim2.new(0.45, -20, 0, 28)
closeAllBtn.Position = UDim2.new(0, 10, 0, sy)
closeAllBtn.BackgroundColor3 = C_RED
closeAllBtn.Text = "FERMER LSX V1"
closeAllBtn.TextColor3 = Color3.new(1,1,1)
closeAllBtn.TextSize = 12
closeAllBtn.Font = Enum.Font.GothamBold
closeAllBtn.BorderSizePixel = 0
closeAllBtn.Parent = SP
Instance.new("UICorner", closeAllBtn).CornerRadius = UDim.new(0, 3)

closeAllBtn.MouseButton1Click:Connect(function()
    Config.AimbotToggle = false
    Config.ShowESP = false
    Config.Noclip = false
    Config.WalkSpeed = false
    Config.JumpPower = false
    Config.InfiniteJump = false
    Config.Fly = false
    Config.Smoke = false
    Config.SilentAimToggle = false
    stopFly(); stopLoopSpeed(); stopLoopPower(); stopInfiniteJump()
    ClearHighlights()
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 25.2; h.JumpPower = 20 end
    for _, conn in ipairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
    end
    if DrawingCircle then DrawingCircle:Remove(); DrawingCircle = nil end
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    ScreenGui:Destroy()
end)

local rqBtn = Instance.new("TextButton")
rqBtn.Size = UDim2.new(0.45, -20, 0, 28)
rqBtn.Position = UDim2.new(0.5, 5, 0, sy)
rqBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
rqBtn.Text = "RAGE QUIT"
rqBtn.TextColor3 = Color3.new(1,1,1)
rqBtn.TextSize = 12
rqBtn.Font = Enum.Font.GothamBold
rqBtn.BorderSizePixel = 0
rqBtn.Parent = SP
Instance.new("UICorner", rqBtn).CornerRadius = UDim.new(0, 3)
rqBtn.MouseButton1Click:Connect(function()
    player:Kick("LSX V1 — Rage quit")
end)
