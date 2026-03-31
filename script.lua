-- LSX V1 | by Laysox
-- Anti-detection max

local ok, err = pcall(function()

task.wait(6)

-- ========================
-- SERVICES (via index pour eviter detection)
-- ========================
local gs = game:GetService
local Players       = gs(game, "Players")
local RunService    = gs(game, "RunService")
local UIS           = gs(game, "UserInputService")
local TweenService  = gs(game, "TweenService")
local HttpService   = gs(game, "HttpService")

local lp      = Players.LocalPlayer
local Mouse   = lp:GetMouse()
local Camera  = workspace.CurrentCamera

repeat task.wait(0.5) until lp.Character
local character       = lp.Character
local hrp             = character:WaitForChild("HumanoidRootPart", 10)
local humanoid        = character:WaitForChild("Humanoid", 10)

-- ========================
-- SAFE CALL
-- ========================
local function sc(f, ...)
    local s, e = pcall(f, ...)
    return s
end

-- ========================
-- MASQUAGE
-- ========================
sc(function()
    if script then
        script.Name = "LocalScript"
    end
end)

-- Supprime traces console
local _print = print
local _warn  = warn
local _error = error
print = function() end
warn  = function() end

-- ========================
-- CONFIG
-- ========================
local Cfg = {
    -- Aimbot
    Aim        = false,
    AimPart    = "Head",
    AimFOV     = 150,
    AimSens    = 0.3,
    AimTarget  = nil,
    RMB        = false,
    WallCheck  = true,
    ShowFOV    = true,
    -- Silent Aim
    SA         = false,
    SAPart     = "Head",
    SAFOV      = 200,
    SAIntensity= 100,
    -- ESP
    ESP        = false,
    ESPColor   = Color3.fromRGB(0, 150, 255),
    ESPTrans   = 0.3,
    ESPNames   = true,
    ESPHP      = true,
    ESPBlink   = false,
    -- Player
    WS         = false,
    WSVal      = 25.2,
    JP         = false,
    JPVal      = 20,
    Noclip     = false,
    IJ         = false,
    Fly        = false,
    FlySpd     = 100,
    Smoke      = false,
    Invis      = false,
    -- Misc
    AutoRespawn   = false,
    AutoReactivate= false,
    -- UI
    GuiOpen    = true,
    MenuKey    = "LeftShift",
    -- Spin
    Spin       = false,
    SpinSpd    = 10,
    SpinDir    = 1,
    SpinAxis   = "Y",
}

-- State sauvegarde pour AutoReactivate
local SavedState = {}

local function saveState()
    for k,v in pairs(Cfg) do
        if type(v) == "boolean" then
            SavedState[k] = v
        end
    end
end

-- ========================
-- CONNECTIONS + CLEANUP
-- ========================
local Conns = {}
local function addConn(c) table.insert(Conns, c) end
local function cleanConns()
    for _, c in ipairs(Conns) do
        sc(function() c:Disconnect() end)
    end
    Conns = {}
end

-- ========================
-- REFRESH PERSO
-- ========================
local function refresh()
    character = lp.Character
    if not character then return end
    hrp       = character:FindFirstChild("HumanoidRootPart")
    humanoid  = character:FindFirstChildWhichIsA("Humanoid")
end

-- ========================
-- TEAM CHECK
-- ========================
local function isEnemy(p)
    if not p or p == lp then return false end
    if lp.Team and p.Team then return lp.Team ~= p.Team end
    return true
end

-- ========================
-- WALKSPEED
-- ========================
local HMC = {}

local function startWS()
    local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.WalkSpeed = Cfg.WSVal end
    apply()
    if HMC.ws then HMC.ws:Disconnect() end
    HMC.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
end

local function stopWS()
    if HMC.ws then HMC.ws:Disconnect(); HMC.ws = nil end
    local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 25.2 end
end

-- ========================
-- JUMPPOWER
-- ========================
local function startJP()
    local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.UseJumpPower = true; h.JumpPower = Cfg.JPVal end
    apply()
    if HMC.jp then HMC.jp:Disconnect() end
    HMC.jp = h:GetPropertyChangedSignal("JumpPower"):Connect(apply)
end

local function stopJP()
    if HMC.jp then HMC.jp:Disconnect(); HMC.jp = nil end
    local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.JumpPower = 20 end
end

-- ========================
-- INFINITE JUMP
-- ========================
local IJConn = nil
local function startIJ()
    if IJConn then return end
    IJConn = UIS.JumpRequest:Connect(function()
        local c = lp.Character
        if c and c:FindFirstChildWhichIsA("Humanoid") then
            c:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopIJ()
    if IJConn then IJConn:Disconnect(); IJConn = nil end
end

-- ========================
-- FLY
-- ========================
local FlyConn = nil

local function startFly()
    if Cfg.Fly then return end
    Cfg.Fly = true
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end

    sc(function()
        if h:FindFirstChild("FlyGyro") then h.FlyGyro:Destroy() end
        if h:FindFirstChild("FlyVel")   then h.FlyVel:Destroy()  end
    end)

    local gyro      = Instance.new("BodyGyro")
    gyro.Name       = "FlyGyro"
    gyro.MaxTorque  = Vector3.new(1,1,1) * math.huge
    gyro.P          = 100000
    gyro.CFrame     = h.CFrame
    gyro.Parent     = h

    local vel       = Instance.new("BodyVelocity")
    vel.Name        = "FlyVel"
    vel.MaxForce    = Vector3.new(1,1,1) * math.huge
    vel.P           = 10000
    vel.Velocity    = Vector3.zero
    vel.Parent      = h

    if FlyConn then FlyConn:Disconnect() end
    FlyConn = RunService.RenderStepped:Connect(function()
        if not Cfg.Fly or not h or not h.Parent then
            if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
            sc(function() gyro:Destroy() end)
            sc(function() vel:Destroy()  end)
            return
        end
        local mv = Vector3.zero
        local cf = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)       then mv += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
        vel.Velocity  = mv.Magnitude > 0 and mv.Unit * Cfg.FlySpd or Vector3.zero
        gyro.CFrame   = cf
    end)
end

local function stopFly()
    Cfg.Fly = false
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h then
        sc(function()
            if h:FindFirstChild("FlyGyro") then h.FlyGyro:Destroy() end
            if h:FindFirstChild("FlyVel")  then h.FlyVel:Destroy()  end
        end)
    end
end

-- ========================
-- NOCLIP (interval safe)
-- ========================
local noclipParts = {}
task.spawn(function()
    while true do
        task.wait(0.25)
        local c = lp.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    if Cfg.Noclip then
                        if p.CanCollide then p.CanCollide = false; noclipParts[p] = true end
                    else
                        if noclipParts[p] then p.CanCollide = true; noclipParts[p] = nil end
                    end
                end
            end
        end
    end
end)

-- ========================
-- INVISIBLE
-- ========================
local origTrans = {}
local function setInvis(state)
    Cfg.Invis = state
    local c = lp.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if state then
                origTrans[p] = p.Transparency
                p.Transparency = 1; p.LocalTransparencyModifier = 1
            else
                p.Transparency = origTrans[p] or 0; p.LocalTransparencyModifier = 0
            end
        end
        if p:IsA("Decal") then p.Transparency = state and 1 or 0 end
    end
    for _, obj in ipairs(c:GetChildren()) do
        if obj:IsA("Accessory") then
            local h2 = obj:FindFirstChild("Handle")
            if h2 then
                if state then
                    origTrans[h2] = h2.Transparency
                    h2.Transparency = 1; h2.LocalTransparencyModifier = 1
                else
                    h2.Transparency = origTrans[h2] or 0; h2.LocalTransparencyModifier = 0
                end
            end
        end
    end
    local hum = c:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.DisplayDistanceType = state
            and Enum.HumanoidDisplayDistanceType.None
            or  Enum.HumanoidDisplayDistanceType.Automatic
    end
end

-- ========================
-- SPIN
-- ========================
local SpinConn = nil
local function startSpin()
    if SpinConn then return end
    SpinConn = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end
        local a = math.rad(Cfg.SpinSpd) * Cfg.SpinDir
        local cf = Cfg.SpinAxis == "X" and CFrame.Angles(a,0,0)
                or Cfg.SpinAxis == "Z" and CFrame.Angles(0,0,a)
                or CFrame.Angles(0,a,0)
        hrp.CFrame *= cf
    end)
