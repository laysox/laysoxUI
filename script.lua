task.wait(3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UIS = UserInputService

local player = Players.LocalPlayer
local Mouse = player:GetMouse()
repeat task.wait() until player.Character
local character = player.Character
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

-- ========================
-- ANTI-DETECTION
-- Rend le script le plus discret possible
-- ========================
local function safeCall(f, ...)
    local ok, err = pcall(f, ...)
    if not ok then end
end

-- Cache le script dans les descendants
local scriptRef = script
safeCall(function()
    if scriptRef then
        scriptRef.Name = "RbxGui"
    end
end)

-- Pas de prints, pas de warns
local oldPrint = print
local oldWarn = warn
print = function() end
warn = function() end

-- CONFIG
local Config = {
    -- Aimbot
    AimbotToggle = false,
    AimbotPart = "Head",
    RightMouseDown = false,
    FOV = 150,
    Sensitivity = 0.3,
    LockOnTarget = nil,
    ShowFOV = true,
    WallCheck = true,
    -- Silent Aim
    SilentAimToggle = false,
    SilentAimPart = "Head",
    SilentAimFOV = 200,
    SilentAimIntensity = 100,
    -- ESP
    ShowESP = false,
    EnemyColor = Color3.fromRGB(0, 162, 255),
    HPESP = true,
    ESPTransparency = 0.3,
    ShowNameTags = true,
    BlinkingESP = false,
    -- Player
    WalkSpeed = false,
    WalkSpeedValue = 25.2,
    JumpPower = false,
    JumpPowerValue = 20,
    Noclip = false,
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 100,
    Smoke = false,
    -- Misc
    AutoRespawn = false,
    AutoReactivate = false,
    -- UI
    MenuKey = "LeftShift",
    GuiOpen = true,
}

-- Sauvegarde état features pour AutoReactivate
local FeatureState = {
    AimbotToggle = false,
    SilentAimToggle = false,
    ShowESP = false,
    WalkSpeed = false,
    JumpPower = false,
    Noclip = false,
    InfiniteJump = false,
    Fly = false,
    Smoke = false,
    AutoRespawn = false,
}

local HumanModCons = {}
local connections = {}
local noclippedParts = {}
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

local aimlockKeyName = "Q"
local flyKeyName = "G"
local silentAimKeyName = "F"

-- ========================
-- UPDATE PERSO
-- ========================
local function refresh()
    character = player.Character
    if not character then return end
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end

-- ========================
-- TEAM CHECK
-- ========================
local function isEnemy(p)
    if not p or p == player then return false end
    if player.Team and p.Team then return player.Team ~= p.Team end
    return true
end

-- ========================
-- WALKSPEED
-- ========================
local function startLoopSpeed()
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply()
        -- Applique via propriété directe — moins détectable que boucle
        h.WalkSpeed = Config.WalkSpeedValue
    end
    apply()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    HumanModCons.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
end

local function stopLoopSpeed()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 25.2 end
end

-- ========================
-- JUMPPOWER
-- ========================
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

-- ========================
-- INFINITE JUMP
-- ========================
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

-- ========================
-- FLY
-- ========================
local activeFlyConn = nil

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

    if activeFlyConn then activeFlyConn:Disconnect() end
    activeFlyConn = RunService.RenderStepped:Connect(function()
        if not Config.Fly or not hrp or not hrp.Parent then
            if activeFlyConn then activeFlyConn:Disconnect(); activeFlyConn = nil end
            safeCall(function() gyro:Destroy() end)
            safeCall(function() vel:Destroy() end)
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
    if activeFlyConn then activeFlyConn:Disconnect(); activeFlyConn = nil end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
    end
end

-- ========================
-- NOCLIP
-- ========================
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

-- ========================
-- INVISIBLE
-- ========================
local function setInvis(state)
    invisible = state
    local char = player.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if state then originalTransparency[p] = p.Transparency; p.Transparency = 1; p.LocalTransparencyModifier = 1
            else p.Transparency = originalTransparency[p] or 0; p.LocalTransparencyModifier = 0 end
        end
        if p:IsA("Decal") then p.Transparency = state and 1 or 0 end
    end
    for _, obj in pairs(char:GetChildren()) do
        if obj:IsA("Accessory") then
            local h = obj:FindFirstChild("Handle")
            if h then
                if state then originalTransparency[h] = h.Transparency; h.Transparency = 1; h.LocalTransparencyModifier = 1
                else h.Transparency = originalTransparency[h] or 0; h.LocalTransparencyModifier = 0 end
            end
        end
    end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.DisplayDistanceType = state and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Automatic
    end
end

-- ========================
-- SPIN
-- ========================
local function getSpinCF()
    local a = math.rad(spinSpeed) * spinDirection
    if spinAxis == "X" then return CFrame.Angles(a,0,0)
    elseif spinAxis == "Z" then return CFrame.Angles(0,0,a)
    else return CFrame.Angles(0,a,0) end
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

-- ========================
-- SMOKE
-- ========================
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

-- ========================
-- AUTO RESPAWN
-- ========================
local function setupAutoRespawn()
    if not humanoid then return end
    humanoid.Died:Connect(function()
        if not Config.AutoRespawn then return end
        task.wait(0.2)
        safeCall(function() player:LoadCharacter() end)
    end)
end

-- ========================
-- SAVE/RESTORE FEATURES (AutoReactivate)
-- ========================
local function saveFeatureState()
    FeatureState.AimbotToggle = Config.AimbotToggle
    FeatureState.SilentAimToggle = Config.SilentAimToggle
    FeatureState.ShowESP = Config.ShowESP
    FeatureState.WalkSpeed = Config.WalkSpeed
    FeatureState.JumpPower = Config.JumpPower
    FeatureState.Noclip = Config.Noclip
    FeatureState.InfiniteJump = Config.InfiniteJump
    FeatureState.Fly = Config.Fly
    FeatureState.Smoke = Config.Smoke
    FeatureState.AutoRespawn = Config.AutoRespawn
end

local function restoreFeatureState()
    if not Config.AutoReactivate then return end
    task.wait(0.5)
    if FeatureState.AimbotToggle then Config.AimbotToggle = true end
    if FeatureState.SilentAimToggle then Config.SilentAimToggle = true end
    if FeatureState.ShowESP then Config.ShowESP = true end
    if FeatureState.WalkSpeed then Config.WalkSpeed = true; startLoopSpeed() end
    if FeatureState.JumpPower then Config.JumpPower = true; startLoopPower() end
    if FeatureState.Noclip then Config.Noclip = true end
    if FeatureState.InfiniteJump then Config.InfiniteJump = true; startInfiniteJump() end
    if FeatureState.Fly then
        task.wait(1)
        startFly()
    end
    if FeatureState.Smoke then Config.Smoke = true end
    if FeatureState.AutoRespawn then Config.AutoRespawn = true end
end

-- ========================
-- AIMBOT
-- ========================
safeCall(function()
    if Drawing then
        DrawingCircle = Drawing.new("Circle")
        DrawingCircle.Thickness = 1
        DrawingCircle.Filled = false
        DrawingCircle.Transparency = 1
        DrawingCircle.Color = Color3.fromRGB(0, 162, 255)
        DrawingCircle.Visible = false
        DrawingCircle.Radius = Config.FOV
        table.insert(connections, RunService.RenderStepped:Connect(function()
            DrawingCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
            DrawingCircle.Radius = Config.FOV
            DrawingCircle.Visible = Config.ShowFOV and Config.AimbotToggle and not Config.GuiOpen
        end))
    end
end)

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

local function getClosestInFOV()
    local closest, shortest = nil, Config.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local part = getTargetPart(p.Character)
            if part then
                if not Config.WallCheck or isVisible(p) then
                    local sp = Camera:WorldToScreenPoint(part.Position)
                    local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(sp.X, sp.Y)).Magnitude
                    if dist < shortest then closest = p; shortest = dist end
                end
            end
        end
    end
    return closest
end

local function isLockedValid()
    local t = Config.LockOnTarget
    if not t or not t.Parent then return false end
    if not isValidTarget(t) then return false end
    if not getTargetPart(t.Character) then return false end
    return true
end

-- SILENT AIM
local function getSATarget()
    local closest, minD = nil, Config.SilentAimFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in pairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character then
            local part = p.Character:FindFirstChild(Config.SilentAimPart)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist < minD then minD = dist; closest = p end
                end
            end
        end
    end
    return closest
end

-- INPUT HANDLER
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.RightMouseDown = true
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Config.SilentAimToggle and not Config.GuiOpen then
            local chance = math.random(1, 100)
            if chance <= Config.SilentAimIntensity then
                local target = getSATarget()
                if target and target.Character then
                    local part = target.Character:FindFirstChild(Config.SilentAimPart)
                    if part then
                        local originalCF = Camera.CFrame
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                        task.delay(0.065, function()
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
    if not Config.AimbotToggle or not Config.RightMouseDown or Config.GuiOpen then return end
    if Config.LockOnTarget and isLockedValid() then
        local part = getTargetPart(Config.LockOnTarget.Character)
        local pos = Camera:WorldToScreenPoint(part.Position)
        if pos.Z > 0 then
            local delta = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)) * Config.Sensitivity
            safeCall(function() mousemoverel(delta.X, delta.Y) end)
        end
    else
        local t = getClosestInFOV()
        if t then Config.LockOnTarget = t end
    end
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(p)
    if Config.LockOnTarget == p then Config.LockOnTarget = nil end
