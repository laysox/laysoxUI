-- LSX V1
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

local lp     = Players.LocalPlayer
local Mouse  = lp:GetMouse()
local Camera = workspace.CurrentCamera

-- Attend que le perso soit là
repeat task.wait(1) until lp.Character
local character = lp.Character
local hrp       = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

local function sc(f,...) pcall(f,...) end

-- CONFIG
local Cfg = {
    Aim=false, AimPart="Head", AimFOV=150, AimSens=0.3,
    AimTarget=nil, RMB=false, WallCheck=true, ShowFOV=true,
    SA=false, SAPart="Head", SAFOV=200, SAIntensity=100,
    ESP=false, ESPColor=Color3.fromRGB(0,150,255), ESPTrans=0.3,
    ESPNames=true, ESPHP=true,
    WS=false, WSVal=25.2, JP=false, JPVal=20,
    Noclip=false, IJ=false, Fly=false, FlySpd=100,
    Smoke=false, Invis=false, AutoRespawn=false,
    Spin=false, SpinSpd=10, SpinDir=1, SpinAxis="Y",
}

local HMC={}, noclipP={}, origTrans={}
local IJConn,FlyConn,SpinConn=nil,nil,nil
local AimKey="Q"; local FlyKey="G"; local SAKey="F"

-- Fonctions déclarées avant Rayfield
local function refresh()
    character=lp.Character; if not character then return end
    hrp=character:FindFirstChild("HumanoidRootPart")
    humanoid=character:FindFirstChildWhichIsA("Humanoid")
end

local function isEnemy(p)
    if not p or p==lp then return false end
    if lp.Team and p.Team then return lp.Team~=p.Team end
    return true
end

local function startWS()
    local h=lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.WalkSpeed=Cfg.WSVal end; apply()
    if HMC.ws then HMC.ws:Disconnect() end
    HMC.ws=h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
end
local function stopWS()
    if HMC.ws then HMC.ws:Disconnect(); HMC.ws=nil end
    local h=lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed=25.2 end
end

local function startJP()
    local h=lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.UseJumpPower=true; h.JumpPower=Cfg.JPVal end; apply()
    if HMC.jp then HMC.jp:Disconnect() end
    HMC.jp=h:GetPropertyChangedSignal("JumpPower"):Connect(apply)
end
local function stopJP()
    if HMC.jp then HMC.jp:Disconnect(); HMC.jp=nil end
    local h=lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.JumpPower=20 end
end

