-- ============================================================
--  Laysox Hub - BloxStrike | Skin Changer
--  Discord : https://discord.gg/tFkAe2RVKB
-- ============================================================
-- 
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/twistedk1d/BloxStrike/refs/heads/main/Source/UI/source.lua"))()
--// Window creation
local Window = Rayfield:CreateWindow({
    Name = "Laysox Hub - BloxStrike",
    Icon = 0,
    LoadingTitle = "Laysox Hub - BloxStrike",
    LoadingSubtitle = "discord.gg/tFkAe2RVKB",
    ShowText = "Menu",
    Theme = "Bloom",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Laysox Hub - BloxStrike",
        FileName = "laysox_bloxstrike_config"
    }
})
--// Services \& Globals
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local CharactersFolder = Workspace:WaitForChild("Characters", 10)
--// TABS
local Tab_Combat = Window:CreateTab("Combat", "crosshair")
local Tab_Skins = Window:CreateTab("Skins", "swords")
local Tab_Visuals = Window:CreateTab("Visuals", "eye")
local SkinChangerEnabled = false
local SelectedSkins = {}
local DropdownObjects = {}
local SkinOptions = {}
local COOLDOWN = 0.1
local WEAR = "Factory New"
local CT_ONLY = {["USP-S"]=true, ["Five-SeveN"]=true, ["MP9"]=true, ["FAMAS"]=true, ["M4A1-S"]=true, ["M4A4"]=true, ["AUG"]=true}
local SHARED = {["P250"]=true, ["Desert Eagle"]=true, ["Dual Berettas"]=true, ["Negev"]=true, ["P90"]=true, ["Nova"]=true, ["XM1014"]=true, ["AWP"]=true, ["SSG 08"]=true}
local KNIVES = {["Karambit"]=true, ["Butterfly Knife"]=true, ["M9 Bayonet"]=true, ["Flip Knife"]=true, ["Gut Knife"]=true, ["T Knife"]=true, ["CT Knife"]=true}
local GLOVES = {["Sports Gloves"]=true}
local SkinsFolder = RS:WaitForChild("Assets"):WaitForChild("Skins")
local IgnoreFolders = {["HE Grenade"]=true, ["Incendiary Grenade"]=true, ["Molotov"]=true, ["Smoke Grenade"]=true, ["Flashbang"]=true, ["Decoy Grenade"]=true, ["C4"]=true, ["CT Glove"]=true, ["T Glove"]=true}
local function applyWeaponSkin(model)
    if not model or not SkinChangerEnabled or not isAlive() then return end
    local skinName = SelectedSkins[model.Name]
    if not skinName then return end
    pcall(function()
        local skinFolder = SkinsFolder:FindFirstChild(model.Name)
        if not skinFolder then return end
        local skinType = skinFolder:FindFirstChild(skinName)
        local sourceFolder = skinType and skinType:FindFirstChild("Camera") and skinType.Camera:FindFirstChild(WEAR)
        if not sourceFolder then return end
        for _, obj in camera:GetChildren() do
            local left, right = obj:FindFirstChild("Left Arm"), obj:FindFirstChild("Right Arm")
            if left or right then
                local gloveFolder = SkinsFolder:FindFirstChild("Sports Gloves")
                local gloveSkin = gloveFolder and gloveFolder:FindFirstChild(SelectedSkins["Sports Gloves"])
                local gloveSource = gloveSkin and gloveSkin:FindFirstChild("Camera") and gloveSkin.Camera:FindFirstChild(WEAR)
                if gloveSource then
                    for _, side in {"Left Arm", "Right Arm"} do
                        local arm, src = obj:FindFirstChild(side), gloveSource:FindFirstChild(side)
                        if arm and src then
                            local gloveMesh = arm:FindFirstChild("Glove")
                            if gloveMesh then
                                local existing = gloveMesh:FindFirstChildOfClass("SurfaceAppearance")
                                if existing then existing:Destroy() end
                                local clone = src:Clone()
                                clone.Name, clone.Parent = "SurfaceAppearance", gloveMesh
                            end
                        end
                    end
                end
            end
        end
        if not GLOVES[model.Name] then
            local weaponFolder = model:FindFirstChild("Weapon")
            if weaponFolder then
                for _, part in weaponFolder:GetDescendants() do
                    if part:IsA("BasePart") then
                        local newSkin = sourceFolder:FindFirstChild(part.Name)
                        if newSkin then
                            local existing = part:FindFirstChildOfClass("SurfaceAppearance")
                            if existing then existing:Destroy() end
                            local clone = newSkin:Clone()
                            clone.Name, clone.Parent = "SurfaceAppearance", part
                        end
                    end
                end
            end
        end
        model:SetAttribute("SkinApplied", skinName)
    end)
