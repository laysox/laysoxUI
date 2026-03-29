--// Laysox UI - Script complet corrigé
--// LocalScript dans StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--========================
-- CONFIG
--========================
local spinSpeed = 10
local defaultDirection = 1
local defaultAxis = "Y"
local flySpeed = 50

local spinning, spinConnection = false, nil
local spinDirection = defaultDirection
local spinAxis = defaultAxis

local flying, flyConnection = false, nil
local flyBodyVelocity, flyBodyGyro = nil, nil

local sticking, stickConnection = false, nil
local selectedStickPlayer = ""

local invisible = false
local noclip, noclipConnection = false, nil

local aimlock = false
local aimlockTarget = nil
local aimlockKey = Enum.KeyCode.Q
local aimlockConnection = nil
local aimlockToggleConnection = nil

local savedPositions = {}

--========================
-- UPDATE PERSO
--========================
local function updateCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	updateCharacter()
	flying = false
	spinning = false
	sticking = false
	noclip = false
	aimlock = false
	aimlockTarget = nil
end)

--========================
-- SPIN
--========================
local function getSpinCFrame(speed)
	local amount = math.rad(speed) * spinDirection
	if spinAxis == "X" then return CFrame.Angles(amount, 0, 0)
	elseif spinAxis == "Z" then return CFrame.Angles(0, 0, amount)
	else return CFrame.Angles(0, amount, 0) end
end

local function startSpin()
	if spinning then return end
	spinning = true
	spinConnection = RunService.RenderStepped:Connect(function()
		if humanoidRootPart and humanoidRootPart.Parent then
			humanoidRootPart.CFrame = humanoidRootPart.CFrame * getSpinCFrame(spinSpeed)
		end
	end)
end

local function stopSpin()
	spinning = false
	if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
end

--========================
-- FLY
--========================
local function startFly()
	if flying then return end
	flying = true
	humanoid.PlatformStand = true

	flyBodyVelocity = Instance.new("BodyVelocity")
	flyBodyVelocity.Velocity = Vector3.zero
	flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBodyVelocity.Parent = humanoidRootPart

	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBodyGyro.P = 1e4
	flyBodyGyro.Parent = humanoidRootPart

	flyConnection = RunService.RenderStepped:Connect(function()
		if not flying or not humanoidRootPart then return end
		local moveDir = Vector3.zero
		local forward = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector
		local up = Vector3.new(0, 1, 0)

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += forward end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= forward end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= right end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += right end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += up end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= up end

		flyBodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * flySpeed or Vector3.zero
		flyBodyGyro.CFrame = camera.CFrame
	end)
end

local function stopFly()
	flying = false
	if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
	if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
	if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
	if humanoid then humanoid.PlatformStand = false end
end

--========================
-- TP
--========================
local function tpToCoords(x, y, z)
	if humanoidRootPart then humanoidRootPart.CFrame = CFrame.new(x, y, z) end
end

local function tpToPlayer(targetName)
	local target = Players:FindFirstChild(targetName)
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		humanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
		return true
	end
	return false
end

local function savePosition(slotName)
	if humanoidRootPart then savedPositions[slotName] = humanoidRootPart.CFrame; return true end
	return false
end

local function loadPosition(slotName)
	if savedPositions[slotName] then humanoidRootPart.CFrame = savedPositions[slotName]; return true end
	return false
end

local function getPlayerNames()
	local names = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then table.insert(names, p.Name) end
	end
	return names
end

--========================
-- STICK
--========================
local function startStick(targetName)
	if sticking then return false end
	if not Players:FindFirstChild(targetName) then return false end
	sticking = true
	stickConnection = RunService.RenderStepped:Connect(function()
		if not sticking then return end
		local t = Players:FindFirstChild(targetName)
		if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and humanoidRootPart then
			humanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(3, 0, 0)
		end
	end)
	return true
end

local function stopStick()
	sticking = false
	if stickConnection then stickConnection:Disconnect(); stickConnection = nil end
end

--========================
-- INVISIBLE (visible par tous)
--========================
local originalTransparency = {}

local function setInvisible(state)
	invisible = state
	if not character then return end

	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if state then
				originalTransparency[part] = part.Transparency
				part.Transparency = 1
				part.LocalTransparencyModifier = 1
			else
				part.Transparency = originalTransparency[part] or 0
				part.LocalTransparencyModifier = 0
			end
		end
		if part:IsA("Decal") then
			part.Transparency = state and 1 or 0
		end
	end

	for _, obj in pairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				if state then
					originalTransparency[handle] = handle.Transparency
					handle.Transparency = 1
					handle.LocalTransparencyModifier = 1
				else
					handle.Transparency = originalTransparency[handle] or 0
					handle.LocalTransparencyModifier = 0
				end
			end
		end
	end

	humanoid.DisplayDistanceType = state
		and Enum.HumanoidDisplayDistanceType.None
		or Enum.HumanoidDisplayDistanceType.Automatic