end
local function stopSpin()
    if SpinConn then SpinConn:Disconnect(); SpinConn = nil end
end

-- ========================
-- SMOKE
-- ========================
task.spawn(function()
    while true do
        task.wait(0.35)
        if Cfg.Smoke then
            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "Smoke Grenade" then sc(function() v:Destroy() end) end
            end
        end
    end
end)

-- ========================
-- AUTO RESPAWN
-- ========================
local function hookDied()
    if not humanoid then return end
    humanoid.Died:Connect(function()
        if not Cfg.AutoRespawn then return end
        task.wait(0.3)
        sc(function() lp:LoadCharacter() end)
    end)
end
hookDied()

-- ========================
-- RESTORE FEATURES
-- ========================
local function restoreFeatures()
    if not Cfg.AutoReactivate then return end
    task.wait(1)
    if SavedState.WS      then Cfg.WS = true;  startWS()  end
    if SavedState.JP      then Cfg.JP = true;  startJP()  end
    if SavedState.IJ      then Cfg.IJ = true;  startIJ()  end
    if SavedState.Noclip  then Cfg.Noclip = true         end
    if SavedState.Smoke   then Cfg.Smoke  = true         end
    if SavedState.Aim     then Cfg.Aim    = true         end
    if SavedState.SA      then Cfg.SA     = true         end
    if SavedState.ESP     then Cfg.ESP    = true         end
    if SavedState.Fly then
        task.wait(1.5)
        startFly()
    end
end

lp.CharacterAdded:Connect(function()
    task.wait(1.2)
    refresh()
    hookDied()
    restoreFeatures()
end)