local function startIJ()
    if IJConn then return end
    IJConn=UIS.JumpRequest:Connect(function()
        local c=lp.Character
        if c then
            local h=c:FindFirstChildWhichIsA("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end
local function stopIJ()
    if IJConn then IJConn:Disconnect(); IJConn=nil end
end

local function startFly()
    if Cfg.Fly then return end
    Cfg.Fly=true
    local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then Cfg.Fly=false; return end
    sc(function()
        if h:FindFirstChild("FG") then h.FG:Destroy() end
        if h:FindFirstChild("FV") then h.FV:Destroy() end
    end)
    local gyro=Instance.new("BodyGyro"); gyro.Name="FG"
    gyro.MaxTorque=Vector3.new(1,1,1)*math.huge
    gyro.P=100000; gyro.CFrame=h.CFrame; gyro.Parent=h
    local vel=Instance.new("BodyVelocity"); vel.Name="FV"
    vel.MaxForce=Vector3.new(1,1,1)*math.huge
    vel.P=10000; vel.Velocity=Vector3.zero; vel.Parent=h
    if FlyConn then FlyConn:Disconnect() end
    FlyConn=RunService.RenderStepped:Connect(function()
        if not Cfg.Fly or not h or not h.Parent then
            if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
            sc(function() gyro:Destroy() end)
            sc(function() vel:Destroy() end)
            return
        end
        local mv=Vector3.zero; local cf=Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv+=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv-=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv-=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv+=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv+=Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv-=Vector3.new(0,1,0) end
        vel.Velocity=mv.Magnitude>0 and mv.Unit*Cfg.FlySpd or Vector3.zero
        gyro.CFrame=cf
    end)
end
local function stopFly()
    Cfg.Fly=false
    if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
    local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h then
        sc(function()
            if h:FindFirstChild("FG") then h.FG:Destroy() end
            if h:FindFirstChild("FV") then h.FV:Destroy() end
        end)
    end
end

local function startSpin()
    if SpinConn then return end
    SpinConn=RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end
        local a=math.rad(Cfg.SpinSpd)*Cfg.SpinDir
        hrp.CFrame*=(Cfg.SpinAxis=="X" and CFrame.Angles(a,0,0)
            or Cfg.SpinAxis=="Z" and CFrame.Angles(0,0,a)
            or CFrame.Angles(0,a,0))
    end)
end
local function stopSpin()
    if SpinConn then SpinConn:Disconnect(); SpinConn=nil end
end

local function setInvis(state)
    Cfg.Invis=state
    local c=lp.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
            if state then
                origTrans[p]=p.Transparency
                p.Transparency=1; p.LocalTransparencyModifier=1
            else
                p.Transparency=origTrans[p] or 0
                p.LocalTransparencyModifier=0
            end
        end
        if p:IsA("Decal") then p.Transparency=state and 1 or 0 end
    end
    for _,obj in ipairs(c:GetChildren()) do
        if obj:IsA("Accessory") then
            local h2=obj:FindFirstChild("Handle")
            if h2 then
                if state then
                    origTrans[h2]=h2.Transparency
                    h2.Transparency=1; h2.LocalTransparencyModifier=1
                else
                    h2.Transparency=origTrans[h2] or 0
                    h2.LocalTransparencyModifier=0
                end
            end
        end
    end
    local hum=c:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.DisplayDistanceType=state
            and Enum.HumanoidDisplayDistanceType.None
            or Enum.HumanoidDisplayDistanceType.Automatic
    end
end

local function clearESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl=p.Character:FindFirstChild("EH"); if hl then hl:Destroy() end
            local bb=p.Character:FindFirstChild("EB"); if bb then bb:Destroy() end
        end
    end
end

local function refreshESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp and p.Character then
            local c=p.Character
            local ehl=c:FindFirstChild("EH")
            local ebb=c:FindFirstChild("EB")
            if Cfg.ESP then
                if not ehl then
                    local hl=Instance.new("Highlight"); hl.Name="EH"
                    hl.FillTransparency=Cfg.ESPTrans
                    hl.OutlineTransparency=1
                    hl.FillColor=Cfg.ESPColor; hl.Parent=c
                else
                    ehl.FillColor=Cfg.ESPColor
                    ehl.FillTransparency=Cfg.ESPTrans
                end
                if Cfg.ESPNames and not ebb then
                    local head=c:FindFirstChild("Head")
                    if head then
                        local bb=Instance.new("BillboardGui"); bb.Name="EB"
                        bb.Adornee=head; bb.Size=UDim2.new(0,100,0,20)
                        bb.StudsOffset=Vector3.new(0,2.5,0); bb.AlwaysOnTop=true
                        local lbl=Instance.new("TextLabel",bb)
                        lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
                        lbl.TextColor3=Cfg.ESPColor; lbl.TextScaled=true
                        lbl.Font=Enum.Font.SourceSansBold
                        if Cfg.ESPHP then
                            task.spawn(function()
                                while lbl and lbl.Parent and Cfg.ESP do
                                    sc(function()
                                        lbl.Text=p.Name.." | "..math.floor(p.Character.Humanoid.Health).." HP"
                                    end)
                                    task.wait(0.3)
                                end
                            end)
                        else lbl.Text=p.Name end
                        bb.Parent=c
                    end
                end
            else
                if ehl then ehl:Destroy() end
                if ebb then ebb:Destroy() end
            end
        end
    end
end

-- Boucles légères
task.spawn(function()
    while task.wait(0.25) do
        local c=lp.Character; if not c then continue end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if Cfg.Noclip then
                    if p.CanCollide then p.CanCollide=false; noclipP[p]=true end
                else
                    if noclipP[p] then p.CanCollide=true; noclipP[p]=nil end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.4) do
        if Cfg.Smoke then
            for _,v in ipairs(workspace:GetChildren()) do
                if v.Name=="Smoke Grenade" then sc(function() v:Destroy() end) end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if Cfg.ESP then refreshESP() else clearESP() end
    end
end)

