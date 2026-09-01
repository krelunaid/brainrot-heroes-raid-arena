local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

Players.RespawnTime = 2

repeat task.wait(0.1) until workspace:GetAttribute("PrismoraReady")

local remote = ReplicatedStorage:FindFirstChild("PrismoraCombat") or Instance.new("RemoteEvent")
remote.Name = "PrismoraCombat"
remote.Parent = ReplicatedStorage

local oldEnemies = workspace:FindFirstChild("PrismoraEnemies")
if oldEnemies then
	oldEnemies:Destroy()
end

local enemies = Instance.new("Folder")
enemies.Name = "PrismoraEnemies"
enemies.Parent = workspace

local combatCenter = workspace:GetAttribute("PrismoraCombatCenter") or Vector3.new(0, 72, -20)
local combatHalfSizeX = workspace:GetAttribute("PrismoraCombatHalfSizeX") or 48
local combatHalfSizeZ = workspace:GetAttribute("PrismoraCombatHalfSizeZ") or 48
local playerState = {}
local runState = { stage = 0, defeats = 0, runNumber = 0 }
local activeModifier = "NESSUNO"
local currentPhaseText = "INCURSIONE IN PREPARAZIONE"
local registerDefeat

local ENEMY_DATA = {
	Scheggino = { health = 55, speed = 9, damage = 7, range = 5.5, reward = 1, size = 3.2, color = Color3.fromRGB(74, 70, 88) },
	Rapido = { health = 42, speed = 14, damage = 6, range = 5, reward = 1, size = 2.7, color = Color3.fromRGB(69, 114, 145) },
	Gonfio = { health = 105, speed = 6.2, damage = 11, range = 6.2, reward = 2, size = 4.4, color = Color3.fromRGB(111, 69, 121) },
	Tessitore = { health = 78, speed = 7.4, damage = 9, range = 9, reward = 2, size = 3.6, color = Color3.fromRGB(58, 112, 98) },
	Guscione = { health = 170, speed = 5.5, damage = 13, range = 7, reward = 2, size = 5.4, color = Color3.fromRGB(74, 70, 88), armored = true },
	GuscioneElite = { health = 285, speed = 4.8, damage = 17, range = 7.5, reward = 4, size = 6.4, color = Color3.fromRGB(83, 64, 105), armored = true },
	Monolite = { health = 650, speed = 2.2, damage = 18, range = 18, reward = 8, size = 12, color = Color3.fromRGB(74, 70, 88) },
}

local WEAPON_ORDER = { "Scintilla", "Pulsar", "Raggialama", "Frantuma" }
local WEAPON_ASSET_IDS = {
	Raggialama = 94748150816254,
}
local WEAPON_DATA = {
	Scintilla = { damage = 19, finisher = 31, cooldown = 0.31, box = Vector3.new(9, 8, 10), offset = 5 },
	Pulsar = { damage = 21, finisher = 32, cooldown = 0.48, box = Vector3.new(8, 8, 58), offset = 29 },
	Raggialama = { damage = 25, finisher = 39, cooldown = 0.38, box = Vector3.new(11, 9, 12), offset = 6 },
	Frantuma = { damage = 39, finisher = 62, cooldown = 0.72, box = Vector3.new(16, 11, 13), offset = 6.5 },
}

local function getStat(player, name)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name)
end