end))

-- ========================
-- ESP
-- ========================
local storedNametags = {}

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
                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3 = Config.EnemyColor
                        lbl.TextScaled = true
                        lbl.Font = Enum.Font.SourceSansBold
                        if Config.HPESP then
                            task.spawn(function()
                                while lbl and lbl.Parent and Config.ShowESP do
                                    safeCall(function()
                                        local hp = math.floor(p.Character.Humanoid.Health)
                                        lbl.Text = p.Name.." | "..hp.." HP"
                                    end)
                                    task.wait(0.1)
                                end
                            end)
                        else
                            lbl.Text = p.Name
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
    p.CharacterAdded:Connect(function() task.wait(1); RefreshHighlights() end)
end)

task.spawn(function()
    while true do
        if Config.ShowESP then RefreshHighlights() else ClearHighlights() end
        task.wait(0.15)
    end
end)

-- ========================
-- CharacterAdded — Persist features
-- ========================
player.CharacterAdded:Connect(function()
    task.wait(1)
    refresh()
    setupAutoRespawn()
    restoreFeatureState()

    -- Refresh checkboxes UI après respawn
    task.wait(0.5)
    if Config.ShowESP then RefreshHighlights() end
end)

setupAutoRespawn()

-- ========================
-- KEYBINDS GLOBAUX
-- ========================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode.Name

    -- Toggle menu
    if k == Config.MenuKey then
        Config.GuiOpen = not Config.GuiOpen
        -- Libère ou bloque le curseur
        if Config.GuiOpen then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
        return
    end

    if Config.GuiOpen then return end -- Bloque les keybinds si menu ouvert

    if k == aimlockKeyName then
        Config.AimbotToggle = not Config.AimbotToggle
    end
    if k == flyKeyName then
        if Config.Fly then stopFly() else startFly() end
    end
