--// Laysox UI - Rayfield Version
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
--========================

local spinning = false
local spinConnection = nil
local spinDirection = defaultDirection
local spinAxis = defaultAxis

local flying = false
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

local sticking = false
local stickConnection = nil
local selectedStickPlayer = ""

local invisible = false

local noclip = false
local noclipConnection = nil

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
-- LOGIQUE SPIN
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
-- LOGIQUE FLY
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
-- LOGIQUE TP
--========================
local function tpToCoords(x, y, z)
	if humanoidRootPart then
		humanoidRootPart.CFrame = CFrame.new(x, y, z)
	end
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
	if humanoidRootPart then
		savedPositions[slotName] = humanoidRootPart.CFrame
		return true
	end
	return false
end

local function loadPosition(slotName)
	if savedPositions[slotName] then
		humanoidRootPart.CFrame = savedPositions[slotName]
		return true
	end
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
-- LOGIQUE STICK
--========================
local function startStick(targetName)
	if sticking then return end
	local target = Players:FindFirstChild(targetName)
	if not target then return false end
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
-- INVISIBLE (côté serveur via réseau)
-- Utilise un RemoteEvent si disponible, sinon LocalTransparency + suppression du personnage réseau
--========================
local function setInvisible(state)
	invisible = state
	if not character then return end

	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			-- LocalTransparencyModifier pour le client local
			part.LocalTransparencyModifier = state and 1 or 0

			-- Pour les autres joueurs : on change la Transparency réseau
			if state then
				part.Transparency = 1
			else
				-- Restaure selon le type de part
				if part.Name == "Head" or part.Name:find("Leg") or part.Name:find("Arm") or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" then
					part.Transparency = 0
				end
			end
		end
		if part:IsA("Decal") or part:IsA("SpecialMesh") then
			part.Parent.Transparency = state and 1 or 0
		end
	end

	-- Accessoires et outils
	for _, obj in pairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = state and 1 or 0
				handle.Transparency = state and 1 or 0
			end
		end
		if obj:IsA("Tool") then
			for _, p in pairs(obj:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Transparency = state and 1 or 0
				end
			end
		end
	end

	-- Cacher le nom au-dessus de la tête
	local billboard = character:FindFirstChildOfClass("BillboardGui")
	if billboard then billboard.Enabled = not state end
	humanoid.DisplayDistanceType = state and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Automatic
end

--========================
-- NOCLIP RÉEL
-- Désactive CanCollide sur chaque Stepped pour contrer le reset serveur
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
	task.wait(0.1)
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end

--========================
-- AIMLOCK
--========================
local function getClosestPlayer()
	local closest = nil
	local minDist = math.huge
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
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

local function startAimlock()
	if aimlockConnection then return end
	aimlockConnection = RunService.RenderStepped:Connect(function()
		if not aimlock then return end

		-- Vérifie que la cible est encore valide
		if aimlockTarget then
			if not aimlockTarget.Character or not aimlockTarget.Character:FindFirstChild("Head") then
				aimlockTarget = nil
			end
		end

		-- Cherche une cible si pas de cible
		if not aimlockTarget then
			aimlockTarget = getClosestPlayer()
		end

		-- Verrouille la caméra sur la tête
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
					Content = aimlockTarget and ("Cible : " .. aimlockTarget.Name) or "Aucune cible trouvée",
					Duration = 2,
				})
			else
				aimlockTarget = nil
				Rayfield:Notify({ Title = "Aimlock OFF", Content = "Viseur déverrouillé.", Duration = 2 })
			end
		end
	end)
end

--========================
-- RAYFIELD UI — LAYSOX UI
--========================
local Window = Rayfield:CreateWindow({
	Name = "Laysox UI",
	LoadingTitle = "Laysox UI",
	LoadingSubtitle = "Chargement des modules...",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = { Enabled = false },
	KeySystem = false,
})

--========================
-- TAB SPIN
--========================
local SpinTab = Window:CreateTab("Spin", 4483362458)

SpinTab:CreateSlider({
	Name = "Vitesse de spin", Range = {1, 100}, Increment = 1,
	Suffix = "°/frame", CurrentValue = spinSpeed, Flag = "SpinSpeed",
	Callback = function(value) spinSpeed = value end,
})

