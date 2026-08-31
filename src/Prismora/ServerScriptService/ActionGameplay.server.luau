local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
local playerState = {}

local ENEMY_DATA = {
	Scheggino = { health = 55, speed = 9, damage = 7, range = 5.5, reward = 1, size = 3.2 },
	Guscione = { health = 170, speed = 5.5, damage = 13, range = 7, reward = 2, size = 5.4 },
	Monolite = { health = 650, speed = 2.2, damage = 18, range = 11, reward = 8, size = 12 },
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
		label.Text = string.format("%s  %d%%", string.upper(enemy:GetAttribute("Kind") or "SPENTO"), math.max(0, math.ceil((health / maxHealth) * 100)))
	end
end

local function createEnemy(kind, position)
	local data = ENEMY_DATA[kind]
	local model = Instance.new("Model")
	model.Name = kind
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Health", data.health)
	model:SetAttribute("MaxHealth", data.health)
	model:SetAttribute("Dead", false)
	model:SetAttribute("SpawnPosition", position)
	model:SetAttribute("NextAttack", 0)
	model.Parent = enemies

	local root = makePart(
		model,
		"EnemyRoot",
		Vector3.new(data.size, data.size, data.size),
		Color3.fromRGB(74, 70, 88),
		Enum.Material.Slate,
		kind == "Monolite" and Enum.PartType.Block or Enum.PartType.Ball
	)
	root.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(45), math.rad(kind == "Scheggino" and 45 or 0))
	model.PrimaryPart = root

	local coreSize = kind == "Monolite" and Vector3.new(1.2, 5.4, 0.8) or Vector3.new(data.size * 0.35, data.size * 0.35, data.size * 0.35)
	local core = makePart(model, "WeakCore", coreSize, Color3.fromRGB(255, 122, 47), Enum.Material.Neon, kind == "Monolite" and Enum.PartType.Block or Enum.PartType.Ball)
	core.CFrame = root.CFrame * CFrame.new(0, 0, -(data.size * 0.52))

	if kind == "Guscione" then
		local shell = makePart(model, "FrontShell", Vector3.new(5.8, 4.2, 1.2), Color3.fromRGB(107, 100, 120), Enum.Material.Slate)
		shell.CFrame = root.CFrame * CFrame.new(0, 0, -2.4)
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
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.StudsOffset = Vector3.new(0, data.size * 0.8 + 2.2, 0)
	billboard.Size = UDim2.fromOffset(kind == "Monolite" and 230 or 160, 36)
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

local function attachWeapon(character)
	local previous = character:FindFirstChild("RaggialamaAlba")
	if previous then
		previous:Destroy()
	end

	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end

	local weapon = Instance.new("Model")
	weapon.Name = "RaggialamaAlba"
	weapon.Parent = character

	local handle = Instance.new("Part")
	handle.Name = "WeaponHandle"
	handle.Size = Vector3.new(0.38, 1.25, 0.38)
	handle.Color = Color3.fromRGB(232, 115, 74)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CFrame = hand.CFrame * CFrame.new(0, -0.85, 0) * CFrame.Angles(0, 0, math.rad(-12))
	handle.Parent = weapon
	weapon.PrimaryPart = handle

	local blade = Instance.new("WedgePart")
	blade.Name = "PrismBlade"
	blade.Size = Vector3.new(0.28, 3.8, 0.92)
	blade.Color = Color3.fromRGB(255, 233, 184)
	blade.Material = Enum.Material.Glass
	blade.Transparency = 0.18
	blade.CanCollide = false
	blade.CanTouch = false
	blade.CanQuery = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, -2.35, 0)
	blade.Parent = weapon

	local core = Instance.new("Part")
	core.Name = "PrismCore"
	core.Size = Vector3.new(0.12, 3.25, 0.18)
	core.Color = Color3.fromRGB(255, 201, 74)
	core.Material = Enum.Material.Neon
	core.CanCollide = false
	core.CanTouch = false
	core.CanQuery = false
	core.Massless = true
	core.CFrame = blade.CFrame * CFrame.new(0, 0, -0.35)
	core.Parent = weapon

	local weldHand = Instance.new("WeldConstraint")
	weldHand.Part0 = hand
	weldHand.Part1 = handle
	weldHand.Parent = handle
	for _, part in { blade, core } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end

	local topAttachment = Instance.new("Attachment")
	topAttachment.Position = Vector3.new(0, -1.85, 0)
	topAttachment.Parent = blade
	local bottomAttachment = Instance.new("Attachment")
	bottomAttachment.Position = Vector3.new(0, 1.85, 0)
	bottomAttachment.Parent = blade
	local trail = Instance.new("Trail")
	trail.Name = "AttackTrail"
	trail.Attachment0 = topAttachment
	trail.Attachment1 = bottomAttachment
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 201, 74), Color3.fromRGB(255, 95, 162))
	trail.Lifetime = 0.22
	trail.LightEmission = 0.75
	trail.Enabled = false
	trail.Parent = blade
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
	task.delay(kind == "Monolite" and 18 or 7, function()
		createEnemy(kind, spawnPosition)
	end)