end

--========================
-- NOCLIP RÉEL
--========================
local function startNoclip()
	if noclipConnection then return end
	noclipConnection = RunService.Stepped:Connect(function()
		if not noclip or not character then return end
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

local function stopNoclip()
	noclip = false
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	task.wait(0.05)
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = true end
		end
	end
end

--========================
-- AIMLOCK
--========================
local function getClosestPlayer()
	local closest, minDist = nil, math.huge
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if dist < minDist then minDist = dist; closest = p end
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
		if not aimlockTarget then aimlockTarget = getClosestPlayer() end
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

local function setupAimlockToggle()
	if aimlockToggleConnection then aimlockToggleConnection:Disconnect() end
	aimlockToggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == aimlockKey then
			aimlock = not aimlock
			if aimlock then
				aimlockTarget = getClosestPlayer()
				Rayfield:Notify({
					Title = "Aimlock ON",
					Content = aimlockTarget and ("Cible : " .. aimlockTarget.Name) or "Aucune cible",
					Duration = 2,
				})
			else
				aimlockTarget = nil
				Rayfield:Notify({ Title = "Aimlock OFF", Content = "Viseur libre.", Duration = 2 })
			end
		end
	end)
end

--========================
-- RAYFIELD UI
--========================
local Window = Rayfield:CreateWindow({
	Name = "Laysox UI",
	LoadingTitle = "Laysox UI",
	LoadingSubtitle = "Chargement...",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = { Enabled = false },
	KeySystem = false,
})

-- TAB SPIN
local SpinTab = Window:CreateTab("Spin", 4483362458)

SpinTab:CreateSlider({
	Name = "Vitesse", Range = {1, 100}, Increment = 1,
	Suffix = "°/frame", CurrentValue = spinSpeed, Flag = "SpinSpeed",
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
	Suffix = " studs/s", CurrentValue = flySpeed, Flag = "FlySpeed",
	Callback = function(v) flySpeed = v end,
})
FlyTab:CreateParagraph({ Title="Contrôles", Content="W/A/S/D → Directions\nSpace → Monter\nCtrl → Descendre" })
FlyTab:CreateToggle({
	Name = "Activer Fly", CurrentValue = false, Flag = "FlyToggle",
	Callback = function(v)
		if v then startFly(); Rayfield:Notify({ Title="Fly ON", Content=flySpeed.." studs/s", Duration=2 })
		else stopFly(); Rayfield:Notify({ Title="Fly OFF", Content="Retour au sol.", Duration=2 }) end
	end,
})

-- TAB TP
local TPTab = Window:CreateTab("Téléport", 4483362458)
local coordX, coordY, coordZ = 0, 0, 0
local selectedPlayer = ""

TPTab:CreateSection("Coordonnées XYZ")
TPTab:CreateInput({ Name="X", PlaceholderText="ex: 100", RemoveTextAfterFocusLost=false, Flag="CX",
	Callback=function(v) coordX=tonumber(v) or coordX end })
TPTab:CreateInput({ Name="Y", PlaceholderText="ex: 50", RemoveTextAfterFocusLost=false, Flag="CY",
	Callback=function(v) coordY=tonumber(v) or coordY end })
TPTab:CreateInput({ Name="Z", PlaceholderText="ex: 200", RemoveTextAfterFocusLost=false, Flag="CZ",
	Callback=function(v) coordZ=tonumber(v) or coordZ end })
TPTab:CreateButton({ Name="Téléporter aux coordonnées", Callback=function()
	tpToCoords(coordX, coordY, coordZ)
	Rayfield:Notify({ Title="TP !", Content=string.format("X:%d Y:%d Z:%d", coordX,coordY,coordZ), Duration=3 })
end })

TPTab:CreateSection("TP vers joueur")
TPTab:CreateDropdown({ Name="Joueur", Options=getPlayerNames(), CurrentOption={}, Flag="TPPlayer", MultipleOptions=false,
	Callback=function(o) selectedPlayer=o[1] or "" end })