end
Tab_Skins:CreateToggle({Name = "Enable Skin Changer", CurrentValue = false, Flag = "SkinChangerToggle", Callback = function(Value) SkinChangerEnabled = Value; if not Value then for _, obj in camera:GetChildren() do obj:SetAttribute("SkinApplied", nil) end end end})
Tab_Skins:CreateButton({Name = "🎲 Randomize All Skins", Callback = function()
    for weaponName, optionsList in pairs(SkinOptions) do
        if #optionsList > 0 then
            local randomSkin = optionsList[math.random(1, #optionsList)]
            if DropdownObjects[weaponName] then
                for _, dropdown in ipairs(DropdownObjects[weaponName]) do dropdown:Set({randomSkin}) end
            end
        end
    end
end})
local function CreateSkinDropdown(weaponName)
    local folder = SkinsFolder:FindFirstChild(weaponName)
    if not folder then return end
    local options = {}
    for _, skin in folder:GetChildren() do table.insert(options, skin.Name) end
    SkinOptions[weaponName] = options
    if not SelectedSkins[weaponName] then SelectedSkins[weaponName] = options[1] end
    local dp = Tab_Skins:CreateDropdown({
        Name = weaponName,
        Options = options,
        CurrentOption = {SelectedSkins[weaponName]},
        Flag = "Skin_" .. weaponName,
        Callback = function(opt)
            local newSkin = opt[1]
            SelectedSkins[weaponName] = newSkin
            if DropdownObjects[weaponName] then
                for _, other in DropdownObjects[weaponName] do
                    if other.CurrentOption[1] \~= newSkin then other:Set({newSkin}) end
                end
            end
            for _, obj in camera:GetChildren() do obj:SetAttribute("SkinApplied", nil); applyWeaponSkin(obj) end
        end
    })
    DropdownObjects[weaponName] = DropdownObjects[weaponName] or {}
    table.insert(DropdownObjects[weaponName], dp)
end
Tab_Skins:CreateToggle({Name = "Enable Custom Knife", CurrentValue = false, Flag = "KnifeToggle", Callback = function(Value) scriptRunning = Value; if not Value then removeViewmodel() end end})
Tab_Skins:CreateDropdown({Name = "Selected Custom Knife", Options = {"Butterfly Knife", "Karambit", "M9 Bayonet", "Flip Knife", "Gut Knife"}, CurrentOption = {"Butterfly Knife"}, MultipleOptions = false, Flag = "KnifeDropdown", Callback = function(Options) selectedKnife = Options[1]; if spawned then removeViewmodel() end end})
Tab_Skins:CreateSection("Knives Skins")
for name in pairs(KNIVES) do CreateSkinDropdown(name) end
Tab_Skins:CreateSection("Gloves")
for name in pairs(GLOVES) do CreateSkinDropdown(name) end
Tab_Skins:CreateSection("CT Weapons")
for name in pairs(CT_ONLY) do CreateSkinDropdown(name) end
Tab_Skins:CreateSection("T Weapons")
for name in pairs(SHARED) do CreateSkinDropdown(name) end
for _, folder in SkinsFolder:GetChildren() do
    local n = folder.Name
    if not IgnoreFolders[n] and not KNIVES[n] and not GLOVES[n] and not CT_ONLY[n] and not SHARED[n] then CreateSkinDropdown(n) end
end
camera.ChildAdded:Connect(function(obj)
    if not SkinChangerEnabled or not isAlive() then return end
    task.wait(COOLDOWN); applyWeaponSkin(obj)
end)
task.spawn(function()
    while task.wait(0.5) do
        if SkinChangerEnabled and isAlive() then
            for _, obj in camera:GetChildren() do
                if SelectedSkins[obj.Name] and obj:GetAttribute("SkinApplied") \~= SelectedSkins[obj.Name] then applyWeaponSkin(obj) end
            end
        end
    end
end)
--// ESP + CHAMS (unchanged)
local EspEnabled = false
local EspBox = true
local EspName = true
local EspHealth = true
local EspDistance = true
local EspSkeleton = false
local EspHeadDot = false
local EspTracers = false
local EspMaxDistance = 0
local RainbowESP = false
local RainbowESP_Speed = 2.0
local RainbowChams = false
local RainbowChams_Speed = 2.0
local BoxColor = Color3.fromRGB(255, 50, 50)
local TextColor = Color3.fromRGB(255, 255, 255)
local SkeletonColor = Color3.fromRGB(255, 255, 255)
local TracerColor = Color3.fromRGB(255, 50, 50)
local HeadDotColor = Color3.fromRGB(255, 255, 255)
local EspTextSize = 15
local BoxThickness = 1.5
local ChamsEnabled = false
local ChamsColor = Color3.fromRGB(255, 0, 255)
local ChamsFillTransparency = 0.7
local ChamsOutlineTransparency = 0
local WeaponChamsEnabled = false
local WeaponChamsColor = Color3.fromRGB(0, 255, 255)
local WeaponChamsFillTransparency = 0.5
local WeaponChamsOutlineTransparency = 0.0
local espCache = {}
local chamsCache = {}
local weaponChamsCache = {}
local function getRainbowColor(speed)
    local time = tick() * speed
    return Color3.fromHSV(time % 1, 1, 1)
end
local function createESP()
    local esp = {
        boxOutline = Drawing.new("Square"),
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        healthOutline = Drawing.new("Line"),
        healthBackground = Drawing.new("Line"),
        healthBar = Drawing.new("Line"),
        headDot = Drawing.new("Circle"),
        tracer = Drawing.new("Line"),
        skeleton = {
            headToNeck = Drawing.new("Line"),
            neckToTorso = Drawing.new("Line"),
            torsoToLeftUpper = Drawing.new("Line"),
            torsoToRightUpper = Drawing.new("Line"),
            leftUpperToLower = Drawing.new("Line"),
            rightUpperToLower = Drawing.new("Line"),
            leftLowerToFoot = Drawing.new("Line"),
            rightLowerToFoot = Drawing.new("Line")
        }
    }
    esp.boxOutline.Thickness = 3
    esp.boxOutline.Filled = false
    esp.boxOutline.Color = Color3.new(0, 0, 0)
    esp.box.Thickness = BoxThickness
    esp.box.Filled = false
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Size = EspTextSize
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Size = EspTextSize - 2
    esp.healthOutline.Thickness = 3
    esp.healthOutline.Color = Color3.new(0, 0, 0)
    esp.healthBackground.Thickness = 4
    esp.healthBackground.Color = Color3.new(0, 0, 0)
    esp.healthBackground.Transparency = 0.7
    esp.healthBar.Thickness = 2
    esp.headDot.Radius = 3
    esp.headDot.Filled = true
    esp.headDot.Transparency = 1
    esp.tracer.Thickness = 1.5
    esp.tracer.Transparency = 0.8
    for _, line in pairs(esp.skeleton) do
        line.Thickness = 1.5
        line.Transparency = 0.9
    end
    return esp
end
RunService.RenderStepped:Connect(function()
    if not EspEnabled or not isAlive() then
        for _, e in pairs(espCache) do
            for _, drawing in pairs(e) do
                if typeof(drawing) == "table" then
                    for _, line in pairs(drawing) do line.Visible = false end
                else
                    drawing.Visible = false
                end
            end
        end
        return
    end
    local enemyFolder = getEnemyFolder()
    if not enemyFolder then return end
    local currentAlive = {}
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local rainbowColor = RainbowESP and getRainbowColor(RainbowESP_Speed) or nil
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart")
        local head = enemy:FindFirstChild("Head")
        if hum and hum.Health > 0 and root and head then
            currentAlive[enemy] = true
            if not espCache[enemy] then espCache[enemy] = createESP() end
            local esp = espCache[enemy]
            local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
            local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.4, 0))
            local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))
            local distance = (camera.CFrame.Position - root.Position).Magnitude
            if EspMaxDistance > 0 and distance > EspMaxDistance then
                for _, d in pairs(esp) do
                    if typeof(d) == "table" then
                        for _, l in pairs(d) do l.Visible = false end
                    else
                        d.Visible = false
                    end
                end
                continue
            end
            if onScreen then
                local boxHeight = math.abs(headPos.Y - legPos.Y) * 1.05
                local boxWidth = boxHeight * 0.55
                local boxX = rootPos.X - boxWidth / 2
                local boxY = headPos.Y
                local currentBoxColor = RainbowESP and rainbowColor or BoxColor
                local currentTextColor = RainbowESP and rainbowColor or TextColor
                local currentSkeletonColor = RainbowESP and rainbowColor or SkeletonColor
                local currentTracerColor = RainbowESP and rainbowColor or TracerColor
                local currentHeadDotColor = RainbowESP and rainbowColor or HeadDotColor
                if EspBox then
                    esp.boxOutline.Size = Vector2.new(boxWidth, boxHeight)
                    esp.boxOutline.Position = Vector2.new(boxX, boxY)
                    esp.boxOutline.Visible = true
                    esp.box.Size = Vector2.new(boxWidth, boxHeight)
                    esp.box.Position = Vector2.new(boxX, boxY)
                    esp.box.Color = currentBoxColor
                    esp.box.Thickness = BoxThickness
                    esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false
                    esp.box.Visible = false
                end
                if EspHealth then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = boxX - 7
                    local barTop = boxY
                    local barBottom = boxY + boxHeight
                    esp.healthBackground.From = Vector2.new(barX, barTop)
                    esp.healthBackground.To = Vector2.new(barX, barBottom)
                    esp.healthBackground.Visible = true
                    esp.healthOutline.From = Vector2.new(barX - 1, barTop - 1)
                    esp.healthOutline.To = Vector2.new(barX + 1, barBottom + 1)
                    esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, barBottom)
                    esp.healthBar.To = Vector2.new(barX, barBottom - (boxHeight * hpPct))
                    esp.healthBar.Color = Color3.fromHSV(hpPct * 0.33, 1, 1)
                    esp.healthBar.Visible = true
                else
                    esp.healthBackground.Visible = false
                    esp.healthOutline.Visible = false
                    esp.healthBar.Visible = false
                end
                if EspName then
                    esp.name.Text = enemy.Name
                    esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 22)
                    esp.name.Color = currentTextColor
                    esp.name.Size = EspTextSize
                    esp.name.Visible = true
                else
                    esp.name.Visible = false
                end
                if EspDistance then
                    esp.distance.Text = string.format("[%d studs]", math.floor(distance))
                    esp.distance.Position = Vector2.new(rootPos.X, boxY + boxHeight + 4)
                    esp.distance.Color = currentTextColor
                    esp.distance.Size = EspTextSize - 2
                    esp.distance.Visible = true
                else
                    esp.distance.Visible = false
                end
                if EspHeadDot then
                    esp.headDot.Position = Vector2.new(headPos.X, headPos.Y)
                    esp.headDot.Color = currentHeadDotColor
                    esp.headDot.Visible = true
                else
                    esp.headDot.Visible = false
                end
                if EspTracers then
                    esp.tracer.From = screenCenter
                    esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
                    esp.tracer.Color = currentTracerColor
                    esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end
                if EspSkeleton then
                    local neck = enemy:FindFirstChild("Neck") or head
                    local torso = enemy:FindFirstChild("UpperTorso") or enemy:FindFirstChild("Torso")
                    local leftUpper = enemy:FindFirstChild("LeftUpperArm")
                    local rightUpper = enemy:FindFirstChild("RightUpperArm")
                    local leftLower = enemy:FindFirstChild("LeftLowerArm")
                    local rightLower = enemy:FindFirstChild("RightLowerArm")
                    local leftFoot = enemy:FindFirstChild("LeftFoot") or enemy:FindFirstChild("Left Leg")
                    local rightFoot = enemy:FindFirstChild("RightFoot") or enemy:FindFirstChild("Right Leg")
                    local function w2s(pos)
                        local p = camera:WorldToViewportPoint(pos)
                        return Vector2.new(p.X, p.Y)
                    end
                    local lines = esp.skeleton
                    for _, line in pairs(lines) do
                        line.Color = currentSkeletonColor
                        line.Visible = true
                    end
                    lines.headToNeck.From = Vector2.new(headPos.X, headPos.Y)
                    lines.headToNeck.To = w2s(neck.Position)
                    lines.neckToTorso.From = w2s(neck.Position)
                    lines.neckToTorso.To = w2s(torso and torso.Position or root.Position)
                    lines.torsoToLeftUpper.From = w2s(torso and torso.Position or root.Position)
                    lines.torsoToLeftUpper.To = w2s(leftUpper and leftUpper.Position or root.Position)
                    lines.torsoToRightUpper.From = w2s(torso and torso.Position or root.Position)
                    lines.torsoToRightUpper.To = w2s(rightUpper and rightUpper.Position or root.Position)
                    lines.leftUpperToLower.From = w2s(leftUpper and leftUpper.Position or root.Position)
                    lines.leftUpperToLower.To = w2s(leftLower and leftLower.Position or root.Position)
                    lines.rightUpperToLower.From = w2s(rightUpper and rightUpper.Position or root.Position)
                    lines.rightUpperToLower.To = w2s(rightLower and rightLower.Position or root.Position)
                    lines.leftLowerToFoot.From = w2s(leftLower and leftLower.Position or root.Position)
                    lines.leftLowerToFoot.To = w2s(leftFoot and leftFoot.Position or root.Position)
                    lines.rightLowerToFoot.From = w2s(rightLower and rightLower.Position or root.Position)
                    lines.rightLowerToFoot.To = w2s(rightFoot and rightFoot.Position or root.Position)
                else
                    for _, line in pairs(esp.skeleton) do line.Visible = false end
                end
            else
                for _, d in pairs(esp) do
                    if typeof(d) == "table" then
                        for _, l in pairs(d) do l.Visible = false end
                    else
                        d.Visible = false
                    end
                end
            end
        end
    end
    for cEnemy, e in pairs(espCache) do
        if not currentAlive[cEnemy] then
            for _, d in pairs(e) do
                if typeof(d) == "table" then
                    for _, l in pairs(d) do l:Remove() end
                else
                    d:Remove()
                end
            end
            espCache[cEnemy] = nil
        end
    end