local function makePart(parent, name, size, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Size = size
	part.Color = color
	part.Material = material
	part.Shape = shape or Enum.PartType.Block
	part.Parent = parent
	return part
end

local function updateHealthDisplay(enemy)
	local root = enemy.PrimaryPart
	local billboard = root and root:FindFirstChild("EnemyHealth")
	local label = billboard and billboard:FindFirstChild("Value")
	local health = enemy:GetAttribute("Health") or 0
	local maxHealth = enemy:GetAttribute("MaxHealth") or 1
	if label then
		local percentage = math.max(0, math.ceil((health / maxHealth) * 100))
		local enemyName = string.upper(enemy:GetAttribute("Kind") or "SPENTO")
		label.Text = percentage >= 100 and enemyName or string.format("%s %d%%", enemyName, percentage)
		if billboard and billboard:IsA("BillboardGui") then
			billboard.Enabled = enemy:GetAttribute("Kind") == "Monolite" or health < maxHealth
			if health < maxHealth and health > 0 then
				local token = os.clock()
				enemy:SetAttribute("HealthLabelToken", token)
				task.delay(1.5, function()
					if enemy.Parent and enemy:GetAttribute("HealthLabelToken") == token and billboard.Parent then
						billboard.Enabled = false
					end
				end)
			end
		end
	end
end

local function createEnemy(kind, position)
	local data = ENEMY_DATA[kind]
	local healthMultiplier = activeModifier == "CORAZZA PRISMATICA" and 1.3 or 1
	local speedMultiplier = activeModifier == "FURIA DEGLI SPENTI" and 1.25 or 1
	local maxHealth = math.floor(data.health * healthMultiplier)
	local model = Instance.new("Model")
	model.Name = kind
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Health", maxHealth)
	model:SetAttribute("MaxHealth", maxHealth)
	model:SetAttribute("MoveSpeed", data.speed * speedMultiplier)
	model:SetAttribute("Dead", false)
	model:SetAttribute("SpawnPosition", position)
	model:SetAttribute("NextAttack", 0)
	model.Parent = enemies

	local root = makePart(
		model,
		"EnemyRoot",
		Vector3.new(data.size, data.size, data.size),
		data.color,
		Enum.Material.Slate,
		kind == "Monolite" and Enum.PartType.Block or Enum.PartType.Ball
	)
	root.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(45), math.rad(kind == "Scheggino" and 45 or 0))
	model.PrimaryPart = root

	local coreSize = kind == "Monolite" and Vector3.new(1.2, 5.4, 0.8) or Vector3.new(data.size * 0.35, data.size * 0.35, data.size * 0.35)
	local core = makePart(model, "WeakCore", coreSize, Color3.fromRGB(255, 122, 47), Enum.Material.Neon, kind == "Monolite" and Enum.PartType.Block or Enum.PartType.Ball)
	core.CFrame = root.CFrame * CFrame.new(0, 0, -(data.size * 0.52))

	if data.armored then
		local shell = makePart(model, "FrontShell", Vector3.new(5.8, 4.2, 1.2), Color3.fromRGB(107, 100, 120), Enum.Material.Slate)
		shell.CFrame = root.CFrame * CFrame.new(0, 0, -2.4)
	elseif kind == "Rapido" then
		for side = -1, 1, 2 do
			local fin = makePart(model, "SpeedFin", Vector3.new(0.35, 1.2, 2.8), Color3.fromRGB(70, 224, 255), Enum.Material.Neon)
			fin.CFrame = root.CFrame * CFrame.new(side * 1.2, 0.3, 0.7) * CFrame.Angles(0, math.rad(side * 20), 0)
		end
	elseif kind == "Tessitore" then
		for index = 1, 4 do
			local leg = makePart(model, "WebLeg", Vector3.new(0.28, 0.28, 3.2), Color3.fromRGB(127, 232, 196), Enum.Material.Neon)
			local angle = math.rad((index - 1) * 90 + 45)
			leg.CFrame = root.CFrame * CFrame.new(math.cos(angle) * 1.7, -0.7, math.sin(angle) * 1.7) * CFrame.Angles(0, -angle, math.rad(18))
		end
	elseif kind == "Monolite" then
		root.Size = Vector3.new(9, 13, 7)
		for index = 1, 3 do
			local band = makePart(model, "PrismBand" .. index, Vector3.new(10.4, 0.35, 8.4), Color3.fromRGB(255, 95, 162), Enum.Material.Neon)
			band.Transparency = 0.12
			band.CFrame = root.CFrame * CFrame.new(0, (index - 2) * 3.4, 0)
		end
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyHealth"
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = kind == "Monolite" and 130 or 34
	billboard.StudsOffset = Vector3.new(0, data.size * 0.72 + 1.4, 0)
	billboard.Size = UDim2.fromOffset(kind == "Monolite" and 190 or 82, kind == "Monolite" and 30 or 18)
	billboard.Enabled = kind == "Monolite"
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(19, 20, 30)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	updateHealthDisplay(model)
	return model
end

local importedWeaponTemplates = {}
local importedWeaponUnavailable = {}

local function importedWeaponClone(weaponName)
	local assetId = WEAPON_ASSET_IDS[weaponName]
	if not assetId or importedWeaponUnavailable[weaponName] then return nil end
	local template = importedWeaponTemplates[weaponName]
	if not template then
		local ok, container = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)
		if not ok or not container then
			importedWeaponUnavailable[weaponName] = true
			warn(string.format("PRISMORA_WEAPON_ASSET_FAILED name=%s asset=%d error=%s", weaponName, assetId, tostring(container)))
			return nil
		end
		for _, item in container:GetDescendants() do
			if item:IsA("LuaSourceContainer") then item:Destroy() end
		end
		container.Name = weaponName .. "MeshTemplate"
		container.Parent = ServerStorage
		importedWeaponTemplates[weaponName] = container
		template = container
		print(string.format("PRISMORA_WEAPON_ASSET_READY name=%s asset=%d", weaponName, assetId))
	end
	return template:Clone()
end

local function attachImportedWeapon(character, hand, weaponName)
	local weapon = importedWeaponClone(weaponName)
	if not weapon then return nil end
	local primary = weapon:FindFirstChild("RaggialamaV2_Body", true)
	if not primary or not primary:IsA("BasePart") then
		primary = weapon:FindFirstChildWhichIsA("BasePart", true)
	end
	if not primary then
		weapon:Destroy()
		return nil
	end

	weapon.Name = "PrismoraWeapon"
	weapon:SetAttribute("WeaponName", weaponName)
	weapon.Parent = character
	weapon.PrimaryPart = primary
	local _, initialSize = weapon:GetBoundingBox()
	local longest = math.max(initialSize.X, initialSize.Y, initialSize.Z)
	if longest > 0.01 then
		weapon:ScaleTo(weapon:GetScale() * (6.6 / longest))
	end

	for _, item in weapon:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = false
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.Massless = true
			if item ~= primary then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary
				weld.Part1 = item
				weld.Parent = item
			end
		end
	end

	local grip = Instance.new("Motor6D")
	grip.Name = "WeaponGrip"
	grip.Part0 = hand
	grip.Part1 = primary
	grip.C0 = CFrame.new(0, -0.84, 0) * CFrame.Angles(0, 0, math.rad(180))
	grip.C1 = CFrame.identity
	grip.Parent = hand

	local trailSource = weapon:FindFirstChild("RaggialamaV2_Energy", true) or primary
	if trailSource:IsA("BasePart") then
		local topAttachment = Instance.new("Attachment")
		topAttachment.Position = Vector3.new(0, -trailSource.Size.Y * 0.46, 0)
		topAttachment.Parent = trailSource
		local bottomAttachment = Instance.new("Attachment")
		bottomAttachment.Position = Vector3.new(0, trailSource.Size.Y * 0.46, 0)
		bottomAttachment.Parent = trailSource
		local trail = Instance.new("Trail")
		trail.Name = "AttackTrail"
		trail.Attachment0 = topAttachment
		trail.Attachment1 = bottomAttachment
		trail.Color = ColorSequence.new(Color3.fromRGB(70, 224, 255), Color3.fromRGB(255, 95, 162))
		trail.Lifetime = 0.24
		trail.LightEmission = 0.8
		trail.Enabled = false
		trail.Parent = trailSource
	end
	return weapon
