-- CarpetClean Script | Laysox
-- Carpet Cleaning Simulator

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

local lp     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function sc(f,...) pcall(f,...) end

-- ========================
-- CONFIG
-- ========================
local Cfg = {
    AutoJob     = false,
    AutoJobXP   = 9999999,
    AutoJobLoop = true,
    AutoJobDelay= 1,
    WS          = false,
    WSVal       = 25,
    Fly         = false,
    FlySpd      = 100,
    Noclip      = false,
    IJ          = false,
}

local HMC      = {}
local noclipP  = {}
local IJConn   = nil
local FlyConn  = nil
local autoJobThread = nil
local FlyKey   = "G"

-- ========================
-- WAIT PERSO
-- ========================
local character = lp.Character or lp.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart", 10)
local humanoid  = character:WaitForChild("Humanoid", 10)

local function refresh()
    character = lp.Character; if not character then return end
    hrp      = character:FindFirstChild("HumanoidRootPart")
    humanoid = character:FindFirstChildWhichIsA("Humanoid")
end

lp.CharacterAdded:Connect(function()
    task.wait(1); refresh()
end)

-- ========================
-- AUTO JOB (coeur du script)
-- ========================
local function fireJob()
    sc(function()
        local args = {1, Cfg.AutoJobXP}
        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("RequestJobComplete")
            :FireServer(unpack(args))
    end)
end

local function startAutoJob()
    if autoJobThread then return end
    Cfg.AutoJob = true
    autoJobThread = task.spawn(function()
        while Cfg.AutoJob do
            fireJob()
            task.wait(Cfg.AutoJobDelay)
        end
        autoJobThread = nil
    end)
end

local function stopAutoJob()
    Cfg.AutoJob = false
    autoJobThread = nil
end

-- ========================
-- WALKSPEED
-- ========================
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

-- ========================
-- FLY
-- ========================
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
-- RAYFIELD
-- ========================
local Rayfield
sc(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not Rayfield then
    task.wait(2)
    sc(function()
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
end
if not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "CarpetClean | Laysox",
    LoadingTitle = "CarpetClean Script",
    LoadingSubtitle = "by Laysox",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

-- ========================
-- TAB AUTO FARM
-- ========================
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateSection("Auto Job")

FarmTab:CreateToggle({
    Name = "Auto Job (Complete jobs auto)",
    CurrentValue = false,
    Flag = "AutoJobToggle",
    Callback = function(v)
        if v then
            startAutoJob()
            Rayfield:Notify({
                Title = "Auto Job ON",
                Content = "Jobs completes automatiquement!\nXP par job : "..Cfg.AutoJobXP,
                Duration = 3,
            })
        else
            stopAutoJob()
            Rayfield:Notify({Title="Auto Job OFF", Content="Arrete.", Duration=2})
        end
    end,
})

FarmTab:CreateSlider({
    Name = "XP par job",
    Range = {1000, 99999999},
    Increment = 100000,
    Suffix = " XP",
    CurrentValue = 9999999,
    Flag = "AutoJobXP",
    Callback = function(v)
        Cfg.AutoJobXP = v
        Rayfield:Notify({Title="XP mis a jour", Content=v.." XP par job", Duration=2})
    end,
})

FarmTab:CreateSlider({
    Name = "Delai entre les jobs",
    Range = {0, 10},
    Increment = 1,
    Suffix = " sec",
    CurrentValue = 1,
    Flag = "AutoJobDelay",
    Callback = function(v)
        Cfg.AutoJobDelay = math.max(v, 0)
    end,
})

FarmTab:CreateButton({
    Name = "Completer 1 job maintenant",
    Callback = function()
        fireJob()
        Rayfield:Notify({Title="Job complete!", Content="+"..Cfg.AutoJobXP.." XP", Duration=2})
    end,
})

FarmTab:CreateParagraph({
    Title = "Comment ca marche",
    Content = "Active Auto Job pour completer les jobs automatiquement.\nChaque job te donne l'XP configure.\nMets le delai a 0 pour etre le plus rapide possible.\nLe '1' dans les args est la perfection (ne pas changer).",
})

-- ========================
-- TAB PLAYER
-- ========================
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Mouvement")

local FlyToggleUI = PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(v)
        if v then startFly(); Rayfield:Notify({Title="Fly ON", Content=Cfg.FlySpd.." studs/s", Duration=2})
        else stopFly(); Rayfield:Notify({Title="Fly OFF", Content="Retour au sol.", Duration=2}) end
    end,
})