end)
local function updatePlayerChams()
    local enemyFolder = getEnemyFolder()
    if not enemyFolder then return end
    local rainbowColor = RainbowChams and getRainbowColor(RainbowChams_Speed) or ChamsColor
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            if not chamsCache[enemy] then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = enemy
                highlight.Parent = enemy
                highlight.FillTransparency = ChamsFillTransparency
                highlight.OutlineTransparency = ChamsOutlineTransparency
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                chamsCache[enemy] = highlight
            end
            local hl = chamsCache[enemy]
            hl.FillColor = rainbowColor
            hl.OutlineColor = rainbowColor
            hl.FillTransparency = ChamsFillTransparency
            hl.OutlineTransparency = ChamsOutlineTransparency
        end
    end
    for model, hl in pairs(chamsCache) do
        if not model.Parent or (model:FindFirstChildOfClass("Humanoid") and model:FindFirstChildOfClass("Humanoid").Health <= 0) then
            if hl then hl:Destroy() end
            chamsCache[model] = nil
        end
    end
end
local function updateWeaponChams()
    if not WeaponChamsEnabled then 
        for _, hl in pairs(weaponChamsCache) do
            if hl then hl:Destroy() end
        end
        weaponChamsCache = {}
        return 
    end
    local rainbowColor = RainbowChams and getRainbowColor(RainbowChams_Speed) or WeaponChamsColor
    for _, obj in ipairs(camera:GetChildren()) do
        if obj:IsA("Model") and (obj.Name:find("Knife") or obj:FindFirstChild("Weapon")) then
            if not weaponChamsCache[obj] then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = obj
                highlight.Parent = obj
                highlight.FillTransparency = WeaponChamsFillTransparency
                highlight.OutlineTransparency = WeaponChamsOutlineTransparency
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                weaponChamsCache[obj] = highlight
            end
            local hl = weaponChamsCache[obj]
            hl.FillColor = rainbowColor
            hl.OutlineColor = rainbowColor
            hl.FillTransparency = WeaponChamsFillTransparency
            hl.OutlineTransparency = WeaponChamsOutlineTransparency
        end
    end
    for obj, hl in pairs(weaponChamsCache) do
        if not obj.Parent then
            if hl then hl:Destroy() end
            weaponChamsCache[obj] = nil
        end
    end