end

local function damageEnemy(enemy, player, amount)
	if enemy:GetAttribute("Dead") then return false end
	local health = math.max(0, (enemy:GetAttribute("Health") or 0) - amount)
	enemy:SetAttribute("Health", health)
	updateHealthDisplay(enemy)

	local root = enemy.PrimaryPart
	if root then
		local original = root.Color
		root.Color = Color3.fromRGB(255, 230, 170)
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
	local weapon = character:FindFirstChild("RaggialamaAlba")
	local trail = weapon and weapon:FindFirstChild("AttackTrail", true)
	if trail then
		trail.Enabled = true
		task.delay(duration, function()
			if trail.Parent then trail.Enabled = false end
		end)
	end
end

local function addHeroCharge(player, amount)
	local state = playerState[player]
	if not state or state.heroActive then return end
	state.heroCharge = math.clamp(state.heroCharge + amount, 0, 100)
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
		state.attack = now + 0.38
		state.combo = (state.combo % 3) + 1
		local damage = state.combo == 3 and 36 or 23
		local hitCount = 0
		for _, enemy in targetsInBox(character, Vector3.new(10, 8, 11), 5.5) do
			if damageEnemy(enemy, player, damage) then
				hitCount += 1
				addHeroCharge(player, state.combo == 3 and 25 or 18)
			end
		end
		flashWeapon(character, 0.24)
		remote:FireClient(player, "AttackFeedback", state.combo, hitCount)
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
	end
end)

local function nearestPlayer(position, maxDistance)
	local bestPlayer, bestRoot, bestDistance
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - position).Magnitude
			if distance <= maxDistance and (not bestDistance or distance < bestDistance) then
				bestPlayer, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return bestPlayer, bestRoot, bestDistance
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
			local player, targetRoot, distance = nearestPlayer(position, enemy:GetAttribute("Kind") == "Monolite" and 55 or 70)
			if player and targetRoot and distance then
				local flatTarget = Vector3.new(targetRoot.Position.X, position.Y, targetRoot.Position.Z)
				local delta = flatTarget - position
				if distance > data.range and delta.Magnitude > 0.1 then
					local newPosition = position + (delta.Unit * data.speed * step)
					enemy:PivotTo(CFrame.lookAt(newPosition, newPosition + delta.Unit))
				elseif os.clock() >= (enemy:GetAttribute("NextAttack") or 0) then
					enemy:SetAttribute("NextAttack", os.clock() + (enemy:GetAttribute("Kind") == "Monolite" and 2.8 or 1.7))
					local humanoid = targetRoot.Parent and targetRoot.Parent:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(data.damage)
						remote:FireClient(player, "DamageReceived", data.damage, enemy:GetAttribute("Kind"))
					end
				end
			end
		end
	end
end)

local function setupPlayer(player)
	playerState[player] = { attack = 0, skill = 0, dash = 0, combo = 0, heroCharge = 0, heroActive = false }
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 20
		humanoid.JumpHeight = 9
		task.wait(0.4)
		attachWeapon(character)
		remote:FireClient(player, "WeaponEquipped")
	end)
	if player.Character then
		task.defer(attachWeapon, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)
for _, player in Players:GetPlayers() do setupPlayer(player) end

createEnemy("Scheggino", combatCenter + Vector3.new(-9, 4, -12))
createEnemy("Scheggino", combatCenter + Vector3.new(0, 5, -16))
createEnemy("Scheggino", combatCenter + Vector3.new(10, 4, -11))
createEnemy("Guscione", combatCenter + Vector3.new(-18, 4, -30))
createEnemy("Monolite", combatCenter + Vector3.new(18, 8, -42))

print("PRISMORA_ACTION_READY enemies=5 weapon=RaggialamaAlba")