PlayerTab:CreateSlider({
    Name = "Vitesse Fly",
    Range = {10, 2000},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = 100,
    Flag = "FlySpd",
    Callback = function(v) Cfg.FlySpd = v end,
})

PlayerTab:CreateDropdown({
    Name = "Touche Fly",
    Options = {"G","Q","E","R","T","F","H","J","K","L","Z","X","C","V","B","N","M","F1","F2","F3","F4","F5","F6"},
    CurrentOption = {"G"},
    Flag = "FlyKeyDD",
    MultipleOptions = false,
    Callback = function(o)
        FlyKey = o[1]
        Rayfield:Notify({Title="Touche Fly", Content="Fly -> "..o[1], Duration=2})
    end,
})

PlayerTab:CreateParagraph({
    Title = "Controles Fly",
    Content = "W/A/S/D -> Directions\nSpace -> Monter\nCtrl -> Descendre",
})

PlayerTab:CreateSection("Vitesse & Saut")

local WSToggle = PlayerTab:CreateToggle({
    Name = "WalkSpeed",
    CurrentValue = false,
    Flag = "WSToggle",
    Callback = function(v)
        Cfg.WS = v
        if v then startWS(); Rayfield:Notify({Title="Speed ON", Content=Cfg.WSVal.." studs", Duration=2})
        else stopWS(); Rayfield:Notify({Title="Speed OFF", Content="Vitesse normale.", Duration=2}) end
    end,
})

PlayerTab:CreateSlider({
    Name = "Set WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 25,
    Flag = "WSVal",
    Callback = function(v) Cfg.WSVal = v end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "IJToggle",
    Callback = function(v)
        Cfg.IJ = v
        if v then startIJ(); Rayfield:Notify({Title="Infinite Jump ON", Content="Saute sans limite!", Duration=2})
        else stopIJ(); Rayfield:Notify({Title="Infinite Jump OFF", Content="Saut normal.", Duration=2}) end
    end,
})

PlayerTab:CreateSection("Physique")

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(v)
        Cfg.Noclip = v
        Rayfield:Notify({Title=v and "Noclip ON" or "Noclip OFF",
            Content=v and "Tu traverses les murs." or "Collisions restaurees.", Duration=2})
    end,
})

-- ========================
-- TAB SETTINGS
-- ========================
local SettTab = Window:CreateTab("Settings", 4483362458)

SettTab:CreateSection("Actions")
SettTab:CreateButton({
    Name = "FERMER LE SCRIPT",
    Callback = function()
        stopAutoJob()
        Cfg.Fly = false; Cfg.WS = false; Cfg.Noclip = false
        sc(function() stopFly() end); sc(function() stopWS() end); sc(function() stopIJ() end)
        local h = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
        if h then h.WalkSpeed = 16 end
        Rayfield:Destroy()
    end,
})

SettTab:CreateButton({
    Name = "Rejoindre le Discord LSX",
    Callback = function()
        sc(function() setclipboard("https://discord.gg/94CnwG3ySJ") end)
        Rayfield:Notify({Title="Discord", Content="Lien copie!", Duration=3})
    end,
})

Rayfield:Notify({
    Title = "CarpetClean charge!",
    Content = "Active Auto Job pour farmer l'XP automatiquement.",
    Duration = 4,
})