-- ========================
-- AIMBOT
-- ========================
local DrawCircle = nil
sc(function()
    if Drawing then
        DrawCircle             = Drawing.new("Circle")
        DrawCircle.Thickness   = 1
        DrawCircle.Filled      = false
        DrawCircle.Transparency= 1
        DrawCircle.Color       = Color3.fromRGB(0,150,255)
        DrawCircle.Visible     = false
        DrawCircle.Radius      = Cfg.AimFOV
        addConn(RunService.RenderStepped:Connect(function()
            DrawCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
            DrawCircle.Radius   = Cfg.AimFOV
            DrawCircle.Visible  = Cfg.ShowFOV and Cfg.Aim and not Cfg.GuiOpen
        end))
    end
end)

local function isValidTarget(p)
    if p == lp           then return false end
    if not p.Character   then return false end
    local hum = p.Character:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not isEnemy(p)    then return false end
    return true
end

local function getAimPart(char)
    return char:FindFirstChild(Cfg.AimPart)
end

local function isVisible(p)
    local c = p.Character
    if not c then return false end
    local part = getAimPart(c)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dir    = (part.Position - origin).Unit * 1000
    local rp     = RaycastParams.new()
    rp.FilterType                  = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances  = {lp.Character}
    rp.IgnoreWater                 = true
    local hit = workspace:Raycast(origin, dir, rp)
    if hit and hit.Instance and not c:IsAncestorOf(hit.Instance) then return false end
    return true
end

local function getClosestFOV()
    local best, dist = nil, Cfg.AimFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local part = getAimPart(p.Character)
            if part then
                if not Cfg.WallCheck or isVisible(p) then
                    local sp = Camera:WorldToScreenPoint(part.Position)
                    local d  = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(sp.X, sp.Y)).Magnitude
                    if d < dist then best = p; dist = d end
                end
            end
        end
    end
    return best
end

local function isTargetValid()
    local t = Cfg.AimTarget
    if not t or not t.Parent then return false end
    if not isValidTarget(t)  then return false end
    if not getAimPart(t.Character) then return false end
    return true
end

-- ========================
-- SILENT AIM
-- ========================
local function getSATarget()
    local best, dist = nil, Cfg.SAFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character then
            local part = p.Character:FindFirstChild(Cfg.SAPart)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < dist then best = p; dist = d end
                end
            end
        end
    end
    return best
end

-- ========================
-- INPUT HANDLER
-- ========================
local AimKeyName = "Q"
local FlyKeyName = "G"
local SAKeyName  = "F"

addConn(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Toggle menu
    if input.KeyCode.Name == Cfg.MenuKey then
        Cfg.GuiOpen = not Cfg.GuiOpen
        UIS.MouseBehavior = Cfg.GuiOpen
            and Enum.MouseBehavior.Default
            or  Enum.MouseBehavior.LockCenter
        return
    end

    if Cfg.GuiOpen then return end

    local k = input.KeyCode.Name
    if k == AimKeyName then Cfg.Aim = not Cfg.Aim end
    if k == FlyKeyName then
        if Cfg.Fly then stopFly() else startFly() end
    end

    -- Clic gauche — Silent Aim
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Cfg.SA then
        if math.random(1,100) <= Cfg.SAIntensity then
            local target = getSATarget()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Cfg.SAPart)
                if part then
                    local origCF = Camera.CFrame
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    task.delay(0.065, function()
                        if Camera then Camera.CFrame = origCF end
                    end)
                end
            end
        end
    end

    -- Clic droit — Aimbot
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Cfg.RMB = true
    end
end))

addConn(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Cfg.RMB = false; Cfg.AimTarget = nil
    end
end))

-- Aimbot loop
addConn(RunService.RenderStepped:Connect(function()
    if not Cfg.Aim or not Cfg.RMB or Cfg.GuiOpen then return end
    if Cfg.AimTarget and isTargetValid() then
        local part = getAimPart(Cfg.AimTarget.Character)
        local pos  = Camera:WorldToScreenPoint(part.Position)
        if pos.Z > 0 then
            local delta = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)) * Cfg.AimSens
            sc(function() mousemoverel(delta.X, delta.Y) end)
        end
    else
        local t = getClosestFOV()
        if t then Cfg.AimTarget = t end
    end
end))

-- Curseur libre quand menu ouvert
addConn(RunService.RenderStepped:Connect(function()
    if Cfg.GuiOpen then
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end
end))

