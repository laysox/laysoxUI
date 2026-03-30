task.wait(3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UIS = UserInputService

local player = Players.LocalPlayer
local Mouse = player:GetMouse()
repeat task.wait() until player.Character
local character = player.Character
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

local Rayfield
pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not Rayfield then
    task.wait(3)
    pcall(function()
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
end
if not Rayfield then return end

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
    ShowESP = false,
    EnemyColor = Color3.fromRGB(255, 0, 0),
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
    UseFakeName = false,
    UseFakeDisplayName = false,
    FakeName = "",
    FakeDisplayName = "",
}

local HumanModCons = {}
local connections = {}
local noclippedParts = {}
local storedNametags = {}
local InfiniteJumpConnection = nil
local DrawingCircle = nil
local originalName = player.Name
local originalDisplayName = player.DisplayName

local spinSpeed = 10
local spinDirection = 1
local spinAxis = "Y"
local spinning, spinConnection = false, nil

local sticking, stickConnection = false, nil
local stickTarget = ""

local invisible = false
local originalTransparency = {}

local savedPositions = {}
local selectedPlayer = ""

local aimlockKeyName = "Q"
local flyKeyName = "G"

local allKeys = {
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

player.CharacterAdded:Connect(function()
    task.wait(1)
    refresh()
    spinning = false
    sticking = false
    invisible = false
    Config.AimbotToggle = false
    Config.LockOnTarget = nil
    Config.Fly = false
    Config.SilentAimToggle = false
end)

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

-- TP
local function tpCoords(x, y, z)
    humanoidRootPart.CFrame = CFrame.new(x, y, z)
end

local function tpPlayer(name)
    local t = Players:FindFirstChild(name)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        humanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame + Vector3.new(3,0,0)
        return true
    end
    return false
end

local function savePOS(slot)
    savedPositions[slot] = humanoidRootPart.CFrame
end

local function loadPOS(slot)
    if savedPositions[slot] then
        humanoidRootPart.CFrame = savedPositions[slot]
        return true
    end
    return false
end

local function getPlayers()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then table.insert(t, p.Name) end
    end
    if #t == 0 then t = {"Aucun joueur"} end
    return t
end

-- STICK
local function startStick(name)
    if sticking then return false end
    if not Players:FindFirstChild(name) then return false end
    sticking = true
    stickConnection = RunService.RenderStepped:Connect(function()
        if not sticking then return end
        local t = Players:FindFirstChild(name)
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            humanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(3,0,0)
        end
    end)
    return true
end

local function stopStick()
    sticking = false
    if stickConnection then stickConnection:Disconnect(); stickConnection = nil end
end

-- INVISIBLE
local function setInvis(state)
    invisible = state
    if not character then return end
    for _, p in pairs(character:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if state then
                originalTransparency[p] = p.Transparency
                p.Transparency = 1
                p.LocalTransparencyModifier = 1
            else
                p.Transparency = originalTransparency[p] or 0
                p.LocalTransparencyModifier = 0
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
                    h.Transparency = 1
                    h.LocalTransparencyModifier = 1
                else
                    h.Transparency = originalTransparency[h] or 0
                    h.LocalTransparencyModifier = 0
                end
            end
        end
    end
    humanoid.DisplayDistanceType = state
        and Enum.HumanoidDisplayDistanceType.None
        or Enum.HumanoidDisplayDistanceType.Automatic
end

-- NOCLIP
task.spawn(function()
    while true do
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if Config.Noclip then
                        if part.CanCollide then
                            part.CanCollide = false
                            noclippedParts[part] = true
                        end
                    else
                        if noclippedParts[part] then
                            part.CanCollide = true
                            noclippedParts[part] = nil
                        end
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
    if HumanModCons.wsCA then HumanModCons.wsCA:Disconnect() end
    HumanModCons.wsCA = player.CharacterAdded:Connect(function(char)
        h = char:WaitForChild("Humanoid")
        apply()
        if HumanModCons.ws then HumanModCons.ws:Disconnect() end
        HumanModCons.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
    end)
end

local function stopLoopSpeed()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    if HumanModCons.wsCA then HumanModCons.wsCA:Disconnect() end
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
    if HumanModCons.jpCA then HumanModCons.jpCA:Disconnect() end
    HumanModCons.jpCA = player.CharacterAdded:Connect(function(char)
        h = char:WaitForChild("Humanoid")
        apply()
        if HumanModCons.jp then HumanModCons.jp:Disconnect() end
        HumanModCons.jp = h:GetPropertyChangedSignal("JumpPower"):Connect(apply)
    end)
end

local function stopLoopPower()
    if HumanModCons.jp then HumanModCons.jp:Disconnect() end
    if HumanModCons.jpCA then HumanModCons.jpCA:Disconnect() end
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

-- FAKE NAME
local function processtext(text)
    if type(text) ~= "string" then return text end
    if Config.UseFakeName and originalName and Config.FakeName ~= "" then
        text = string.gsub(text, originalName, Config.FakeName)
    end
    if Config.UseFakeDisplayName and originalDisplayName and Config.FakeDisplayName ~= "" then
        text = string.gsub(text, originalDisplayName, Config.FakeDisplayName)
    end
    return text
end

local function hookUIObject(obj)
    if obj:IsA("TextBox") or obj:IsA("TextLabel") or obj:IsA("TextButton") then
        pcall(function()
            obj.Text = processtext(obj.Text)
            obj.Changed:Connect(function(prop)
                if prop == "Text" then obj.Text = processtext(obj.Text) end
            end)
        end)
    end
end

for _, v in next, game:GetDescendants() do hookUIObject(v) end
game.DescendantAdded:Connect(hookUIObject)

-- AIMBOT
if Drawing then
    DrawingCircle = Drawing.new("Circle")
    DrawingCircle.Thickness = 1
    DrawingCircle.Filled = false
    DrawingCircle.Transparency = 1
    DrawingCircle.Color = Color3.fromRGB(255, 255, 255)
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

local function getTargetPart(char)
    return char:FindFirstChild(Config.AimbotPart)
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

-- SILENT AIM (safe — redirige la caméra sans hookmetamethod)
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
                    if dist < minDist then
                        minDist = dist
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

-- Silent Aim via CFrame camera redirect au moment du clic
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.RightMouseDown = true
    end

    -- Silent Aim : au moment du clic gauche, pointe la caméra vers la cible
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Config.SilentAimToggle then
            local target = getSilentAimTarget()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Config.SilentAimPart)
                if part then
                    local originalCF = Camera.CFrame
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    task.delay(0.07, function()
                        if Camera then
                            Camera.CFrame = originalCF
                        end
                    end)
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

-- Aimbot loop
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
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                if Config.ShowESP and Config.ShowNameTags then
                    if root:FindFirstChild("Nametag") then
                        storedNametags[p] = root.Nametag:Clone()
                        root.Nametag:Destroy()
                    end
                elseif storedNametags[p] and not root:FindFirstChild("Nametag") then
                    storedNametags[p].Parent = root
                    storedNametags[p] = nil
                end
            end
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
                if Config.ShowNameTags then
                    if not existingBB then
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
                            label.TextColor3 = Color3.new(1,1,1)
                            label.TextScaled = true
                            label.Font = Enum.Font.SourceSansBold
                            if Config.HPESP then
                                task.spawn(function()
                                    while label and label.Parent and Config.ShowESP and Config.HPESP do
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
                    if existingBB then existingBB:Destroy() end
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
        task.wait(1)
        RefreshHighlights()
    end)
end)

task.spawn(function()
    while true do
        if Config.ShowESP then
            RefreshHighlights()
            task.wait(Config.BlinkingESP and 2 or 0.1)
        else
            ClearHighlights()
            task.wait(0.1)
        end
    end
end)

-- KEYBINDS GLOBAUX
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode.Name

    if keyName == aimlockKeyName then
        Config.AimbotToggle = not Config.AimbotToggle
        Rayfield:Notify({
            Title = Config.AimbotToggle and "Aimbot ON" or "Aimbot OFF",
            Content = Config.AimbotToggle and "Clic droit pour viser." or "Désactivé.",
            Duration = 2,
        })
    end

    if keyName == flyKeyName then
        if Config.Fly then
            stopFly()
            Rayfield:Notify({ Title="Fly OFF", Content="Retour au sol.", Duration=2 })
        else
            startFly()
            Rayfield:Notify({ Title="Fly ON", Content=Config.FlySpeed.." studs/s", Duration=2 })
        end
    end
end)

-- ========================
-- UI — LSX V1
-- ========================
local Window = Rayfield:CreateWindow({
    Name = "LSX V1",
    LoadingTitle = "LSX V1",
    LoadingSubtitle = "by Laysox",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- TAB COMBAT
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Aimbot")
local AimbotToggleUI = CombatTab:CreateToggle({
    Name = "Activer Aimbot", CurrentValue = false, Flag = "AimbotTrigger",
    Callback = function(v) Config.AimbotToggle = v end,
})
CombatTab:CreateToggle({
    Name = "Wall Check", CurrentValue = true, Flag = "AimbotWallCheck",
    Callback = function(v) Config.WallCheck = v end,
})
CombatTab:CreateToggle({
    Name = "Afficher FOV", CurrentValue = true, Flag = "AimbotShowFOV",
    Callback = function(v)
        Config.ShowFOV = v
        if DrawingCircle then DrawingCircle.Visible = v and Config.AimbotToggle end
    end,
})
CombatTab:CreateSlider({
    Name = "FOV", Range = {10,600}, Increment = 1,
    Suffix = " px", CurrentValue = 150, Flag = "AimbotFov",
    Callback = function(v) Config.FOV = v end,
})
CombatTab:CreateSlider({
    Name = "Sensibilité", Range = {0.01,1}, Increment = 0.01,
    Suffix = "", CurrentValue = 0.3, Flag = "AimbotSensitivity",
    Callback = function(v) Config.Sensitivity = v end,
})
CombatTab:CreateDropdown({
    Name = "Partie visée (Aimbot)", Flag = "AimbotPart", MultipleOptions = false,
    Options = {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg","LeftUpperArm","RightUpperArm"},
    CurrentOption = {"Head"},
    Callback = function(o) Config.AimbotPart = o[1] end,
})
CombatTab:CreateDropdown({
    Name = "Touche Aimbot", Options = allKeys,
    CurrentOption = {"Q"}, Flag = "AimlockKeyDD", MultipleOptions = false,
    Callback = function(o)
        aimlockKeyName = o[1]
        Rayfield:Notify({ Title="Touche Aimbot", Content="Aimbot → "..o[1], Duration=2 })
    end,
})

CombatTab:CreateSection("Silent Aim")
CombatTab:CreateToggle({
    Name = "Activer Silent Aim", CurrentValue = false, Flag = "SilentAimToggle",
    Callback = function(v)
        Config.SilentAimToggle = v
        Rayfield:Notify({
            Title = v and "Silent Aim ON" or "Silent Aim OFF",
            Content = v and "Tes tirs visent l'ennemi le plus proche." or "Désactivé.",
            Duration = 3,
        })
    end,
})
CombatTab:CreateSlider({
    Name = "FOV Silent Aim", Range = {10,600}, Increment = 1,
    Suffix = " px", CurrentValue = 200, Flag = "SilentAimFOV",
    Callback = function(v) Config.SilentAimFOV = v end,
})
CombatTab:CreateDropdown({
    Name = "Partie visée (Silent Aim)", Flag = "SilentAimPart", MultipleOptions = false,
    Options = {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg","LeftUpperArm","RightUpperArm"},
    CurrentOption = {"Head"},
    Callback = function(o) Config.SilentAimPart = o[1] end,
})
CombatTab:CreateParagraph({
    Title = "Info Silent Aim",
    Content = "Au moment du clic gauche, la caméra se redirige\nvers l'ennemi le plus proche pendant 70ms.\nSafe — aucun hookmetamethod utilisé.",
})

-- TAB VISUALS
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

VisualsTab:CreateSection("ESP")
local ESPToggle = VisualsTab:CreateToggle({
    Name = "ESP", CurrentValue = false, Flag = "ESPToggle",
    Callback = function(v) Config.ShowESP = v; RefreshHighlights() end,
})
VisualsTab:CreateToggle({
    Name = "ESP Clignotant", CurrentValue = false, Flag = "ESPBlinking",
    Callback = function(v) Config.BlinkingESP = v; RefreshHighlights() end,
})
VisualsTab:CreateToggle({
    Name = "Noms", CurrentValue = true, Flag = "ESPShowNameTags",
    Callback = function(v) Config.ShowNameTags = v; RefreshHighlights() end,
})
VisualsTab:CreateToggle({
    Name = "HP dans le nom", CurrentValue = true, Flag = "HPESP",
    Callback = function(v) Config.HPESP = v; RefreshHighlights() end,
})
VisualsTab:CreateSlider({
    Name = "Transparence ESP", Range = {0,1}, Increment = 0.05,
    CurrentValue = 0.3, Flag = "ESPTransparency",
    Callback = function(v) Config.ESPTransparency = v; RefreshHighlights() end,
})
VisualsTab:CreateColorPicker({
    Name = "Couleur ESP",
    Color = Color3.fromRGB(255,0,0),
    Flag = "ESPEnemyColor",
    Callback = function(c) Config.EnemyColor = c; RefreshHighlights() end,
})
local ESPBind = VisualsTab:CreateKeybind({
    Name = "Touche ESP", CurrentKeybind = "F15", Flag = "ESPBind", HoldToInteract = false,
    Callback = function() ESPToggle:Set(not Config.ShowESP) end,
})
VisualsTab:CreateButton({ Name="Reset Touche ESP", Callback=function() ESPBind:Set("F15") end })

-- TAB PLAYER
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Mouvement")
local FlyToggleUI = PlayerTab:CreateToggle({
    Name = "Fly", CurrentValue = false, Flag = "FlyToggleUI",
    Callback = function(v)
        if v then startFly() else stopFly() end
    end,
})
PlayerTab:CreateSlider({
    Name = "Vitesse Fly", Range = {10,2000}, Increment = 10,
    Suffix = " studs/s", CurrentValue = 100, Flag = "FlySpeedSlider",
    Callback = function(v) Config.FlySpeed = v end,
})
PlayerTab:CreateDropdown({
    Name = "Touche Fly", Options = allKeys,
    CurrentOption = {"G"}, Flag = "FlyKeyDD", MultipleOptions = false,
    Callback = function(o)
        flyKeyName = o[1]
        Rayfield:Notify({ Title="Touche Fly", Content="Fly → "..o[1], Duration=2 })
    end,
})
local WalkSpeedToggle = PlayerTab:CreateToggle({
    Name = "WalkSpeed", CurrentValue = false, Flag = "WalkSpeedToggle",
    Callback = function(v)
        Config.WalkSpeed = v
        if v then startLoopSpeed() else stopLoopSpeed() end
    end,
})
PlayerTab:CreateSlider({
    Name = "Set WalkSpeed", Range = {16,500}, Increment = 1,
    Suffix = " studs", CurrentValue = 25.2, Flag = "WalkSpeedValue",
    Callback = function(v) Config.WalkSpeedValue = v end,
})

PlayerTab:CreateSection("Saut")
local JumpPowerToggle = PlayerTab:CreateToggle({
    Name = "JumpPower", CurrentValue = false, Flag = "JumpPowerToggle",
    Callback = function(v)
        Config.JumpPower = v
        if v then startLoopPower() else stopLoopPower() end
    end,
})
PlayerTab:CreateSlider({
    Name = "Set JumpPower", Range = {20,500}, Increment = 1,
    Suffix = " studs", CurrentValue = 20, Flag = "JumpPowerValue",
    Callback = function(v) Config.JumpPowerValue = v end,
})
PlayerTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfiniteJumpToggle",
    Callback = function(v)
        Config.InfiniteJump = v
        if v then startInfiniteJump() else stopInfiniteJump() end
    end,
})

PlayerTab:CreateSection("Physique")
local NoclipToggle = PlayerTab:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "NoclipToggle",
    Callback = function(v) Config.Noclip = v end,
})
PlayerTab:CreateToggle({
    Name = "Invisible", CurrentValue = false, Flag = "InvisToggle",
    Callback = function(v)
        setInvis(v)
        Rayfield:Notify({
            Title = v and "Invisible !" or "Visible",
            Content = v and "Personne ne te voit." or "Tu es visible.",
            Duration = 2,
        })
    end,
})

PlayerTab:CreateSection("Keybinds")
local WalkSpeedBind = PlayerTab:CreateKeybind({
    Name = "Touche WalkSpeed", CurrentKeybind = "F15", Flag = "WalkSpeedBind", HoldToInteract = false,
    Callback = function() WalkSpeedToggle:Set(not Config.WalkSpeed) end,
})
local JumpPowerBind = PlayerTab:CreateKeybind({
    Name = "Touche JumpPower", CurrentKeybind = "F15", Flag = "JumpPowerBind", HoldToInteract = false,
    Callback = function() JumpPowerToggle:Set(not Config.JumpPower) end,
})
local NoclipBind = PlayerTab:CreateKeybind({
    Name = "Touche Noclip", CurrentKeybind = "F15", Flag = "NoclipBind", HoldToInteract = false,
    Callback = function() NoclipToggle:Set(not Config.Noclip) end,
})
PlayerTab:CreateButton({ Name="Reset WalkSpeed Bind", Callback=function() WalkSpeedBind:Set("F15") end })
PlayerTab:CreateButton({ Name="Reset JumpPower Bind", Callback=function() JumpPowerBind:Set("F15") end })
PlayerTab:CreateButton({ Name="Reset Noclip Bind", Callback=function() NoclipBind:Set("F15") end })

-- TAB TELEPORT
local TPTab = Window:CreateTab("Téléport", 4483362458)
local cx, cy, cz = 0, 0, 0

TPTab:CreateSection("Coordonnées XYZ")
TPTab:CreateInput({ Name="X", PlaceholderText="100", RemoveTextAfterFocusLost=false, Flag="CX",
    Callback=function(v) cx=tonumber(v) or cx end })
TPTab:CreateInput({ Name="Y", PlaceholderText="50", RemoveTextAfterFocusLost=false, Flag="CY",
    Callback=function(v) cy=tonumber(v) or cy end })
TPTab:CreateInput({ Name="Z", PlaceholderText="200", RemoveTextAfterFocusLost=false, Flag="CZ",
    Callback=function(v) cz=tonumber(v) or cz end })
TPTab:CreateButton({ Name="Téléporter aux coordonnées", Callback=function()
    tpCoords(cx,cy,cz)
    Rayfield:Notify({ Title="TP !", Content=("X:%d Y:%d Z:%d"):format(cx,cy,cz), Duration=3 })
end })

TPTab:CreateSection("TP vers joueur")
TPTab:CreateDropdown({ Name="Joueur", Options=getPlayers(), CurrentOption={}, Flag="TPPlayer", MultipleOptions=false,
    Callback=function(o) selectedPlayer=o[1] or "" end })
TPTab:CreateButton({ Name="Téléporter", Callback=function()
    if selectedPlayer=="" or selectedPlayer=="Aucun joueur" then
        Rayfield:Notify({ Title="Erreur", Content="Aucun joueur.", Duration=2 }); return
    end
    local ok=tpPlayer(selectedPlayer)
    Rayfield:Notify({ Title=ok and "TP !" or "Échec", Content=ok and "Vers : "..selectedPlayer or "Introuvable.", Duration=3 })
end })

TPTab:CreateSection("Suivre un joueur")
TPTab:CreateDropdown({ Name="Joueur à suivre", Options=getPlayers(), CurrentOption={}, Flag="StickPlayer", MultipleOptions=false,
    Callback=function(o) stickTarget=o[1] or "" end })
TPTab:CreateToggle({ Name="Activer le Suivi", CurrentValue=false, Flag="StickToggle",
    Callback=function(v)
        if v then
            if stickTarget=="" or stickTarget=="Aucun joueur" then
                Rayfield:Notify({ Title="Erreur", Content="Aucun joueur.", Duration=2 }); return
            end
            local ok=startStick(stickTarget)
            Rayfield:Notify({ Title=ok and "Suivi ON" or "Échec", Content=ok and "Collé : "..stickTarget or "Introuvable.", Duration=3 })
        else
            stopStick()
            Rayfield:Notify({ Title="Suivi OFF", Content="Plus collé.", Duration=2 })
        end
    end,
})

TPTab:CreateSection("Positions sauvegardées")
for _, slot in pairs({"Slot 1","Slot 2","Slot 3"}) do
    TPTab:CreateButton({ Name="💾 Sauvegarder — "..slot, Callback=function()
        savePOS(slot); Rayfield:Notify({ Title="Sauvegardé !", Content=slot, Duration=2 }) end })
    TPTab:CreateButton({ Name="📍 Charger — "..slot, Callback=function()
        local ok=loadPOS(slot)
        Rayfield:Notify({ Title=ok and "Chargé !" or "Slot vide", Content=slot, Duration=2 }) end })
end

-- TAB MISC
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Spin")
MiscTab:CreateSlider({
    Name = "Vitesse Spin", Range = {1,100}, Increment = 1,
    Suffix = "°/frame", CurrentValue = 10, Flag = "SpinSpeed",
    Callback = function(v) spinSpeed = v end,
})
MiscTab:CreateDropdown({
    Name = "Direction", Options = {"Clockwise","Counterclockwise"},
    CurrentOption = {"Clockwise"}, Flag = "SpinDir", MultipleOptions = false,
    Callback = function(o) spinDirection = o[1] == "Clockwise" and 1 or -1 end,
})
MiscTab:CreateDropdown({
    Name = "Axe", Options = {"Y","X","Z"},
    CurrentOption = {"Y"}, Flag = "SpinAxis", MultipleOptions = false,
    Callback = function(o) spinAxis = o[1] end,
})
MiscTab:CreateToggle({
    Name = "Activer Spin", CurrentValue = false, Flag = "SpinToggle",
    Callback = function(v)
        if v then startSpin(); Rayfield:Notify({ Title="Spin ON", Content="Axe : "..spinAxis, Duration=2 })
        else stopSpin(); Rayfield:Notify({ Title="Spin OFF", Content="Arrêté.", Duration=2 }) end
    end,
})

MiscTab:CreateSection("Divers")
MiscTab:CreateToggle({ Name="Supprimer Grenades Fumigènes", CurrentValue=false, Flag="SmokeToggle",
    Callback=function(v) Config.Smoke = v end,
})

MiscTab:CreateSection("Spoofer")
MiscTab:CreateToggle({
    Name = "Faux Pseudo", CurrentValue = false, Flag = "EnableFakeName",
    Callback = function(v)
        Config.UseFakeName = v
        for _, obj in next, game:GetDescendants() do hookUIObject(obj) end
    end,
})
MiscTab:CreateToggle({
    Name = "Faux Display Name", CurrentValue = false, Flag = "EnableFakeDisplayName",
    Callback = function(v)
        Config.UseFakeDisplayName = v
        for _, obj in next, game:GetDescendants() do hookUIObject(obj) end
    end,
})
MiscTab:CreateInput({
    Name = "Pseudo", PlaceholderText = "Faux pseudo", RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.FakeName = v
        if Config.UseFakeName then pcall(function() player.Name = v end) end
    end,
})
MiscTab:CreateInput({
    Name = "Display Name", PlaceholderText = "Faux display name", RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.FakeDisplayName = v
        if Config.UseFakeDisplayName then pcall(function() player.DisplayName = v end) end
    end,
})
MiscTab:CreateDropdown({
    Name = "Device Spoofer",
    Options = {"PC (MouseKeyboard)","Mobile (Touch)","Console (Gamepad)"},
    CurrentOption = {"PC (MouseKeyboard)"},
    Flag = "DeviceSpoofer", MultipleOptions = false,
    Callback = function(o)
        local map = {
            ["PC (MouseKeyboard)"] = "MouseKeyboard",
            ["Mobile (Touch)"] = "Touch",
            ["Console (Gamepad)"] = "Gamepad",
        }
        local dt = map[o[1]]
        if dt then
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Remotes")
                    :WaitForChild("Replication")
                    :WaitForChild("Fighter")
                    :WaitForChild("SetControls")
                    :FireServer(dt)
            end)
            Rayfield:Notify({ Title="Device Spoofer", Content="→ "..o[1], Duration=3 })
        end
    end,
})

-- TAB IMPORTANT
local ImportantTab = Window:CreateTab("Important", 4483362458)
ImportantTab:CreateButton({
    Name = "FERMER LSX V1",
    Callback = function()
        Config.AimbotToggle = false
        Config.ShowESP = false
        Config.Noclip = false
        Config.WalkSpeed = false
        Config.JumpPower = false
        Config.InfiniteJump = false
        Config.Fly = false
        Config.Smoke = false
        Config.SilentAimToggle = false
        stopFly()
        stopLoopSpeed()
        stopLoopPower()
        stopInfiniteJump()
        ClearHighlights()
        local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
        if h then h.WalkSpeed = 25.2; h.JumpPower = 20 end
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                pcall(function() conn:Disconnect() end)
            end
        end
        if DrawingCircle then DrawingCircle:Remove(); DrawingCircle = nil end
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect(); InfiniteJumpConnection = nil end
        Rayfield:Destroy()
    end,
})
ImportantTab:CreateButton({
    Name = "RAGE QUIT",
    Callback = function()
        player:Kick("LSX V1 — Rage quit")
    end,
})
