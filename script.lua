-- LSX V1
task.wait(4)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

local lp     = Players.LocalPlayer
local Mouse  = lp:GetMouse()
local Camera = workspace.CurrentCamera

repeat task.wait(0.5) until lp.Character
local character = lp.Character
local hrp       = character:WaitForChild("HumanoidRootPart", 10)
local humanoid  = character:WaitForChild("Humanoid", 10)

local function sc(f, ...) pcall(f, ...) end

-- Masquage discret
sc(function() if script then script.Name = "LocalScript" end end)
local _print = print; local _warn = warn
print = function() end; warn = function() end

-- CONFIG
local Cfg = {
    Aim=false, AimPart="Head", AimFOV=150, AimSens=0.3,
    AimTarget=nil, RMB=false, WallCheck=true, ShowFOV=true,
    SA=false, SAPart="Head", SAFOV=200, SAIntensity=100,
    ESP=false, ESPColor=Color3.fromRGB(0,150,255), ESPTrans=0.3,
    ESPNames=true, ESPHP=true, ESPBlink=false,
    WS=false, WSVal=25.2, JP=false, JPVal=20,
    Noclip=false, IJ=false, Fly=false, FlySpd=100,
    Smoke=false, Invis=false,
    AutoRespawn=false, AutoReactivate=false,
    GuiOpen=true, MenuKey="LeftShift",
    Spin=false, SpinSpd=10, SpinDir=1, SpinAxis="Y",
}

local SavedState = {}
local function saveState()
    for k,v in pairs(Cfg) do
        if type(v) == "boolean" then SavedState[k] = v end
    end
end

local HMC       = {}
local noclipP   = {}
local origTrans = {}
local IJConn    = nil
local FlyConn   = nil
local SpinConn  = nil
local DrawCircle= nil

-- REFRESH
local function refresh()
    character = lp.Character
    if not character then return end
    hrp      = character:FindFirstChild("HumanoidRootPart")
    humanoid = character:FindFirstChildWhichIsA("Humanoid")
end

-- ENEMY CHECK
local function isEnemy(p)
    if not p or p == lp then return false end
    if lp.Team and p.Team then return lp.Team ~= p.Team end
    return true
end

-- WALKSPEED
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

-- JUMPPOWER
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

-- INFINITE JUMP
local function startIJ()
    if IJConn then return end
    IJConn = UIS.JumpRequest:Connect(function()
        local c = lp.Character
        if c then
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end
local function stopIJ()
    if IJConn then IJConn:Disconnect(); IJConn = nil end
end

-- FLY
local function startFly()
    if Cfg.Fly then return end
    Cfg.Fly = true
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then Cfg.Fly = false; return end
    sc(function()
        if h:FindFirstChild("FlyG") then h.FlyG:Destroy() end
        if h:FindFirstChild("FlyV") then h.FlyV:Destroy() end
    end)
    local gyro = Instance.new("BodyGyro")
    gyro.Name = "FlyG"; gyro.MaxTorque = Vector3.new(1,1,1)*math.huge
    gyro.P = 100000; gyro.CFrame = h.CFrame; gyro.Parent = h
    local vel = Instance.new("BodyVelocity")
    vel.Name = "FlyV"; vel.MaxForce = Vector3.new(1,1,1)*math.huge
    vel.P = 10000; vel.Velocity = Vector3.zero; vel.Parent = h
    if FlyConn then FlyConn:Disconnect() end
    FlyConn = RunService.RenderStepped:Connect(function()
        if not Cfg.Fly or not h or not h.Parent then
            if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
            sc(function() gyro:Destroy() end); sc(function() vel:Destroy() end)
            return
        end
        local mv = Vector3.zero; local cf = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)       then mv += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
        vel.Velocity = mv.Magnitude > 0 and mv.Unit*Cfg.FlySpd or Vector3.zero
        gyro.CFrame  = cf
    end)
end
local function stopFly()
    Cfg.Fly = false
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h then
        sc(function()
            if h:FindFirstChild("FlyG") then h.FlyG:Destroy() end
            if h:FindFirstChild("FlyV") then h.FlyV:Destroy() end
        end)
    end
end

-- NOCLIP
task.spawn(function()
    while task.wait(0.25) do
        local c = lp.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    if Cfg.Noclip then
                        if p.CanCollide then p.CanCollide = false; noclipP[p] = true end
                    else
                        if noclipP[p] then p.CanCollide = true; noclipP[p] = nil end
                    end
                end
            end
        end
    end
end)