-- ========================
-- ESP
-- ========================
local function clearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("ESPh")
            if hl then hl:Destroy() end
            local bb = p.Character:FindFirstChild("ESPb")
            if bb then bb:Destroy() end
        end
    end
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local c    = p.Character
            local ehl  = c:FindFirstChild("ESPh")
            local ebb  = c:FindFirstChild("ESPb")
            local blink = Cfg.ESPBlink and (tick() % 4 < 2)

            if Cfg.ESP and (not Cfg.ESPBlink or blink) then
                if not ehl then
                    local hl               = Instance.new("Highlight")
                    hl.Name                = "ESPh"
                    hl.FillTransparency    = Cfg.ESPTrans
                    hl.OutlineTransparency = 1
                    hl.FillColor           = Cfg.ESPColor
                    hl.Parent              = c
                else
                    ehl.FillColor        = Cfg.ESPColor
                    ehl.FillTransparency = Cfg.ESPTrans
                end
                if Cfg.ESPNames and not ebb then
                    local head = c:FindFirstChild("Head")
                    if head then
                        local bb = Instance.new("BillboardGui")
                        bb.Name         = "ESPb"
                        bb.Adornee      = head
                        bb.Size         = UDim2.new(0,100,0,20)
                        bb.StudsOffset  = Vector3.new(0,2.5,0)
                        bb.AlwaysOnTop  = true
                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size                = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3          = Cfg.ESPColor
                        lbl.TextScaled          = true
                        lbl.Font                = Enum.Font.SourceSansBold
                        if Cfg.ESPHP then
                            task.spawn(function()
                                while lbl and lbl.Parent and Cfg.ESP do
                                    sc(function()
                                        local hp = math.floor(p.Character.Humanoid.Health)
                                        lbl.Text = p.Name.." | "..hp.." HP"
                                    end)
                                    task.wait(0.3)
                                end
                            end)
                        else
                            lbl.Text = p.Name
                        end
                        bb.Parent = c
                    end
                end
            else
                if ehl then ehl:Destroy() end
                if ebb then ebb:Destroy() end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if Cfg.ESP then refreshESP() else clearESP() end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        sc(function()
            local hl = p.Character:FindFirstChild("ESPh")
            if hl then hl:Destroy() end
        end)
    end
end)

-- Auto save state
task.spawn(function()
    while true do
        task.wait(3)
        if Cfg.AutoReactivate then saveState() end
    end
end)

-- ========================
-- GUI
-- ========================
local GUI = Instance.new("ScreenGui")
GUI.Name             = "Sys_"..tostring(math.random(10000,99999))
GUI.ResetOnSpawn     = false
GUI.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder     = 999
GUI.IgnoreGuiInset   = true

local parented = false
sc(function()
    GUI.Parent = game:GetService("CoreGui")
    parented   = true
end)
if not parented then
    GUI.Parent = lp:WaitForChild("PlayerGui")
end

-- Couleurs
local C = {
    bg     = Color3.fromRGB(20,20,22),
    bg2    = Color3.fromRGB(28,28,31),
    bg3    = Color3.fromRGB(38,38,42),
    acc    = Color3.fromRGB(0,145,255),
    acc2   = Color3.fromRGB(0,95,200),
    txt    = Color3.fromRGB(210,210,215),
    txt2   = Color3.fromRGB(120,120,128),
    border = Color3.fromRGB(50,50,58),
    red    = Color3.fromRGB(200,50,50),
}

-- MAIN FRAME
local MF = Instance.new("Frame")
MF.Name              = "W"
MF.Size              = UDim2.new(0,650,0,430)
MF.Position          = UDim2.new(0.5,-325,0.5,-215)
MF.BackgroundColor3  = C.bg
MF.BorderSizePixel   = 0
MF.Active            = true
MF.Selectable        = false
MF.Parent            = GUI
Instance.new("UICorner",MF).CornerRadius = UDim.new(0,4)
local MStroke = Instance.new("UIStroke",MF)
MStroke.Color = C.border; MStroke.Thickness = 1

local function setVisible(v)
    Cfg.GuiOpen = v
    MF.Visible  = v
    UIS.MouseBehavior = v
        and Enum.MouseBehavior.Default
        or  Enum.MouseBehavior.LockCenter
end

-- TITLEBAR
local TB = Instance.new("Frame",MF)
TB.Size             = UDim2.new(1,0,0,28)
TB.BackgroundColor3 = C.bg2
TB.BorderSizePixel  = 0
Instance.new("UICorner",TB).CornerRadius = UDim.new(0,4)
local TBfix = Instance.new("Frame",TB)
TBfix.Size             = UDim2.new(1,0,0,6)
TBfix.Position         = UDim2.new(0,0,1,-6)
TBfix.BackgroundColor3 = C.bg2
TBfix.BorderSizePixel  = 0

local TLbl = Instance.new("TextLabel",TB)
TLbl.Size                = UDim2.new(1,-70,1,0)
TLbl.Position            = UDim2.new(0,10,0,0)
TLbl.BackgroundTransparency = 1
TLbl.Text                = "LSX V1  |  Rivals"
TLbl.TextColor3          = C.txt
TLbl.TextSize            = 12
TLbl.Font                = Enum.Font.GothamBold
TLbl.TextXAlignment      = Enum.TextXAlignment.Left

local function makeBtn(parent, x, text, bg)
    local b = Instance.new("TextButton",parent)
    b.Size             = UDim2.new(0,24,0,18)
    b.Position         = UDim2.new(1,x,0,5)
    b.BackgroundColor3 = bg
    b.Text             = text
    b.TextColor3       = Color3.new(1,1,1)
    b.TextSize         = 11
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,3)
    return b
end

local CloseB  = makeBtn(TB, -28,  "✕", C.red)
local MinB    = makeBtn(TB, -56,  "−", C.bg3)

-- DRAG
local drag, ds, dpos = false, nil, nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true; ds = i.Position; dpos = MF.Position
    end
