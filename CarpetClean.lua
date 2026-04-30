-- CarpetClean Script | Laysox
-- Interface: Linoria Rewrite

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function sc(f,...) pcall(f,...) end

local Cfg = {
    AutoJob      = false,
    AutoJobXP    = 9999999,
    AutoJobDelay = 1,
    WS           = false,
    WSVal        = 25,
    Fly          = false,
    FlySpd       = 100,
    Noclip       = false,
    IJ           = false,
}

local HMC          = {}
local IJConn       = nil
local FlyConn      = nil
local autoJobThread= nil
local FlyKey       = "G"

local character = lp.Character or lp.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart", 10)

local function refresh()
    character = lp.Character; if not character then return end
    hrp = character:FindFirstChild("HumanoidRootPart")
end
lp.CharacterAdded:Connect(function() task.wait(1); refresh() end)

-- AUTO JOB
local function fireJob()
    sc(function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("RequestJobComplete")
            :FireServer(1, Cfg.AutoJobXP)
    end)
end
local function startAutoJob()
    if autoJobThread then return end
    Cfg.AutoJob = true
    autoJobThread = task.spawn(function()
        while Cfg.AutoJob do fireJob(); task.wait(Cfg.AutoJobDelay) end
        autoJobThread = nil
    end)
end
local function stopAutoJob()
    Cfg.AutoJob = false; autoJobThread = nil
end

-- WALKSPEED
local function startWS()
    local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.WalkSpeed = Cfg.WSVal end; apply()
    if HMC.ws then HMC.ws:Disconnect() end
    HMC.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
end
local function stopWS()
    if HMC.ws then HMC.ws:Disconnect(); HMC.ws = nil end
    local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 16 end
end

-- FLY
local function startFly()
    if Cfg.Fly then return end
    Cfg.Fly = true
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then Cfg.Fly = false; return end
    sc(function()
        if h:FindFirstChild("FG") then h.FG:Destroy() end
        if h:FindFirstChild("FV") then h.FV:Destroy() end
    end)
    local gyro = Instance.new("BodyGyro"); gyro.Name="FG"
    gyro.MaxTorque = Vector3.new(1,1,1)*math.huge; gyro.P=100000
    gyro.CFrame = h.CFrame; gyro.Parent = h
    local vel = Instance.new("BodyVelocity"); vel.Name="FV"
    vel.MaxForce = Vector3.new(1,1,1)*math.huge; vel.P=10000
    vel.Velocity = Vector3.zero; vel.Parent = h
    if FlyConn then FlyConn:Disconnect() end
    FlyConn = RunService.RenderStepped:Connect(function()
        if not Cfg.Fly or not h or not h.Parent then
            if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
            sc(function() gyro:Destroy() end); sc(function() vel:Destroy() end)
            return
        end
        local mv = Vector3.zero; local cf = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
        vel.Velocity = mv.Magnitude > 0 and mv.Unit * Cfg.FlySpd or Vector3.zero
        gyro.CFrame = cf
    end)
end
local function stopFly()
    Cfg.Fly = false
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h then
        sc(function()
            if h:FindFirstChild("FG") then h.FG:Destroy() end
            if h:FindFirstChild("FV") then h.FV:Destroy() end
        end)
    end
end

-- NOCLIP
task.spawn(function()
    while task.wait(0.25) do
        if not Cfg.Noclip then continue end
        local c = lp.Character; if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

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

-- FLY KEY
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode.Name == FlyKey then
        if Cfg.Fly then stopFly() else startFly() end
    end
end)

-- ========================
-- LINORIA REWRITE
-- ========================
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title    = 'CarpetClean | Laysox',
    Center   = true,
    AutoShow = true,
})

local Tabs = {
    Farm     = Window:AddTab('Auto Farm'),
    Player   = Window:AddTab('Player'),
    Settings = Window:AddTab('UI Settings'),
}

-- AUTO FARM TAB
local FarmBox = Tabs.Farm:AddLeftGroupbox('Auto Job')

FarmBox:AddToggle('AutoJobToggle', {
    Text     = 'Auto Job',
    Default  = false,
    Tooltip  = 'Complete les jobs automatiquement',
    Callback = function(v)
        if v then startAutoJob(); Library:Notify('Auto Job ON - '..Cfg.AutoJobXP..' XP/job', 3)
        else stopAutoJob(); Library:Notify('Auto Job OFF', 2) end
    end
})