-- INVISIBLE
local function setInvis(state)
    Cfg.Invis = state
    local c = lp.Character; if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if state then origTrans[p] = p.Transparency; p.Transparency = 1; p.LocalTransparencyModifier = 1
            else p.Transparency = origTrans[p] or 0; p.LocalTransparencyModifier = 0 end
        end
        if p:IsA("Decal") then p.Transparency = state and 1 or 0 end
    end
    for _, obj in ipairs(c:GetChildren()) do
        if obj:IsA("Accessory") then
            local h2 = obj:FindFirstChild("Handle")
            if h2 then
                if state then origTrans[h2] = h2.Transparency; h2.Transparency = 1; h2.LocalTransparencyModifier = 1
                else h2.Transparency = origTrans[h2] or 0; h2.LocalTransparencyModifier = 0 end
            end
        end
    end
    local hum = c:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.DisplayDistanceType = state and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Automatic end
end

-- SPIN
local function startSpin()
    if SpinConn then return end
    SpinConn = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end
        local a = math.rad(Cfg.SpinSpd) * Cfg.SpinDir
        hrp.CFrame *= (Cfg.SpinAxis=="X" and CFrame.Angles(a,0,0) or Cfg.SpinAxis=="Z" and CFrame.Angles(0,0,a) or CFrame.Angles(0,a,0))
    end)
end
local function stopSpin()
    if SpinConn then SpinConn:Disconnect(); SpinConn = nil end
end

-- SMOKE
task.spawn(function()
    while task.wait(0.4) do
        if Cfg.Smoke then
            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "Smoke Grenade" then sc(function() v:Destroy() end) end
            end
        end
    end
end)

-- AUTO RESPAWN
local function hookDied()
    if not humanoid then return end
    humanoid.Died:Connect(function()
        if not Cfg.AutoRespawn then return end
        task.wait(0.3)
        sc(function() lp:LoadCharacter() end)
    end)
end
hookDied()

-- RESTORE
local function restoreFeatures()
    if not Cfg.AutoReactivate then return end
    task.wait(1)
    if SavedState.WS     then Cfg.WS=true;     startWS()  end
    if SavedState.JP     then Cfg.JP=true;     startJP()  end
    if SavedState.IJ     then Cfg.IJ=true;     startIJ()  end
    if SavedState.Noclip then Cfg.Noclip=true             end
    if SavedState.Smoke  then Cfg.Smoke=true              end
    if SavedState.Aim    then Cfg.Aim=true                end
    if SavedState.SA     then Cfg.SA=true                 end
    if SavedState.ESP    then Cfg.ESP=true                end
    if SavedState.Fly    then task.wait(1.5); startFly()  end
end

lp.CharacterAdded:Connect(function()
    task.wait(1.2); refresh(); hookDied(); restoreFeatures()
end)

-- AIMBOT FOV CIRCLE
sc(function()
    if Drawing then
        DrawCircle = Drawing.new("Circle")
        DrawCircle.Thickness = 1; DrawCircle.Filled = false
        DrawCircle.Transparency = 1; DrawCircle.Color = Color3.fromRGB(0,150,255)
        DrawCircle.Visible = false; DrawCircle.Radius = Cfg.AimFOV
        RunService.RenderStepped:Connect(function()
            DrawCircle.Position = Vector2.new(Mouse.X, Mouse.Y+36)
            DrawCircle.Radius   = Cfg.AimFOV
            DrawCircle.Visible  = Cfg.ShowFOV and Cfg.Aim and not Cfg.GuiOpen
        end)
    end
end)

-- AIMBOT LOGIC
local function isValidTarget(p)
    if p == lp then return false end
    if not p.Character then return false end
    local h = p.Character:FindFirstChildWhichIsA("Humanoid")
    if not h or h.Health <= 0 then return false end
    if not isEnemy(p) then return false end
    return true
end

local function getAimPart(char) return char:FindFirstChild(Cfg.AimPart) end

local function isVisible(p)
    local c = p.Character; if not c then return false end
    local part = getAimPart(c); if not part then return false end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {lp.Character}
    rp.IgnoreWater = true
    local origin = Camera.CFrame.Position
    local hit = workspace:Raycast(origin, (part.Position-origin).Unit*1000, rp)
    if hit and hit.Instance and not c:IsAncestorOf(hit.Instance) then return false end
    return true