end)
TB.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)
UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        MF.Position = UDim2.new(dpos.X.Scale, dpos.X.Offset+d.X, dpos.Y.Scale, dpos.Y.Offset+d.Y)
    end
end)

local minimized = false
MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(MF:GetChildren()) do
        if child ~= TB then child.Visible = not minimized end
    end
    MF.Size = minimized and UDim2.new(0,650,0,28) or UDim2.new(0,650,0,430)
end)

CloseB.MouseButton1Click:Connect(function()
    setVisible(false)
    MF.Visible = false
end)

-- TABBAR
local TabBar = Instance.new("Frame",MF)
TabBar.Size             = UDim2.new(1,0,0,28)
TabBar.Position         = UDim2.new(0,0,0,28)
TabBar.BackgroundColor3 = C.bg2
TabBar.BorderSizePixel  = 0
local TBLayout = Instance.new("UIListLayout",TabBar)
TBLayout.FillDirection = Enum.FillDirection.Horizontal
TBLayout.SortOrder     = Enum.SortOrder.LayoutOrder

-- CONTENT
local Content = Instance.new("Frame",MF)
Content.Size             = UDim2.new(1,0,1,-56)
Content.Position         = UDim2.new(0,0,0,56)
Content.BackgroundTransparency = 1

-- ========================
-- UI HELPERS
-- ========================
local LW  = 296  -- largeur colonne gauche
local RX  = 324  -- début colonne droite
local RW  = 296  -- largeur colonne droite

local allBtns, allInds, allPanels = {}, {}, {}

local function makeTab(name, order)
    local btn = Instance.new("TextButton",TabBar)
    btn.Size             = UDim2.new(0,104,1,0)
    btn.BackgroundColor3 = C.bg2
    btn.BorderSizePixel  = 0
    btn.Text             = name
    btn.TextColor3       = C.txt2
    btn.TextSize         = 11
    btn.Font             = Enum.Font.Gotham
    btn.LayoutOrder      = order

    local ind = Instance.new("Frame",btn)
    ind.Size             = UDim2.new(1,0,0,2)
    ind.Position         = UDim2.new(0,0,1,-2)
    ind.BackgroundColor3 = C.acc
    ind.BorderSizePixel  = 0
    ind.Visible          = false

    local panel = Instance.new("Frame",Content)
    panel.Size              = UDim2.new(1,0,1,0)
    panel.BackgroundTransparency = 1
    panel.Visible           = false

    table.insert(allBtns,  btn)
    table.insert(allInds,  ind)
    table.insert(allPanels,panel)

    btn.MouseButton1Click:Connect(function()
        for _, p in ipairs(allPanels) do p.Visible = false end
        for _, i in ipairs(allInds)   do i.Visible = false end
        for _, b in ipairs(allBtns)   do b.TextColor3 = C.txt2 end
        panel.Visible    = true
        ind.Visible      = true
        btn.TextColor3   = C.txt
    end)

    return panel
end

-- Checkbox
local function CB(parent, lbl, default, x, y, w, cb)
    local f = Instance.new("Frame",parent)
    f.Size              = UDim2.new(0,w,0,20)
    f.Position          = UDim2.new(0,x,0,y)
    f.BackgroundTransparency = 1

    local box = Instance.new("Frame",f)
    box.Size             = UDim2.new(0,13,0,13)
    box.Position         = UDim2.new(0,0,0.5,-6)
    box.BackgroundColor3 = default and C.acc or C.bg3
    box.BorderSizePixel  = 0
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,2)
    local bs = Instance.new("UIStroke",box); bs.Color = C.border; bs.Thickness = 1

    local tick = Instance.new("TextLabel",box)
    tick.Size               = UDim2.new(1,0,1,0)
    tick.BackgroundTransparency = 1
    tick.Text               = default and "✓" or ""
    tick.TextColor3         = Color3.new(1,1,1)
    tick.TextSize           = 9
    tick.Font               = Enum.Font.GothamBold

    local label = Instance.new("TextLabel",f)
    label.Size              = UDim2.new(1,-18,1,0)
    label.Position          = UDim2.new(0,18,0,0)
    label.BackgroundTransparency = 1
    label.Text              = lbl
    label.TextColor3        = C.txt
    label.TextSize          = 11
    label.Font              = Enum.Font.Gotham
    label.TextXAlignment    = Enum.TextXAlignment.Left

    local val = default
    local btn = Instance.new("TextButton",f)
    btn.Size              = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text              = ""

    local function setVal(v)
        val = v
        box.BackgroundColor3 = v and C.acc or C.bg3
        tick.Text            = v and "✓" or ""
    end
    btn.MouseButton1Click:Connect(function()
        setVal(not val)
        if cb then cb(val) end
    end)
    return setVal
end

