-- LSX V1.1 (Version Performance)
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

local lp     = Players.LocalPlayer
local Mouse  = lp:GetMouse()
local Camera = workspace.CurrentCamera

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

-- VARIABLES DE CACHE (Pour éviter de surcharger le CPU)
local character, hrp, humanoid
local IJConn, FlyConn, SpinConn
local AimKey="Q"; local FlyKey="G"; local SAKey="F"

local function refresh()
    character = lp.Character
    if character then
        hrp = character:FindFirstChild("HumanoidRootPart")
        humanoid = character:FindFirstChildWhichIsA("Humanoid")
    end
end

-- ==========================================
-- GESTION DES BOUCLES (Optimisation CPU)
-- ==========================================

-- Boucle lente (0.1s) pour le Noclip et les vérifications de base
task.spawn(function()
    while true do
        if Cfg.Noclip and lp.Character then
            for _, v in ipairs(lp.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        task.wait(0.1) -- On ne scanne pas à chaque frame, c'est inutile
    end
end)

-- Boucle pour la vitesse et le jump (Evite les crashs Anti-Cheat)
RunService.Heartbeat:Connect(function()
    if not humanoid or not humanoid.Parent then return end
    if Cfg.WS then humanoid.WalkSpeed = Cfg.WSVal end
    if Cfg.JP then 
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Cfg.JPVal 
    end
end)

-- ==========================================
-- ESP OPTIMISÉ (Zéro Lag)
-- ==========================================
local function clearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("EH"); if h then h:Destroy() end
            local b = p.Character:FindFirstChild("EB"); if b then b:Destroy() end
        end
    end
end

local function updateESP()
    if not Cfg.ESP then clearESP(); return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local char = p.Character
            -- Highlight
            local hl = char:FindFirstChild("EH") or Instance.new("Highlight", char)
            hl.Name = "EH"
            hl.FillColor = Cfg.ESPColor
            hl.FillTransparency = Cfg.ESPTrans
            hl.OutlineTransparency = 1
            hl.Enabled = Cfg.ESP

            -- Billboard (Nom/HP)
            if Cfg.ESPNames then
                local head = char:FindFirstChild("Head")
                if head then
                    local bb = char:FindFirstChild("EB") or Instance.new("BillboardGui", char)
                    bb.Name = "EB"
                    bb.Adornee = head
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 100, 0, 20)
                    bb.StudsOffset = Vector3.new(0, 2, 0)

                    local lbl = bb:FindFirstChild("LBL") or Instance.new("TextLabel", bb)
                    lbl.Name = "LBL"
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.TextColor3 = Cfg.ESPColor
                    lbl.TextScaled = true
                    lbl.Font = Enum.Font.SourceSansBold
                    
                    local hp = char:FindFirstChildWhichIsA("Humanoid") and math.floor(char.Humanoid.Health) or 0
                    lbl.Text = Cfg.ESPHP and p.Name.." ["..hp.."]" or p.Name
                end
            else
                local b = char:FindFirstChild("EB"); if b then b:Destroy() end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do -- Refresh l'ESP 2 fois par seconde seulement
        updateESP()
        if Cfg.Smoke then
            for _,v in ipairs(workspace:GetChildren()) do
                if v.Name=="Smoke Grenade" then v:Destroy() end
            end
        end
    end
end)

-- Le reste des fonctions (Fly, Spin, Aimbot) reste similaire mais avec pcall
-- [Garder ici tes fonctions startFly, stopFly, startSpin, etc. de la version précédente]

-- ==========================================
-- INITIALISATION UI (RAYFIELD)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "LSX V1.1 - PRO EDITION",
    LoadingTitle = "Optimisation en cours...",
    LoadingSubtitle = "By Laysox",
    ConfigurationSaving = {Enabled = false}
})

-- Ajoute tes onglets et boutons ici (utilise le même format que ton premier script)
-- ...