end

local function getClosestFOV()
    local best, dist = nil, Cfg.AimFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local part = getAimPart(p.Character)
            if part and (not Cfg.WallCheck or isVisible(p)) then
                local sp = Camera:WorldToScreenPoint(part.Position)
                local d  = (Vector2.new(Mouse.X,Mouse.Y)-Vector2.new(sp.X,sp.Y)).Magnitude
                if d < dist then best=p; dist=d end
            end
        end
    end
    return best
end

-- SILENT AIM
local function getSATarget()
    local best, dist = nil, Cfg.SAFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character then
            local part = p.Character:FindFirstChild(Cfg.SAPart)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d < dist then best=p; dist=d end
                end
            end
        end
    end
    return best
end

-- INPUT
local AimKey = "Q"; local FlyKey = "G"; local SAKey = "F"

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode.Name == Cfg.MenuKey then
        Cfg.GuiOpen = not Cfg.GuiOpen
        UIS.MouseBehavior = Cfg.GuiOpen and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
        return
    end

    if Cfg.GuiOpen then return end

    local k = input.KeyCode.Name
    if k == AimKey then Cfg.Aim = not Cfg.Aim end
    if k == FlyKey then if Cfg.Fly then stopFly() else startFly() end end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then Cfg.RMB = true end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and Cfg.SA then
        if math.random(1,100) <= Cfg.SAIntensity then
            local target = getSATarget()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Cfg.SAPart)
                if part then
                    local origCF = Camera.CFrame
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    task.delay(0.065, function() if Camera then Camera.CFrame = origCF end end)
                end
            end
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Cfg.RMB = false; Cfg.AimTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if Cfg.GuiOpen then UIS.MouseBehavior = Enum.MouseBehavior.Default; return end
    if not Cfg.Aim or not Cfg.RMB then return end
    if Cfg.AimTarget and Cfg.AimTarget.Parent and isValidTarget(Cfg.AimTarget) then
        local part = getAimPart(Cfg.AimTarget.Character)
        if part then
            local pos = Camera:WorldToScreenPoint(part.Position)
            if pos.Z > 0 then
                local delta = (Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y))*Cfg.AimSens
                sc(function() mousemoverel(delta.X, delta.Y) end)
            end
        end
    else
        local t = getClosestFOV()
        if t then Cfg.AimTarget = t end
    end
end)

-- ESP
local function clearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("ESPh"); if hl then hl:Destroy() end
            local bb = p.Character:FindFirstChild("ESPb"); if bb then bb:Destroy() end
        end
    end
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local c   = p.Character
            local ehl = c:FindFirstChild("ESPh")
            local ebb = c:FindFirstChild("ESPb")
            local blink = Cfg.ESPBlink and (tick()%4 < 2)
            if Cfg.ESP and (not Cfg.ESPBlink or blink) then
                if not ehl then
                    local hl = Instance.new("Highlight"); hl.Name = "ESPh"
                    hl.FillTransparency = Cfg.ESPTrans; hl.OutlineTransparency = 1
                    hl.FillColor = Cfg.ESPColor; hl.Parent = c
                else ehl.FillColor = Cfg.ESPColor; ehl.FillTransparency = Cfg.ESPTrans end
                if Cfg.ESPNames and not ebb then
                    local head = c:FindFirstChild("Head")
                    if head then
                        local bb = Instance.new("BillboardGui"); bb.Name = "ESPb"
                        bb.Adornee = head; bb.Size = UDim2.new(0,100,0,20)
                        bb.StudsOffset = Vector3.new(0,2.5,0); bb.AlwaysOnTop = true
                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
                        lbl.TextColor3 = Cfg.ESPColor; lbl.TextScaled = true
                        lbl.Font = Enum.Font.SourceSansBold
                        if Cfg.ESPHP then
                            task.spawn(function()
                                while lbl and lbl.Parent and Cfg.ESP do
                                    sc(function()
                                        lbl.Text = p.Name.." | "..math.floor(p.Character.Humanoid.Health).." HP"
                                    end)
                                    task.wait(0.3)
                                end
                            end)
                        else lbl.Text = p.Name end
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
    while task.wait(0.3) do
        if Cfg.ESP then refreshESP() else clearESP() end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        sc(function()
            local hl = p.Character:FindFirstChild("ESPh"); if hl then hl:Destroy() end
        end)
    end