end)

-- Libère le curseur quand le menu est ouvert
RunService.RenderStepped:Connect(function()
    if Config.GuiOpen then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- ========================
-- GUI CUSTOM — LSX V1
-- ========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CoreGui_"..math.random(1000,9999) -- Nom aléatoire anti-détection
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999 -- Passe devant TOUT
ScreenGui.IgnoreGuiInset = true

-- Tente de mettre dans CoreGui pour passer devant tout
local guiParented = false
safeCall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
    guiParented = true
end)
if not guiParented then
    ScreenGui.Parent = player:WaitForChild("PlayerGui")
end

-- COULEURS
local C = {
    bg      = Color3.fromRGB(22, 22, 24),
    bg2     = Color3.fromRGB(30, 30, 33),
    bg3     = Color3.fromRGB(40, 40, 44),
    accent  = Color3.fromRGB(0, 150, 255),
    accent2 = Color3.fromRGB(0, 100, 200),
    text    = Color3.fromRGB(215, 215, 220),
    text2   = Color3.fromRGB(130, 130, 138),
    border  = Color3.fromRGB(55, 55, 62),
    red     = Color3.fromRGB(210, 55, 55),
    green   = Color3.fromRGB(35, 190, 90),
}

-- FENÊTRE
local MainFrame = Instance.new("Frame")
MainFrame.Name = "M"
MainFrame.Size = UDim2.new(0, 660, 0, 440)
MainFrame.Position = UDim2.new(0.5,-330,0.5,-220)
MainFrame.BackgroundColor3 = C.bg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Selectable = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,4)
local ms = Instance.new("UIStroke", MainFrame)
ms.Color = C.border; ms.Thickness = 1