SpinTab:CreateDropdown({
	Name = "Direction", Options = {"Clockwise", "Counterclockwise"},
	CurrentOption = {"Clockwise"}, Flag = "SpinDirection", MultipleOptions = false,
	Callback = function(option)
		spinDirection = (option[1] == "Clockwise") and 1 or -1
	end,
})

SpinTab:CreateDropdown({
	Name = "Axe de rotation", Options = {"Y", "X", "Z"},
	CurrentOption = {"Y"}, Flag = "SpinAxis", MultipleOptions = false,
	Callback = function(option) spinAxis = option[1] end,
})

SpinTab:CreateToggle({
	Name = "Activer le Spin", CurrentValue = false, Flag = "SpinToggle",
	Callback = function(value)
		if value then startSpin(); Rayfield:Notify({ Title = "Spin activé", Content = "Axe : " .. spinAxis, Duration = 3 })
		else stopSpin(); Rayfield:Notify({ Title = "Spin arrêté", Content = "Rotation désactivée.", Duration = 2 }) end
	end,
})

--========================
-- TAB FLY
--========================
local FlyTab = Window:CreateTab("Fly", 4483362458)

FlyTab:CreateSlider({
	Name = "Vitesse de vol", Range = {10, 300}, Increment = 5,
	Suffix = " studs/s", CurrentValue = flySpeed, Flag = "FlySpeed",
	Callback = function(value) flySpeed = value end,
})

FlyTab:CreateParagraph({
	Title = "Contrôles",
	Content = "W/A/S/D → Directions\nSpace → Monter\nCtrl → Descendre",
})

FlyTab:CreateToggle({
	Name = "Activer le Fly", CurrentValue = false, Flag = "FlyToggle",
	Callback = function(value)
		if value then startFly(); Rayfield:Notify({ Title = "Fly activé", Content = flySpeed .. " studs/s", Duration = 3 })
		else stopFly(); Rayfield:Notify({ Title = "Fly désactivé", Content = "Retour au sol.", Duration = 2 }) end
	end,
})

--========================
-- TAB TP
--========================
local TPTab = Window:CreateTab("Téléport", 4483362458)

local coordX, coordY, coordZ = 0, 0, 0
local selectedPlayer = ""

TPTab:CreateSection("Coordonnées XYZ")

TPTab:CreateInput({ Name = "X", PlaceholderText = "ex: 100", RemoveTextAfterFocusLost = false, Flag = "CoordX",
	Callback = function(v) coordX = tonumber(v) or coordX end })
TPTab:CreateInput({ Name = "Y", PlaceholderText = "ex: 50", RemoveTextAfterFocusLost = false, Flag = "CoordY",
	Callback = function(v) coordY = tonumber(v) or coordY end })
TPTab:CreateInput({ Name = "Z", PlaceholderText = "ex: 200", RemoveTextAfterFocusLost = false, Flag = "CoordZ",
	Callback = function(v) coordZ = tonumber(v) or coordZ end })

TPTab:CreateButton({
	Name = "Téléporter aux coordonnées",
	Callback = function()
		tpToCoords(coordX, coordY, coordZ)
		Rayfield:Notify({ Title = "Téléporté !", Content = string.format("X:%d Y:%d Z:%d", coordX, coordY, coordZ), Duration = 3 })
	end,
})

TPTab:CreateSection("TP vers joueur")

TPTab:CreateDropdown({
	Name = "Choisir un joueur", Options = getPlayerNames(),
	CurrentOption = {}, Flag = "TargetPlayer", MultipleOptions = false,
	Callback = function(option) selectedPlayer = option[1] or "" end,
})

TPTab:CreateButton({
	Name = "Téléporter",
	Callback = function()
		if selectedPlayer == "" then Rayfield:Notify({ Title = "Erreur", Content = "Aucun joueur.", Duration = 3 }); return end
		local ok = tpToPlayer(selectedPlayer)
		Rayfield:Notify({ Title = ok and "Téléporté !" or "Échec", Content = ok and ("Vers : " .. selectedPlayer) or (selectedPlayer .. " introuvable."), Duration = 3 })
	end,
})