-- Slider
local function SL(parent, lbl, min, max, default, x, y, w, cb)
    local f = Instance.new("Frame",parent)
    f.Size              = UDim2.new(0,w,0,34)
    f.Position          = UDim2.new(0,x,0,y)
    f.BackgroundTransparency = 1

    local top = Instance.new("Frame",f)
    top.Size            = UDim2.new(1,0,0,14)
    top.BackgroundTransparency = 1

    local llbl = Instance.new("TextLabel",top)
    llbl.Size           = UDim2.new(0.6,0,1,0)
    llbl.BackgroundTransparency = 1
    llbl.Text           = lbl
    llbl.TextColor3     = C.txt
    llbl.TextSize       = 10
    llbl.Font           = Enum.Font.Gotham
    llbl.TextXAlignment = Enum.TextXAlignment.Left

    local vlbl = Instance.new("TextLabel",top)
    vlbl.Size           = UDim2.new(0.4,0,1,0)
    vlbl.Position       = UDim2.new(0.6,0,0,0)
    vlbl.BackgroundTransparency = 1
    vlbl.Text           = tostring(default).."/"..tostring(max)
    vlbl.TextColor3     = C.txt2
    vlbl.TextSize       = 10
    vlbl.Font           = Enum.Font.Gotham
    vlbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame",f)
    track.Size          = UDim2.new(1,0,0,5)
    track.Position      = UDim2.new(0,0,0,17)
    track.BackgroundColor3 = C.bg3
    track.BorderSizePixel  = 0
    Instance.new("UICorner",track).CornerRadius = UDim.new(0,3)

    local fill = Instance.new("Frame",track)
    fill.Size           = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = C.acc
    fill.BorderSizePixel  = 0
    Instance.new("UICorner",fill).CornerRadius = UDim.new(0,3)

    local val = default; local sliding = false
    local function upd(mx)
        local rel = math.clamp((mx - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        val       = math.floor(min + (max-min)*rel)
        fill.Size = UDim2.new(rel,0,1,0)
        vlbl.Text = tostring(val).."/"..tostring(max)
        if cb then cb(val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
end

-- Keybind
local function KB(parent, lbl, default, x, y, w, cb)
    local f = Instance.new("Frame",parent)
    f.Size              = UDim2.new(0,w,0,20)
    f.Position          = UDim2.new(0,x,0,y)
    f.BackgroundTransparency = 1

    local ll = Instance.new("TextLabel",f)
    ll.Size             = UDim2.new(0.55,0,1,0)
    ll.BackgroundTransparency = 1
    ll.Text             = lbl
    ll.TextColor3       = C.txt
    ll.TextSize         = 10
    ll.Font             = Enum.Font.Gotham
    ll.TextXAlignment   = Enum.TextXAlignment.Left

    local kb = Instance.new("TextButton",f)
    kb.Size             = UDim2.new(0.43,0,1,0)
    kb.Position         = UDim2.new(0.57,0,0,0)
    kb.BackgroundColor3 = C.bg3
    kb.Text             = default
    kb.TextColor3       = C.acc
    kb.TextSize         = 10
    kb.Font             = Enum.Font.GothamBold
    kb.BorderSizePixel  = 0
    Instance.new("UICorner",kb).CornerRadius = UDim.new(0,2)
    local ks = Instance.new("UIStroke",kb); ks.Color = C.acc2; ks.Thickness = 1

    local waiting = false
    kb.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true; kb.Text = "..."; kb.TextColor3 = C.txt2
        local conn
        conn = UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                local n = i.KeyCode.Name
                kb.Text = n; kb.TextColor3 = C.acc
                if cb then cb(n) end
                waiting = false; conn:Disconnect()
            end
        end)
    end)
end

-- Dropdown
local function DD(parent, lbl, opts, default, x, y, w, cb)
    local f = Instance.new("Frame",parent)
    f.Size              = UDim2.new(0,w,0,20)
    f.Position          = UDim2.new(0,x,0,y)
    f.BackgroundTransparency = 1

    local ll = Instance.new("TextLabel",f)
    ll.Size             = UDim2.new(0.45,0,1,0)
    ll.BackgroundTransparency = 1
    ll.Text             = lbl
    ll.TextColor3       = C.txt
    ll.TextSize         = 10
    ll.Font             = Enum.Font.Gotham
    ll.TextXAlignment   = Enum.TextXAlignment.Left

    local db = Instance.new("TextButton",f)
    db.Size             = UDim2.new(0.53,0,1,0)
    db.Position         = UDim2.new(0.47,0,0,0)
    db.BackgroundColor3 = C.bg3
    db.Text             = default.." ▾"
    db.TextColor3       = C.txt
    db.TextSize         = 9
    db.Font             = Enum.Font.Gotham
    db.BorderSizePixel  = 0
    Instance.new("UICorner",db).CornerRadius = UDim.new(0,2)
    local ds2 = Instance.new("UIStroke",db); ds2.Color = C.border; ds2.Thickness = 1

    local open = false; local menu = nil
    db.MouseButton1Click:Connect(function()
        if open and menu then menu:Destroy(); menu = nil; open = false; return end
        open = true
        menu = Instance.new("Frame",parent)
        menu.Size             = UDim2.new(0,120,0,#opts*20)
        menu.Position         = UDim2.new(0,x+w*0.47,0,y+22)
        menu.BackgroundColor3 = C.bg2
        menu.BorderSizePixel  = 0
        menu.ZIndex           = 20
        Instance.new("UICorner",menu).CornerRadius = UDim.new(0,3)
        local ms2 = Instance.new("UIStroke",menu); ms2.Color = C.border; ms2.Thickness = 1
        for i, opt in ipairs(opts) do
            local ob = Instance.new("TextButton",menu)
            ob.Size             = UDim2.new(1,0,0,20)
            ob.Position         = UDim2.new(0,0,0,(i-1)*20)
            ob.BackgroundTransparency = 1
            ob.Text             = opt
            ob.TextColor3       = C.txt
            ob.TextSize         = 10
            ob.Font             = Enum.Font.Gotham
            ob.ZIndex           = 21
            ob.MouseButton1Click:Connect(function()
                db.Text = opt.." ▾"
                if cb then cb(opt) end
                menu:Destroy(); menu = nil; open = false
            end)
            ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0; ob.BackgroundColor3 = C.bg3 end)
            ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
        end
    end)
end

-- Section header
local function SEC(panel, lbl, x, y, w)
    local l = Instance.new("TextLabel",panel)
    l.Size              = UDim2.new(0,w,0,15)
    l.Position          = UDim2.new(0,x,0,y)
    l.BackgroundTransparency = 1
    l.Text              = lbl
    l.TextColor3        = C.txt
    l.TextSize          = 11
    l.Font              = Enum.Font.GothamBold
    l.TextXAlignment    = Enum.TextXAlignment.Left
    local line = Instance.new("Frame",panel)
    line.Size           = UDim2.new(0,w,0,1)
    line.Position       = UDim2.new(0,x,0,y+16)
    line.BackgroundColor3 = C.acc
    line.BorderSizePixel  = 0
end

-- ========================
-- BUILD UI
-- ========================
local combatP   = makeTab("Combat",   1)
local visualsP  = makeTab("Visuals",  2)
local miscP     = makeTab("Misc",     3)
local settingsP = makeTab("Settings", 4)

-- Active premier onglet
allPanels[1].Visible = true
allInds[1].Visible   = true
allBtns[1].TextColor3 = C.txt

-- ========================
-- COMBAT
-- ========================
local lcy = 8; local rcy = 8

SEC(combatP, "Aimbot",     8,  lcy, LW); lcy = lcy + 22
CB( combatP, "Activer Aimbot",    false,  8, lcy, LW, function(v) Cfg.Aim = v          end); lcy = lcy + 22
CB( combatP, "Wall Check",        true,   8, lcy, LW, function(v) Cfg.WallCheck = v    end); lcy = lcy + 22
CB( combatP, "Afficher FOV",      true,   8, lcy, LW, function(v) Cfg.ShowFOV = v      end); lcy = lcy + 22
SL( combatP, "FOV",        10,600, 150,   8, lcy, LW, function(v) Cfg.AimFOV = v       end); lcy = lcy + 38
SL( combatP, "Sensibilité",  1,100,  30,  8, lcy, LW, function(v) Cfg.AimSens = v/100  end); lcy = lcy + 38
DD( combatP, "Partie visée", {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"}, "Head", 8, lcy, LW, function(v) Cfg.AimPart = v end); lcy = lcy + 24
KB( combatP, "Touche Aimbot", "Q",    8, lcy, LW, function(k) AimKeyName = k           end)

SEC(combatP, "Silent Aim",  RX, rcy, RW); rcy = rcy + 22
CB( combatP, "Activer Silent Aim", false, RX, rcy, RW, function(v) Cfg.SA = v          end); rcy = rcy + 22
SL( combatP, "FOV Silent Aim", 10,600,200, RX, rcy, RW, function(v) Cfg.SAFOV = v      end); rcy = rcy + 38
SL( combatP, "Intensité (%)",  0,100,100,  RX, rcy, RW, function(v) Cfg.SAIntensity = v end); rcy = rcy + 38
DD( combatP, "Partie visée", {"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"}, "Head", RX, rcy, RW, function(v) Cfg.SAPart = v end); rcy = rcy + 24
KB( combatP, "Touche Silent Aim", "F", RX, rcy, RW, function(k) SAKeyName = k          end)

-- ========================
-- VISUALS
-- ========================
local vly = 8; local vry = 8

SEC(visualsP, "ESP",        8, vly, LW); vly = vly + 22
CB( visualsP, "Activer ESP",       false, 8, vly, LW, function(v) Cfg.ESP = v           end); vly = vly + 22
CB( visualsP, "ESP Clignotant",    false, 8, vly, LW, function(v) Cfg.ESPBlink = v      end); vly = vly + 22
CB( visualsP, "Noms",              true,  8, vly, LW, function(v) Cfg.ESPNames = v      end); vly = vly + 22
CB( visualsP, "HP dans le nom",    true,  8, vly, LW, function(v) Cfg.ESPHP = v         end); vly = vly + 22
SL( visualsP, "Transparence", 0,100,30,   8, vly, LW, function(v) Cfg.ESPTrans = v/100  end); vly = vly + 38

SEC(visualsP, "Fly",        RX, vry, RW); vry = vry + 22
CB( visualsP, "Activer Fly",  false, RX, vry, RW, function(v) if v then startFly() else stopFly() end end); vry = vry + 22
SL( visualsP, "Vitesse Fly", 10,2000,100, RX, vry, RW, function(v) Cfg.FlySpd = v     end); vry = vry + 38
KB( visualsP, "Touche Fly",  "G", RX, vry, RW, function(k) FlyKeyName = k             end); vry = vry + 24

SEC(visualsP, "Spin",       RX, vry, RW); vry = vry + 22
CB( visualsP, "Activer Spin", false, RX, vry, RW, function(v) if v then startSpin() else stopSpin() end end); vry = vry + 22
SL( visualsP, "Vitesse",   1,100,10,  RX, vry, RW, function(v) Cfg.SpinSpd = v        end); vry = vry + 38
DD( visualsP, "Direction", {"Clockwise","Counterclockwise"}, "Clockwise", RX, vry, RW, function(v) Cfg.SpinDir = v == "Clockwise" and 1 or -1 end); vry = vry + 24
DD( visualsP, "Axe",       {"Y","X","Z"}, "Y", RX, vry, RW, function(v) Cfg.SpinAxis = v end)

-- ========================
-- MISC
-- ========================
local mly = 8; local mry = 8

SEC(miscP, "Mouvement",     8, mly, LW); mly = mly + 22
CB( miscP, "Noclip",         false, 8, mly, LW, function(v) Cfg.Noclip = v             end); mly = mly + 22
CB( miscP, "Infinite Jump",  false, 8, mly, LW, function(v) Cfg.IJ = v; if v then startIJ() else stopIJ() end end); mly = mly + 22
CB( miscP, "Invisible",      false, 8, mly, LW, function(v) setInvis(v)                end); mly = mly + 22
CB( miscP, "Auto Respawn",   false, 8, mly, LW, function(v) Cfg.AutoRespawn = v        end); mly = mly + 22

SEC(miscP, "Character",     8, mly, LW); mly = mly + 22
CB( miscP, "WalkSpeed",      false, 8, mly, LW, function(v) Cfg.WS = v; if v then startWS() else stopWS() end end); mly = mly + 22
SL( miscP, "Set WalkSpeed", 16,500,25, 8, mly, LW, function(v) Cfg.WSVal = v           end); mly = mly + 38
CB( miscP, "JumpPower",      false, 8, mly, LW, function(v) Cfg.JP = v; if v then startJP() else stopJP() end end); mly = mly + 22
SL( miscP, "Set JumpPower", 20,500,20, 8, mly, LW, function(v) Cfg.JPVal = v           end)

SEC(miscP, "World",         RX, mry, RW); mry = mry + 22
CB( miscP, "Supprimer Fumigènes", false, RX, mry, RW, function(v) Cfg.Smoke = v        end); mry = mry + 22
CB( miscP, "Auto Réactivation",   false, RX, mry, RW, function(v)
    Cfg.AutoReactivate = v
    if v then saveState() end
end)

-- ========================
-- SETTINGS
-- ========================
local sly = 8

SEC(settingsP, "Interface", 8, sly, LW); sly = sly + 22
KB(settingsP, "Touche Menu (Toggle)", "LeftShift", 8, sly, LW, function(k)
    Cfg.MenuKey = k
end); sly = sly + 28

SEC(settingsP, "Reset",     8, sly, LW); sly = sly + 22

local closeBig = Instance.new("TextButton",settingsP)
closeBig.Size             = UDim2.new(0,LW,0,24)
closeBig.Position         = UDim2.new(0,8,0,sly)
closeBig.BackgroundColor3 = C.red
closeBig.Text             = "FERMER LSX V1"
closeBig.TextColor3       = Color3.new(1,1,1)
closeBig.TextSize         = 11
closeBig.Font             = Enum.Font.GothamBold
closeBig.BorderSizePixel  = 0
Instance.new("UICorner",closeBig).CornerRadius = UDim.new(0,3)

closeBig.MouseButton1Click:Connect(function()
    Cfg.Aim = false; Cfg.SA = false; Cfg.ESP = false
    Cfg.Noclip = false; Cfg.WS = false; Cfg.JP = false
    Cfg.IJ = false; Cfg.Fly = false; Cfg.Smoke = false
    stopFly(); stopWS(); stopJP(); stopIJ(); stopSpin()
    cleanConns(); clearESP()
    local h2 = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h2 then h2.WalkSpeed = 25.2; h2.JumpPower = 20 end
    if DrawCircle then DrawCircle:Remove(); DrawCircle = nil end
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    print = _print; warn = _warn
    GUI:Destroy()
end)

local rqBig = Instance.new("TextButton",settingsP)
rqBig.Size             = UDim2.new(0,LW,0,24)
rqBig.Position         = UDim2.new(0,8,0,sly+30)
rqBig.BackgroundColor3 = Color3.fromRGB(60,20,20)
rqBig.Text             = "RAGE QUIT"
rqBig.TextColor3       = Color3.new(1,1,1)
rqBig.TextSize         = 11
rqBig.Font             = Enum.Font.GothamBold
rqBig.BorderSizePixel  = 0
Instance.new("UICorner",rqBig).CornerRadius = UDim.new(0,3)
rqBig.MouseButton1Click:Connect(function()
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    lp:Kick(".")
end)

end) -- fin pcall
