-- Laysox UI
-- Compatible Madium

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
repeat task.wait() until player.Character
local character = player.Character
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- VARIABLES
local spinSpeed = 10
local spinDirection = 1
local spinAxis = "Y"
local flySpeed = 50

local spinning, spinConnection = false, nil
local flying, flyConnection = false, nil
local flyBV, flyBG = nil, nil
local sticking, stickConnection = false, nil
local stickTarget = ""
local noclip, noclipConnection = false, nil
local invisible = false
local originalTransparency = {}
local aimlock, aimlockConnection = false, nil
local aimlockToggleConn = nil
local aimlockTarget = nil
local aimlockKey = Enum.KeyCode.Q
local savedPositions = {}
local selectedPlayer = ""

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
    flying = false
    sticking = false
    noclip = false
    invisible = false
    aimlock = false
    aimlockTarget = nil
end)

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
    if flying then return end
    flying = true
    humanoid.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.zero
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Parent = humanoidRootPart

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1e4
    flyBG.Parent = humanoidRootPart

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not humanoidRootPart then return end
        local dir = Vector3.zero
        local cf = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyBG.CFrame = cf
    end)
end

local function stopFly()
    flying = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if humanoid then humanoid.PlatformStand = false end
end

-- TP
local function tpCoords(x, y, z)
    humanoidRootPart.CFrame = CFrame.new(x, y, z)
end

local function tpPlayer(name)
    local t = Players:FindFirstChild(name)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        humanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
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
            humanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(3, 0, 0)
        end
    end)
    return true
end

local function stopStick()
    sticking = false
    if stickConnection then stickConnection:Disconnect(); stickConnection = nil end
end

-- INVISIBLE (tous les joueurs)
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
        if p:IsA("Decal") then
            p.Transparency = state and 1 or 0
        end
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
local function startNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclip or not character then return end
        for _, p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    noclip = false
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    task.wait(0.05)
    if character then
        for _, p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- AIMLOCK
local function getClosest()
    local closest, minD = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local sp, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < minD then minD = d; closest = p end
                end
            end
        end
    end
    return closest
end

local function startAimlock()
    if aimlockConnection then return end
    aimlockConnection = RunService.RenderStepped:Connect(function()
        if not aimlock then return end
        if aimlockTarget then
            if not aimlockTarget.Character or not aimlockTarget.Character:FindFirstChild("Head") then
                aimlockTarget = nil
            end
        end
        if not aimlockTarget then aimlockTarget = getClosest() end
        if aimlockTarget and aimlockTarget.Character then
            local head = aimlockTarget.Character:FindFirstChild("Head")
            if head then
                camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
            end
        end
    end)
end

local function stopAimlock()
    aimlock = false
    aimlockTarget = nil
    if aimlockConnection then aimlockConnection:Disconnect(); aimlockConnection = nil end
end

local function setupAimlockKey()
    if aimlockToggleConn then aimlockToggleConn:Disconnect() end
    aimlockToggleConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == aimlockKey then
            aimlock = not aimlock
            if aimlock then
                aimlockTarget = getClosest()
                Rayfield:Notify({ Title="Aimlock ON", Content=aimlockTarget and "Cible : "..aimlockTarget.Name or "Aucune cible", Duration=2 })
            else
                aimlockTarget = nil
                Rayfield:Notify({ Title="Aimlock OFF", Content="Viseur libre.", Duration=2 })
            end
        end
    end)
end

-- UI
local Window = Rayfield:CreateWindow({
    Name = "Laysox UI",
    LoadingTitle = "Laysox UI",
    LoadingSubtitle = "Chargement...",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- TAB SPIN
local SpinTab = Window:CreateTab("Spin", 4483362458)

SpinTab:CreateSlider({
    Name = "Vitesse", Range = {1, 100}, Increment = 1,
    Suffix = "°/frame", CurrentValue = 10, Flag = "SpinSpeed",
    Callback = function(v) spinSpeed = v end,
})
SpinTab:CreateDropdown({
    Name = "Direction", Options = {"Clockwise","Counterclockwise"},
    CurrentOption = {"Clockwise"}, Flag = "SpinDir", MultipleOptions = false,
    Callback = function(o) spinDirection = o[1] == "Clockwise" and 1 or -1 end,
})
SpinTab:CreateDropdown({
    Name = "Axe", Options = {"Y","X","Z"},
    CurrentOption = {"Y"}, Flag = "SpinAxis", MultipleOptions = false,
    Callback = function(o) spinAxis = o[1] end,
})
SpinTab:CreateToggle({
    Name = "Activer Spin", CurrentValue = false, Flag = "SpinToggle",
    Callback = function(v)
        if v then startSpin(); Rayfield:Notify({ Title="Spin ON", Content="Axe : "..spinAxis, Duration=2 })
        else stopSpin(); Rayfield:Notify({ Title="Spin OFF", Content="Arrêté.", Duration=2 }) end
    end,
})

-- TAB FLY
local FlyTab = Window:CreateTab("Fly", 4483362458)

FlyTab:CreateSlider({
    Name = "Vitesse", Range = {10,300}, Increment = 5,
    Suffix = " studs/s", CurrentValue = 50, Flag = "FlySpeed",
    Callback = function(v) flySpeed = v end,
})
FlyTab:CreateParagraph({
    Title = "Contrôles",
    Content = "W/A/S/D → Directions\nSpace → Monter\nCtrl → Descendre",
})
FlyTab:CreateToggle({
    Name = "Activer Fly", CurrentValue = false, Flag = "FlyToggle",
    Callback = function(v)
        if v then startFly(); Rayfield:Notify({ Title="Fly ON", Content=flySpeed.." studs/s", Duration=2 })
        else stopFly(); Rayfield:Notify({ Title="Fly OFF", Content="Retour au sol.", Duration=2 }) end
    end,
})

-- TAB TP
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
    tpCoords(cx, cy, cz)
    Rayfield:Notify({ Title="TP !", Content=("X:%d Y:%d Z:%d"):format(cx,cy,cz), Duration=3 })
end })