end

local function attachWeapon(character, weaponName)
	local previousGrip = character:FindFirstChild("WeaponGrip", true)
	if previousGrip then
		previousGrip:Destroy()
	end
	local previous = character:FindFirstChild("PrismoraWeapon")
	if previous then
		previous:Destroy()
	end

	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	if attachImportedWeapon(character, hand, weaponName) then
		return
	end

	local weapon = Instance.new("Model")
	weapon.Name = "PrismoraWeapon"
	weapon:SetAttribute("WeaponName", weaponName)
	weapon.Parent = character

	local handle = Instance.new("Part")
	handle.Name = "WeaponHandle"
	handle.Size = Vector3.new(0.42, weaponName == "Frantuma" and 2.8 or 1.05, 0.42)
	handle.Color = Color3.fromRGB(39, 42, 58)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CFrame = hand.CFrame * CFrame.new(0, -0.85, 0) * CFrame.Angles(0, 0, math.rad(-12))
	handle.Parent = weapon
	weapon.PrimaryPart = handle

	local grip = Instance.new("Motor6D")
	grip.Name = "WeaponGrip"
	grip.Part0 = hand
	grip.Part1 = handle
	grip.C0 = CFrame.new(0, -0.85, 0) * CFrame.Angles(0, 0, math.rad(-12))
	grip.C1 = CFrame.identity
	grip.Parent = hand

	local created = {}
	local function addPiece(name, size, color, material, relative, shape)
		local part = shape == "Wedge" and Instance.new("WedgePart") or Instance.new("Part")
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = material
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CFrame = handle.CFrame * relative
		part.Parent = weapon
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
		table.insert(created, part)
		return part
	end

	local trailSource
	if weaponName == "Scintilla" then
		handle.Transparency = 1
		addPiece("GauntletPalm", Vector3.new(1.22, 1.34, 0.88), Color3.fromRGB(49, 58, 84), Enum.Material.Metal, CFrame.new(0, -0.12, -0.18))
		addPiece("WristCuff", Vector3.new(1.42, 0.48, 1.05), Color3.fromRGB(255, 95, 162), Enum.Material.Metal, CFrame.new(0, 0.78, -0.02))
		addPiece("PrismCore", Vector3.new(0.62, 0.62, 0.28), Color3.fromRGB(70, 224, 255), Enum.Material.Neon, CFrame.new(0, -0.05, -0.66), "Ball")
		for side = -1, 1, 2 do
			addPiece("SidePlate", Vector3.new(0.24, 1.05, 0.9), Color3.fromRGB(214, 228, 255), Enum.Material.Metal, CFrame.new(side * 0.68, -0.08, -0.05) * CFrame.Angles(0, 0, math.rad(side * 12)))
		end
		for finger = -1.5, 1.5, 1 do
			addPiece("Knuckle", Vector3.new(0.22, 0.42, 0.52), finger % 2 == 0.5 and Color3.fromRGB(70, 224, 255) or Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(finger * 0.24, -0.82, -0.5))
		end
		trailSource = addPiece("ImpactArc", Vector3.new(1.92, 0.18, 0.18), Color3.fromRGB(255, 95, 162), Enum.Material.Neon, CFrame.new(0, -1.22, -0.72))
	elseif weaponName == "Pulsar" then
		handle.Color = Color3.fromRGB(32, 37, 54)
		addPiece("PistolBody", Vector3.new(1.06, 0.94, 2.55), Color3.fromRGB(49, 58, 84), Enum.Material.Metal, CFrame.new(0, 0.05, -1.18))
		addPiece("BarrelShroud", Vector3.new(0.78, 0.72, 1.75), Color3.fromRGB(214, 228, 255), Enum.Material.Metal, CFrame.new(0, 0.12, -2.45))
		addPiece("UpperRail", Vector3.new(0.42, 0.2, 2.45), Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(0, 0.67, -1.62))
		addPiece("RearSight", Vector3.new(0.74, 0.42, 0.2), Color3.fromRGB(255, 95, 162), Enum.Material.Neon, CFrame.new(0, 0.88, -0.55))
		addPiece("EnergyCell", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(70, 224, 255), Enum.Material.Neon, CFrame.new(0, 0.02, -1.25), "Ball")
		for side = -1, 1, 2 do
			addPiece("SideCell", Vector3.new(0.28, 0.5, 1.2), side < 0 and Color3.fromRGB(176, 118, 255) or Color3.fromRGB(255, 95, 162), Enum.Material.Neon, CFrame.new(side * 0.64, 0.04, -1.55))
		end
		addPiece("TriggerGuard", Vector3.new(0.68, 0.18, 0.52), Color3.fromRGB(255, 201, 74), Enum.Material.Metal, CFrame.new(0, -0.58, -0.55))
		trailSource = addPiece("Muzzle", Vector3.new(0.86, 0.86, 0.26), Color3.fromRGB(255, 95, 162), Enum.Material.Neon, CFrame.new(0, 0.12, -3.35), "Cylinder")
	elseif weaponName == "Frantuma" then
		handle.Color = Color3.fromRGB(47, 51, 70)
		addPiece("ShaftGrip", Vector3.new(0.72, 1.2, 0.72), Color3.fromRGB(232, 115, 74), Enum.Material.Fabric, CFrame.new(0, -0.45, 0))
		addPiece("ShaftRing", Vector3.new(0.9, 0.24, 0.9), Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(0, -1.25, 0))
		addPiece("HeadSpine", Vector3.new(3.6, 0.58, 0.84), Color3.fromRGB(49, 58, 84), Enum.Material.Metal, CFrame.new(0, -2.32, 0))
		addPiece("AxeCore", Vector3.new(1.15, 1.15, 0.92), Color3.fromRGB(70, 224, 255), Enum.Material.Neon, CFrame.new(0, -2.32, 0), "Ball")
		addPiece("LeftAxeBlade", Vector3.new(0.38, 2.45, 2.5), Color3.fromRGB(214, 228, 255), Enum.Material.Metal, CFrame.new(-1.18, -2.32, 0) * CFrame.Angles(0, 0, math.rad(90)), "Wedge")
		trailSource = addPiece("RightAxeBlade", Vector3.new(0.38, 2.45, 2.5), Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(1.18, -2.32, 0) * CFrame.Angles(0, 0, math.rad(-90)), "Wedge")
		addPiece("BackSpike", Vector3.new(0.55, 1.4, 1.5), Color3.fromRGB(255, 95, 162), Enum.Material.Neon, CFrame.new(0, -3.18, 0) * CFrame.Angles(0, 0, math.rad(90)), "Wedge")
	else
		handle.Color = Color3.fromRGB(31, 35, 52)
		addPiece("PrismGuard", Vector3.new(2.35, 0.32, 0.58), Color3.fromRGB(255, 95, 162), Enum.Material.Metal, CFrame.new(0, -0.92, 0))
		for side = -1, 1, 2 do
			addPiece("GuardWing", Vector3.new(0.34, 0.95, 1.1), side < 0 and Color3.fromRGB(176, 118, 255) or Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(side * 1.02, -1.08, 0) * CFrame.Angles(0, 0, math.rad(side * 38)), "Wedge")
		end
		trailSource = addPiece("PrismBlade", Vector3.new(0.42, 4.05, 1.16), Color3.fromRGB(216, 238, 255), Enum.Material.Glass, CFrame.new(0, -3.0, 0), "Wedge")
		trailSource.Transparency = 0.08
		addPiece("BladeCore", Vector3.new(0.16, 3.55, 0.25), Color3.fromRGB(70, 224, 255), Enum.Material.Neon, CFrame.new(0, -2.9, -0.38))
		addPiece("BladeEdge", Vector3.new(0.12, 3.55, 0.72), Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(0.24, -2.92, 0.02))
		for rune = 1, 3 do
			addPiece("BladeRune", Vector3.new(0.48, 0.12, 0.18), Color3.fromRGB(255, 95, 162), Enum.Material.Neon, CFrame.new(0, -1.8 - (rune * 0.72), -0.51) * CFrame.Angles(0, 0, math.rad(rune % 2 == 0 and 22 or -22)))
		end
		addPiece("Pommel", Vector3.new(0.76, 0.76, 0.76), Color3.fromRGB(255, 201, 74), Enum.Material.Neon, CFrame.new(0, 0.72, 0), "Ball")
	end

	trailSource = trailSource or handle
	local topAttachment = Instance.new("Attachment")
	topAttachment.Position = Vector3.new(0, -trailSource.Size.Y * 0.48, 0)
	topAttachment.Parent = trailSource
	local bottomAttachment = Instance.new("Attachment")
	bottomAttachment.Position = Vector3.new(0, trailSource.Size.Y * 0.48, 0)
	bottomAttachment.Parent = trailSource
	local trail = Instance.new("Trail")
	trail.Name = "AttackTrail"
	trail.Attachment0 = topAttachment
	trail.Attachment1 = bottomAttachment
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 201, 74), Color3.fromRGB(255, 95, 162))
	trail.Lifetime = 0.22
	trail.LightEmission = 0.75
	trail.Enabled = false
	trail.Parent = trailSource