-- Auto respawn
humanoid.Died:Connect(function()
    if not Cfg.AutoRespawn then return end
    task.wait(0.3); sc(function() lp:LoadCharacter() end)
end)

lp.CharacterAdded:Connect(function()
    task.wait(1); refresh()
    if humanoid then
        humanoid.Died:Connect(function()
            if not Cfg.AutoRespawn then return end
            task.wait(0.3); sc(function() lp:LoadCharacter() end)
        end)
    end
end)

-- Aimbot
local function isValidTarget(p)
    if p==lp then return false end
    if not p.Character then return false end
    local h=p.Character:FindFirstChildWhichIsA("Humanoid")
    if not h or h.Health<=0 then return false end
    if not isEnemy(p) then return false end
    return true
end
local function getAimPart(char) return char:FindFirstChild(Cfg.AimPart) end
local function isVisible(p)
    local c=p.Character; if not c then return false end
    local part=getAimPart(c); if not part then return false end
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances={lp.Character}; rp.IgnoreWater=true
    local hit=workspace:Raycast(Camera.CFrame.Position,(part.Position-Camera.CFrame.Position).Unit*1000,rp)
    if hit and hit.Instance and not c:IsAncestorOf(hit.Instance) then return false end
    return true
end
local function getClosestFOV()
    local best,dist=nil,Cfg.AimFOV
    for _,p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local part=getAimPart(p.Character)
            if part and (not Cfg.WallCheck or isVisible(p)) then
                local sp=Camera:WorldToScreenPoint(part.Position)
                local d=(Vector2.new(Mouse.X,Mouse.Y)-Vector2.new(sp.X,sp.Y)).Magnitude
                if d<dist then best=p; dist=d end
            end
        end
    end
    return best
end

local function getSATarget()
    local best,dist=nil,Cfg.SAFOV
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character then
            local part=p.Character:FindFirstChild(Cfg.SAPart)
            if part then
                local sp,onScreen=Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d<dist then best=p; dist=d end
                end
            end
        end
    end
    return best
end

UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    local k=input.KeyCode.Name
    if k==AimKey then Cfg.Aim=not Cfg.Aim end
    if k==FlyKey then if Cfg.Fly then stopFly() else startFly() end end
    if input.UserInputType==Enum.UserInputType.MouseButton2 then Cfg.RMB=true end
    if input.UserInputType==Enum.UserInputType.MouseButton1 and Cfg.SA then
        if math.random(1,100)<=Cfg.SAIntensity then
            local target=getSATarget()
            if target and target.Character then
                local part=target.Character:FindFirstChild(Cfg.SAPart)
                if part then
                    local origCF=Camera.CFrame
                    Camera.CFrame=CFrame.new(Camera.CFrame.Position,part.Position)
                    task.delay(0.065,function() if Camera then Camera.CFrame=origCF end end)
                end
            end
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        Cfg.RMB=false; Cfg.AimTarget=nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not Cfg.Aim or not Cfg.RMB then return end
    if Cfg.AimTarget and Cfg.AimTarget.Parent and isValidTarget(Cfg.AimTarget) then
        local part=getAimPart(Cfg.AimTarget.Character)
        if part then
            local pos=Camera:WorldToScreenPoint(part.Position)
            if pos.Z>0 then
                local delta=(Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y))*Cfg.AimSens
                sc(function() mousemoverel(delta.X,delta.Y) end)
            end
        end
    else
        local t=getClosestFOV(); if t then Cfg.AimTarget=t end
    end
end)

-- ========================
-- RAYFIELD UI
-- ========================
local Rayfield=loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window=Rayfield:CreateWindow({
    Name="LSX V1",
    LoadingTitle="LSX V1",
    LoadingSubtitle="by Laysox",
    Theme="Default",
    DisableRayfieldPrompts=true,
    DisableBuildWarnings=true,
    ConfigurationSaving={Enabled=false},
    KeySystem=false,
})

