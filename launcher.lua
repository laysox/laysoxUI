-- Laysox Launcher
task.wait(2)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
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

-- VARIABLES UNIVERSEL
local flySpeed = 100
local flyActive = false
local flyKeyName = "G"
local noclip = false
local noclippedParts = {}
local wsActive = false
local wsValue = 50
local ijActive = false
local ijConnection = nil
local HumanModCons = {}

local function refresh()
    character = player.Character
    if not character then return end
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    refresh()
    flyActive = false
    noclip = false
    wsActive = false
end)

-- FLY
local function startFly()
    if flyActive then return end
    flyActive = true
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
        if not flyActive or not hrp or not hrp.Parent then
            if conn then conn:Disconnect() end
            pcall(function() gyro:Destroy() end)
            pcall(function() vel:Destroy() end)
            return
        end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        vel.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
        gyro.CFrame = Camera.CFrame
    end)
end

local function stopFly()
    flyActive = false
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
                    if noclip then
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
local function startWS()
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() h.WalkSpeed = wsValue end
    apply()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    HumanModCons.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
end

local function stopWS()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    local h = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 16 end
end

-- INFINITE JUMP
local function startIJ()
    if ijConnection then return end
    ijConnection = UserInputService.JumpRequest:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopIJ()
    if ijConnection then ijConnection:Disconnect(); ijConnection = nil end
end

-- KEYBIND FLY GLOBAL
local allKeys = {
    "Q","E","R","T","F","G","H","J","K","L","Z","X","C","V","B","N","M",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero",
    "LeftAlt","RightAlt","LeftShift","RightShift","Tab","CapsLock"
}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode.Name == flyKeyName then
        if flyActive then
            stopFly()
            Rayfield:Notify({ Title="Fly OFF", Content="Retour au sol.", Duration=2 })
        else
            startFly()
            Rayfield:Notify({ Title="Fly ON", Content=flySpeed.." studs/s", Duration=2 })
        end
    end
end)

-- ========================
-- UI
-- ========================
local Window = Rayfield:CreateWindow({
    Name = "Laysox Launcher",
    LoadingTitle = "Laysox Launcher",
    LoadingSubtitle = "Chargement...",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ========================
-- TAB UNIVERSEL (en premier)
-- ========================
local UniTab = Window:CreateTab("Universel", 4483362458)

UniTab:CreateSection("Fly")
UniTab:CreateSlider({
    Name = "Vitesse Fly", Range = {10,2000}, Increment = 10,
    Suffix = " studs/s", CurrentValue = 100, Flag = "UniFlySpeed",
    Callback = function(v) flySpeed = v end,
})
local FlyToggleUI = UniTab:CreateToggle({
    Name = "Activer Fly", CurrentValue = false, Flag = "UniFlyToggle",
    Callback = function(v)
        if v then startFly(); Rayfield:Notify({ Title="Fly ON", Content=flySpeed.." studs/s", Duration=2 })
        else stopFly(); Rayfield:Notify({ Title="Fly OFF", Content="Retour au sol.", Duration=2 }) end
    end,
})
UniTab:CreateDropdown({
    Name = "Touche Fly", Options = allKeys,
    CurrentOption = {"G"}, Flag = "UniFlyKey", MultipleOptions = false,
    Callback = function(o)
        flyKeyName = o[1]
        Rayfield:Notify({ Title="Touche Fly", Content="Fly → "..o[1], Duration=2 })
    end,
})
UniTab:CreateParagraph({
    Title = "Contrôles Fly",
    Content = "W/A/S/D → Directions\nSpace → Monter\nCtrl → Descendre\nTouche configurée → Toggle",
})

UniTab:CreateSection("Noclip")
local NoclipToggleUI = UniTab:CreateToggle({
    Name = "Noclip (traverser les murs)", CurrentValue = false, Flag = "UniNoclip",
    Callback = function(v)
        noclip = v
        Rayfield:Notify({ Title=v and "Noclip ON" or "Noclip OFF",
            Content=v and "Tu traverses les murs." or "Collisions restaurées.", Duration=2 })
    end,
})

UniTab:CreateSection("Vitesse")
UniTab:CreateSlider({
    Name = "WalkSpeed", Range = {16,500}, Increment = 1,
    Suffix = " studs", CurrentValue = 50, Flag = "UniWalkSpeed",
    Callback = function(v) wsValue = v; if wsActive then startWS() end end,
})
local WSToggleUI = UniTab:CreateToggle({
    Name = "Activer WalkSpeed", CurrentValue = false, Flag = "UniWSToggle",
    Callback = function(v)
        wsActive = v
        if v then startWS(); Rayfield:Notify({ Title="Speed ON", Content=wsValue.." studs", Duration=2 })
        else stopWS(); Rayfield:Notify({ Title="Speed OFF", Content="Vitesse normale.", Duration=2 }) end
    end,
})

UniTab:CreateSection("Saut")
UniTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "UniIJ",
    Callback = function(v)
        ijActive = v
        if v then startIJ(); Rayfield:Notify({ Title="Infinite Jump ON", Content="Saute sans limite !", Duration=2 })
        else stopIJ(); Rayfield:Notify({ Title="Infinite Jump OFF", Content="Saut normal.", Duration=2 }) end
    end,
})