TPTab:CreateButton({ Name="Téléporter", Callback=function()
	if selectedPlayer=="" then Rayfield:Notify({ Title="Erreur", Content="Aucun joueur.", Duration=2 }); return end
	local ok=tpToPlayer(selectedPlayer)
	Rayfield:Notify({ Title=ok and "TP !" or "Échec", Content=ok and "Vers : "..selectedPlayer or "Introuvable.", Duration=3 })
end })

TPTab:CreateSection("Suivre un joueur")
TPTab:CreateDropdown({ Name="Joueur à suivre", Options=getPlayerNames(), CurrentOption={}, Flag="StickPlayer", MultipleOptions=false,
	Callback=function(o) selectedStickPlayer=o[1] or "" end })
TPTab:CreateToggle({ Name="Activer le Suivi", CurrentValue=false, Flag="StickToggle",
	Callback=function(v)
		if v then
			if selectedStickPlayer=="" then Rayfield:Notify({ Title="Erreur", Content="Aucun joueur.", Duration=2 }); return end
			local ok=startStick(selectedStickPlayer)
			Rayfield:Notify({ Title=ok and "Suivi ON" or "Échec", Content=ok and "Collé à : "..selectedStickPlayer or "Introuvable.", Duration=3 })
		else stopStick(); Rayfield:Notify({ Title="Suivi OFF", Content="Plus collé.", Duration=2 }) end
	end,
})

TPTab:CreateSection("Positions sauvegardées")
for _, slot in pairs({"Slot 1","Slot 2","Slot 3"}) do
	TPTab:CreateButton({ Name="💾 Sauvegarder — "..slot, Callback=function()
		savePosition(slot); Rayfield:Notify({ Title="Sauvegardé", Content=slot, Duration=2 }) end })
	TPTab:CreateButton({ Name="📍 Charger — "..slot, Callback=function()
		local ok=loadPosition(slot)
		Rayfield:Notify({ Title=ok and "Chargé" or "Vide", Content=slot, Duration=2 }) end })
end

-- TAB DIVERS
local DiversTab = Window:CreateTab("Divers", 4483362458)

DiversTab:CreateSection("Invisibilité")
DiversTab:CreateToggle({ Name="Invisible", CurrentValue=false, Flag="InvisToggle",
	Callback=function(v)
		setInvisible(v)
		Rayfield:Notify({ Title=v and "Invisible !" or "Visible", Content=v and "Personne ne te voit." or "Tu es visible.", Duration=3 })
	end,
})

DiversTab:CreateSection("No-Clip")
DiversTab:CreateToggle({ Name="No-Clip", CurrentValue=false, Flag="NoclipToggle",
	Callback=function(v)
		noclip=v
		if v then startNoclip(); Rayfield:Notify({ Title="No-Clip ON", Content="Tu traverses les murs.", Duration=3 })
		else stopNoclip(); Rayfield:Notify({ Title="No-Clip OFF", Content="Collisions restaurées.", Duration=2 }) end
	end,
})

-- TAB COMBAT (AIMLOCK)
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Aimlock")
CombatTab:CreateKeybind({
	Name="Touche Aimlock", CurrentKeybind="Q", HoldToInteract=false, Flag="AimlockKey",
	Callback=function(key)
		aimlockKey=Enum.KeyCode[key] or Enum.KeyCode.Q
		setupAimlockToggle()
		Rayfield:Notify({ Title="Touche maj", Content="Aimlock → "..key, Duration=2 })
	end,
})
CombatTab:CreateToggle({ Name="Activer Aimlock", CurrentValue=false, Flag="AimlockToggle",
	Callback=function(v)
		if v then
			startAimlock()
			setupAimlockToggle()
			Rayfield:Notify({ Title="Aimlock ON", Content="Touche : "..aimlockKey.Name, Duration=3 })
		else
			stopAimlock()
			Rayfield:Notify({ Title="Aimlock OFF", Content="Viseur libre.", Duration=2 })
		end
	end,
})
CombatTab:CreateParagraph({
	Title="Info",
	Content="Verrouille sur le joueur le plus proche du centre de l'écran.\nAppuie sur ta touche pour toggle rapidement.",
})
```

---

## Étape 2 — Le rendre court comme les autres scripts

**1.** Va sur [github.com](https://github.com) et crée un compte si tu n'en as pas

**2.** Crée un nouveau **repository** public

**3.** Crée un fichier `LaysoxUI.lua` et colle tout le code dedans

**4.** Clique sur le fichier → **Raw** → copie l'URL qui ressemble à :
```
https://raw.githubusercontent.com/TON_PSEUDO/TON_REPO/main/LaysoxUI.lua