end
task.spawn(function()
    while task.wait(0.05) do
        if ChamsEnabled then
            updatePlayerChams()
        end
        updateWeaponChams()
    end
end)
--// ADVANCED BULLET TRACERS WITH PATTERNS (unchanged)
local BulletTracersEnabled = false
local BulletTracerColor = Color3.fromRGB(0, 255, 255)
local BulletTracerTransparency = 0.3
local BulletTracerDuration = 0.6
local BulletTracerThickness = 0.2
local BulletTracerPattern = "Straight"
local tracerParts = {}
local function createAdvancedTracer(origin, direction)
    local tracer = Instance.new("Part")
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Transparency = BulletTracerTransparency
    tracer.Color = BulletTracerColor
    tracer.Material = Enum.Material.Neon
    tracer.Size = Vector3.new(BulletTracerThickness, BulletTracerThickness, 300)
    tracer.CFrame = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, -150)
    tracer.Parent = Workspace
    if BulletTracerPattern == "Wave" then
        task.spawn(function()
            local startTime = tick()
            while tracer.Parent and (tick() - startTime) < BulletTracerDuration do
                local t = (tick() - startTime) * 15
                local offset = Vector3.new(math.sin(t) * 2, 0, 0)
                tracer.CFrame = CFrame.new(origin + offset, origin + direction + offset) * CFrame.new(0, 0, -150)
                RunService.Heartbeat:Wait()
            end
            if tracer.Parent then tracer:Destroy() end
        end)
    elseif BulletTracerPattern == "Spiral" then
        task.spawn(function()
            local startTime = tick()
            while tracer.Parent and (tick() - startTime) < BulletTracerDuration do
                local t = (tick() - startTime) * 20
                local offset = Vector3.new(math.cos(t) * 1.5, math.sin(t) * 1.5, 0)
                tracer.CFrame = CFrame.new(origin + offset, origin + direction + offset) * CFrame.new(0, 0, -150)
                RunService.Heartbeat:Wait()
            end
            if tracer.Parent then tracer:Destroy() end
        end)
    elseif BulletTracerPattern == "Dashed" then
        task.spawn(function()
            local startTime = tick()
            while tracer.Parent and (tick() - startTime) < BulletTracerDuration do
                tracer.Transparency = (math.sin(tick() * 30) > 0) and BulletTracerTransparency or 1
                RunService.Heartbeat:Wait()
            end
            if tracer.Parent then tracer:Destroy() end
        end)
    else
        task.delay(BulletTracerDuration, function()
            if tracer and tracer.Parent then tracer:Destroy() end
        end)
    end
    table.insert(tracerParts, tracer)