UniTab:CreateSection("Téléport rapide")
local qx, qy, qz = 0, 0, 0
UniTab:CreateInput({ Name="X", PlaceholderText="100", RemoveTextAfterFocusLost=false, Flag="UniX",
    Callback=function(v) qx=tonumber(v) or qx end })
UniTab:CreateInput({ Name="Y", PlaceholderText="50", RemoveTextAfterFocusLost=false, Flag="UniY",
    Callback=function(v) qy=tonumber(v) or qy end })
UniTab:CreateInput({ Name="Z", PlaceholderText="200", RemoveTextAfterFocusLost=false, Flag="UniZ",
    Callback=function(v) qz=tonumber(v) or qz end })
UniTab:CreateButton({ Name="Téléporter", Callback=function()
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(qx, qy, qz)
        Rayfield:Notify({ Title="TP !", Content=("X:%d Y:%d Z:%d"):format(qx,qy,qz), Duration=2 })
    end
end })

-- ========================
-- TAB JEUX
-- ========================
local GamesTab = Window:CreateTab("Jeux", 4483362458)

local games = {
    {
        name = "Rivals",
        placeId = 17625359962,
        script = "https://raw.githubusercontent.com/laysox/laysoxUI/main/script.lua",
        icon = "⚔️",
        description = "Aimbot, ESP, Fly, TP, Spin..."
    },
    -- Ajoute tes futurs jeux ici
    -- {
    --     name = "Brookhaven",
    --     placeId = 4924922222,
    --     script = "https://raw.githubusercontent.com/laysox/laysoxUI/main/brookhaven.lua",
    --     icon = "🏠",
    --     description = "Script Brookhaven"
    -- },
}

GamesTab:CreateParagraph({
    Title = "Laysox Launcher — Jeux",
    Content = "Clique sur un jeu pour charger son script.\nTu dois être dans le bon jeu.",
})

GamesTab:CreateSection("Scripts disponibles")

local currentPlaceId = game.PlaceId

for _, gameInfo in pairs(games) do
    local isCurrentGame = currentPlaceId == gameInfo.placeId
    local status = isCurrentGame and " ✅" or " ❌"

    GamesTab:CreateButton({
        Name = gameInfo.icon.." "..gameInfo.name..status,
        Callback = function()
            if not isCurrentGame then
                Rayfield:Notify({
                    Title = "Mauvais jeu !",
                    Content = "Tu dois être dans "..gameInfo.name.." pour ce script.",
                    Duration = 4,
                })
                return
            end
            Rayfield:Notify({
                Title = "Chargement...",
                Content = "Script "..gameInfo.name.." en cours...",
                Duration = 3,
            })
            task.wait(1)
            Rayfield:Destroy()
            task.wait(0.5)
            loadstring(game:HttpGet(gameInfo.script))()
        end,
    })

    GamesTab:CreateParagraph({
        Title = gameInfo.icon.." "..gameInfo.name,
        Content = gameInfo.description.."\nPlace ID : "..gameInfo.placeId,
    })
end

GamesTab:CreateSection("Jeu actuel")
GamesTab:CreateParagraph({
    Title = "Place ID",
    Content = "Tu es sur le jeu ID : "..tostring(currentPlaceId),
})

-- ========================
-- TAB INFOS
-- ========================
local InfoTab = Window:CreateTab("Infos", 4483362458)
InfoTab:CreateParagraph({
    Title = "Comment utiliser le Launcher",
    Content = "1. L'onglet Universel fonctionne dans TOUS les jeux\n2. Va dans l'onglet Jeux pour charger un script spécifique\n3. Clique sur le jeu dans lequel tu es (✅)\n4. Le script se charge et remplace le launcher",
})
InfoTab:CreateParagraph({
    Title = "Scripts dispo",
    Content = "⚔️ Rivals — Aimbot, ESP, Fly, TP, Spin, Noclip...",
})
InfoTab:CreateParagraph({
    Title = "Universel — Fonctions",
    Content = "✅ Fly (touche configurable)\n✅ Noclip\n✅ WalkSpeed\n✅ Infinite Jump\n✅ Téléport rapide",
})