end

local function awardDefeat(player, enemy)
	local defeats = getStat(player, "Sconfitte")
	local fragments = getStat(player, "Frammenti")
	local crystals = getStat(player, "Cristalli")
	local reward = ENEMY_DATA[enemy:GetAttribute("Kind")].reward
	if defeats then defeats.Value += 1 end
	if fragments then fragments.Value += reward end
	if crystals then crystals.Value += enemy:GetAttribute("Kind") == "Monolite" and 3 or 1 end
	remote:FireClient(player, "Reward", reward, enemy:GetAttribute("Kind"))
end

local function defeatEnemy(enemy, player)
	if enemy:GetAttribute("Dead") then return end
	enemy:SetAttribute("Dead", true)
	awardDefeat(player, enemy)
	local spawnPosition = enemy:GetAttribute("SpawnPosition")
	local kind = enemy:GetAttribute("Kind")
	if registerDefeat then registerDefeat(kind) end

	for _, part in enemy:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanQuery = false
			TweenService:Create(part, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = part.Size * 0.12,
				Transparency = 1,
			}):Play()
		end
	end
	task.delay(0.4, function()
		if enemy.Parent then enemy:Destroy() end
	end)
end

local function damageEnemy(enemy, player, amount)
	if enemy:GetAttribute("Dead") then return false end
	local enemyData = ENEMY_DATA[enemy:GetAttribute("Kind")]
	if enemyData and enemyData.armored and enemy.PrimaryPart then
		local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if playerRoot then
			local toPlayer = playerRoot.Position - enemy.PrimaryPart.Position
			if toPlayer.Magnitude > 0 and enemy.PrimaryPart.CFrame.LookVector:Dot(toPlayer.Unit) > 0.2 then
				amount = math.max(3, math.floor(amount * 0.2))
				remote:FireClient(player, "ArmorBlocked")
			end
		end
	end
	local health = math.max(0, (enemy:GetAttribute("Health") or 0) - amount)
	enemy:SetAttribute("Health", health)
	updateHealthDisplay(enemy)

	local root = enemy.PrimaryPart
	if root then
		local original = root.Color
		root.Color = Color3.fromRGB(255, 230, 170)
		local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if playerRoot and enemy:GetAttribute("Kind") ~= "Monolite" then
			local knockback = Vector3.new(root.Position.X - playerRoot.Position.X, 0, root.Position.Z - playerRoot.Position.Z)
			if knockback.Magnitude > 0.1 then
				enemy:PivotTo(enemy:GetPivot() + (knockback.Unit * (amount >= 35 and 3.2 or 1.35)))
			end
		end
		remote:FireClient(player, "HitImpact", amount, root.Position)
		task.delay(0.08, function()
			if root.Parent then root.Color = original end
		end)
	end

	if health <= 0 then
		defeatEnemy(enemy, player)
	end
	return true