end
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and BulletTracersEnabled and isAlive() then
        local origin = camera.CFrame.Position
        local direction = camera.CFrame.LookVector * 300
        createAdvancedTracer(origin, direction)
    end
end)
RunService.Heartbeat:Connect(function()
    for i = #tracerParts, 1, -1 do
        if not tracerParts[i].Parent then
            table.remove(tracerParts, i)
        end
    end
end)
--// PARTICLE EFFECTS (unchanged)
local ParticleEffectsEnabled = false
local ParticleColor = Color3.fromRGB(255, 100, 0)
local ParticleAmount = 25
local ParticleLifetime = 1.2
local ParticleStyle = "Spark"
local function createParticleEffect(position)
    if not ParticleEffectsEnabled then return end
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = Workspace.Terrain
    local particle = Instance.new("ParticleEmitter")
    particle.Color = ColorSequence.new(ParticleColor)
    particle.Texture = "rbxassetid://243660364"
    particle.Lifetime = NumberRange.new(ParticleLifetime * 0.6, ParticleLifetime)
    particle.Rate = 0
    particle.EmissionDirection = Enum.NormalId.Front
    particle.SpreadAngle = Vector2.new(35, 35)
    particle.Speed = NumberRange.new(8, 18)
    particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.1)})
    particle.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    particle.Parent = attachment
    if ParticleStyle == "Smoke" then
        particle.Texture = "rbxassetid://243098098"
        particle.Speed = NumberRange.new(2, 6)
    elseif ParticleStyle == "Fire" then
        particle.Texture = "rbxassetid://241650934"
        particle.Speed = NumberRange.new(5, 12)
    elseif ParticleStyle == "Explosion" then
        particle.Lifetime = NumberRange.new(0.4, 0.8)
        particle.Speed = NumberRange.new(15, 30)
        particle.SpreadAngle = Vector2.new(80, 80)
        particle.Amount = ParticleAmount * 2
    elseif ParticleStyle == "Magic" then
        particle.Texture = "rbxassetid://243098098"
        particle.RotSpeed = NumberRange.new(-200, 200)
    end
    particle:Emit(ParticleAmount)
    task.delay(ParticleLifetime + 0.5, function()
        if attachment then attachment:Destroy() end
    end)