-- VISIBILITY
local function setGuiVisible(v)
    Config.GuiOpen = v
    MainFrame.Visible = v
    if v then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

-- TITLEBAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,30)
TitleBar.BackgroundColor3 = C.bg2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,4)
local tf = Instance.new("Frame", TitleBar)
tf.Size = UDim2.new(1,0,0,8); tf.Position = UDim2.new(0,0,1,-8)
tf.BackgroundColor3 = C.bg2; tf.BorderSizePixel = 0

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size = UDim2.new(1,-70,1,0); TitleLbl.Position = UDim2.new(0,10,0,0)
TitleLbl.BackgroundTransparency = 1; TitleLbl.Text = "LSX V1  |  Rivals"
TitleLbl.TextColor3 = C.text; TitleLbl.TextSize = 12
TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0,26,0,20); CloseBtn.Position = UDim2.new(1,-30,0,5)
CloseBtn.BackgroundColor3 = C.red; CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.TextSize = 11
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,3)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0,26,0,20); MinBtn.Position = UDim2.new(1,-60,0,5)
MinBtn.BackgroundColor3 = C.bg3; MinBtn.Text = "−"
MinBtn.TextColor3 = C.text; MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold; MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,3)

-- DRAG
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- MINIMIZE
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, c in pairs(MainFrame:GetChildren()) do
        if c ~= TitleBar then c.Visible = not minimized end
    end
    MainFrame.Size = minimized and UDim2.new(0,660,0,30) or UDim2.new(0,660,0,440)
end)

CloseBtn.MouseButton1Click:Connect(function()
    setGuiVisible(false)
    MainFrame.Visible = false
end)

-- TABBAR
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1,0,0,30)
TabBar.Position = UDim2.new(0,0,0,30)
TabBar.BackgroundColor3 = C.bg2
TabBar.BorderSizePixel = 0
local tbl = Instance.new("UIListLayout", TabBar)
tbl.FillDirection = Enum.FillDirection.Horizontal
tbl.SortOrder = Enum.SortOrder.LayoutOrder

-- CONTENT
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1,0,1,-60)
Content.Position = UDim2.new(0,0,0,60)
Content.BackgroundTransparency = 1

-- ========================
-- UI HELPERS
-- ========================
local function Tab(name, order)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0,110,1,0)
    btn.BackgroundColor3 = C.bg2
    btn.BorderSizePixel = 0
    btn.Text = name; btn.TextColor3 = C.text2
    btn.TextSize = 11; btn.Font = Enum.Font.Gotham
    btn.LayoutOrder = order

    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(1,0,0,2)
    ind.Position = UDim2.new(0,0,1,-2)
    ind.BackgroundColor3 = C.accent
    ind.BorderSizePixel = 0; ind.Visible = false

    local panel = Instance.new("Frame", Content)
    panel.Size = UDim2.new(1,0,1,0)
    panel.BackgroundTransparency = 1; panel.Visible = false

    return btn, ind, panel
end

local function activate(btn, ind, panel, allBtns, allInds, allPanels)
    for _, p in pairs(allPanels) do p.Visible = false end
    for _, i in pairs(allInds) do i.Visible = false end
    for _, b in pairs(allBtns) do b.TextColor3 = C.text2 end
    panel.Visible = true; ind.Visible = true; btn.TextColor3 = C.text
end

-- Checkbox
local checkboxRefs = {}