end

local function targetsInBox(character, boxSize, forwardOffset)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return {} end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { enemies }
	local parts = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, 0, -forwardOffset), boxSize, params)
	local found = {}
	local result = {}
	for _, part in parts do
		local enemy = part:FindFirstAncestorOfClass("Model")
		if enemy and enemy.Parent == enemies and not found[enemy] then
			found[enemy] = true
			table.insert(result, enemy)
		end
	end
	return result
end

local function flashWeapon(character, duration)
	local weapon = character:FindFirstChild("PrismoraWeapon")
	local trail = weapon and weapon:FindFirstChild("AttackTrail", true)
	local grip = character:FindFirstChild("WeaponGrip", true)
	if trail then
		trail.Enabled = true
		task.delay(duration, function()
			if trail.Parent then trail.Enabled = false end
		end)
	end
	if grip and grip:IsA("Motor6D") and weapon then
		local weaponName = weapon:GetAttribute("WeaponName")
		local strike = weaponName == "Pulsar"
			and CFrame.new(0, 0, 0.32)
			or CFrame.Angles(math.rad(weaponName == "Frantuma" and -105 or -72), 0, math.rad(-32))
		TweenService:Create(grip, TweenInfo.new(0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Transform = strike,
		}):Play()
		task.delay(0.075, function()
			if grip.Parent then
				TweenService:Create(grip, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Transform = CFrame.identity,
				}):Play()
			end
		end)
	end
end

local function addHeroCharge(player, amount)
	local state = playerState[player]
	if not state or state.heroActive then return end
	local multiplier = activeModifier == "TEMPESTA SOLARE" and 1.45 or 1
	state.heroCharge = math.clamp(state.heroCharge + (amount * multiplier), 0, 100)
	remote:FireClient(player, "HeroCharge", state.heroCharge)
	if state.heroCharge >= 100 then
		remote:FireClient(player, "HeroReady")
	end
end