local CombatTab =Window:CreateTab("Combat",  4483362458)
local VisualsTab=Window:CreateTab("Visuals", 4483362458)
local MiscTab   =Window:CreateTab("Misc",    4483362458)
local SettTab   =Window:CreateTab("Settings",4483362458)

-- COMBAT
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({Name="Activer Aimbot",CurrentValue=false,Flag="AT",Callback=function(v) Cfg.Aim=v end})
CombatTab:CreateToggle({Name="Wall Check",CurrentValue=true,Flag="WC",Callback=function(v) Cfg.WallCheck=v end})
CombatTab:CreateToggle({Name="Afficher FOV",CurrentValue=true,Flag="SF",Callback=function(v) Cfg.ShowFOV=v end})
CombatTab:CreateSlider({Name="FOV",Range={10,600},Increment=1,Suffix=" px",CurrentValue=150,Flag="AF",Callback=function(v) Cfg.AimFOV=v end})
CombatTab:CreateSlider({Name="Sensibilité",Range={1,100},Increment=1,CurrentValue=30,Flag="AS",Callback=function(v) Cfg.AimSens=v/100 end})
CombatTab:CreateDropdown({Name="Partie visée",Flag="AP",MultipleOptions=false,Options={"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"},CurrentOption={"Head"},Callback=function(o) Cfg.AimPart=o[1] end})
CombatTab:CreateDropdown({Name="Touche Aimbot",Flag="AK",MultipleOptions=false,Options={"Q","E","R","T","F","G","H","J","K","L","Z","X","C","V","B","N","M","F1","F2","F3","F4","F5","F6"},CurrentOption={"Q"},Callback=function(o) AimKey=o[1] end})

CombatTab:CreateSection("Silent Aim")
CombatTab:CreateToggle({Name="Activer Silent Aim",CurrentValue=false,Flag="SAT",Callback=function(v) Cfg.SA=v end})
CombatTab:CreateSlider({Name="FOV Silent Aim",Range={10,600},Increment=1,Suffix=" px",CurrentValue=200,Flag="SAF",Callback=function(v) Cfg.SAFOV=v end})
CombatTab:CreateSlider({Name="Intensité (%)",Range={0,100},Increment=1,Suffix="%",CurrentValue=100,Flag="SAI",Callback=function(v) Cfg.SAIntensity=v end})
CombatTab:CreateDropdown({Name="Partie visée SA",Flag="SAP",MultipleOptions=false,Options={"Head","UpperTorso","LeftUpperLeg","RightUpperLeg"},CurrentOption={"Head"},Callback=function(o) Cfg.SAPart=o[1] end})
CombatTab:CreateDropdown({Name="Touche Silent Aim",Flag="SAK",MultipleOptions=false,Options={"F","Q","E","R","T","G","H","J","K","L","Z","X","C","V","B","N","M","F1","F2","F3","F4","F5","F6"},CurrentOption={"F"},Callback=function(o) SAKey=o[1] end})

-- VISUALS
VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({Name="Activer ESP",CurrentValue=false,Flag="ET",Callback=function(v) Cfg.ESP=v end})
VisualsTab:CreateToggle({Name="Noms",CurrentValue=true,Flag="EN",Callback=function(v) Cfg.ESPNames=v end})
VisualsTab:CreateToggle({Name="HP",CurrentValue=true,Flag="EH",Callback=function(v) Cfg.ESPHP=v end})
VisualsTab:CreateSlider({Name="Transparence",Range={0,100},Increment=5,CurrentValue=30,Flag="ETr",Callback=function(v) Cfg.ESPTrans=v/100 end})
VisualsTab:CreateColorPicker({Name="Couleur ESP",Color=Color3.fromRGB(0,150,255),Flag="EC",Callback=function(c) Cfg.ESPColor=c end})