TPTab:CreateSection("TP vers joueur")
TPTab:CreateDropdown({ Name="Joueur", Options=getPlayers(), CurrentOption={}, Flag="TPPlayer", MultipleOptions=false,
    Callback=function(o) selectedPlayer=o[1] or "" end })
TPTab:CreateButton({ Name="Téléporter", Callback=function()
    if selectedPlayer == "" or selectedPlayer == "Aucun joueur" then
        Rayfield:Notify({ Title="Erreur", Content="Aucun joueur.", Duration=2 }); return
    end
    local ok = tpPlayer(selectedPlayer)
    Rayfield:Notify({ Title=ok and "TP !" or "Échec", Content=ok and "Vers : "..selectedPlayer or "Introuvable.", Duration=3 })
end })

TPTab:CreateSection("Suivre un joueur")
TPTab:CreateDropdown({ Name="Joueur à suivre", Options=getPlayers(), CurrentOption={}, Flag="StickPlayer", MultipleOptions=false,
    Callback=function(o) stickTarget=o[1] or "" end })
TPTab:CreateToggle({ Name="Activer le Suivi", CurrentValue=false, Flag="StickToggle",
    Callback=function(v)
        if v then
            if stickTarget == "" or stickTarget == "Aucun joueur" then
                Rayfield:Notify({ Title="Erreur", Content="Aucun joueur.", Duration=2 }); return
            end
            local ok = startStick(stickTarget)
            Rayfield:Notify({ Title=ok and "Suivi ON" or "Échec", Content=ok and "Collé à : "..stickTarget or "Introuvable.", Duration=3 })
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
        local ok = loadPOS(slot)
        Rayfield:Notify({ Title=ok and "Chargé !" or "Slot vide", Content=slot, Duration=2 }) end })
end

-- TAB DIVERS
local DiversTab = Window:CreateTab("Divers", 4483362458)

DiversTab:CreateSection("Invisibilité")
DiversTab:CreateToggle({ Name="Invisible", CurrentValue=false, Flag="InvisToggle",
    Callback=function(v)
        setInvis(v)
        Rayfield:Notify({ Title=v and "Invisible !" or "Visible", Content=v and "Personne ne te voit." or "Tu es visible.", Duration=3 })
    end,
})

DiversTab:CreateSection("No-Clip")
DiversTab:CreateToggle({ Name="No-Clip", CurrentValue=false, Flag="NoclipToggle",
    Callback=function(v)
        noclip = v
        if v then startNoclip(); Rayfield:Notify({ Title="No-Clip ON", Content="Tu traverses les murs.", Duration=3 })
        else stopNoclip(); Rayfield:Notify({ Title="No-Clip OFF", Content="Collisions restaurées.", Duration=2 }) end
    end,
})

-- TAB COMBAT
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Aimlock")
CombatTab:CreateKeybind({
    Name = "Touche Aimlock",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Flag = "AimlockKey",
    Callback = function(key)
        aimlockKey = Enum.KeyCode[key] or Enum.KeyCode.Q
        setupAimlockKey()
        Rayfield:Notify({ Title="Touche maj", Content="Aimlock → "..key, Duration=2 })
    end,
})
CombatTab:CreateToggle({
    Name = "Activer Aimlock", CurrentValue=false, Flag="AimlockToggle",
    Callback=function(v)
        if v then
            startAimlock()
            setupAimlockKey()
            Rayfield:Notify({ Title="Aimlock ON", Content="Touche : "..aimlockKey.Name, Duration=3 })
        else
            stopAimlock()
            Rayfield:Notify({ Title="Aimlock OFF", Content="Viseur libre.", Duration=2 })
        end
    end,
})
CombatTab:CreateParagraph({
    Title = "Info",
    Content = "Se verrouille sur le joueur le plus proche du centre de l'écran.\nAppuie sur ta touche pour toggle rapidement en jeu.",
})