end)

-- AUTO SAVE STATE
task.spawn(function()
    while task.wait(3) do
        if Cfg.AutoReactivate then saveState() end
    end
end)

-- ========================
-- GUI
-- ========================
local GUI = Instance.new("ScreenGui")
GUI.Name           = "S"..tostring(math.random(1000,9999))
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder   = 999
GUI.IgnoreGuiInset = true

local ok2 = false
sc(function() GUI.Parent = game:GetService("CoreGui"); ok2 = true end)
if not ok2 then GUI.Parent = lp:WaitForChild("PlayerGui") end

local C = {
    bg=Color3.fromRGB(20,20,22), bg2=Color3.fromRGB(28,28,31),
    bg3=Color3.fromRGB(38,38,42), acc=Color3.fromRGB(0,145,255),
    acc2=Color3.fromRGB(0,95,200), txt=Color3.fromRGB(210,210,215),
    txt2=Color3.fromRGB(120,120,128), border=Color3.fromRGB(50,50,58),
    red=Color3.fromRGB(200,50,50),
}

local MF = Instance.new("Frame", GUI)
MF.Name = "W"; MF.Size = UDim2.new(0,650,0,430)
MF.Position = UDim2.new(0.5,-325,0.5,-215)
MF.BackgroundColor3 = C.bg; MF.BorderSizePixel = 0
MF.Active = true; MF.Selectable = false
Instance.new("UICorner",MF).CornerRadius = UDim.new(0,4)
local MStr = Instance.new("UIStroke",MF); MStr.Color = C.border; MStr.Thickness = 1

local function setVisible(v)
    Cfg.GuiOpen = v; MF.Visible = v
    UIS.MouseBehavior = v and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
end

-- TITLEBAR
local TB = Instance.new("Frame",MF)
TB.Size = UDim2.new(1,0,0,28); TB.BackgroundColor3 = C.bg2; TB.BorderSizePixel = 0
Instance.new("UICorner",TB).CornerRadius = UDim.new(0,4)
local TBf = Instance.new("Frame",TB)
TBf.Size = UDim2.new(1,0,0,6); TBf.Position = UDim2.new(0,0,1,-6)
TBf.BackgroundColor3 = C.bg2; TBf.BorderSizePixel = 0

local TL = Instance.new("TextLabel",TB)
TL.Size = UDim2.new(1,-70,1,0); TL.Position = UDim2.new(0,10,0,0)
TL.BackgroundTransparency = 1; TL.Text = "LSX V1  |  Rivals"
TL.TextColor3 = C.txt; TL.TextSize = 12
TL.Font = Enum.Font.GothamBold; TL.TextXAlignment = Enum.TextXAlignment.Left

local function mkBtn(p,x,t,bg)
    local b = Instance.new("TextButton",p)
    b.Size = UDim2.new(0,24,0,18); b.Position = UDim2.new(1,x,0,5)
    b.BackgroundColor3 = bg; b.Text = t; b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 11; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,3)
    return b
end
local CloseB = mkBtn(TB,-28,"✕",C.red)
local MinB   = mkBtn(TB,-56,"−",C.bg3)

-- DRAG
local drag,ds,dp = false,nil,nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=true; ds=i.Position; dp=MF.Position end
end)
TB.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
end)
UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position-ds
        MF.Position = UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
    end
end)

local minimized = false
MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _,child in ipairs(MF:GetChildren()) do
        if child ~= TB then child.Visible = not minimized end
    end
    MF.Size = minimized and UDim2.new(0,650,0,28) or UDim2.new(0,650,0,430)
end)
CloseB.MouseButton1Click:Connect(function() setVisible(false); MF.Visible = false end)

-- TABBAR + CONTENT
local TBar = Instance.new("Frame",MF)
TBar.Size = UDim2.new(1,0,0,28); TBar.Position = UDim2.new(0,0,0,28)
TBar.BackgroundColor3 = C.bg2; TBar.BorderSizePixel = 0
local TBL = Instance.new("UIListLayout",TBar)
TBL.FillDirection = Enum.FillDirection.Horizontal; TBL.SortOrder = Enum.SortOrder.LayoutOrder

local Cont = Instance.new("Frame",MF)
Cont.Size = UDim2.new(1,0,1,-56); Cont.Position = UDim2.new(0,0,0,56)
Cont.BackgroundTransparency = 1