FarmBox:AddSlider('AutoJobXP', {
    Text     = 'XP par job',
    Default  = 9999999,
    Min      = 1000,
    Max      = 99999999,
    Rounding = 0,
    Callback = function(v) Cfg.AutoJobXP = v end
})

FarmBox:AddSlider('AutoJobDelay', {
    Text     = 'Delai entre jobs (sec)',
    Default  = 1,
    Min      = 0,
    Max      = 10,
    Rounding = 0,
    Callback = function(v) Cfg.AutoJobDelay = math.max(v, 0) end
})

FarmBox:AddButton({
    Text = 'Completer 1 job maintenant',
    Func = function()
        fireJob()
        Library:Notify('Job complete! +'..Cfg.AutoJobXP..' XP', 2)
    end
})

local FarmInfo = Tabs.Farm:AddRightGroupbox('Info')
FarmInfo:AddLabel('Active Auto Job pour farmer')
FarmInfo:AddLabel("l'XP automatiquement.")
FarmInfo:AddLabel('Delai a 0 = max speed.')

-- PLAYER TAB
local FlyBox = Tabs.Player:AddLeftGroupbox('Fly')

FlyBox:AddToggle('FlyToggle', {
    Text     = 'Activer Fly',
    Default  = false,
    Callback = function(v)
        if v then startFly(); Library:Notify('Fly ON - '..Cfg.FlySpd..' studs/s', 2)
        else stopFly(); Library:Notify('Fly OFF', 2) end
    end
})
FlyBox:AddSlider('FlySpd', {
    Text = 'Vitesse Fly', Default = 100, Min = 10, Max = 2000, Rounding = 0,
    Callback = function(v) Cfg.FlySpd = v end
})
FlyBox:AddDropdown('FlyKeyDD', {
    Text     = 'Touche Fly',
    Default  = 'G',
    Values   = {'G','Q','E','R','T','F','H','J','K','L','Z','X','C','V','B','N','M','F1','F2','F3','F4','F5','F6'},
    Multi    = false,
    Callback = function(v) FlyKey = v; Library:Notify('Touche Fly -> '..v, 2) end
})
FlyBox:AddLabel('W/A/S/D → Directions')
FlyBox:AddLabel('Space → Monter | Ctrl → Descendre')

local MoveBox = Tabs.Player:AddRightGroupbox('Mouvement')
MoveBox:AddToggle('WSToggle', {
    Text     = 'WalkSpeed',
    Default  = false,
    Callback = function(v)
        Cfg.WS = v
        if v then startWS(); Library:Notify('Speed ON - '..Cfg.WSVal..' studs', 2)
        else stopWS(); Library:Notify('Speed OFF', 2) end
    end
})
MoveBox:AddSlider('WSVal', {
    Text = 'WalkSpeed', Default = 25, Min = 16, Max = 500, Rounding = 0,
    Callback = function(v) Cfg.WSVal = v end
})
MoveBox:AddToggle('IJToggle', {
    Text     = 'Infinite Jump',
    Default  = false,
    Callback = function(v)
        Cfg.IJ = v
        if v then startIJ(); Library:Notify('Infinite Jump ON', 2)
        else stopIJ(); Library:Notify('Infinite Jump OFF', 2) end
    end
})
MoveBox:AddToggle('NoclipToggle', {
    Text     = 'Noclip',
    Default  = false,
    Callback = function(v)
        Cfg.Noclip = v
        Library:Notify(v and 'Noclip ON' or 'Noclip OFF', 2)
    end
})

-- SETTINGS TAB
local MenuBox = Tabs.Settings:AddLeftGroupbox('Menu')
MenuBox:AddButton({
    Text = 'Discord LSX',
    Func = function()
        sc(function() setclipboard('https://discord.gg/94CnwG3ySJ') end)
        Library:Notify('Lien Discord copie!', 3)
    end
})
MenuBox:AddButton({
    Text = 'Fermer le script',
    Func = function()
        stopAutoJob(); sc(function() stopFly() end)
        sc(function() stopWS() end); sc(function() stopIJ() end)
        local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
        if h then h.WalkSpeed = 16 end
        Library:Unload()
    end
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder('LaysoxScripts/CarpetClean')
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Library:Notify('CarpetClean charge! Active Auto Job.', 4)