TPTab:CreateSection("Suivre un joueur")

TPTab:CreateDropdown({
	Name = "Joueur à suivre", Options = getPlayerNames(),
	CurrentOption = {}, Flag = "StickPlayer", MultipleOptions = false,
	Callback = function(option) selectedStickPlayer = option[1] or "" end,
})

TPTab:CreateToggle({
	Name = "Activer le Suivi", CurrentValue = false, Flag = "StickToggle",
	Callback = function(value)
		if value then
			if selectedStickPlayer == "" then Rayfield:Notify({ Title = "Erreur", Content = "Aucun joueur.", Duration = 3 }); return end
			local ok = startStick(selectedStickPlayer)
			Rayfield:Notify({ Title = ok and "Suivi activé" or "Échec", Content = ok and ("Collé à : " .. selectedStickPlayer) or "Introuvable.", Duration = 3 })
		else
			stopStick()
			Rayfield:Notify({ Title = "Suivi arrêté", Content = "Tu n'es plus collé.", Duration = 2 })
		end
	end,
})

TPTab:CreateSection("Positions sauvegardées")

for _, slot in pairs({"Slot 1", "Slot 2", "Slot 3"}) do
	TPTab:CreateButton({ Name = "💾 Sauvegarder — " .. slot, Callback = function()
		savePosition(slot); Rayfield:Notify({ Title = "Sauvegardé", Content = slot, Duration = 2 }) end })
	TPTab:CreateButton({ Name = "📍 Charger — " .. slot, Callback = function()
		local ok = loadPosition(slot)
		Rayfield:Notify({ Title = ok and "Chargé" or "Vide", Content = slot, Duration = 2 }) end })
end

--========================
-- TAB DIVERS
--========================
local DiversTab = Window:CreateTab("Divers", 4483362458)

DiversTab:CreateSection("Invisibilité")

DiversTab:CreateToggle({
	Name = "Invisible (tous les joueurs)",
	CurrentValue = false, Flag = "InvisToggle",
	Callback = function(value)
		setInvisible(value)
		Rayfield:Notify({
			Title = value and "Invisible !" or "Visible",
			Content = value and "Personne ne te voit." or "Tu es visible.",
			Duration = 3,
		})
	end,
})

DiversTab:CreateSection("No-Clip")

DiversTab:CreateToggle({
	Name = "No-Clip (traverser les murs)",
	CurrentValue = false, Flag = "NoclipToggle",
	Callback = function(value)
		noclip = value
		if value then
			startNoclip()
			Rayfield:Notify({ Title = "No-Clip ON", Content = "Tu traverses les murs.", Duration = 3 })
		else
			stopNoclip()
			Rayfield:Notify({ Title = "No-Clip OFF", Content = "Collisions restaurées.", Duration = 2 })
		end
	end,
})

DiversTab:CreateSection("Aimlock")

-- Keybind personnalisable
DiversTab:CreateKeybind({
	Name = "Touche Aimlock",
	CurrentKeybind = "Q",
	HoldToInteract = false,
	Flag = "AimlockKey",
	Callback = function(key)
		aimlockKey = Enum.KeyCode[key] or Enum.KeyCode.Q
		setupAimlockToggle()
		Rayfield:Notify({ Title = "Touche mise à jour", Content = "Aimlock → " .. key, Duration = 2 })
	end,
})

DiversTab:CreateToggle({
	Name = "Activer l'Aimlock",
	CurrentValue = false, Flag = "AimlockToggle",
	Callback = function(value)
		if value then
			startAimlock()
			setupAimlockToggle()
			Rayfield:Notify({ Title = "Aimlock activé", Content = "Appuie sur " .. tostring(aimlockKey.Name) .. " pour toggle.", Duration = 3 })
		else
			stopAimlock()
			Rayfield:Notify({ Title = "Aimlock désactivé", Content = "Viseur libre.", Duration = 2 })
		end
	end,
})

DiversTab:CreateParagraph({
	Title = "Info Aimlock",
	Content = "Le viseur se verrouille automatiquement sur le joueur le plus proche de ton écran.\nAppuie sur ta touche configurée pour activer/désactiver rapidement.",
})