-- HELPERS
local LW=296; local RX=324; local RW=296
local aBtns,aInds,aPanels = {},{},{}

local function mkTab(name,order)
    local btn = Instance.new("TextButton",TBar)
    btn.Size = UDim2.new(0,104,1,0); btn.BackgroundColor3 = C.bg2
    btn.BorderSizePixel = 0; btn.Text = name; btn.TextColor3 = C.txt2
    btn.TextSize = 11; btn.Font = Enum.Font.Gotham; btn.LayoutOrder = order
    local ind = Instance.new("Frame",btn)
    ind.Size = UDim2.new(1,0,0,2); ind.Position = UDim2.new(0,0,1,-2)
    ind.BackgroundColor3 = C.acc; ind.BorderSizePixel = 0; ind.Visible = false
    local panel = Instance.new("Frame",Cont)
    panel.Size = UDim2.new(1,0,1,0); panel.BackgroundTransparency = 1; panel.Visible = false
    table.insert(aBtns,btn); table.insert(aInds,ind); table.insert(aPanels,panel)
    btn.MouseButton1Click:Connect(function()
        for _,p in ipairs(aPanels) do p.Visible=false end
        for _,i in ipairs(aInds)   do i.Visible=false end
        for _,b in ipairs(aBtns)   do b.TextColor3=C.txt2 end
        panel.Visible=true; ind.Visible=true; btn.TextColor3=C.txt
    end)
    return panel
end

local function CB(parent,lbl,default,x,y,w,cb)
    local f = Instance.new("Frame",parent)
    f.Size = UDim2.new(0,w,0,20); f.Position = UDim2.new(0,x,0,y); f.BackgroundTransparency=1
    local box = Instance.new("Frame",f)
    box.Size = UDim2.new(0,13,0,13); box.Position = UDim2.new(0,0,0.5,-6)
    box.BackgroundColor3 = default and C.acc or C.bg3; box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,2)
    local bs=Instance.new("UIStroke",box); bs.Color=C.border; bs.Thickness=1
    local tick=Instance.new("TextLabel",box)
    tick.Size=UDim2.new(1,0,1,0); tick.BackgroundTransparency=1
    tick.Text=default and "✓" or ""; tick.TextColor3=Color3.new(1,1,1)
    tick.TextSize=9; tick.Font=Enum.Font.GothamBold
    local label=Instance.new("TextLabel",f)
    label.Size=UDim2.new(1,-18,1,0); label.Position=UDim2.new(0,18,0,0)
    label.BackgroundTransparency=1; label.Text=lbl; label.TextColor3=C.txt
    label.TextSize=11; label.Font=Enum.Font.Gotham; label.TextXAlignment=Enum.TextXAlignment.Left
    local val=default
    local btn=Instance.new("TextButton",f)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    local function sv(v) val=v; box.BackgroundColor3=v and C.acc or C.bg3; tick.Text=v and "✓" or "" end
    btn.MouseButton1Click:Connect(function() sv(not val); if cb then cb(val) end end)
    return sv
end