end
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and ParticleEffectsEnabled and isAlive() then
        local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {camera, player.Character or {}}
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
        if result and result.Position then
            createParticleEffect(result.Position)
        else
            local muzzlePos = camera.CFrame.Position + camera.CFrame.LookVector * 3
            createParticleEffect(muzzlePos)
        end
    end
end)
--// KILL EFFECTS (NEW)
local KillEffectsEnabled = false
local KillEffectColor = Color3.fromRGB(255, 0, 100)
local KillEffectDuration = 0.8
local KillEffectIntensity = 0.6
local killFlashGui = nil
local killText = nil
local function createKillEffects()
    if not KillEffectsEnabled then return end
    -- Screen Flash
    if not killFlashGui then
        killFlashGui = Instance.new("ScreenGui")
        killFlashGui.ResetOnSpawn = false
        killFlashGui.Parent = player:WaitForChild("PlayerGui")
        local flashFrame = Instance.new("Frame")
        flashFrame.Size = UDim2.new(1, 0, 1, 0)
        flashFrame.BackgroundColor3 = KillEffectColor
        flashFrame.BackgroundTransparency = 1
        flashFrame.BorderSizePixel = 0
        flashFrame.Parent = killFlashGui
        killFlashGui.Frame = flashFrame
    end
    local flash = killFlashGui.Frame
    flash.BackgroundTransparency = 0.2
    TweenService:Create(flash, TweenInfo.new(KillEffectDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    -- Floating Kill Text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 300, 0, 100)
    text.Position = UDim2.new(0.5, -150, 0.4, 0)
    text.BackgroundTransparency = 1
    text.Text = "KILL"
    text.TextColor3 = KillEffectColor
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Parent = player.PlayerGui
    TweenService:Create(text, TweenInfo.new(KillEffectDuration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.25, 0), TextTransparency = 1}):Play()
    task.delay(KillEffectDuration, function()
        if text and text.Parent then text:Destroy() end
    end)
end
-- Detect kills (monitor enemy health dropping to 0)
task.spawn(function()
    local lastHealth = {}
    while task.wait(0.1) do
        if not KillEffectsEnabled then continue end
        local enemyFolder = getEnemyFolder()
        if not enemyFolder then continue end
        for _, enemy in ipairs(enemyFolder:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum then
                local currentHealth = hum.Health
                if lastHealth[enemy] and lastHealth[enemy] > 0 and currentHealth <= 0 then
                    createKillEffects()
                end
                lastHealth[enemy] = currentHealth
            end
        end
    end
end)
--// Visuals Tab UI