VisualsTab:CreateSection("Fly")
VisualsTab:CreateToggle({Name="Activer Fly",CurrentValue=false,Flag="FT",Callback=function(v) if v then startFly() else stopFly() end end})
VisualsTab:CreateSlider({Name="Vitesse Fly",Range={10,2000},Increment=10,Suffix=" studs/s",CurrentValue=100,Flag="FS",Callback=function(v) Cfg.FlySpd=v end})
VisualsTab:CreateDropdown({Name="Touche Fly",Flag="FK",MultipleOptions=false,Options={"G","Q","E","R","T","F","H","J","K","L","Z","X","C","V","B","N","M","F1","F2","F3","F4","F5","F6"},CurrentOption={"G"},Callback=function(o) FlyKey=o[1] end})

VisualsTab:CreateSection("Spin")
VisualsTab:CreateToggle({Name="Activer Spin",CurrentValue=false,Flag="ST",Callback=function(v) if v then startSpin() else stopSpin() end end})
VisualsTab:CreateSlider({Name="Vitesse",Range={1,100},Increment=1,CurrentValue=10,Flag="SS",Callback=function(v) Cfg.SpinSpd=v end})
VisualsTab:CreateDropdown({Name="Direction",Flag="SD",MultipleOptions=false,Options={"Clockwise","Counterclockwise"},CurrentOption={"Clockwise"},Callback=function(o) Cfg.SpinDir=o[1]=="Clockwise" and 1 or -1 end})
VisualsTab:CreateDropdown({Name="Axe",Flag="SA2",MultipleOptions=false,Options={"Y","X","Z"},CurrentOption={"Y"},Callback=function(o) Cfg.SpinAxis=o[1] end})

-- MISC
MiscTab:CreateSection("Mouvement")
MiscTab:CreateToggle({Name="Noclip",CurrentValue=false,Flag="NC",Callback=function(v) Cfg.Noclip=v end})
MiscTab:CreateToggle({Name="Infinite Jump",CurrentValue=false,Flag="IJ",Callback=function(v) Cfg.IJ=v; if v then startIJ() else stopIJ() end end})
MiscTab:CreateToggle({Name="Invisible",CurrentValue=false,Flag="IV",Callback=function(v) setInvis(v) end})
MiscTab:CreateToggle({Name="Auto Respawn",CurrentValue=false,Flag="AR",Callback=function(v) Cfg.AutoRespawn=v end})

MiscTab:CreateSection("Character")
MiscTab:CreateToggle({Name="WalkSpeed",CurrentValue=false,Flag="WS",Callback=function(v) Cfg.WS=v; if v then startWS() else stopWS() end end})
MiscTab:CreateSlider({Name="Set WalkSpeed",Range={16,500},Increment=1,Suffix=" studs",CurrentValue=25,Flag="WSV",Callback=function(v) Cfg.WSVal=v end})
MiscTab:CreateToggle({Name="JumpPower",CurrentValue=false,Flag="JP",Callback=function(v) Cfg.JP=v; if v then startJP() else stopJP() end end})
MiscTab:CreateSlider({Name="Set JumpPower",Range={20,500},Increment=1,Suffix=" studs",CurrentValue=20,Flag="JPV",Callback=function(v) Cfg.JPVal=v end})

MiscTab:CreateSection("World")
MiscTab:CreateToggle({Name="Supprimer Fumigènes",CurrentValue=false,Flag="SM",Callback=function(v) Cfg.Smoke=v end})

-- SETTINGS
SettTab:CreateSection("Actions")
SettTab:CreateButton({Name="FERMER LSX V1",Callback=function()
    Cfg.Aim=false; Cfg.SA=false; Cfg.ESP=false; Cfg.Noclip=false
    Cfg.WS=false; Cfg.JP=false; Cfg.IJ=false; Cfg.Fly=false; Cfg.Smoke=false
    sc(function() stopFly() end); sc(function() stopWS() end)
    sc(function() stopJP() end); sc(function() stopIJ() end)
    sc(function() stopSpin() end); sc(function() clearESP() end)
    local h=lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed=25.2; h.JumpPower=20 end
    UIS.MouseBehavior=Enum.MouseBehavior.Default
    Rayfield:Destroy()
end})
SettTab:CreateButton({Name="RAGE QUIT",Callback=function()
    lp:Kick(".")
end})