local function CB(parent, label, default, x, y, w, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0, w, 0, 20)
    f.Position = UDim2.new(0, x, 0, y)
    f.BackgroundTransparency = 1

    local box = Instance.new("Frame", f)
    box.Size = UDim2.new(0,13,0,13)
    box.Position = UDim2.new(0,0,0.5,-6)
    box.BackgroundColor3 = default and C.accent or C.bg3
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,2)
    local bstroke = Instance.new("UIStroke", box); bstroke.Color = C.border; bstroke.Thickness = 1

    local tick_ = Instance.new("TextLabel", box)
    tick_.Size = UDim2.new(1,0,1,0); tick_.BackgroundTransparency = 1
    tick_.Text = default and "✓" or ""; tick_.TextColor3 = Color3.new(1,1,1)
    tick_.TextSize = 9; tick_.Font = Enum.Font.GothamBold

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,-18,1,0); lbl.Position = UDim2.new(0,18,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = C.text; lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local val = default
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""

    local function setVal(v)
        val = v
        box.BackgroundColor3 = v and C.accent or C.bg3
        tick_.Text = v and "✓" or ""
    end

    btn.MouseButton1Click:Connect(function()
        setVal(not val)
        if callback then callback(val) end
    end)

    return setVal
end

-- Slider
local function SL(parent, label, min, max, default, x, y, w, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0, w, 0, 36)
    f.Position = UDim2.new(0, x, 0, y)
    f.BackgroundTransparency = 1

    local top = Instance.new("Frame", f)
    top.Size = UDim2.new(1,0,0,14); top.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", top)
    lbl.Size = UDim2.new(0.6,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = C.text
    lbl.TextSize = 10; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local vlbl = Instance.new("TextLabel", top)
    vlbl.Size = UDim2.new(0.4,0,1,0); vlbl.Position = UDim2.new(0.6,0,0,0)
    vlbl.BackgroundTransparency = 1; vlbl.Text = tostring(default).."/"..tostring(max)
    vlbl.TextColor3 = C.text2; vlbl.TextSize = 10
    vlbl.Font = Enum.Font.Gotham; vlbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", f)
    track.Size = UDim2.new(1,0,0,5); track.Position = UDim2.new(0,0,0,18)
    track.BackgroundColor3 = C.bg3; track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(0,3)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = C.accent; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)

    local val = default; local sliding = false

    local function upd(mx)
        local rel = math.clamp((mx - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local step = (max-min)
        val = math.floor(min + step*rel)
        fill.Size = UDim2.new(rel,0,1,0)
        vlbl.Text = tostring(val).."/"..tostring(max)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
end

-- KeyBind
local function KB(parent, label, default, x, y, w, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0, w, 0, 20)
    f.Position = UDim2.new(0, x, 0, y)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.55,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = C.text
    lbl.TextSize = 10; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local kbtn = Instance.new("TextButton", f)
    kbtn.Size = UDim2.new(0.43,0,1,0); kbtn.Position = UDim2.new(0.57,0,0,0)
    kbtn.BackgroundColor3 = C.bg3; kbtn.Text = default
    kbtn.TextColor3 = C.accent; kbtn.TextSize = 10
    kbtn.Font = Enum.Font.GothamBold; kbtn.BorderSizePixel = 0
    Instance.new("UICorner", kbtn).CornerRadius = UDim.new(0,2)
    local ks = Instance.new("UIStroke", kbtn); ks.Color = C.accent2; ks.Thickness = 1

    local waiting = false
    kbtn.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true; kbtn.Text = "..."; kbtn.TextColor3 = C.text2
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local name = input.KeyCode.Name
                kbtn.Text = name; kbtn.TextColor3 = C.accent
                if callback then callback(name) end
                waiting = false; conn:Disconnect()
            end
        end)
    end)

    return kbtn
end

-- Dropdown
local function DD(parent, label, opts, default, x, y, w, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0, w, 0, 20)
    f.Position = UDim2.new(0, x, 0, y)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.45,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = C.text
    lbl.TextSize = 10; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local dbtn = Instance.new("TextButton", f)
    dbtn.Size = UDim2.new(0.53,0,1,0); dbtn.Position = UDim2.new(0.47,0,0,0)
    dbtn.BackgroundColor3 = C.bg3; dbtn.Text = default.." ▾"
    dbtn.TextColor3 = C.text; dbtn.TextSize = 9
    dbtn.Font = Enum.Font.Gotham; dbtn.BorderSizePixel = 0
    Instance.new("UICorner", dbtn).CornerRadius = UDim.new(0,2)
    local ds = Instance.new("UIStroke", dbtn); ds.Color = C.border; ds.Thickness = 1

    local open = false; local menu = nil
    dbtn.MouseButton1Click:Connect(function()
        if open and menu then menu:Destroy(); menu = nil; open = false; return end
        open = true
        menu = Instance.new("Frame", parent)
        menu.Size = UDim2.new(0,120,0,#opts*20)
        menu.Position = UDim2.new(0, x + w*0.47, 0, y+22)
        menu.BackgroundColor3 = C.bg2; menu.BorderSizePixel = 0; menu.ZIndex = 20
        Instance.new("UICorner", menu).CornerRadius = UDim.new(0,3)
        local mstroke = Instance.new("UIStroke", menu); mstroke.Color = C.border; mstroke.Thickness = 1

        for i, opt in ipairs(opts) do
            local ob = Instance.new("TextButton", menu)
            ob.Size = UDim2.new(1,0,0,20); ob.Position = UDim2.new(0,0,0,(i-1)*20)
            ob.BackgroundTransparency = 1; ob.Text = opt
            ob.TextColor3 = C.text; ob.TextSize = 10
            ob.Font = Enum.Font.Gotham; ob.ZIndex = 21
            ob.MouseButton1Click:Connect(function()
                dbtn.Text = opt.." ▾"
                if callback then callback(opt) end
                menu:Destroy(); menu = nil; open = false
            end)
            ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0; ob.BackgroundColor3 = C.bg3 end)
            ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
        end
    end)
end

-- Separator label
local function SEC(parent, label, x, y, w)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(0, w, 0, 16)
    lbl.Position = UDim2.new(0, x, 0, y)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = C.text; lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", parent)
    line.Size = UDim2.new(0, w, 0, 1)
    line.Position = UDim2.new(0, x, 0, y+17)
    line.BackgroundColor3 = C.accent; line.BorderSizePixel = 0
end

-- ========================
-- BUILD TABS
-- ========================
local allBtns, allInds, allPanels = {}, {}, {}

local combatBtn, combatInd, combatP = Tab("Combat", 1)
local visualsBtn, visualsInd, visualsP = Tab("Visuals", 2)
local miscBtn, miscInd, miscP = Tab("Misc", 3)
local settingsBtn, settingsInd, settingsP = Tab("Settings", 4)

allBtns = {combatBtn, visualsBtn, miscBtn, settingsBtn}
allInds = {combatInd, visualsInd, miscInd, settingsInd}
allPanels = {combatP, visualsP, miscP, settingsP}

for i, btn in ipairs(allBtns) do
    local ind = allInds[i]; local panel = allPanels[i]
    btn.MouseButton1Click:Connect(function()
        activate(btn, ind, panel, allBtns, allInds, allPanels)
    end)
end

-- Active Combat par défaut
activate(combatBtn, combatInd, combatP, allBtns, allInds, allPanels)

-- Colonnes
local LW = 300  -- largeur colonne gauche
local RX = 330  -- départ colonne droite
local RW = 300  -- largeur colonne droite

-- ========================
-- COMBAT TAB
-- ========================
local lcy = 8
local rcy = 8

SEC(combatP, "Aimbot", 8, lcy, LW); lcy = lcy + 24
CB(combatP, "Activer Aimbot", false, 8, lcy, LW, function(v) Config.AimbotToggle = v end); lcy = lcy + 22
CB(combatP, "Wall Check", true, 8, lcy, LW, function(v) Config.WallCheck = v end); lcy = lcy + 22
CB(combatP, "Afficher FOV", true, 8, lcy, LW, function(v)
    Config.ShowFOV = v
    if DrawingCircle then DrawingCircle.Visible = v and Config.AimbotToggle end
end); lcy = lcy + 22
SL(combatP, "FOV", 10, 600, 150, 8, lcy, LW, function(v) Config.FOV = v end); lcy = lcy + 40
SL(combatP, "Sensibilité", 1, 100, 30, 8, lcy, LW, function(v) Config.Sensitivity = v/100 end); lcy = lcy + 40
DD(combatP, "Partie visée", {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"}, "Head", 8, lcy, LW, function(v)
    Config.AimbotPart = v
end); lcy = lcy + 24
KB(combatP, "Touche Aimbot", "Q", 8, lcy, LW, function(k) aimlockKeyName = k end)

-- Droite
SEC(combatP, "Silent Aim", RX, rcy, RW); rcy = rcy + 24
CB(combatP, "Activer Silent Aim", false, RX, rcy, RW, function(v) Config.SilentAimToggle = v end); rcy = rcy + 22
SL(combatP, "FOV Silent Aim", 10, 600, 200, RX, rcy, RW, function(v) Config.SilentAimFOV = v end); rcy = rcy + 40
SL(combatP, "Intensité (%)", 0, 100, 100, RX, rcy, RW, function(v) Config.SilentAimIntensity = v end); rcy = rcy + 40
DD(combatP, "Partie visée", {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"}, "Head", RX, rcy, RW, function(v)
    Config.SilentAimPart = v
end); rcy = rcy + 24
KB(combatP, "Touche Silent Aim", "F", RX, rcy, RW, function(k) silentAimKeyName = k end)

-- ========================
-- VISUALS TAB
-- ========================
local vly = 8; local vry = 8

SEC(visualsP, "ESP", 8, vly, LW); vly = vly + 24
CB(visualsP, "Activer ESP", false, 8, vly, LW, function(v) Config.ShowESP = v end); vly = vly + 22
CB(visualsP, "ESP Clignotant", false, 8, vly, LW, function(v) Config.BlinkingESP = v end); vly = vly + 22
CB(visualsP, "Noms", true, 8, vly, LW, function(v) Config.ShowNameTags = v end); vly = vly + 22
CB(visualsP, "HP dans le nom", true, 8, vly, LW, function(v) Config.HPESP = v end); vly = vly + 22
SL(visualsP, "Transparence", 0, 100, 30, 8, vly, LW, function(v) Config.ESPTransparency = v/100 end); vly = vly + 40

SEC(visualsP, "Fly", RX, vry, RW); vry = vry + 24
CB(visualsP, "Activer Fly", false, RX, vry, RW, function(v)
    if v then startFly() else stopFly() end
end); vry = vry + 22
SL(visualsP, "Vitesse Fly", 10, 2000, 100, RX, vry, RW, function(v) Config.FlySpeed = v end); vry = vry + 40
KB(visualsP, "Touche Fly", "G", RX, vry, RW, function(k) flyKeyName = k end); vry = vry + 24

SEC(visualsP, "Spin", RX, vry, RW); vry = vry + 24
CB(visualsP, "Activer Spin", false, RX, vry, RW, function(v)
    if v then startSpin() else stopSpin() end
end); vry = vry + 22
SL(visualsP, "Vitesse Spin", 1, 100, 10, RX, vry, RW, function(v) spinSpeed = v end); vry = vry + 40
DD(visualsP, "Direction", {"Clockwise","Counterclockwise"}, "Clockwise", RX, vry, RW, function(v)
    spinDirection = v == "Clockwise" and 1 or -1
end); vry = vry + 24
DD(visualsP, "Axe", {"Y","X","Z"}, "Y", RX, vry, RW, function(v) spinAxis = v end)

-- ========================
-- MISC TAB
-- ========================
local mly = 8; local mry = 8

SEC(miscP, "Mouvement", 8, mly, LW); mly = mly + 24
CB(miscP, "Noclip", false, 8, mly, LW, function(v) Config.Noclip = v end); mly = mly + 22
CB(miscP, "Infinite Jump", false, 8, mly, LW, function(v)
    Config.InfiniteJump = v
    if v then startInfiniteJump() else stopInfiniteJump() end
end); mly = mly + 22
CB(miscP, "Invisible", false, 8, mly, LW, function(v) setInvis(v) end); mly = mly + 22
CB(miscP, "Auto Respawn", false, 8, mly, LW, function(v) Config.AutoRespawn = v end); mly = mly + 22

SEC(miscP, "Character", 8, mly, LW); mly = mly + 24
CB(miscP, "WalkSpeed", false, 8, mly, LW, function(v)
    Config.WalkSpeed = v
    if v then startLoopSpeed() else stopLoopSpeed() end
end); mly = mly + 22
SL(miscP, "Set WalkSpeed", 16, 500, 25, 8, mly, LW, function(v) Config.WalkSpeedValue = v end); mly = mly + 40
CB(miscP, "JumpPower", false, 8, mly, LW, function(v)
    Config.JumpPower = v
    if v then startLoopPower() else stopLoopPower() end
end); mly = mly + 22
SL(miscP, "Set JumpPower", 20, 500, 20, 8, mly, LW, function(v) Config.JumpPowerValue = v end)

SEC(miscP, "World", RX, mry, RW); mry = mry + 24
CB(miscP, "Supprimer Fumigènes", false, RX, mry, RW, function(v) Config.Smoke = v end); mry = mry + 22
CB(miscP, "Auto Réactivation", false, RX, mry, RW, function(v)
    Config.AutoReactivate = v
    if v then saveFeatureState() end
end); mry = mry + 22

-- ========================
-- SETTINGS TAB
-- ========================
local sly = 8

SEC(settingsP, "Interface", 8, sly, LW); sly = sly + 24

-- Touche pour ouvrir/fermer le menu
local menuKeyBtn = KB(settingsP, "Touche Menu (Toggle)", "LeftShift", 8, sly, LW, function(k)
    Config.MenuKey = k
end); sly = sly + 24

SEC(settingsP, "Options", 8, sly, LW); sly = sly + 24

CB(settingsP, "Auto Réactivation au chargement", false, 8, sly, LW, function(v)
    Config.AutoReactivate = v
    if v then saveFeatureState() end
end); sly = sly + 22

-- Bouton fermer
local closeAllBtn = Instance.new("TextButton", settingsP)
closeAllBtn.Size = UDim2.new(0, LW, 0, 26)
closeAllBtn.Position = UDim2.new(0, 8, 0, sly + 20)
closeAllBtn.BackgroundColor3 = C.red
closeAllBtn.Text = "FERMER LSX V1"
closeAllBtn.TextColor3 = Color3.new(1,1,1)
closeAllBtn.TextSize = 11; closeAllBtn.Font = Enum.Font.GothamBold
closeAllBtn.BorderSizePixel = 0
Instance.new("UICorner", closeAllBtn).CornerRadius = UDim.new(0,3)
closeAllBtn.MouseButton1Click:Connect(function()
    Config.AimbotToggle = false; Config.ShowESP = false
    Config.Noclip = false; Config.WalkSpeed = false
    Config.JumpPower = false; Config.InfiniteJump = false
    Config.Fly = false; Config.Smoke = false; Config.SilentAimToggle = false
    stopFly(); stopLoopSpeed(); stopLoopPower(); stopInfiniteJump()
    ClearHighlights()
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 25.2; h.JumpPower = 20 end
    for _, conn in ipairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then safeCall(function() conn:Disconnect() end) end
    end
    if DrawingCircle then DrawingCircle:Remove(); DrawingCircle = nil end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    print = oldPrint; warn = oldWarn
    ScreenGui:Destroy()
end)

local rqBtn = Instance.new("TextButton", settingsP)
rqBtn.Size = UDim2.new(0, LW, 0, 26)
rqBtn.Position = UDim2.new(0, 8, 0, sly + 52)
rqBtn.BackgroundColor3 = Color3.fromRGB(70, 25, 25)
rqBtn.Text = "RAGE QUIT"
rqBtn.TextColor3 = Color3.new(1,1,1)
rqBtn.TextSize = 11; rqBtn.Font = Enum.Font.GothamBold
rqBtn.BorderSizePixel = 0
Instance.new("UICorner", rqBtn).CornerRadius = UDim.new(0,3)
rqBtn.MouseButton1Click:Connect(function()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    player:Kick("LSX V1")
end)

-- ========================
-- SAVE FEATURES à chaque changement
-- ========================
RunService.Heartbeat:Connect(function()
    if Config.AutoReactivate then
        saveFeatureState()
    end
end)