local function createSolaris(player)
	local state = playerState[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not state or not root or state.heroActive or state.heroCharge < 100 then return end
	state.heroCharge = 0
	state.heroActive = true
	remote:FireClient(player, "HeroCharge", 0)

	local hero = Instance.new("Model")
	hero.Name = "SolarisHero"
	hero.Parent = workspace
	local heroPosition = root.Position + (root.CFrame.LookVector * 14) + Vector3.new(0, 9, 0)

	local body = makePart(hero, "SolarisCore", Vector3.new(8, 14, 5), Color3.fromRGB(255, 201, 74), Enum.Material.Neon)
	body.CanQuery = false
	body.CFrame = CFrame.lookAt(heroPosition, heroPosition + root.CFrame.LookVector)
	hero.PrimaryPart = body
	local head = makePart(hero, "SolarisCrown", Vector3.new(7, 7, 7), Color3.fromRGB(255, 240, 184), Enum.Material.Neon, Enum.PartType.Ball)
	head.CanQuery = false
	head.CFrame = body.CFrame * CFrame.new(0, 9, 0)
	for side = -1, 1, 2 do
		local arm = makePart(hero, side < 0 and "LeftSolarArm" or "RightSolarArm", Vector3.new(3.2, 12, 3.2), Color3.fromRGB(255, 95, 162), Enum.Material.Neon)
		arm.CanQuery = false
		arm.CFrame = body.CFrame * CFrame.new(side * 6, 0, 0) * CFrame.Angles(0, 0, math.rad(side * -18))
	end

	local heroLight = Instance.new("PointLight")
	heroLight.Color = Color3.fromRGB(255, 201, 74)
	heroLight.Brightness = 2.5
	heroLight.Range = 34
	heroLight.Shadows = false
	heroLight.Parent = body

	local nameGui = Instance.new("BillboardGui")
	nameGui.Size = UDim2.fromOffset(280, 52)
	nameGui.StudsOffset = Vector3.new(0, 15, 0)
	nameGui.AlwaysOnTop = true
	nameGui.MaxDistance = 180
	nameGui.Parent = body
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Text = "SOLARIS • " .. string.upper(player.DisplayName)
	nameLabel.TextColor3 = Color3.fromRGB(255, 240, 184)
	nameLabel.TextScaled = true
	nameLabel.Parent = nameGui

	local aura = Instance.new("Highlight")
	aura.FillColor = Color3.fromRGB(255, 201, 74)
	aura.FillTransparency = 0.45
	aura.OutlineColor = Color3.fromRGB(255, 95, 162)
	aura.OutlineTransparency = 0.02
	aura.Parent = character

	remote:FireAllClients("HeroSummoned", player.DisplayName)

	task.spawn(function()
		for pulseIndex = 1, 5 do
			if not hero.Parent then break end
			local ring = Instance.new("Part")
			ring.Name = "SolarisShockwave"
			ring.Anchored = true
			ring.CanCollide = false
			ring.CanTouch = false
			ring.CanQuery = false
			ring.Shape = Enum.PartType.Cylinder
			ring.Material = Enum.Material.Neon
			ring.Color = pulseIndex % 2 == 0 and Color3.fromRGB(255, 95, 162) or Color3.fromRGB(255, 201, 74)
			ring.Transparency = 0.18
			ring.Size = Vector3.new(0.35, 4, 4)
			ring.CFrame = CFrame.new(hero.PrimaryPart.Position - Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = workspace
			TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {
				Size = Vector3.new(0.35, 72, 72),
				Transparency = 1,
			}):Play()
			task.delay(0.6, function() if ring.Parent then ring:Destroy() end end)

			for _, enemy in enemies:GetChildren() do
				if enemy:IsA("Model") and enemy.PrimaryPart and not enemy:GetAttribute("Dead") then
					if (enemy.PrimaryPart.Position - hero.PrimaryPart.Position).Magnitude <= 40 then
						damageEnemy(enemy, player, pulseIndex == 1 and 95 or 62)
					end
				end
			end
			task.wait(1.35)
		end
	end)

	task.delay(8, function()
		if hero.Parent then hero:Destroy() end
		if aura.Parent then aura:Destroy() end
		if playerState[player] then playerState[player].heroActive = false end
	end)
end

remote.OnServerEvent:Connect(function(player, action)
	local state = playerState[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not state or not character or not humanoid or humanoid.Health <= 0 or not root then return end

	local now = os.clock()
	if action == "Attack" and now >= state.attack then
		local weaponName = WEAPON_ORDER[state.weaponIndex or 1]
		local weaponData = WEAPON_DATA[weaponName]
		state.attack = now + weaponData.cooldown
		state.combo = (state.combo % 3) + 1
		local damage = state.combo == 3 and weaponData.finisher or weaponData.damage
		local hitCount = 0
		for _, enemy in targetsInBox(character, weaponData.box, weaponData.offset) do
			if damageEnemy(enemy, player, damage) then
				hitCount += 1
				addHeroCharge(player, state.combo == 3 and 25 or 18)
			end
		end
		flashWeapon(character, 0.24)
		remote:FireClient(player, "AttackFeedback", state.combo, hitCount, weaponName)
	elseif action == "Skill" and now >= state.skill then
		state.skill = now + 7
		local hitCount = 0
		for _, enemy in targetsInBox(character, Vector3.new(16, 12, 28), 13) do
			if damageEnemy(enemy, player, 72) then
				hitCount += 1
				addHeroCharge(player, 30)
			end
		end
		root.AssemblyLinearVelocity = (root.CFrame.LookVector * 48) + Vector3.new(0, math.max(5, root.AssemblyLinearVelocity.Y), 0)
		flashWeapon(character, 0.55)
		remote:FireClient(player, "SkillFeedback", hitCount, 7)
	elseif action == "Dash" and now >= state.dash then
		state.dash = now + 1.2
		root.AssemblyLinearVelocity = (root.CFrame.LookVector * 78) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		remote:FireClient(player, "DashFeedback", 1.2)
	elseif action == "SummonHero" then
		createSolaris(player)
	elseif action == "CycleWeapon" and now >= (state.cycle or 0) then
		state.cycle = now + 0.35
		state.weaponIndex = ((state.weaponIndex or 1) % #WEAPON_ORDER) + 1
		local weaponName = WEAPON_ORDER[state.weaponIndex]
		attachWeapon(character, weaponName)
		remote:FireClient(player, "WeaponChanged", weaponName, state.weaponIndex, WEAPON_DATA[weaponName].cooldown)
	end
end)

local function nearestPlayer(position, maxDistance)
	local bestPlayer, bestRoot, bestDistance
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local state = playerState[player]
		if humanoid and humanoid.Health > 0 and root and (not state or os.clock() >= (state.protectedUntil or 0)) then
			local distance = (root.Position - position).Magnitude
			if distance <= maxDistance and (not bestDistance or distance < bestDistance) then
				bestPlayer, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return bestPlayer, bestRoot, bestDistance
end

local function balancedTarget(enemy, maxDistance)
	local loads = {}
	for _, other in enemies:GetChildren() do
		local userId = other:GetAttribute("TargetUserId")
		if userId and userId ~= 0 and not other:GetAttribute("Dead") then
			loads[userId] = (loads[userId] or 0) + 1
		end
	end

	local bestPlayer, bestRoot, bestScore
	for _, candidate in Players:GetPlayers() do
		local character = candidate.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local state = playerState[candidate]
		if humanoid and humanoid.Health > 0 and root and (not state or os.clock() >= (state.protectedUntil or 0)) then
			local distance = (root.Position - enemy.PrimaryPart.Position).Magnitude
			if distance <= maxDistance then
				local score = distance + ((loads[candidate.UserId] or 0) * 14)
				if not bestScore or score < bestScore then
					bestPlayer, bestRoot, bestScore = candidate, root, score
				end
			end
		end
	end
	return bestPlayer, bestRoot
end

local function separationVector(enemy, position)
	local steering = Vector3.zero
	for _, other in enemies:GetChildren() do
		if other ~= enemy and other:IsA("Model") and other.PrimaryPart and not other:GetAttribute("Dead") then
			local offset = Vector3.new(position.X - other.PrimaryPart.Position.X, 0, position.Z - other.PrimaryPart.Position.Z)
			local distance = offset.Magnitude
			if distance > 0.05 and distance < 11 then
				steering += offset.Unit * ((11 - distance) / 11)
			elseif distance <= 0.05 then
				local sign = enemy:GetAttribute("OrbitSign") or 1
				steering += Vector3.new(sign, 0, -sign)
			end
		end
	end
	return steering
end

local function clampToCombatFloor(position)
	return Vector3.new(
		math.clamp(position.X, combatCenter.X - combatHalfSizeX, combatCenter.X + combatHalfSizeX),
		position.Y,
		math.clamp(position.Z, combatCenter.Z - combatHalfSizeZ, combatCenter.Z + combatHalfSizeZ)
	)
end

local function activeAttackers(userId, now)
	local count = 0
	for _, other in enemies:GetChildren() do
		if other:GetAttribute("TargetUserId") == userId and (other:GetAttribute("AttackTokenUntil") or 0) > now then
			count += 1
		end
	end
	return count
end

local function bossShockwave(enemy)
	if not enemy.PrimaryPart or enemy:GetAttribute("Dead") then return end
	local origin = enemy.PrimaryPart.Position - Vector3.new(0, 6.2, 0)
	local warning = Instance.new("Part")
	warning.Name = "BossWarning"
	warning.Anchored = true
	warning.CanCollide = false
	warning.CanTouch = false
	warning.CanQuery = false
	warning.Shape = Enum.PartType.Cylinder
	warning.Material = Enum.Material.Neon
	warning.Color = Color3.fromRGB(255, 122, 47)
	warning.Transparency = 0.5
	warning.Size = Vector3.new(0.22, 40, 40)
	warning.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
	warning.Parent = workspace
	remote:FireAllClients("BossTelegraph")
	TweenService:Create(warning, TweenInfo.new(0.8), { Transparency = 0.16 }):Play()

	task.delay(0.85, function()
		if warning.Parent then
			warning.Color = Color3.fromRGB(255, 95, 162)
			TweenService:Create(warning, TweenInfo.new(0.34), {
				Size = Vector3.new(0.22, 58, 58),
				Transparency = 1,
			}):Play()
		end
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and root and (root.Position - origin).Magnitude <= 24 then
				local state = playerState[player]
				local now = os.clock()
				if not state or now >= (state.nextDamage or 0) then
					if state then
						state.nextDamage = now + 0.65
						state.lastDamage = now
					end
					humanoid:TakeDamage(18)
					remote:FireClient(player, "DamageReceived", 18, "Monolite")
				end
			end
		end
		task.delay(0.4, function() if warning.Parent then warning:Destroy() end end)
	end)
end

local aiAccumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
	aiAccumulator += deltaTime
	if aiAccumulator < 0.08 then return end
	local step = aiAccumulator
	aiAccumulator = 0

	for _, enemy in enemies:GetChildren() do
		if enemy:IsA("Model") and enemy.PrimaryPart and not enemy:GetAttribute("Dead") then
			local data = ENEMY_DATA[enemy:GetAttribute("Kind")]
			local position = enemy.PrimaryPart.Position
			local now = os.clock()
			local player, targetRoot
			local currentUserId = enemy:GetAttribute("TargetUserId") or 0
			if currentUserId ~= 0 and now < (enemy:GetAttribute("NextTargetUpdate") or 0) then
				player = Players:GetPlayerByUserId(currentUserId)
				targetRoot = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			end
			if not player or not targetRoot then
				player, targetRoot = balancedTarget(enemy, enemy:GetAttribute("Kind") == "Monolite" and 70 or 95)
				enemy:SetAttribute("TargetUserId", player and player.UserId or 0)
				enemy:SetAttribute("NextTargetUpdate", now + 2.5)
			end
			if player and targetRoot then
				local flatTarget = Vector3.new(targetRoot.Position.X, position.Y, targetRoot.Position.Z)
				local delta = flatTarget - position
				local distance = delta.Magnitude
				local separation = separationVector(enemy, position)
				if distance > data.range + 0.8 and distance > 0.1 then
					local desired = delta.Unit + (separation * 1.35)
					if desired.Magnitude > 0.1 then
						local newPosition = clampToCombatFloor(position + (desired.Unit * (enemy:GetAttribute("MoveSpeed") or data.speed) * step))
						enemy:PivotTo(CFrame.lookAt(newPosition, newPosition + desired.Unit))
					end
				elseif now >= (enemy:GetAttribute("NextAttack") or 0) then
					local maxAttackers = math.clamp(math.ceil(#Players:GetPlayers() * 0.75), 1, 4)
					if enemy:GetAttribute("Kind") == "Monolite" or activeAttackers(player.UserId, now) < maxAttackers then
						enemy:SetAttribute("AttackTokenUntil", now + 0.9)
						enemy:SetAttribute("NextAttack", now + (enemy:GetAttribute("Kind") == "Monolite" and 2.8 or 1.7))
						if enemy:GetAttribute("Kind") == "Monolite" then
						bossShockwave(enemy)
						else
						local humanoid = targetRoot.Parent and targetRoot.Parent:FindFirstChildOfClass("Humanoid")
							if humanoid then
								local state = playerState[player]
								if not state or now >= (state.nextDamage or 0) then
									if state then
										state.nextDamage = now + 0.65
										state.lastDamage = now
									end
									humanoid:TakeDamage(data.damage)
									remote:FireClient(player, "DamageReceived", data.damage, enemy:GetAttribute("Kind"))
								end
							end
						end
					else
						local tangent = Vector3.new(-delta.Z, 0, delta.X)
					if tangent.Magnitude > 0.1 then
						local orbitSign = enemy:GetAttribute("OrbitSign") or 1
						local desired = (tangent.Unit * orbitSign) + (separation * 1.7)
						local newPosition = clampToCombatFloor(position + (desired.Unit * (enemy:GetAttribute("MoveSpeed") or data.speed) * 0.55 * step))
						enemy:PivotTo(CFrame.lookAt(newPosition, flatTarget))
					end
					end
				end
			end
		end
	end
end)

local function setupPlayer(player)
	playerState[player] = { attack = 0, skill = 0, dash = 0, cycle = 0, combo = 0, heroCharge = 0, heroActive = false, weaponIndex = 3, protectedUntil = os.clock() + 7, nextDamage = 0, lastDamage = 0 }
	local function configureCharacter(character)
		if playerState[player] then playerState[player].protectedUntil = os.clock() + 7 end
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.BreakJointsOnDeath = false
		humanoid.MaxHealth = 140
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = 20
		humanoid.JumpHeight = 9
		humanoid.Died:Connect(function()
			remote:FireClient(player, "PlayerDown")
		end)
		task.wait(0.4)
		local weaponIndex = playerState[player] and playerState[player].weaponIndex or 3
		local weaponName = WEAPON_ORDER[weaponIndex]
		attachWeapon(character, weaponName)
		remote:FireClient(player, "WeaponEquipped", weaponName, weaponIndex, WEAPON_DATA[weaponName].cooldown)
		remote:FireClient(player, "RunPhase", currentPhaseText, activeModifier)
		if runState.stage > 0 then
			remote:FireClient(player, "RunProgress", runState.stage, runState.defeats, runState.expectedDefeats or 0)
		end
		remote:FireClient(player, "HeroCharge", playerState[player] and playerState[player].heroCharge or 0)
	end
	player.CharacterAdded:Connect(configureCharacter)
	if player.Character then
		task.spawn(configureCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)
for _, player in Players:GetPlayers() do setupPlayer(player) end

task.spawn(function()
	while enemies.Parent do
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local state = playerState[player]
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if state and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth and now - (state.lastDamage or 0) >= 3 then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 6)
			end
		end
		task.wait(1)
	end
end)

local function announcePhase(text)
	currentPhaseText = text
	remote:FireAllClients("RunPhase", text, activeModifier)
end

local function startStage(stage)
	runState.stage = stage
	runState.defeats = 0
	local entries
	local playerCount = math.max(1, #Players:GetPlayers())
	if stage == 1 then
		announcePhase("ONDATA 1 • SCHIVA IL BRANCO")
		local pool = { "Scheggino", "Rapido", "Gonfio", "Tessitore", "Scheggino", "Rapido", "Gonfio", "Tessitore", "Scheggino", "Rapido", "Gonfio", "Tessitore" }
		entries = {}
		for index = 1, math.min(3 + (playerCount * 2), #pool) do table.insert(entries, pool[index]) end
	elseif stage == 2 then
		announcePhase("ONDATA 2 • ROMPI LE CORAZZE")
		local pool = { "Rapido", "Guscione", "Tessitore", "Gonfio", "Guscione", "Scheggino", "GuscioneElite", "Rapido", "Guscione", "Tessitore", "Gonfio", "GuscioneElite", "Rapido", "Guscione" }
		entries = {}
		for index = 1, math.min(4 + (playerCount * 2), #pool) do table.insert(entries, pool[index]) end
	elseif stage == 3 then
		announcePhase("GUARDIANO SPENTO • EVOCA SOLARIS")
		entries = { "Monolite" }
	end
	if entries then
		runState.expectedDefeats = #entries
		remote:FireAllClients("RunProgress", stage, 0, #entries)
		task.spawn(function()
			for index, kind in entries do
				local ring = stage == 3 and 38 or (22 + ((index % 2) * 8))
				local angle = ((index - 1) / #entries) * math.pi * 2
				local data = ENEMY_DATA[kind]
				local rootHeight = kind == "Monolite" and 13 or data.size
				local floorY = combatCenter.Y - 2
				local spawnY = floorY + (rootHeight * 0.5) + 0.15
				local position = clampToCombatFloor(Vector3.new(
					combatCenter.X + (math.cos(angle) * ring),
					spawnY,
					combatCenter.Z + (math.sin(angle) * ring) - 8
				))
				local enemy = createEnemy(kind, position)
				enemy:SetAttribute("OrbitSign", index % 2 == 0 and 1 or -1)
				enemy:SetAttribute("TargetUserId", 0)
				enemy:SetAttribute("AttackTokenUntil", 0)
				task.wait(0.18)
			end
		end)
	end
end

local function beginRun()
	for _, enemy in enemies:GetChildren() do enemy:Destroy() end
	runState.runNumber += 1
	local modifiers = { "FURIA DEGLI SPENTI", "CORAZZA PRISMATICA", "TEMPESTA SOLARE" }
	activeModifier = modifiers[((runState.runNumber - 1) % #modifiers) + 1]
	remote:FireAllClients("RunModifier", activeModifier)
	startStage(1)
end

registerDefeat = function(kind)
	runState.defeats += 1
	remote:FireAllClients("RunProgress", runState.stage, runState.defeats, runState.expectedDefeats or 0)
	if runState.stage == 1 and runState.defeats >= (runState.expectedDefeats or 7) then
		task.delay(1.2, function() startStage(2) end)
	elseif runState.stage == 2 and runState.defeats >= (runState.expectedDefeats or 8) then
		task.delay(1.5, function() startStage(3) end)
	elseif runState.stage == 3 and kind == "Monolite" then
		runState.stage = 4
		announcePhase("INCURSIONE COMPLETATA • FRAMMENTI OTTENUTI")
		local teamReward = 3
		for _, player in Players:GetPlayers() do
			local fragments = getStat(player, "Frammenti")
			if fragments then
				fragments.Value += teamReward
			end
		end
		remote:FireAllClients("RunComplete", runState.runNumber, teamReward)
		task.delay(8, beginRun)
	end
end

task.delay(1, beginRun)

print("PRISMORA_ACTION_READY waves=adaptive separation=on attack_tokens=scaled solo_regen=on")