local function SL(parent,lbl,min,max,default,x,y,w,cb)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(0,w,0,34); f.Position=UDim2.new(0,x,0,y); f.BackgroundTransparency=1
    local top=Instance.new("Frame",f); top.Size=UDim2.new(1,0,0,14); top.BackgroundTransparency=1
    local ll=Instance.new("TextLabel",top); ll.Size=UDim2.new(0.6,0,1,0)
    ll.BackgroundTransparency=1; ll.Text=lbl; ll.TextColor3=C.txt; ll.TextSize=10
    ll.Font=Enum.Font.Gotham; ll.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",top); vl.Size=UDim2.new(0.4,0,1,0); vl.Position=UDim2.new(0.6,0,0,0)
    vl.BackgroundTransparency=1; vl.Text=tostring(default).."/"..tostring(max)
    vl.TextColor3=C.txt2; vl.TextSize=10; vl.Font=Enum.Font.Gotham; vl.TextXAlignment=Enum.TextXAlignment.Right
    local track=Instance.new("Frame",f); track.Size=UDim2.new(1,0,0,5); track.Position=UDim2.new(0,0,0,17)
    track.BackgroundColor3=C.bg3; track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,3)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((default-min)/(max-min),0,1,0); fill.BackgroundColor3=C.acc; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)
    local val=default; local sliding=false
    local function upd(mx)
        local rel=math.clamp((mx-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        val=math.floor(min+(max-min)*rel); fill.Size=UDim2.new(rel,0,1,0)
        vl.Text=tostring(val).."/"..tostring(max); if cb then cb(val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
end

local function KB(parent,lbl,default,x,y,w,cb)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(0,w,0,20); f.Position=UDim2.new(0,x,0,y); f.BackgroundTransparency=1
    local ll=Instance.new("TextLabel",f); ll.Size=UDim2.new(0.55,0,1,0)
    ll.BackgroundTransparency=1; ll.Text=lbl; ll.TextColor3=C.txt; ll.TextSize=10
    ll.Font=Enum.Font.Gotham; ll.TextXAlignment=Enum.TextXAlignment.Left
    local kb=Instance.new("TextButton",f)
    kb.Size=UDim2.new(0.43,0,1,0); kb.Position=UDim2.new(0.57,0,0,0)
    kb.BackgroundColor3=C.bg3; kb.Text=default; kb.TextColor3=C.acc
    kb.TextSize=10; kb.Font=Enum.Font.GothamBold; kb.BorderSizePixel=0
    Instance.new("UICorner",kb).CornerRadius=UDim.new(0,2)
    local ks=Instance.new("UIStroke",kb); ks.Color=C.acc2; ks.Thickness=1
    local waiting=false
    kb.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting=true; kb.Text="..."; kb.TextColor3=C.txt2
        local conn; conn=UIS.InputBegan:Connect(function(i,gp)
            if gp then return end
            if i.UserInputType==Enum.UserInputType.Keyboard then
                local n=i.KeyCode.Name; kb.Text=n; kb.TextColor3=C.acc
                if cb then cb(n) end; waiting=false; conn:Disconnect()
            end
        end)
    end)
end

local function DD(parent,lbl,opts,default,x,y,w,cb)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(0,w,0,20); f.Position=UDim2.new(0,x,0,y); f.BackgroundTransparency=1
    local ll=Instance.new("TextLabel",f); ll.Size=UDim2.new(0.45,0,1,0)
    ll.BackgroundTransparency=1; ll.Text=lbl; ll.TextColor3=C.txt; ll.TextSize=10
    ll.Font=Enum.Font.Gotham; ll.TextXAlignment=Enum.TextXAlignment.Left
    local db=Instance.new("TextButton",f)
    db.Size=UDim2.new(0.53,0,1,0); db.Position=UDim2.new(0.47,0,0,0)
    db.BackgroundColor3=C.bg3; db.Text=default.." ▾"; db.TextColor3=C.txt
    db.TextSize=9; db.Font=Enum.Font.Gotham; db.BorderSizePixel=0
    Instance.new("UICorner",db).CornerRadius=UDim.new(0,2)
    local ds3=Instance.new("UIStroke",db); ds3.Color=C.border; ds3.Thickness=1
    local open=false; local menu=nil
    db.MouseButton1Click:Connect(function()
        if open and menu then menu:Destroy(); menu=nil; open=false; return end
        open=true; menu=Instance.new("Frame",parent)
        menu.Size=UDim2.new(0,120,0,#opts*20); menu.Position=UDim2.new(0,x+w*0.47,0,y+22)
        menu.BackgroundColor3=C.bg2; menu.BorderSizePixel=0; menu.ZIndex=20
        Instance.new("UICorner",menu).CornerRadius=UDim.new(0,3)
        local ms3=Instance.new("UIStroke",menu); ms3.Color=C.border; ms3.Thickness=1
        for i,opt in ipairs(opts) do
            local ob=Instance.new("TextButton",menu)
            ob.Size=UDim2.new(1,0,0,20); ob.Position=UDim2.new(0,0,0,(i-1)*20)
            ob.BackgroundTransparency=1; ob.Text=opt; ob.TextColor3=C.txt
            ob.TextSize=10; ob.Font=Enum.Font.Gotham; ob.ZIndex=21
            ob.MouseButton1Click:Connect(function()
                db.Text=opt.." ▾"; if cb then cb(opt) end
                menu:Destroy(); menu=nil; open=false
            end)
            ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0; ob.BackgroundColor3=C.bg3 end)
            ob.MouseLeave:Connect(function() ob.BackgroundTransparency=1 end)
        end
    end)
end

local function SEC(panel,lbl,x,y,w)
    local l=Instance.new("TextLabel",panel)
    l.Size=UDim2.new(0,w,0,15); l.Position=UDim2.new(0,x,0,y)
    l.BackgroundTransparency=1; l.Text=lbl; l.TextColor3=C.txt
    l.TextSize=11; l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
    local line=Instance.new("Frame",panel)
    line.Size=UDim2.new(0,w,0,1); line.Position=UDim2.new(0,x,0,y+16)
    line.BackgroundColor3=C.acc; line.BorderSizePixel=0
end

-- BUILD TABS
local combatP  = mkTab("Combat",1)
local visualsP = mkTab("Visuals",2)
local miscP    = mkTab("Misc",3)
local settP    = mkTab("Settings",4)

aPanels[1].Visible=true; aInds[1].Visible=true; aBtns[1].TextColor3=C.txt

-- COMBAT
local lcy=8; local rcy=8
SEC(combatP,"Aimbot",8,lcy,LW);        lcy=lcy+22
CB(combatP,"Activer Aimbot",false,8,lcy,LW,function(v) Cfg.Aim=v end);          lcy=lcy+22
CB(combatP,"Wall Check",true,8,lcy,LW,function(v) Cfg.WallCheck=v end);         lcy=lcy+22
CB(combatP,"Afficher FOV",true,8,lcy,LW,function(v) Cfg.ShowFOV=v end);         lcy=lcy+22
SL(combatP,"FOV",10,600,150,8,lcy,LW,function(v) Cfg.AimFOV=v end);            lcy=lcy+38
SL(combatP,"Sensibilité",1,100,30,8,lcy,LW,function(v) Cfg.AimSens=v/100 end); lcy=lcy+38
DD(combatP,"Partie visée",{"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"},"Head",8,lcy,LW,function(v) Cfg.AimPart=v end); lcy=lcy+24
KB(combatP,"Touche Aimbot","Q",8,lcy,LW,function(k) AimKey=k end)

SEC(combatP,"Silent Aim",RX,rcy,RW);      rcy=rcy+22
CB(combatP,"Activer Silent Aim",false,RX,rcy,RW,function(v) Cfg.SA=v end);      rcy=rcy+22
SL(combatP,"FOV Silent Aim",10,600,200,RX,rcy,RW,function(v) Cfg.SAFOV=v end);  rcy=rcy+38
SL(combatP,"Intensité (%)",0,100,100,RX,rcy,RW,function(v) Cfg.SAIntensity=v end); rcy=rcy+38
DD(combatP,"Partie visée",{"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"},"Head",RX,rcy,RW,function(v) Cfg.SAPart=v end); rcy=rcy+24
KB(combatP,"Touche Silent Aim","F",RX,rcy,RW,function(k) SAKey=k end)

-- VISUALS
local vly=8; local vry=8
SEC(visualsP,"ESP",8,vly,LW);               vly=vly+22
CB(visualsP,"Activer ESP",false,8,vly,LW,function(v) Cfg.ESP=v end);            vly=vly+22
CB(visualsP,"ESP Clignotant",false,8,vly,LW,function(v) Cfg.ESPBlink=v end);   vly=vly+22
CB(visualsP,"Noms",true,8,vly,LW,function(v) Cfg.ESPNames=v end);              vly=vly+22
CB(visualsP,"HP dans le nom",true,8,vly,LW,function(v) Cfg.ESPHP=v end);       vly=vly+22
SL(visualsP,"Transparence",0,100,30,8,vly,LW,function(v) Cfg.ESPTrans=v/100 end); vly=vly+38

SEC(visualsP,"Fly",RX,vry,RW);              vry=vry+22
CB(visualsP,"Activer Fly",false,RX,vry,RW,function(v) if v then startFly() else stopFly() end end); vry=vry+22
SL(visualsP,"Vitesse Fly",10,2000,100,RX,vry,RW,function(v) Cfg.FlySpd=v end); vry=vry+38
KB(visualsP,"Touche Fly","G",RX,vry,RW,function(k) FlyKey=k end);              vry=vry+24

SEC(visualsP,"Spin",RX,vry,RW);             vry=vry+22
CB(visualsP,"Activer Spin",false,RX,vry,RW,function(v) if v then startSpin() else stopSpin() end end); vry=vry+22
SL(visualsP,"Vitesse",1,100,10,RX,vry,RW,function(v) Cfg.SpinSpd=v end);       vry=vry+38
DD(visualsP,"Direction",{"Clockwise","Counterclockwise"},"Clockwise",RX,vry,RW,function(v) Cfg.SpinDir=v=="Clockwise" and 1 or -1 end); vry=vry+24
DD(visualsP,"Axe",{"Y","X","Z"},"Y",RX,vry,RW,function(v) Cfg.SpinAxis=v end)

-- MISC
local mly=8; local mry=8
SEC(miscP,"Mouvement",8,mly,LW);             mly=mly+22
CB(miscP,"Noclip",false,8,mly,LW,function(v) Cfg.Noclip=v end);                mly=mly+22
CB(miscP,"Infinite Jump",false,8,mly,LW,function(v) Cfg.IJ=v; if v then startIJ() else stopIJ() end end); mly=mly+22
CB(miscP,"Invisible",false,8,mly,LW,function(v) setInvis(v) end);              mly=mly+22
CB(miscP,"Auto Respawn",false,8,mly,LW,function(v) Cfg.AutoRespawn=v end);     mly=mly+22
SEC(miscP,"Character",8,mly,LW);             mly=mly+22
CB(miscP,"WalkSpeed",false,8,mly,LW,function(v) Cfg.WS=v; if v then startWS() else stopWS() end end); mly=mly+22
SL(miscP,"Set WalkSpeed",16,500,25,8,mly,LW,function(v) Cfg.WSVal=v end);      mly=mly+38
CB(miscP,"JumpPower",false,8,mly,LW,function(v) Cfg.JP=v; if v then startJP() else stopJP() end end); mly=mly+22
SL(miscP,"Set JumpPower",20,500,20,8,mly,LW,function(v) Cfg.JPVal=v end)

SEC(miscP,"World",RX,mry,RW);                mry=mry+22
CB(miscP,"Supprimer Fumigènes",false,RX,mry,RW,function(v) Cfg.Smoke=v end);   mry=mry+22
CB(miscP,"Auto Réactivation",false,RX,mry,RW,function(v)
    Cfg.AutoReactivate=v; if v then saveState() end
end)

-- SETTINGS
local sly=8
SEC(settP,"Interface",8,sly,LW); sly=sly+22
KB(settP,"Touche Menu","LeftShift",8,sly,LW,function(k) Cfg.MenuKey=k end); sly=sly+30

SEC(settP,"Actions",8,sly,LW); sly=sly+22

local cb1 = Instance.new("TextButton",settP)
cb1.Size=UDim2.new(0,LW,0,24); cb1.Position=UDim2.new(0,8,0,sly)
cb1.BackgroundColor3=C.red; cb1.Text="FERMER LSX V1"; cb1.TextColor3=Color3.new(1,1,1)
cb1.TextSize=11; cb1.Font=Enum.Font.GothamBold; cb1.BorderSizePixel=0
Instance.new("UICorner",cb1).CornerRadius=UDim.new(0,3)
cb1.MouseButton1Click:Connect(function()
    Cfg.Aim=false; Cfg.SA=false; Cfg.ESP=false; Cfg.Noclip=false
    Cfg.WS=false; Cfg.JP=false; Cfg.IJ=false; Cfg.Fly=false; Cfg.Smoke=false
    stopFly(); stopWS(); stopJP(); stopIJ(); stopSpin(); clearESP()
    local h2=lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h2 then h2.WalkSpeed=25.2; h2.JumpPower=20 end
    if DrawCircle then DrawCircle:Remove(); DrawCircle=nil end
    UIS.MouseBehavior=Enum.MouseBehavior.Default
    print=_print; warn=_warn
    GUI:Destroy()
end)

local cb2 = Instance.new("TextButton",settP)
cb2.Size=UDim2.new(0,LW,0,24); cb2.Position=UDim2.new(0,8,0,sly+30)
cb2.BackgroundColor3=Color3.fromRGB(60,20,20); cb2.Text="RAGE QUIT"; cb2.TextColor3=Color3.new(1,1,1)
cb2.TextSize=11; cb2.Font=Enum.Font.GothamBold; cb2.BorderSizePixel=0
Instance.new("UICorner",cb2).CornerRadius=UDim.new(0,3)
cb2.MouseButton1Click:Connect(function()
    UIS.MouseBehavior=Enum.MouseBehavior.Default; lp:Kick(".")
end)
